%% ============================================================
% Title: Interactive analysis of TRAN results in CCDDR (MULT3)
%
% Author: Bastian Veas Moyano
%
% Last modification: August 05, 2026
%
% Description: This script allows interactive selection of a valid MAT file,
% calculates the block with maximum efficiency (PCE),
% and plots pairs of variables around that block (maximum block ±1).
% The user enters variable indices to compare, and subplots are generated
% with the corresponding curves.
%% ============================================================
clear; clc; close all;

%% ============================
% Working folder
%% ============================
folder = 'D:\Memoria_Last\Simulaciones_Xschem\Archivos_MAT';

%% ============================
% List valid MAT files
% Excludes files with MULT3 and with suffix "E"
%% ============================
matFiles = dir(fullfile(folder,'Resultados_CCDD2_TRAN_*.mat'));
validFiles = {};
for k = 1:numel(matFiles)
    fname = matFiles(k).name;
    if ~contains(fname,'MULT3') || ~isempty(regexp(fname,'M\d+E','once'))
        continue;
    else
        validFiles{end+1} = fname;
    end
end

disp('================ AVAILABLE FILES (without MULT or E) ================');
for k = 1:numel(validFiles)
    fprintf('%2d: %s\n', k, validFiles{k});
end

%% ============================
% Interactive file selection
%% ============================
idx = input('Select the index of the file you want to plot: ');
if idx < 1 || idx > numel(validFiles)
    error('Invalid index.');
end

fname = fullfile(folder, validFiles{idx});
fprintf('Loading file: %s\n', fname);
load(fname,'results'); % load variable results

%% ============================
% Calculate block with maximum PCE
%% ============================
T = 1/900e6; % fundamental period (adjust according to frequency)
PCE_all = zeros(1,numel(results));
for b = 1:numel(results)
    time = results{b}.vals(:,2);
    idx_vrf  = find(results{b}.NomEje=="vrf");
    idx_irf  = find(results{b}.NomEje=="irf");
    idx_vout = find(results{b}.NomEje=="vout");
    idx_ir   = find(results{b}.NomEje=="ir");

    Vrf  = results{b}.vals(:,idx_vrf);
    Irf  = results{b}.vals(:,idx_irf);
    Vout = results{b}.vals(:,idx_vout);
    Ir   = results{b}.vals(:,idx_ir);

    t_end = max(time);
    mask  = (time >= t_end - T);

    Pin_avg  = abs((1/T) * trapz(time(mask), Vrf(mask).*Irf(mask)));
    Pout_avg = (1/T) * trapz(time(mask), Vout(mask).*Ir(mask));

    PCE_all(b) = Pout_avg / Pin_avg;
end

[~, b_max] = max(PCE_all);
fprintf('Block with maximum PCE: %d\n', b_max);

% Blocks to plot: previous, maximum, next
blocks_to_plot = unique([max(b_max-1,1), b_max, min(b_max+1,numel(results))]);

%% ============================
% Show available variables with index
%% ============================
disp('Available variables in this file:');
for i = 1:numel(results{b_max}.NomEje)
    fprintf('%2d: %s\n', i, results{b_max}.NomEje(i));
end

%% ============================
% Selection of variable pairs by index
% The user enters the indices of the variables to plot
%% ============================
pairs = cell(4,3);
for p = 1:4
    idx1 = input(sprintf('Enter variable index %d.1: ',p));
    idx2 = input(sprintf('Enter variable index %d.2: ',p));
    idx3 = input(sprintf('Enter variable index %d.3: ',p));
    pairs{p,1} = idx1;
    pairs{p,2} = idx2;
    pairs{p,3} = idx3;
end

%% ============================
% Plot pairs vs time in block PCE_MAX ±1
%% ============================
for p = 1:4
    figure('Color','w');
    for bb = 1:numel(blocks_to_plot)
        b = blocks_to_plot(bb);
        time = results{b}.vals(:,2);
        var1 = results{b}.vals(:,pairs{p,1});
        var2 = results{b}.vals(:,pairs{p,2});
        var3 = results{b}.vals(:,pairs{p,3});
        name1 = results{b}.NomEje(pairs{p,1});
        name2 = results{b}.NomEje(pairs{p,2});
        name3 = results{b}.NomEje(pairs{p,3});

        % Calculate maximum VRF of the block
        idx_vrf = find(results{b}.NomEje=="vrf");
        VRF_block = max(abs(results{b}.vals(:,idx_vrf)));

        subplot(numel(blocks_to_plot),1,bb); hold on;
        plot(time,var1,'-b','LineWidth',1.2,'DisplayName',char(name1));
        plot(time,var2,'-r','LineWidth',1.2,'DisplayName',char(name2));
        plot(time,var3,'-g','LineWidth',1.2,'DisplayName',char(name3));

        xlabel('Time [s]'); ylabel('Value');
        title(sprintf('Block %d: %s vs %s vs %s (VRF_{max}=%.2f V)', ...
            b, char(name1), char(name2), char(name3), VRF_block));
        legend('show'); grid on;
    end
    sgtitle(sprintf('Comparison around maximum PCE (Block %d)', b_max));
end

% Example indices useful for analysis:
% Enter variable index 1.1: 5
% Enter variable index 1.2: 6
% Enter variable index 1.3: 7
% Enter variable index 2.1: 10
% Enter variable index 2.2: 11
% Enter variable index 2.3: 12
% Enter variable index 3.1: 16
% Enter variable index 3.2: 17
% Enter variable index 3.3: 18
% Enter variable index 4.1: 19
% Enter variable index 4.2: 20
% Enter variable index 4.3: 21
