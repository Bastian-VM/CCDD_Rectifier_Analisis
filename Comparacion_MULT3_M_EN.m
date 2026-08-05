%% ============================================================
% Title: Comparative analysis of M variations in MULT3 (C00-80, R100k)
%
% Author: Bastian Veas Moyano
%
% Last modification: August 04, 2026
%
% Description: This script loads combined simulation results of the
% Cross-Coupled Differential Drive Rectifier (CCDDR) for the MULT3 case,
% filtering files with capacitance C00-80 and resistance R100k. It builds
% a comparative table based on the multiplier M, calculating metrics of
% efficiency, output voltage, input power, maximum VRF, local area, and
% geometric size. Metrics are then normalized to obtain a weighted score
% and comparative plots are generated.
%% ============================================================
clear; close all; clc;

%% ============================================================
% Working folder and load results
%% ============================================================
folder = 'D:\Memoria_Last\Simulaciones_Xschem\Archivos_MAT';
load(fullfile(folder,'all_Results.mat')); % must contain allResults
disp(['Total loaded results: ', num2str(numel(allResults))]);

%% ============================================================
% Filter only files with MULT3, C00-80 and R100k
%% ============================================================
allResults = allResults(contains({allResults.file}, 'MULT3') & ...
                        contains({allResults.file}, 'C00-80') & ...
                        contains({allResults.file}, 'R100k') & ...
                        contains({allResults.file}, 'L00-20_W00-60'));
disp(['Selected files: ', num2str(numel(allResults))]);

%% ============================================================
% Build table with M and metrics
%% ============================================================
tablaMComp = table();
for f = 1:numel(allResults)
    fname = allResults(f).file;
    fprintf('Processing file: %s\n', fname);

    % Extract multiplier M from filename
    tokensM = regexp(fname,'M(\d+)(E?)','tokens');
    if isempty(tokensM), continue; end
    M_val = str2double(tokensM{1}{1});

    % Sort results by Pin and calculate metrics
    [Pin_sorted, idx_sort] = sort(allResults(f).Pin_dBm);
    PCE_sorted   = allResults(f).PCE(idx_sort);
    Vout_sorted  = allResults(f).Vout(idx_sort);
    VRF_sorted   = allResults(f).VRFmax(idx_sort);

    % Metrics at maximum efficiency point
    [PCE_max, idx_max] = max(PCE_sorted);
    Pin_at_max   = Pin_sorted(idx_max);
    Vout_at_max  = Vout_sorted(idx_max);
    VRF_at_max   = VRF_sorted(idx_max);
    Ratio_at_max = Vout_at_max / VRF_at_max;

    % Local area ±5 dBm around maximum
    mask_range = (Pin_sorted >= (Pin_at_max - 5)) & (Pin_sorted <= (Pin_at_max + 5));
    x_local = Pin_sorted(mask_range); y_local = PCE_sorted(mask_range);
    if numel(x_local)>1
        area_local = trapz(x_local,y_local);
    else
        area_local = 0;
    end

    % Extract geometry L and W from filename
    tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
    tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
    if ~isempty(tokensL)
        Lval = str2double(tokensL{1}{1}) + str2double(tokensL{1}{2})/100;
    else, Lval = NaN; end
    if ~isempty(tokensW)
        Wval = str2double(tokensW{1}{1}) + str2double(tokensW{1}{2})/100;
    else, Wval = NaN; end

    % Geometric product with unit µm² (MULT3 → factor 3)
    size_geom = 3*Lval * Wval * M_val;
    size_geom_str = sprintf('%.3f µm²', size_geom);

    % Add row to table
    tablaMComp = [tablaMComp;
        table({fname}, M_val, PCE_max, Pin_at_max, Vout_at_max, VRF_at_max, ...
              Ratio_at_max, area_local, {size_geom_str}, ...
              'VariableNames', {'File','M','PCE_max','Pin_dBm','Vout', ...
                                'VRF_at_max','Vout_VRFmax','Area_local','LxWxM'})];
end

%% ============================================================
% Normalization and Score
%% ============================================================
size_geom_vals = cellfun(@(x) sscanf(x,'%f'), tablaMComp.LxWxM);

% Normalize metrics
PCE_norm   = normalize(tablaMComp.PCE_max,'range');
Pin_norm   = normalize(tablaMComp.Pin_dBm,'range');
Vout_norm  = normalize(tablaMComp.Vout,'range');
VRF_norm   = normalize(tablaMComp.VRF_at_max,'range');
Area_norm  = normalize(tablaMComp.Area_local,'range');
Size_norm  = normalize(size_geom_vals,'range');

% Invert metrics where lower is better
Pin_norm_inv  = 1 - Pin_norm;
Size_norm_inv = 1 - Size_norm;
VRF_norm_inv  = 1 - VRF_norm;

% Weights for each metric
wPCE   = 0.20;   % maximum efficiency
wPin   = 0.15;   % input power
wVout  = 0.20;   % output voltage
wVRF   = 0.25;   % maximum VRF
wArea  = 0.15;   % local area
wSize  = 0.05;   % geometric size

% Weighted score
score = wPCE*PCE_norm + ...
        wPin*Pin_norm_inv + ...
        wVout*Vout_norm + ...
        wVRF*VRF_norm_inv + ...
        wArea*Area_norm + ...
        wSize*Size_norm_inv;

tablaMComp.Score = score;

% Sort table by Score (descending)
tablaMComp_sorted = sortrows(tablaMComp,'Score','descend');

%% ============================================================
% Show comparative table
%% ============================================================
disp('================ COMPARATIVE TABLE MULT3 FILES (C00-80, by M) =================');
disp(tablaMComp_sorted(1:min(20,height(tablaMComp_sorted)),:));

%% ============================================================
% Metrics vs M plots
%% ============================================================
tablaMComp_byM = sortrows(tablaMComp,'M');

figure('Color','w');

subplot(2,2,1);
plot(tablaMComp_byM.M, tablaMComp_byM.PCE_max,'-o','LineWidth',1.6,'MarkerFaceColor','r');
xlabel('M (multiplier)'); ylabel('PCE_{max}');
title('PCE_{max} vs M (C00-80, MULT3)'); grid on;

subplot(2,2,2);
plot(tablaMComp_byM.M, tablaMComp_byM.Vout,'-s','LineWidth',1.6,'MarkerFaceColor','b');
xlabel('M (multiplier)'); ylabel('Vout_{at max} [V]');
title('Vout_{at max} vs M (C00-80, MULT3)'); grid on;

subplot(2,2,3);
plot(tablaMComp_byM.M, tablaMComp_byM.Pin_dBm,'-^','LineWidth',1.6,'MarkerFaceColor','g');
xlabel('M (multiplier)'); ylabel('Pin_{at max} [dBm]');
title('Pin_{at max} vs M (C00-80, MULT3)'); grid on;

subplot(2,2,4);
plot(tablaMComp_byM.M, tablaMComp_byM.VRF_at_max,'-d','LineWidth',1.6,'MarkerFaceColor','m');
xlabel('M (multiplier)'); ylabel('VRF_{at max} [V]');
title('VRF_{at max} vs M (C00-80, MULT3)'); grid on;

sgtitle('Comparison of metrics vs M (only MULT3 files with C00-80)');
