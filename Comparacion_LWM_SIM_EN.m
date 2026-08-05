%% ============================================================
% Title: Comparative analysis of maximum metrics vs dimensions of the CCDDR
%
% Author: Bastian Veas Moyano
%
% Last modification: August 03, 2026
%
% Description: This script loads the combined simulation results
% of the Cross-Coupled Differential Drive Rectifier (CCDDR),
% filters valid cases according to defined criteria, and extracts
% the maximum metrics of conversion efficiency (PCE), input power
% at maximum (Pin_at_max), and output voltage at maximum (Vout_at_max).
% It then generates comparative plots of these metrics as a function
% of the geometric dimensions (L, W, M).
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
% Extract maximum metrics per file
%% ============================================================
L_vals=[]; W_vals=[]; M_vals=[];
PCE_max_vals=[]; Pin_at_max_vals=[]; Vout_at_max_vals=[];

for f=1:numel(validResults)
    fname = validResults(f).file;

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

    % Sort by Pin
    [Pin_sorted, idx_sort] = sort(validResults(f).Pin_dBm);
    PCE_sorted   = validResults(f).PCE(idx_sort);
    Vout_sorted  = validResults(f).Vout(idx_sort);

    % Maximum values
    [PCE_max, idx_max] = max(PCE_sorted);
    Pin_at_max = Pin_sorted(idx_max);
    Vout_at_max = Vout_sorted(idx_max);

    % Store metrics
    L_vals(end+1) = Lval;
    W_vals(end+1) = Wval;
    M_vals(end+1) = Mval;
    PCE_max_vals(end+1) = PCE_max;
    Pin_at_max_vals(end+1) = Pin_at_max;
    Vout_at_max_vals(end+1) = Vout_at_max;
end

%% ============================================================
% Auxiliary function to plot with trends
%% ============================================================
function plotWithTrends(x,y,xlabelStr,ylabelStr,titleStr)
    % Sort data by x for correct plotting
    [x_sorted, idx] = sort(x);
    y_sorted = y(idx);

    scatter(x_sorted,y_sorted,60,'filled'); hold on;

    % --- Linear trend ---
    p_lin = polyfit(x_sorted,y_sorted,1);
    y_lin = polyval(p_lin,x_sorted);
    plot(x_sorted,y_lin,'r--','LineWidth',1.5,'DisplayName','Linear');

    xlabel(xlabelStr); ylabel(ylabelStr);
    title(titleStr);
    grid on; legend('show','Location','best');
end

%% ============================================================
% Comparative plots L vs metrics
%% ============================================================
figure('Color','w');
subplot(3,1,1); plotWithTrends(L_vals,PCE_max_vals,'L [µm]','PCE_{max}','L vs PCE_{max}');
subplot(3,1,2); plotWithTrends(L_vals,Pin_at_max_vals,'L [µm]','Pin_{at max} [dBm]','L vs Pin_{at max}');
subplot(3,1,3); plotWithTrends(L_vals,Vout_at_max_vals,'L [µm]','Vout_{at max} [V]','L vs Vout_{at max}');

%% ============================================================
% Comparative plots W vs metrics
%% ============================================================
figure('Color','w');
subplot(3,1,1); plotWithTrends(W_vals,PCE_max_vals,'W [µm]','PCE_{max}','W vs PCE_{max}');
subplot(3,1,2); plotWithTrends(W_vals,Pin_at_max_vals,'W [µm]','Pin_{at max} [dBm]','W vs Pin_{at max}');
subplot(3,1,3); plotWithTrends(W_vals,Vout_at_max_vals,'W [µm]','Vout_{at max} [V]','W vs Vout_{at max}');

%% ============================================================
% Comparative plots M vs metrics
%% ============================================================
figure('Color','w');
subplot(3,1,1); plotWithTrends(M_vals,PCE_max_vals,'M','PCE_{max}','M vs PCE_{max}');
subplot(3,1,2); plotWithTrends(M_vals,Pin_at_max_vals,'M','Pin_{at max} [dBm]','M vs Pin_{at max}');
subplot(3,1,3); plotWithTrends(M_vals,Vout_at_max_vals,'M','Vout_{at max} [V]','M vs Vout_{at max}');
