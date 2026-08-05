%% ============================================================
% Title: Construction and verification of Pout, Pin, Vout and VRF tables
%
% Author: Bastian Veas Moyano
%
% Last modification: August 03, 2026
%
% Description: This code loads MAT files generated from simulation CSVs,
% calculates average input/output power, output voltage, maximum RF voltage,
% and conversion efficiency. It then saves combined results and generates
% verification plots to check the correctness of the conversion process.
%% ============================================================
clearvars -except folder matFolder; clc;

%% ============================================================
% Working folder
%% ============================================================

folder = ''; % Carpeta con la carpeta 'Schem_CSV' con los archivos CSV

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

%% ============================================================
% Search for MAT files generated in "Extraccion_Datos_Xschem_1_EN
%% ============================================================
matFiles = dir(fullfile(matFolder,'Resultados_*.mat'));
fprintf('\nFound %d MAT files\n', numel(matFiles));

% Fundamental period of RF signal
F = 900e6;   % fundamental frequency
T = 1/F;     % period
allResults = struct();

%% ============================================================
% PART 4: PROCESS EACH MAT FILE FOUND
%% ============================================================
for f = 1:numel(matFiles)
    filename = fullfile(matFolder, matFiles(f).name);
    fprintf('Processing MAT: %s\n', matFiles(f).name);

    % Load results from file
    load(filename,'results');
    nBlocks = numel(results);

    % Initialize vectors for each block
    Pin_avg_all  = zeros(1,nBlocks);  % average input power
    Pout_avg_all = zeros(1,nBlocks);  % average output power
    Vout_avg_all = zeros(1,nBlocks);  % average output voltage
    VRF_max_all  = zeros(1,nBlocks);  % maximum RF voltage

    %% ------------------------------------------------------------
    % Process each block inside the file
    %% ------------------------------------------------------------
    for b = 1:nBlocks
        % Extract relevant signals
        time = results{b}.vals(:,2); % time
        idx_vrf  = find(results{b}.NomEje=="vrf");   % RF input voltage
        idx_irf  = find(results{b}.NomEje=="irf");   % RF input current
        idx_vout = find(results{b}.NomEje=="vout");  % output voltage
        idx_ir   = find(results{b}.NomEje=="ir");    % output current

        Vrf  = results{b}.vals(:,idx_vrf);
        Irf  = results{b}.vals(:,idx_irf);
        Vout = results{b}.vals(:,idx_vout);
        Ir   = results{b}.vals(:,idx_ir);

        % Select last period of the signal
        t_end   = max(time);
        mask    = (time >= t_end - T); % interval [t_end - T, t_end]
        Vout_T  = Vout(mask);
        Vrf_T   = Vrf(mask);

        % ----------------------------
        % Mathematical calculations
        % ----------------------------

        % Average input power:
        % Pin = (1/T) ∫ Vrf(t) * Irf(t) dt
        Pin_avg_all(b)  = abs((1/T) * trapz(time(mask), Vrf(mask).*Irf(mask)));

        % Average output power:
        % Pout = (1/T) ∫ Vout(t) * Ir(t) dt
        Pout_avg_all(b) = (1/T) * trapz(time(mask), Vout(mask).*Ir(mask));

        % Average output voltage:
        Vout_avg_all(b) = mean(Vout_T);

        % Maximum RF voltage:
        VRF_max_all(b)  = round(max(abs(Vrf_T)),2);
    end

    % Save results in structure
    allResults(f).file     = matFiles(f).name;
    allResults(f).Pin      = Pin_avg_all;
    allResults(f).Pout     = Pout_avg_all;
    allResults(f).Vout     = Vout_avg_all;
    allResults(f).VRFmax   = VRF_max_all;

    % Conversion efficiency:
    allResults(f).PCE      = Pout_avg_all ./ Pin_avg_all;

    % Power conversion to dBm:
    allResults(f).Pin_dBm  = 10*log10(Pin_avg_all*1000);
    allResults(f).Pout_dBm = 10*log10(Pout_avg_all*1000);
end

% Save combined results
outfile = fullfile(matFolder,'all_Results.mat');
save(outfile,'allResults');
fprintf('\nCombined file saved in: %s\n', outfile);

%% ============================================================
% PART 5: VERIFICATION OF CALCULATIONS
%% ============================================================
clearvars -except folder matFolder;

% Load combined results from all_Results.mat
infile = fullfile(matFolder,'all_Results.mat');
load(infile,'allResults');

fprintf('\nPlotting calculations from: %s\n', infile);

%% ============================================================
% Iterate over each processed file and plot
%% ============================================================
for f = 1:numel(allResults)

    % Condition: filter files that meet criteria
    if ~contains(allResults(f).file, 'MULT3') || ...
       ~contains(allResults(f).file, 'C00-80') || ...
       ~contains(allResults(f).file, 'M25')    || ...
       ~contains(allResults(f).file, 'R100k')
        fprintf('Skipping file: %s (does not meet filters)\n', allResults(f).file);
        continue;
    else
        fprintf('Plotting file: %s (meets filters)\n', allResults(f).file);
    end

    % Create verification figure
    figure('Name',['Verification: ', allResults(f).file], 'NumberTitle','off');
    
    % ------------------------------------------------------------
    % Subplot 1: Pin vs Pout in Watts
    % ------------------------------------------------------------
    subplot(2,2,1);
    plot(allResults(f).Pin,'-o','LineWidth',1.5); hold on;
    plot(allResults(f).Pout,'-s','LineWidth',1.5);
    xlabel('Block'); ylabel('Power [W]');
    legend('Pin','Pout','Location','best');
    title('Average powers (last period)');
    grid on;
    
    % ------------------------------------------------------------
    % Subplot 2: Conversion efficiency (PCE)
    % ------------------------------------------------------------
    subplot(2,2,2);
    plot(allResults(f).PCE,'-d','LineWidth',1.5,'Color',[0.2 0.6 0.2]);
    xlabel('Block'); ylabel('Efficiency');
    title('Power Conversion Efficiency (PCE)');
    grid on;
    
    % ------------------------------------------------------------
    % Subplot 3: Powers in dBm
    % ------------------------------------------------------------
    subplot(2,2,3);
    plot(allResults(f).Pin_dBm,'-o','LineWidth',1.5); hold on;
    plot(allResults(f).Pout_dBm,'-s','LineWidth',1.5);
    xlabel('Block'); ylabel('Power [dBm]');
    legend('Pin','Pout','Location','best');
    title('Powers in dBm');
    grid on;
    
    % ------------------------------------------------------------
    % Subplot 4: Average Vout and maximum VRF
    % ------------------------------------------------------------
    subplot(2,2,4);
    yyaxis left;
    plot(allResults(f).Vout,'-^','LineWidth',1.5,'Color',[0 0.4 0.8]);
    ylabel('Average Vout [V]');
    yyaxis right;
    plot(allResults(f).VRFmax,'-v','LineWidth',1.5,'Color',[0.8 0 0]);
    ylabel('Maximum VRF [V]');
    xlabel('Block');
    title('Characteristic voltages');
    legend('Vout avg','VRF max','Location','best');
    grid on;
end
