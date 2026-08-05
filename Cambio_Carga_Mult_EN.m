%% ============================================================
% Title: Comparative analysis of resistance variations in MULT3 (C00-80, M25, L00-20)
%
% Author: Bastian Veas Moyano
%
% Last modification: August 05, 2026
%
% Description: This script loads combined simulation results of the
% Cross-Coupled Differential Drive Rectifier (CCDDR) for the MULT3 case,
% filtering files with capacitance C00-80, multiplier M25, and length L00-20.
% It builds a comparative table based on resistance, calculating metrics
% of efficiency, output voltage, input power, and maximum VRF.
% Additionally, individual plots and subplots are generated to visualize trends.
%% ============================================================
clear; clc; close all;

%% ============================================================
% Working folder and load results
%% ============================================================
folder = 'D:\Memoria_Last\Simulaciones_Xschem\Archivos_MAT';
infile = fullfile(folder,'all_Results.mat');
load(infile,'allResults');
disp(['Total loaded results: ', num2str(numel(allResults))]);

%% ============================================================
% Filter files with MULT3, C00-80, M25 and L00-20
%% ============================================================
allResults = allResults(contains({allResults.file}, 'MULT3') & ...
                        contains({allResults.file}, 'C00-80') & ...
                        contains({allResults.file}, 'M25') & ...
                        contains({allResults.file}, 'L00-20'));
disp(['Selected files: ', num2str(numel(allResults))]);

% Show names of selected files
for i = 1:numel(allResults)
    disp(allResults(i).file);
end

%% ============================================================
% Extract resistances from filenames
%% ============================================================
nFiles = numel(allResults);
Rvals   = zeros(1,nFiles);
labels  = cell(1,nFiles);

for i = 1:nFiles
    fname = allResults(i).file;  
    tokens = regexp(fname,'R(\d+)([kM]?)[Mm]','tokens','once');
    if ~isempty(tokens)
        baseVal = str2double(tokens{1});
        suffix  = tokens{2};
        switch suffix
            case 'k'
                Rvals(i) = baseVal * 1e3;
                labels{i} = sprintf('R = %.0fkΩ',baseVal);
            case 'M'
                Rvals(i) = baseVal * 1e6;
                labels{i} = sprintf('R = %.0fMΩ',baseVal);
            otherwise
                Rvals(i) = baseVal;
                labels{i} = sprintf('R = %.0fΩ',baseVal);
        end
    else
        Rvals(i) = NaN;
        labels{i} = 'Unknown R';
    end
end

%% ============================================================
% Sort by increasing resistance
%% ============================================================
[Rvals_sorted, idxSort] = sort(Rvals);
labels_sorted = labels(idxSort);
allResults_sorted = allResults(idxSort);

colors = lines(nFiles);
Pi_max = zeros(nFiles,1);

%% ============================================================
% Calculate Vout and PCE at maximum efficiency point
%% ============================================================
Vout_maxEff   = zeros(nFiles,1);
PCE_max       = zeros(nFiles,1);
VRF_at_PCEmax = zeros(nFiles,1);

for i = 1:nFiles
    PCE_vals = allResults_sorted(i).PCE;
    [~,idx]  = max(PCE_vals);
    Vout_maxEff(i)   = allResults_sorted(i).Vout(idx);
    PCE_max(i)       = PCE_vals(idx);
    VRF_at_PCEmax(i) = allResults_sorted(i).VRFmax(idx);
    Pi_max(i)        = allResults_sorted(i).Pin_dBm(idx);
end

%% ============================================================
% Plot: PCE vs Pin
%% ============================================================
figure('Color','w'); hold on;
for i = 1:nFiles
    Pin_dBm = allResults_sorted(i).Pin_dBm;
    PCE     = allResults_sorted(i).PCE;
    VRF     = allResults_sorted(i).VRFmax;

    plot(Pin_dBm,PCE,'-o','Color',colors(i,:),'LineWidth',1.6,'DisplayName',labels_sorted{i});
    [~,idx] = max(PCE);

    % Maximum point
    plot(Pin_dBm(idx),PCE(idx),'ko','MarkerFaceColor','k','MarkerSize',8,'HandleVisibility','off');
    text(Pin_dBm(idx),PCE(idx)+0.03, sprintf('VRF=%.2f V', VRF(idx)), ...
        'FontSize',12,'Color','r','FontWeight','bold','HorizontalAlignment','center');
end
xlabel('Pin [dBm]'); ylabel('PCE'); title('PCE vs Pin curves');
legend('show'); grid on;

%% ============================================================
% Plot: Vout vs Pin
%% ============================================================
figure('Color','w'); hold on;
for i = 1:nFiles
    Pin_dBm = allResults_sorted(i).Pin_dBm;
    Vout    = allResults_sorted(i).Vout;
    VRF     = allResults_sorted(i).VRFmax;

    plot(Pin_dBm,Vout,'-s','Color',colors(i,:),'LineWidth',1.6,'DisplayName',labels_sorted{i});
    [~,idx] = max(allResults_sorted(i).PCE);

    plot(Pin_dBm(idx),Vout(idx),'ko','MarkerFaceColor','k','MarkerSize',8,'HandleVisibility','off');
    text(Pin_dBm(idx),Vout(idx)+0.05, sprintf('VRF=%.2f V', VRF(idx)), ...
        'FontSize',12,'Color','r','FontWeight','bold','HorizontalAlignment','center');
end
yline(1,'--k','LineWidth',1.5,'HandleVisibility','off');
xlabel('Pin [dBm]'); ylabel('Vout [V]'); title('Vout vs Pin');
legend('show'); grid on;

%% ============================================================
% Plot: Vout/VRFmax vs Pin
%% ============================================================
figure('Color','w'); hold on;
for i = 1:nFiles
    Pin_dBm = allResults_sorted(i).Pin_dBm;
    Ratio   = allResults_sorted(i).Vout ./ allResults_sorted(i).VRFmax;
    VRF     = allResults_sorted(i).VRFmax;

    plot(Pin_dBm,Ratio,'-^','Color',colors(i,:),'LineWidth',1.6,'DisplayName',labels_sorted{i});
    [~,idx] = max(allResults_sorted(i).PCE);

    plot(Pin_dBm(idx),Ratio(idx),'ko','MarkerFaceColor','k','MarkerSize',8,'HandleVisibility','off');
    text(Pin_dBm(idx),Ratio(idx)+0.05, sprintf('VRF=%.2f V', VRF(idx)), ...
        'FontSize',12,'Color','r','FontWeight','bold','HorizontalAlignment','center');
end
xlabel('Pin [dBm]'); ylabel('Vout/VRF_{max}'); title('Vout/VRF_{max} vs Pin');
legend('show'); grid on;

%% ============================================================
% Comparative subplots (2x2)
%% ============================================================
figure('Color','w');

% Subplot 1: Pin at maximum PCE vs Resistance
subplot(2,2,1);
plot(Rvals_sorted,Pi_max,'-o','LineWidth',1.6,'MarkerFaceColor','k','Color','b');
set(gca,'XScale','log','FontSize',12);
xlabel('Resistance [Ω]'); ylabel('Pin @ PCEmax [dBm]');
title('Pin at maximum PCE vs Resistance'); grid on;

% Subplot 2: Vout at maximum PCE vs Resistance
subplot(2,2,2);
plot(Rvals_sorted,Vout_maxEff,'-s','LineWidth',1.6,'MarkerFaceColor','k','Color','m');
set(gca,'XScale','log','FontSize',12);
xlabel('Resistance [Ω]'); ylabel('Vout @ PCEmax [V]');
title('Vout at maximum PCE vs Resistance'); grid on;

% Subplot 3: Maximum PCE vs Resistance
subplot(2,2,3);
plot(Rvals_sorted,PCE_max,'-^','LineWidth',1.6,'MarkerFaceColor','k','Color','g');
set(gca,'XScale','log','FontSize',12);
xlabel('Resistance [Ω]'); ylabel('Maximum PCE');
title('Maximum efficiency vs Resistance'); grid on;

% Subplot 4: VRF at maximum PCE vs Resistance
subplot(2,2,4);
plot(Rvals_sorted,VRF_at_PCEmax,'-d','LineWidth',1.6,'MarkerFaceColor','k','Color','r');
set(gca,'XScale','log','FontSize',12);
xlabel('Resistance [Ω]'); ylabel('VRF @ PCEmax [V]');
title('VRF at maximum PCE vs Resistance'); grid on;

sgtitle('Comparison of key metrics vs Resistance (MULT3, C00-80, M25, L00-20)');
