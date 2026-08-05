%% ============================================================
% Title: Comparative analysis of CCDDR results
%
% Author: Bastian Veas Moyano
%
% Last modification: August 03, 2026
%
% Description: This script loads the combined simulation results
% of the Cross-Coupled Differential Drive Rectifier (CCDDR),
% filters valid cases according to defined criteria, and generates
% comparative plots of conversion efficiency (PCE), output voltage (Vout),
% and the ratio Vout/VRFmax versus input power (Pin). In addition,
% it builds a 3D scatter plot to visualize the relationship between
% geometric dimensions (W, L, M) and the maximum efficiency achieved.
%% ============================================================

clear; close all; clc;

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
% Combined summary plots
%% ============================================================

% Figure 1: PCE vs Pin with rounded VRFmax annotation
figure('Color','w'); hold on;
colors = lines(numel(validResults));
markers = {'o','s','d','^','v','>','<','p','h','+','x','*','.','|','_'};

for f = 1:numel(validResults)
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);
    VRF_sorted   = validResults(f).VRFmax(idx_sort);

    VRF_rounded = round(VRF_sorted/0.05)*0.05;
    legendLabel = buildLegendLabel(validResults(f).file);

    plot(Pin_sorted, PCE_sorted, [markers{mod(f-1,numel(markers))+1} '-'], ...
        'Color',colors(f,:), 'LineWidth',1.4, 'MarkerFaceColor',colors(f,:), ...
        'DisplayName',legendLabel);

    % Labels with VRFmax at each point
    for i = 1:numel(Pin_sorted)
        text(Pin_sorted(i), PCE_sorted(i), sprintf('%.2f', VRF_rounded(i)), ...
            'FontSize',7,'Color','k','HorizontalAlignment','left');
    end
end
xlabel('Average Pin [dBm]'); ylabel('PCE = Pout/Pin');
title('Comparison PCE vs Pin (rounded VRF_{max})');
legend('show'); grid on; ylim([0 1.5]);

% Figure 2: Vout vs Pin with VRFmax annotation
figure('Color','w'); hold on;
colors = lines(numel(validResults));

for f = 1:numel(validResults)
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    Vout_sorted  = validResults(f).Vout(idx_sort);
    VRF_sorted   = validResults(f).VRFmax(idx_sort);

    VRF_rounded = round(VRF_sorted/0.05)*0.05;
    legendLabel = buildLegendLabel(validResults(f).file);

    plot(Pin_sorted, Vout_sorted, [markers{mod(f-1,numel(markers))+1} '-'], ...
        'Color',colors(f,:), 'LineWidth',1.4, 'MarkerFaceColor',colors(f,:), ...
        'DisplayName',legendLabel);

    for i = 1:numel(Pin_sorted)
        text(Pin_sorted(i), Vout_sorted(i), sprintf('%.2f', VRF_rounded(i)), ...
            'FontSize',7,'Color','k','HorizontalAlignment','left');
    end
end
xlabel('Average Pin [dBm]'); ylabel('Average Vout [V]');
title('Comparison Vout vs Pin (rounded VRF_{max})');
legend('show'); grid on; ylim([0 1.5]);

% Figure 3: Vout/VRFmax vs Pin
figure('Color','w'); hold on;
for f = 1:numel(validResults)
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    Ratio_sorted = validResults(f).Vout(idx_sort) ./ validResults(f).VRFmax(idx_sort);
    VRF_sorted   = validResults(f).VRFmax(idx_sort);

    VRF_rounded = round(VRF_sorted/0.05)*0.05;
    legendLabel = buildLegendLabel(validResults(f).file);

    plot(Pin_sorted, Ratio_sorted, [markers{mod(f-1,numel(markers))+1} '-'], ...
        'Color',colors(f,:), 'LineWidth',1.4, 'MarkerFaceColor',colors(f,:), ...
        'DisplayName',legendLabel);

    for i = 1:numel(Pin_sorted)
        text(Pin_sorted(i), Ratio_sorted(i), sprintf('%.2f', VRF_rounded(i)), ...
            'FontSize',7,'Color','k','HorizontalAlignment','left');
    end
end
xlabel('Average Pin [dBm]'); ylabel('Vout / VRF_{max}');
title('Comparison Vout/VRF_{max} vs Pin (rounded VRF_{max})');
legend('show'); grid on;

%% ============================================================
% 3D Scatter: Dimensions vs PCE_max (Pin > -40 dBm)
%% ============================================================
L_vals=[]; W_vals=[]; M_vals=[]; PCE_max_vals=[]; Pin_at_max_vals=[];

for f=1:numel(validResults)
    fname = validResults(f).file;
    tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
    tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
    tokensM = regexp(fname,'M(\d+)','tokens');
    
    Lval = str2double(tokensL{1}{1}) + str2double(tokensL{1}{2})/100;
    Wval = str2double(tokensW{1}{1}) + str2double(tokensW{1}{2})/100;
    Mval = str2double(tokensM{1}{1});
    
    Pin_vals = validResults(f).Pin_dBm;
    PCE_vals = validResults(f).PCE;
    mask_valid = Pin_vals > -40;
    
    if any(mask_valid)
        [PCE_max_filtered, idx_max] = max(PCE_vals(mask_valid));
        validPins = Pin_vals(mask_valid);
        Pin_at_max = validPins(idx_max);
    else
        PCE_max_filtered = NaN;
        Pin_at_max = NaN;
    end
    
    PCE_max_vals(end+1) = PCE_max_filtered;
    Pin_at_max_vals(end+1) = Pin_at_max;
    L_vals(end+1) = Lval;
    W_vals(end+1) = Wval;
    M_vals(end+1) = Mval;
end

figure('Color','w');
scatter3(W_vals,L_vals,M_vals,80,PCE_max_vals,'filled');
xlabel('W [µm]'); ylabel('L [µm]'); zlabel('M');
title('3D Scatter: Dimensions vs PCE_{max} (Pin > -40 dBm)');
colormap(jet);
c = colorbar; 
c.Label.String = 'PCE_{max}';
caxis([0.6 1.0]);
grid on;

%% ============================
% Auxiliary function for legend labels
%% ============================
function legendLabel = buildLegendLabel(fname)
%BUILDLEGENDLABEL Creates a readable label from the file name.
% - Expected format: ..._L<int>-<dec>_W<int>-<dec>_M<int>(optional E).mat
% - Include only files with 'MULT1'
% - Exclude files ending with 'E' before the extension
% - If tokens are missing, use 'N/A' in that field.

% Filtering consistent with the main script
if ~contains(fname,'MULT1') || ~isempty(regexp(fname,'E\.mat$','once'))
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
