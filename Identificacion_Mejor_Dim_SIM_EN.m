%% ============================================================
% Title: Selection and weighted analysis of the 20 best CCDDR curves
%
% Author: Bastian Veas Moyano
%
% Last modification: August 04, 2026
%
% Description: This script loads the combined simulation results
% of the Cross-Coupled Differential Drive Rectifier (CCDDR),
% filters valid cases (only MULT1, excluding files ending in E,
% excluding suffix _C##-##), selects the 20 curves with the highest
% conversion efficiency (PCE), and generates comparative plots.
% It also builds tables with metrics and a weighted version that
% considers efficiency, input power, output voltage, local area,
% and geometric size to rank the best designs.
%% ============================================================

clear; close all; clc;

%% ============================================================
% Define Weights
%% ============================================================

wPCE   = 0.40;   % efficiency
wPin   = 0.10;   % input power
wVout  = 0.20;   % output voltage
wArea  = 0.15;   % local area
wSize  = 0.15;   % geometric size

disp(wPCE+wPin+wVout+wVRF+wArea+wSize);

%% ============================================================
% Working folder
%% ============================================================

folder = ''; % Main folder containing 'Schem_CSV' and 'Archivos_MAT'

% If not defined or does not exist, use the current directory
if ~exist('folder','var') || isempty(folder) || ~isfolder(folder)
    folder = pwd; % current directory
end

% Subfolder where MAT files will be saved/loaded
matFolder = fullfile(folder,'Archivos_MAT');
if ~exist(matFolder,'dir')
    mkdir(matFolder); % create if it does not exist
end

fprintf('Working folder: %s\n', matFolder);

% Main file with all combined results
load(fullfile(matFolder,'all_results.mat'));

disp(['Total loaded results: ', num2str(numel(allResults))]);

%% ============================================================
% Filter valid results
% - Include only files with 'MULT1'
% - Exclude files ending with 'E' before the extension
% - Exclude files with suffix "_C##-##.mat"
%% ============================================================
validResults = [];
for f = 1:numel(allResults)
    fname = allResults(f).file;
    if ~contains(fname,'MULT1') || ~isempty(regexp(fname,'E\.mat$','once')) || ~isempty(regexp(fname,'_C\d+-\d+\.mat$','once'))
        continue; % discard file
    else
        validResults = [validResults, allResults(f)];
    end
end

disp(['Total valid results: ', num2str(numel(validResults))]);

%% ============================================================
% Show selected archives
%% ============================================================
disp('Selected archives after filtering:');
for f = 1:numel(validResults)
    disp(validResults(f).file);
end

%% ============================================================
% Select Top 20 curves by maximum PCE
%% ============================================================
maxPCE = zeros(1,numel(validResults));
validMask = false(1,numel(validResults));

for f = 1:numel(validResults)
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);
    VRF_sorted   = validResults(f).VRFmax(idx_sort);

    [PCE_max, idx_max] = max(PCE_sorted);
    VRF_at_max = VRF_sorted(idx_max);

    if VRF_at_max >= 0
        maxPCE(f) = PCE_max;
        validMask(f) = true;
    else
        maxPCE(f) = -Inf;
    end
end

[~, idx_sorted] = sort(maxPCE,'descend');
top20_idx = idx_sorted(validMask(idx_sorted));
top20_idx = top20_idx(1:min(20,numel(top20_idx)));

%% ============================================================
% Plot Top 20 curves
%% ============================================================
colors = lines(20);
markers = {'o','s','d','^','v','>','<','p','h','+','x','*','.','|','_'};

figure('Color','w'); hold on;
for k = 1:numel(top20_idx)
    f = top20_idx(k);
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);

    legendLabel = buildLegendLabel(validResults(f).file);

    plot(Pin_sorted, PCE_sorted, [markers{mod(k-1,numel(markers))+1} '-'], ...
        'Color',colors(k,:), 'LineWidth',1.6, 'MarkerFaceColor',colors(k,:), ...
        'DisplayName',legendLabel);

    [PCE_max, idx_max] = max(PCE_sorted);
    plot(Pin_sorted(idx_max), PCE_max, 'ko', 'MarkerFaceColor','r', ...
        'MarkerSize',6,'HandleVisibility','off');
end
xlabel('Pin [dBm]'); ylabel('PCE = Pout/Pin');
title('Top 20 curves with highest PCE (filtered MULT1, no E, no Cs Cap)');
legend('show','Location','bestoutside'); grid on; ylim([0 1.1]);

%% ============================================================
% Comparative metrics table
%% ============================================================
resultsTable = table();
for k = 1:numel(top20_idx)
    f = top20_idx(k);
    fname = validResults(f).file;

    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);
    Vout_sorted  = validResults(f).Vout(idx_sort);
    VRF_sorted   = validResults(f).VRFmax(idx_sort);

    [PCE_max, idx_max] = max(PCE_sorted);
    Pin_at_max = Pin_sorted(idx_max);
    Vout_at_max = Vout_sorted(idx_max);
    VRF_at_max  = VRF_sorted(idx_max);
    Ratio_at_max = Vout_at_max / VRF_at_max;

    % Area under the curve within ±5 dBm around the maximum
    mask_range = (Pin_sorted >= (Pin_at_max - 5)) & (Pin_sorted <= (Pin_at_max + 5));
    x_local = Pin_sorted(mask_range); y_local = PCE_sorted(mask_range);
    if numel(x_local)>1
        area_local = trapz(x_local,y_local);
    else
        area_local = 0;
    end

    % Extract geometry from file name
    tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
    tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
    tokensM = regexp(fname,'M(\d+)','tokens');
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

    resultsTable = [resultsTable; 
        table({fname}, PCE_max, Pin_at_max, area_local, Vout_at_max, Ratio_at_max, size_geom, ...
        'VariableNames', {'File','PCE_max','Pin_dBm','Area_local','Vout','Vout_VRFmax','LxWxM'})];
end

%% ============================================================
% Weighted comparative table (Top 20 with weights)
%% ============================================================
% Normalize metrics
PCE_norm    = normalize(resultsTable.PCE_max,'range');      
Pin_norm    = normalize(resultsTable.Pin_dBm,'range');      
Vout_norm   = normalize(resultsTable.Vout,'range');         
Area_norm   = normalize(resultsTable.Area_local,'range');   
Size_norm   = normalize(resultsTable.LxWxM,'range');        

% Invert metrics where smaller is better
Size_norm_inv = 1 - Size_norm;
Pin_norm_inv  = 1 - Pin_norm;

% Calculate weighted score
score = wPCE*PCE_norm + wPin*Pin_norm_inv + wVout*Vout_norm + wArea*Area_norm + wSize*Size_norm_inv;

% Add score column and sort
resultsTable.Score = score;
resultsTable_sorted = sortrows(resultsTable,'Score','descend');

% Select the best 20
resultsTable_top20_weighted = resultsTable_sorted(1:min(20,height(resultsTable_sorted)),:);

disp('================ WEIGHTED COMPARATIVE TABLE TOP 20 =================');
disp(resultsTable_top20_weighted);


%% ============================================================
% Auxiliary function for legend labels
%
% Description: This function creates readable labels from the
% simulation file names. It applies the same filtering rules
% as the main script (only MULT1, no files ending in E, no
% suffix _C##-##). If geometry tokens are missing, 'N/A' is used.
%% ============================================================
function legendLabel = buildLegendLabel(fname)
% Consistent filtering with the main script
if ~contains(fname,'MULT1') ...
        || ~isempty(regexp(fname,'M\d+E','once')) ...
        || ~isempty(regexp(fname,'_C\d+-\d+\.mat$','once'))
    legendLabel = 'Excluded';
    return;
end

% Extract tokens for L, W, and M
tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
tokensM = regexp(fname,'M(\d+)(E?)','tokens');

% Robust parsing with N/A if missing
if ~isempty(tokensL)
    Lval = str2double(tokensL{1}{1}) + str2double(tokensL{1}{2})/100;
    Lstr = sprintf('%.2f', Lval);
else
    Lstr = 'N/A';
end

if ~isempty(tokensW)
    Wval = str2double(tokensW{1}{1}) + str2double(tokensW{1}{2})/100;
    Wstr = sprintf('%.2f', Wval);
else
    Wstr = 'N/A';
end

if ~isempty(tokensM)
    Mval = str2double(tokensM{1}{1});
    Mstr = sprintf('%d', Mval);
else
    Mstr = 'N/A';
end

% Build final label
legendLabel = sprintf('L=%s µm, W=%s µm, M=%s', Lstr, Wstr, Mstr);
end
