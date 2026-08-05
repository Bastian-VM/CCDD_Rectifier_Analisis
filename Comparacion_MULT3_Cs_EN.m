%% ============================================================
% Title: Comparative analysis of Cs variations in MULT3
%
% Author: Bastian Veas Moyano
%
% Last modification: August 04, 2026
%
% Description: This script loads combined simulation results of the
% Cross-Coupled Differential Drive Rectifier (CCDDR) for the MULT3 case,
% filtering files with geometry M20 and resistance R100k. It builds a
% comparative table with Cs variations, calculating metrics of efficiency,
% output voltage, input power, maximum VRF, local area, and geometric size.
% Metrics are then normalized to obtain a weighted score and comparative
% plots are generated.
%% ============================================================
clear; close all; clc;



%% ============================================================
% Weights for each metric
%% ============================================================

wPCE   = 0.10;   % maximum efficiency
wPin   = 0.30;   % input power
wVout  = 0.20;   % output voltage
wVRF   = 0.30;   % maximum VRF
wArea  = 0.05;   % local area
wSize  = 0.05;   % geometric size


%% ============================================================
% Load main results
%% ============================================================
folder = 'D:\Memoria_Last\Simulaciones_Xschem\Archivos_MAT';
load(fullfile(folder,'all_Results.mat')); % must contain allResults
disp(['Total loaded results: ', num2str(numel(allResults))]);

%% ============================================================
% Filter only MULT3 files with M20 and R100k
%% ============================================================
allResults = allResults( ...
    contains({allResults.file}, 'MULT3') & ...
    contains({allResults.file}, 'M20')   & ...
    contains({allResults.file}, 'L00-20_W00-60')   & ...
    contains({allResults.file}, 'R100k'));

%% ============================================================
% Filter only MULT3 files with M25 and R100k Segunda Iteracion
%% ============================================================
%allResults = allResults( ...
%    contains({allResults.file}, 'MULT3') & ...
%    contains({allResults.file}, 'M25')   & ...
%    contains({allResults.file}, 'L00-20_W00-60')   & ...
%    contains({allResults.file}, 'R100k'));

%% ============================================================
% Build table with Cs and metrics
%% ============================================================
tablaCsComp = table();
for f = 1:numel(allResults)
    fname = allResults(f).file;

    % Extract Cs value from filename
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100; % in pF

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

    % Extract geometry L, W, M from filename
    tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
    tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
    tokensM = regexp(fname,'M(\d+)(E?)','tokens');
    if ~isempty(tokensL)
        Lval = str2double(tokensL{1}{1}) + str2double(tokensL{1}{2})/100;
    else, Lval = NaN; end
    if ~isempty(tokensW)
        Wval = str2double(tokensW{1}{1}) + str2double(tokensW{1}{2})/100;
    else, Wval = NaN; end
    if ~isempty(tokensM)
        Mval = str2double(tokensM{1}{1});
    else, Mval = NaN; end

    % Geometric product with unit µm² (MULT3 → factor 3)
    size_geom = 3*Lval * Wval * Mval;
    size_geom_str = sprintf('%.3f µm²', size_geom);

    % Add row to table
    tablaCsComp = [tablaCsComp;
        table({fname}, Cs_val, PCE_max, Pin_at_max, Vout_at_max, VRF_at_max, Ratio_at_max, area_local, {size_geom_str}, ...
        'VariableNames', {'File','Cs_pF','PCE_max','Pin_dBm','Vout','VRF_at_max','Vout_VRFmax','Area_local','LxWxM'})];
end

%% ============================================================
% Normalization and Score (including VRF_max)
%% ============================================================
size_geom_vals = cellfun(@(x) sscanf(x,'%f'), tablaCsComp.LxWxM);

% Normalizations (adjusted by criterion: higher is better / lower is better)
PCE_norm   = normalize(tablaCsComp.PCE_max,'range');     
Pin_norm   = normalize(tablaCsComp.Pin_dBm,'range');     
Vout_norm  = normalize(tablaCsComp.Vout,'range');        
VRF_norm   = normalize(tablaCsComp.VRF_at_max,'range');  
Area_norm  = normalize(tablaCsComp.Area_local,'range');  
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

tablaCsComp.Score = score;

% Sort table by Score (descending)
tablaCsComp_sorted = sortrows(tablaCsComp,'Score','descend');

%% ============================================================
% Show comparative table
%% ============================================================
disp('================ COMPARATIVE TABLE FILES WITH Cs =================');
disp(tablaCsComp_sorted(1:min(20,height(tablaCsComp_sorted)),:));

%% ============================================================
% File count per Cs
%% ============================================================
[uniqueCs,~,idxCs] = unique(tablaCsComp_sorted.Cs_pF);
countsCs = accumarray(idxCs,1);

disp('================ FILES PER Cs =================');
for i = 1:numel(uniqueCs)
    fprintf('Cs = %.2f pF\n', uniqueCs(i));
end


%% ============================================================
% Metrics vs Cs (ordered by Cs, logarithmic axis)
%% ============================================================
tablaCsComp_byCs = sortrows(tablaCsComp,'Cs_pF');

figure('Color','w');
subplot(2,2,1);
semilogx(tablaCsComp_byCs.Cs_pF, tablaCsComp_byCs.PCE_max,'-o','LineWidth',1.6,'MarkerFaceColor','r');
xlabel('Cs [pF] (log)'); ylabel('PCE_{max}');
title('PCE_{max} vs Cs'); grid on;

subplot(2,2,2);
semilogx(tablaCsComp_byCs.Cs_pF, tablaCsComp_byCs.Vout,'-s','LineWidth',1.6,'MarkerFaceColor','b');
xlabel('Cs [pF] (log)'); ylabel('Vout_{at max} [V]');
title('Vout_{at max} vs Cs'); grid on;

subplot(2,2,3);
semilogx(tablaCsComp_byCs.Cs_pF, tablaCsComp_byCs.Pin_dBm,'-^','LineWidth',1.6,'MarkerFaceColor','g');
xlabel('Cs [pF] (log)'); ylabel('Pin_{at max} [dBm]');
title('Pin_{at max} vs Cs'); grid on;

subplot(2,2,4);
semilogx(tablaCsComp_byCs.Cs_pF, tablaCsComp_byCs.VRF_at_max,'-d','LineWidth',1.6,'MarkerFaceColor','m');
xlabel('Cs [pF] (log)'); ylabel('VRF_{at max} [V]');
title('VRF_{at max} vs Cs'); grid on;

sgtitle('Comparison of metrics vs Cs');

%% ============================================================
% Comparative plots for Cs variations
%% ============================================================
% PCE vs Pin
figure('Color','w'); hold on;
for f = 1:numel(allResults)
    fname = allResults(f).file;
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    % Sort results by Pin and plot PCE
    [Pin_sorted, idx_sort] = sort(allResults(f).Pin_dBm);
    PCE_sorted   = allResults(f).PCE(idx_sort);

    plot(Pin_sorted, PCE_sorted,'LineWidth',1.5,'DisplayName',sprintf('Cs=%.2f pF',Cs_val));
end
xlabel('Pin [dBm]'); ylabel('PCE');
title('PCE vs Pin (Cs variations)');
legend('show','Location','best'); grid on; ylim([0 1.1]);

% Vout vs Pin
figure('Color','w'); hold on;
for f = 1:numel(allResults)
    fname = allResults(f).file;
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    % Sort results by Pin and plot Vout
    [Pin_sorted, idx_sort] = sort(allResults(f).Pin_dBm);
    Vout_sorted   = allResults(f).Vout(idx_sort);

    plot(Pin_sorted, Vout_sorted,'LineWidth',1.5,'DisplayName',sprintf('Cs=%.2f pF',Cs_val));
end
xlabel('Pin [dBm]'); ylabel('Vout [V]');
title('Vout vs Pin (Cs variations)');
legend('show','Location','best'); grid on;

% Vout/VRFmax vs Pin
figure('Color','w'); hold on;
for f = 1:numel(allResults)
    fname = allResults(f).file;
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    % Sort results by Pin and plot Vout/VRFmax ratio
    [Pin_sorted, idx_sort] = sort(allResults(f).Pin_dBm);
    Ratio_sorted = allResults(f).Vout(idx_sort)./allResults(f).VRFmax(idx_sort);

    plot(Pin_sorted, Ratio_sorted,'LineWidth',1.5,'DisplayName',sprintf('Cs=%.2f pF',Cs_val));
end
xlabel('Pin [dBm]'); ylabel('Vout / VRF_{max}');
title('Vout/VRF_{max} vs Pin (Cs variations)');
legend('show','Location','best'); grid on;
