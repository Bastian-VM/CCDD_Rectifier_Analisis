%% ============================================================
% Title: Comparative analysis of Cs variations in the CCDDR
%
% Author: Bastian Veas Moyano
%
% Last modification: August 04, 2026
%
% Description: This script loads combined simulation results of the
% Cross-Coupled Differential Drive Rectifier (CCDDR), filters valid cases
% (only MULT1, geometry L00-20_W00-60, no files ending with E, and with
% suffix _C##-##), and builds a comparative table of files with Cs
% variations. Metrics such as efficiency, output voltage, input power,
% maximum VRF, local area, and geometric size are calculated. Metrics are
% normalized to obtain a weighted score, and comparative plots are generated
% as a function of Cs.
%% ============================================================
clear; close all; clc;

%% ============================================================
% Define Weights
%% ============================================================
wPCE   = 0.20;   % maximum efficiency
wPin   = 0.20;   % input power
wVout  = 0.15;   % output voltage
wVRF   = 0.25;   % maximum VRF
wArea  = 0.15;   % local area
wSize  = 0.05;   % geometric size

disp(wPCE+wPin+wVout+wVRF+wArea+wSize);


%% ============================================================
% Working folder
%% ============================================================
folder = ''; % Main folder containing 'Schem_CSV' and 'Archivos_MAT'
if ~exist('folder','var') || isempty(folder) || ~isfolder(folder)
    folder = pwd; % current directory
end
matFolder = fullfile(folder,'Archivos_MAT');
if ~exist(matFolder,'dir'), mkdir(matFolder); end
fprintf('Working folder: %s\n', matFolder);

% Main file with all combined results
load(fullfile(matFolder,'all_results.mat')); % must contain allResults
disp(['Total loaded results: ', num2str(numel(allResults))]);

%% ============================================================
% Filter valid results
% - Include only files with 'MULT1'
% - Include only files with 'L00-20_W00-60'
% - Exclude files ending with 'E'
% - Include only files with suffix "_C##-##.mat"
%% ============================================================
validResults = [];
for f = 1:numel(allResults)
    fname = allResults(f).file;
    if ~contains(fname,'MULT1') ...
       || ~contains(fname,'L00-20_W00-60') ...
       || ~isempty(regexp(fname,'E\.mat$','once')) ...
       || isempty(regexp(fname,'_C\d+-\d+\.mat$','once'))
        continue; % discard file
    else
        validResults = [validResults, allResults(f)];
    end
end
disp(['Total valid results: ', num2str(numel(validResults))]);
disp('Selected files after filtering:');
for f = 1:numel(validResults)
    disp(validResults(f).file);
end

%% ============================================================
% Build comparative table ONLY with filtered files
%% ============================================================
tablaCsComp = table();
for f = 1:numel(validResults)
    fname = validResults(f).file;

    % Extract Cs
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    % Sort and calculate metrics
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);
    Vout_sorted  = validResults(f).Vout(idx_sort);
    VRF_sorted   = validResults(f).VRFmax(idx_sort);

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

    % Extract geometry L, W, M
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

    size_geom = Lval * Wval * Mval;
    size_geom_str = sprintf('%.3f µm²', size_geom);

    tablaCsComp = [tablaCsComp;
        table({fname}, Cs_val, PCE_max, Pin_at_max, Vout_at_max, VRF_at_max, Ratio_at_max, area_local, {size_geom_str}, ...
        'VariableNames', {'File','Cs_pF','PCE_max','Pin_dBm','Vout','VRF_at_max','Vout_VRFmax','Area_local','LxWxM'})];
end

%% ============================================================
% Normalization and Weighted Score (including VRF_max)
%% ============================================================
size_geom_vals = cellfun(@(x) sscanf(x,'%f'), tablaCsComp.LxWxM);

PCE_norm   = normalize(tablaCsComp.PCE_max,'range');     
Pin_norm   = normalize(tablaCsComp.Pin_dBm,'range');     
Vout_norm  = normalize(tablaCsComp.Vout,'range');        
VRF_norm   = normalize(tablaCsComp.VRF_at_max,'range');  
Area_norm  = normalize(tablaCsComp.Area_local,'range');  
Size_norm  = normalize(size_geom_vals,'range');          

Pin_norm_inv  = 1 - Pin_norm;
Size_norm_inv = 1 - Size_norm;
VRF_norm_inv  = 1 - VRF_norm;

score = wPCE*PCE_norm + ...
        wPin*Pin_norm_inv + ...
        wVout*Vout_norm + ...
        wVRF*VRF_norm_inv + ...
        wArea*Area_norm + ...
        wSize*Size_norm_inv;

tablaCsComp.Score = score;
tablaCsComp_sorted = sortrows(tablaCsComp,'Score','descend');

%% ============================================================
% Show comparative table
%% ============================================================
disp('================ COMPARATIVE TABLE FILES WITH Cs =================');
disp(tablaCsComp_sorted(1:min(20,height(tablaCsComp_sorted)),:));

%% ============================
% File count per Cs
%% ============================
[uniqueCs,~,idxCs] = unique(tablaCsComp_sorted.Cs_pF);
countsCs = accumarray(idxCs,1);

disp('================ FILES PER Cs =================');
for i = 1:numel(uniqueCs)
    fprintf('Cs = %.2f pF \n', uniqueCs(i));
end

%% ============================
% Metrics vs Cs (ordered by Cs, logarithmic axis)
%% ============================
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

sgtitle('Metrics comparison vs Cs');

%% ============================
% Comparative plots for Cs variations (only filtered files)
%% ============================
% PCE vs Pin
figure('Color','w'); hold on;
for f = 1:numel(validResults)
    fname = validResults(f).file;
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);

    plot(Pin_sorted, PCE_sorted,'LineWidth',1.5,'DisplayName',sprintf('Cs=%.2f pF',Cs_val));
end
xlabel('Pin [dBm]'); ylabel('PCE');
title('PCE vs Pin (Cs variations)');
legend('show','Location','best'); grid on; ylim([0 1.1]);

% Vout vs Pin
figure('Color','w'); hold on;
for f = 1:numel(validResults)
    fname = validResults(f).file;
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    Vout_sorted   = validResults(f).Vout(idx_sort);

    plot(Pin_sorted, Vout_sorted,'LineWidth',1.5,'DisplayName',sprintf('Cs=%.2f pF',Cs_val));
end
xlabel('Pin [dBm]'); ylabel('Vout [V]');
title('Vout vs Pin (Cs variations)');
legend('show','Location','best'); grid on;

% Vout/VRFmax vs Pin
figure('Color','w'); hold on;
for f = 1:numel(validResults)
    fname = validResults(f).file;
    tokensC = regexp(fname,'C(\d+)-(\d+)','tokens');
    if isempty(tokensC), continue; end
    Cs_val = str2double(tokensC{1}{1}) + str2double(tokensC{1}{2})/100;

    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    Ratio_sorted = validResults(f).Vout(idx_sort)./validResults(f).VRFmax(idx_sort);

    plot(Pin_sorted, Ratio_sorted,'LineWidth',1.5,'DisplayName',sprintf('Cs=%.2f pF',Cs_val));
end
xlabel('Pin [dBm]'); ylabel('Vout / VRF_{max}');
title('Vout/VRF_{max} vs Pin (Cs variations)');
legend('show','Location','best'); grid on;
