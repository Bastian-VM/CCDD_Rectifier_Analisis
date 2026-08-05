%% ============================================================
% Title: Comparative analysis of L variations in MULT3 (C00-80, R100k, M25)
%
% Author: Bastian Veas Moyano
%
% Last modification: August 05, 2026
%
% Description: This script loads combined simulation results of the
% Cross-Coupled Differential Drive Rectifier (CCDDR) for the MULT3 case,
% filtering files with capacitance C00-80, resistance R100k, and multiplier M25.
% It builds a comparative table based on the length L, calculating metrics
% of efficiency, output voltage, input power, maximum VRF, local area, and
% geometric size. Metrics are then normalized to obtain a weighted score
% and comparative plots are generated.
%% ============================================================
clear; close all; clc;

%% ============================================================
% Define weights for each metric
%% ============================================================
wPCE   = 0.25;   % maximum efficiency
wPin   = 0.25;   % input power
wVout  = 0.25;   % output voltage
wVRF   = 0.10;   % maximum VRF
wArea  = 0.10;   % local area
wSize  = 0.05;   % geometric size

%% ============================================================
% Working folder and load results
%% ============================================================
folder = 'D:\Memoria_Last\Simulaciones_Xschem\Archivos_MAT';
load(fullfile(folder,'all_Results.mat')); % must contain allResults
disp(['Total loaded results: ', num2str(numel(allResults))]);

%% ============================================================
% Filter only files with MULT3, C00-80, R100k and M25
%% ============================================================
allResults = allResults(contains({allResults.file}, 'MULT3') & ...
                        contains({allResults.file}, 'C00-80') & ...
                        contains({allResults.file}, 'R100k') & ...
                        contains({allResults.file}, 'M25'));
disp(['Selected files: ', num2str(numel(allResults))]);

%% ============================================================
% Build table with L and metrics
%% ============================================================
tablaLComp = table();
for f = 1:numel(allResults)
    fname = allResults(f).file;
    fprintf('Processing file: %s\n', fname);

    % Extract length L from filename
    tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
    if isempty(tokensL), continue; end
    Lval = str2double(tokensL{1}{1}) + str2double(tokensL{1}{2})/100;

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

    % Extract W and M for geometric size calculation
    tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
    tokensM = regexp(fname,'M(\d+)(E?)','tokens');
    if ~isempty(tokensW)
        Wval = str2double(tokensW{1}{1}) + str2double(tokensW{1}{2})/100;
    else, Wval = NaN; end
    if ~isempty(tokensM)
        Mval = str2double(tokensM{1}{1});
    else, Mval = NaN; end

    % Geometric product with unit µm²
    size_geom = Lval * Wval * Mval;
    size_geom_str = sprintf('%.3f µm²', size_geom);

    % Add row to table
    tablaLComp = [tablaLComp;
        table({fname}, Lval, PCE_max, Pin_at_max, Vout_at_max, VRF_at_max, ...
              Ratio_at_max, area_local, {size_geom_str}, ...
              'VariableNames', {'File','L','PCE_max','Pin_dBm','Vout', ...
                                'VRF_at_max','Vout_VRFmax','Area_local','LxWxM'})];
end

%% ============================================================
% Normalization and Score
%% ============================================================
size_geom_vals = cellfun(@(x) sscanf(x,'%f'), tablaLComp.LxWxM);

% Normalize metrics
PCE_norm   = normalize(tablaLComp.PCE_max,'range');
Pin_norm   = normalize(tablaLComp.Pin_dBm,'range');
Vout_norm  = normalize(tablaLComp.Vout,'range');
VRF_norm   = normalize(tablaLComp.VRF_at_max,'range');
Area_norm  = normalize(tablaLComp.Area_local,'range');
Size_norm  = normalize(size_geom_vals,'range');

% Invert metrics where lower is better
Pin_norm_inv  = 1 - Pin_norm;
Size_norm_inv = 1 - Size_norm;
VRF_norm_inv  = 1 - VRF_norm;

% Weighted score
score = wPCE*PCE_norm + ...
        wPin*Pin_norm_inv + ...
        wVout*Vout_norm + ...
        wVRF*VRF_norm_inv + ...
        wArea*Area_norm + ...
        wSize*Size_norm_inv;

tablaLComp.Score = score;

% Sort table by Score (descending)
tablaLComp_sorted = sortrows(tablaLComp,'Score','descend');

%% ============================================================
% Show comparative table
%% ============================================================
disp('================ COMPARATIVE TABLE MULT3 FILES (C00-80, by L) =================');
disp(tablaLComp_sorted(1:min(20,height(tablaLComp_sorted)),:));

%% ============================================================
% Metrics vs L plots
%% ============================================================
tablaLComp_byL = sortrows(tablaLComp,'L');

figure('Color','w');

subplot(2,2,1);
plot(tablaLComp_byL.L, tablaLComp_byL.PCE_max,'-o','LineWidth',1.6,'MarkerFaceColor','r');
xlabel('L (µm)'); ylabel('PCE_{max}');
title('PCE_{max} vs L (C00-80, MULT3)'); grid on;

subplot(2,2,2);
plot(tablaLComp_byL.L, tablaLComp_byL.Vout,'-s','LineWidth',1.6,'MarkerFaceColor','b');
xlabel('L (µm)'); ylabel('Vout_{at max} [V]');
title('Vout_{at max} vs L (C00-80, MULT3)'); grid on;

subplot(2,2,3);
plot(tablaLComp_byL.L, tablaLComp_byL.Pin_dBm,'-^','LineWidth',1.6,'MarkerFaceColor','g');
xlabel('L (µm)'); ylabel('Pin_{at max} [dBm]');
title('Pin_{at max} vs L (C00-80, MULT3)'); grid on;

subplot(2,2,4);
plot(tablaLComp_byL.L, tablaLComp_byL.VRF_at_max,'-d','LineWidth',1.6,'MarkerFaceColor','m');
xlabel('L (µm)'); ylabel('VRF_{at max} [V]');
title('VRF_{at max} vs L (C00-80, MULT3)'); grid on;

sgtitle('Comparison of metrics vs L (only MULT3 files with C00-80)');
