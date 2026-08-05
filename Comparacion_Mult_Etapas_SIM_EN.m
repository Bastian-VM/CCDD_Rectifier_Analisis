%% ============================================================
% Title: Comparison of Multiple Stages of the CCDDR
%
% Author: Bastian Veas Moyano
%
% Last modification: August 04, 2026
%
% Description: This script loads combined simulation results of the
% Cross-Coupled Differential Drive Rectifier (CCDDR), filters valid cases
% with suffix C01-00 and selects pairs of rectifiers MULT# (greater than 1
% together with their MULT1 counterparts). It then builds a comparative
% table with metrics of efficiency, output voltage, input power, maximum VRF,
% local area, and geometric size. Finally, metrics are normalized to obtain
% a weighted score and comparative plots of the multiple stages are generated.
%% ============================================================
clear; close all; clc;

%% ============================================================
% Define Weights
%% ============================================================
wPCE   = 0.20;
wPin   = 0.10;
wVout  = 0.45;
wVRF   = 0.10;
wArea  = 0.10;
wSize  = 0.05;

disp(wPCE+wPin+wVout+wVRF+wArea+wSize);


%% ============================================================
% Working folder and load results
%% ============================================================
folder = 'D:\Memoria_Last\Simulaciones_Xschem\Archivos_MAT';
load(fullfile(folder,'all_Results.mat')); % must contain allResults

%% ============================================================
% Filter only files with C01-00
%% ============================================================
allResults = allResults(contains({allResults.file}, 'C01-00') & contains({allResults.file}, 'M20'));

%% ============================================================
% Filter MULT# files (greater than 1 and their MULT1 pairs)
%% ============================================================
multResults = [];
for f = 1:numel(allResults)
    fname = allResults(f).file;
    tokensM = regexp(fname,'^(.*)MULT(\d+)(.*)$','tokens','once');
    if isempty(tokensM), continue; end

    prefix = tokensM{1};
    multNum = str2double(tokensM{2});
    suffix = tokensM{3};

    if multNum > 1
        multResults = [multResults, allResults(f)];
        targetName = [prefix 'MULT1' suffix];
        idxMULT1 = find(strcmp({allResults.file}, targetName));
        if ~isempty(idxMULT1)
            multResults = [multResults, allResults(idxMULT1)];
            fprintf('Found pair: %s ↔ %s\n', fname, allResults(idxMULT1).file);
        else
            fprintf('No MULT1 counterpart found for: %s\n', fname);
        end
    end
end

%% ============================================================
% Remove duplicates and sort by number of stages
%% ============================================================
allFiles = {multResults.file};
[~, idxUnique] = unique(allFiles,'stable');
multResults = multResults(idxUnique);

stages = arrayfun(@(r) str2double(regexp(r.file,'MULT(\d+)','tokens','once')), multResults);
[~, idxSort] = sort(stages);
multResults = multResults(idxSort);

%% ============================================================
% Build table with Number of Stages and metrics
%% ============================================================
tablaMultComp = table();
for f = 1:numel(multResults)
    fname = multResults(f).file;

    % Extract number of stages MULT#
    tokensM = regexp(fname,'MULT(\d+)','tokens');
    if isempty(tokensM), continue; end
    stages = str2double(tokensM{1}{1});

    % Sort and calculate metrics
    [Pin_sorted, idx_sort] = sort(multResults(f).Pin_dBm);
    PCE_sorted   = multResults(f).PCE(idx_sort);
    Vout_sorted  = multResults(f).Vout(idx_sort);
    VRF_sorted   = multResults(f).VRFmax(idx_sort);

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

    % Extract L and W
    tokensL = regexp(fname,'L(\d+)-(\d+)','tokens');
    tokensW = regexp(fname,'W(\d+)-(\d+)','tokens');
    if ~isempty(tokensL)
        Lval = str2double(tokensL{1}{1}) + str2double(tokensL{1}{2})/100;
    else, Lval = NaN; end
    if ~isempty(tokensW)
        Wval = str2double(tokensW{1}{1}) + str2double(tokensW{1}{2})/100;
    else, Wval = NaN; end
    if ~isempty(tokensM)
        Mval = str2double(tokensM{1}{1});
    else, Mval = NaN; end

    % Geometric product with unit µm²
    size_geom = Mval * Lval * Wval * stages;
    size_geom_str = sprintf('%.3f µm²', size_geom);

    tablaMultComp = [tablaMultComp;
        table({fname}, stages, PCE_max, Pin_at_max, Vout_at_max, VRF_at_max, Ratio_at_max, area_local, {size_geom_str}, ...
        'VariableNames', {'File','Stages','PCE_max','Pin_dBm','Vout','VRF_at_max','Vout_VRFmax','Area_local','LxWxM'})];
end

%% ============================================================
% Normalization and Score (for MULT#)
%% ============================================================
size_geom_vals = cellfun(@(x) sscanf(x,'%f'), tablaMultComp.LxWxM);

PCE_norm   = normalize(tablaMultComp.PCE_max,'range');
Pin_norm   = normalize(tablaMultComp.Pin_dBm,'range');
Vout_norm  = normalize(tablaMultComp.Vout,'range');
VRF_norm   = normalize(tablaMultComp.VRF_at_max,'range');
Area_norm  = normalize(tablaMultComp.Area_local,'range');
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

tablaMultComp.Score = score;
tablaMultComp_sorted = sortrows(tablaMultComp,'Score','descend');

%% ============================================================
% Show comparative table
%% ============================================================
disp('================ COMPARATIVE TABLE MULTIPLE STAGES FILES =================');
disp(tablaMultComp_sorted(1:min(20,height(tablaMultComp_sorted)),:));


%% ============================================================
% Comparative plots
%% ============================================================
colors = lines(numel(multResults));
markers = {'o','s','d','^','v','>','<','p','h','+','x','*','.','|','_'};

% PCE vs Pin
figure('Color','w'); hold on;
Pin_at_maxPCE = zeros(1,numel(multResults));
for f = 1:numel(multResults)
    [Pin_sorted, idx_sort] = sort(multResults(f).Pin_dBm);
    PCE_sorted   = multResults(f).PCE(idx_sort);
    VRF_sorted   = multResults(f).VRFmax(idx_sort);

    legendLabel = buildLegendLabel(multResults(f).file);
    plot(Pin_sorted, PCE_sorted, [markers{mod(f-1,numel(markers))+1} '-'], ...
        'Color',colors(f,:), 'LineWidth',1.6, 'MarkerFaceColor',colors(f,:), ...
        'DisplayName',legendLabel);

    [~, idx_max] = max(PCE_sorted);
    Pin_at_maxPCE(f) = Pin_sorted(idx_max);

    plot(Pin_sorted(idx_max), PCE_sorted(idx_max), 'ro', 'MarkerFaceColor','r', ...
    'MarkerSize',8,'HandleVisibility','off');
   
    text(Pin_sorted(idx_max), PCE_sorted(idx_max)+0.05, ...
    sprintf('VRF=%.2f V', VRF_sorted(idx_max)), ...
    'FontSize',12,'Color','r','FontWeight','bold','HorizontalAlignment','center');

end
xlabel('Pin [dBm]','FontSize',18); ylabel('PCE = Pout/Pin','FontSize',18);
title('Comparison of MULT results (PCE vs Pin)','FontSize',20,'FontWeight','bold');
legend('show','Location','northwest','FontSize',14); grid on; ylim([0 1.1]);
set(gca,'FontSize',18);

%% ============================================================
% Comparative plot Vout vs Pin (show VRFmax at red point)
%% ============================================================
figure('Color','w'); hold on;
for f = 1:numel(multResults)
    [Pin_sorted, idx_sort] = sort(multResults(f).Pin_dBm);
    Vout_sorted  = multResults(f).Vout(idx_sort);
    VRF_sorted   = multResults(f).VRFmax(idx_sort);

    legendLabel = buildLegendLabel(multResults(f).file);
    plot(Pin_sorted, Vout_sorted, [markers{mod(f-1,numel(markers))+1} '-'], ...
        'Color',colors(f,:), 'LineWidth',1.6, 'MarkerFaceColor',colors(f,:), ...
        'DisplayName',legendLabel);

    % Find index of Pin_at_maxPCE
    [~, idx_pin] = min(abs(Pin_sorted - Pin_at_maxPCE(f)));
    plot(Pin_sorted(idx_pin), Vout_sorted(idx_pin), 'ro', 'MarkerFaceColor','r', ...
        'MarkerSize',8,'HandleVisibility','off');
    % Show VRFmax as text
    text(Pin_sorted(idx_pin), Vout_sorted(idx_pin)+0.05, ...
        sprintf('VRF=%.2f V', VRF_sorted(idx_pin)), ...
        'FontSize',12,'Color','r','FontWeight','bold','HorizontalAlignment','center');
end
xlabel('Pin [dBm]','FontSize',18); ylabel('Average Vout [V]','FontSize',18);
title('Comparison of MULT results (Vout vs Pin @ PCEmax)','FontSize',20,'FontWeight','bold');
legend('show','Location','northwest','FontSize',14); grid on;
set(gca,'FontSize',18);

%% ============================================================
% Comparative plot Vout/VRFmax vs Pin (show VRFmax at red point)
%% ============================================================
figure('Color','w'); hold on;
for f = 1:numel(multResults)
    [Pin_sorted, idx_sort] = sort(multResults(f).Pin_dBm);
    Vout_sorted  = multResults(f).Vout(idx_sort);
    VRF_sorted   = multResults(f).VRFmax(idx_sort);
    Ratio_sorted = Vout_sorted ./ VRF_sorted;

    legendLabel = buildLegendLabel(multResults(f).file);
    plot(Pin_sorted, Ratio_sorted, [markers{mod(f-1,numel(markers))+1} '-'], ...
        'Color',colors(f,:), 'LineWidth',1.6, 'MarkerFaceColor',colors(f,:), ...
        'DisplayName',legendLabel);

    % Find index of Pin_at_maxPCE
    [~, idx_pin] = min(abs(Pin_sorted - Pin_at_maxPCE(f)));
    plot(Pin_sorted(idx_pin), Ratio_sorted(idx_pin), 'ro', 'MarkerFaceColor','r', ...
        'MarkerSize',8,'HandleVisibility','off');
    % Show VRFmax as text
    text(Pin_sorted(idx_pin), Ratio_sorted(idx_pin)+0.05, ...
        sprintf('VRF=%.2f V', VRF_sorted(idx_pin)), ...
        'FontSize',12,'Color','r','FontWeight','bold','HorizontalAlignment','center');
end
xlabel('Pin [dBm]','FontSize',18); ylabel('Vout / VRF_{max}','FontSize',18);
title('Comparison of MULT results (Vout/VRF_{max} vs Pin @ PCEmax)','FontSize',20,'FontWeight','bold');
legend('show','Location','northwest','FontSize',14); grid on;
set(gca,'FontSize',18);

%% ============================================================
% Auxiliary function for legends
%% ============================================================
function legendLabel = buildLegendLabel(fname)
    tokensStages = regexp(fname,'MULT(\d+)','tokens');
    if ~isempty(tokensStages)
        stages = str2double(tokensStages{1}{1});
        legendLabel = sprintf('Rectifier %d stages', stages);
    else
        legendLabel = 'MULT Rectifier';
    end
end
