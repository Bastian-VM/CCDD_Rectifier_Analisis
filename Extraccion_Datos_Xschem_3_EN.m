%% ============================================================
% Title: Plot selected variables vs time (Part 6)
%
% Author: Bastian Veas Moyano
%
% Last modification: August 03, 2026
%
% Description: This code loads a specific MAT file and asks the user
% to select two variables from the list (by index). It then generates
% plots of all variables vs time, plus an additional figure showing
% variable1 vs variable2 across all simulation blocks.
%% ============================================================
clearvars -except folder matFolder; clc; close all;


%% ============================================================
% Working folder
%% ============================================================

if ~exist('folder','var') || isempty(folder) || ~isfolder(folder)
    folder = pwd; % current directory
end

matFolder = fullfile(folder,'Archivos_MAT');
if ~exist(matFolder,'dir')
    mkdir(matFolder);
end

fprintf('Working folder: %s\n', matFolder);

%% ============================================================
% PART 6: Specific file name to plot
%% ============================================================
targetFile = 'Resultados_CCDD2_TRAN_MULT5_L00-20_W00-60_R100kM20_C01-00.mat';  % <-- change to the exact name

filename = fullfile(matFolder, targetFile);
if exist(filename,'file')
    fprintf('\nLoading file: %s\n', targetFile);
    load(filename,'results');

    %% ============================================================
    % Ask user for variables BEFORE plotting
    %% ============================================================
    disp('Available variables:');
    for i = 1:numel(results{1}.NomEje)
        fprintf('%d: %s\n', i, results{1}.NomEje(i));
    end

    idx_var1 = input('Enter the index of the first variable: ');
    idx_var2 = input('Enter the index of the second variable: ');

    if idx_var1 < 1 || idx_var1 > numel(results{1}.NomEje) || ...
       idx_var2 < 1 || idx_var2 > numel(results{1}.NomEje)
        error('Invalid indices selected.');
    end

    var1 = char(results{1}.NomEje(idx_var1));
    var2 = char(results{1}.NomEje(idx_var2));

    %% ============================================================
    % Plot all variables vs time
    %% ============================================================
    for col = 3:size(results{1}.vals,2)
        figure('Name',[char(results{1}.NomEje(col)),' vs time'],'NumberTitle','off'); hold on;

        for b = 1:numel(results)
            time = results{b}.vals(:,2);
            varData = results{b}.vals(:,col);

            VRF_block = max(abs(results{b}.vals(:,3)));
            VRF_label = sprintf('Block %d (VRF=%.2f V)', b, round(VRF_block,2));

            plot(time,varData,'LineWidth',1.5,'DisplayName',VRF_label);
        end

        xlabel('Time [s]','Interpreter','none');
        ylabel(char(results{1}.NomEje(col)),'Interpreter','none');
        title([char(results{1}.NomEje(col)),' vs time (', targetFile, ')'],'Interpreter','none');
        legend('show','Location','best','Interpreter','none');
        grid on;
    end

    %% ============================================================
    % EXTRA: Plot variable1 vs variable2
    %% ============================================================
    figure('Name',[var1,' vs ',var2],'NumberTitle','off'); hold on;
    for b = 1:numel(results)
        dataX = results{b}.vals(:,idx_var1);
        dataY = results{b}.vals(:,idx_var2);

        VRF_block = max(abs(results{b}.vals(:,3)));
        VRF_label = sprintf('Block %d (VRF=%.2f V)', b, round(VRF_block,2));

        plot(dataX,dataY,'LineWidth',1.5,'DisplayName',VRF_label);
    end
    xlabel(var1,'Interpreter','none');
    ylabel(var2,'Interpreter','none');
    title([var1,' vs ',var2,' (', targetFile, ')'],'Interpreter','none');
    legend('show','Location','best','Interpreter','none');
    grid on;

else
    warning('The file %s does not exist in the folder %s', targetFile, matFolder);
end
