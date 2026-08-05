%% ============================================================
% Title: Conversion and analysis of xschem simulation CSV (ASCII) files
%
% Author: Bastian Veas Moyano
%
% Last modification: August 03, 2026
%
% Description: This code converts CSV files from electrical simulations 
% into MAT files, leaving each variable and its data as a table, checks their
% existence in the working folder, filters valid results, and automatically
% generates plots of variables such as Vout and Vrf for each simulation block,
% in order to verify correct conversion.
%
% The CSV files come from simulations performed with Xschem, saving 
% data in ASCII format. Each file may contain multiple simulation runs 
% grouped in blocks; for example, if 10 blocks are detected, it means 
% the simulation was executed 10 times varying a parameter, in this case VRF.
%
% The simulations correspond to open-source VLSI technologies, specifically 
% the IHP-SG13G2 PDK, within the Chip USM Docker Environment for IC Design 
% and Implementation. This environment integrates tools such as ngspice, 
% xschem, magic, klayout, netgen, cvc, cace, gdsfactory, glayout, pygmid, 
% and openvaf, along with PDKs sky130A, gf180mcuD, and ihp-sg13g2. The flow 
% enables verification, design, and characterization of integrated circuits 
% in a reproducible and portable way.
%% ============================================================
clear; clc; close all;

%% ============================================================
% Working folder
%% ============================================================

% Option: define manually the main folder
% If not defined or does not exist, use the current directory
if ~exist('folder','var') || isempty(folder) || ~isfolder(folder)
    folder = pwd; % current directory
end

% Subfolder where the CSV files are located
csvFolder = fullfile(folder,'Schem_CSV');

% Subfolder where the MAT files will be saved
matFolder = fullfile(folder,'Archivos_MAT');
if ~exist(matFolder,'dir')
    mkdir(matFolder); % create if it does not exist
end

fprintf('Working folder: %s\n', matFolder);
fprintf('CSV folder: %s\n', csvFolder);

%% ============================================================
% List of CSV files to process
%% ============================================================
fileList = {
    'Memoria_CCDD2_TRAN_MULT3_L00-22_W00-60_R100kM25_C00-80.csv'
    'Memoria_CCDD2_TRAN_MULT3_L00-24_W00-60_R100kM25_C00-80.csv'
    'Memoria_CCDD2_TRAN_MULT3_L00-26_W00-60_R100kM25_C00-80.csv'
    %'Memoria_CCDD2_TRAN_MULT2_L00-20_W00-60_R100kM20_C01-00.csv'
    %'Memoria_CCDD2_TRAN_MULT3_L00-20_W00-60_R100kM20_C01-00.csv'
    %'Memoria_CCDD2_TRAN_MULT4_L00-20_W00-60_R100kM20_C01-00.csv'
    %'Memoria_CCDD2_TRAN_MULT5_L00-20_W00-60_R100kM20_C01-00.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-15_R100kM1.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-15_R100kM2.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-15_R100kM5.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-15_R100kM10.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-15_R100kM20.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-20_R100kM1.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-20_R100kM2.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-20_R100kM5.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-20_R100kM10.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-20_R100kM20.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-60_R100kM1.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-60_R100kM2.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-60_R100kM5.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-60_R100kM10.csv'
    %'Memoria_CCDD2_TRAN_MULT1_L01-00_W00-60_R100kM20.csv'
};


% Estimated number of variables in simulation file
NumEstVar = 30;

%% ============================================================
% Verify existing files in CSV folder
%% ============================================================
foundFiles = {};
for i = 1:numel(fileList)
    fullPath = fullfile(csvFolder, fileList{i});
    if exist(fullPath,'file') == 2
        foundFiles{end+1} = fileList{i};
    else
        fprintf('Not found: %s\n', fileList{i});
    end
end

fprintf('\nFound %d of %d CSV files in the CSV folder:\n', numel(foundFiles), numel(fileList));
disp(foundFiles');

%% ============================================================
% PART 1: CONVERT CSV → MAT
%% ============================================================
for f = 1:numel(fileList)
    filename = fullfile(csvFolder, fileList{f});
    fprintf('\nProcessing CSV: %s\n', filename);

    % Read headers with readcell (only first rows)
    opts = detectImportOptions(filename);
    opts.DataLines = [1 NumEstVar+8+10]; 
    data1 = readcell(filename, opts);

    % Detect position of Variables and Values
    IVar_all = find(strcmp(data1(:,1),'Variables:'));
    IVal_all = find(strcmp(data1(:,1),'Values:'));

    % Extract number of variables and points
    NoVar = 0; NoPoints = 0;
    for j = IVar_all(1)-5:IVar_all(1)-1
        if ischar(data1{j}) || isstring(data1{j})
            line = string(data1{j});
            if contains(line,'No. Variables:')
                NoVar = str2double(extractAfter(line,':'));
            elseif contains(line,'No. Points:')
                NoPoints = str2double(extractAfter(line,':'));
            end
        end
    end

    % Build axis names
    NomEje = strings(1,NoVar+1);
    NomEje(1) = "index";
    for i = 1:NoVar
        Nom = data1{IVar_all(1)+i,3};
        rawname = lower(string(Nom));
        ini = strfind(rawname,'('); fin = strfind(rawname,')');
        if ~isempty(ini) && ~isempty(fin) && ini < fin
            NomEje(i+1) = extractBetween(rawname,ini+1,fin-1);
        else
            NomEje(i+1) = rawname;
        end
    end

    % Read full values with readmatrix
    DataNum = readmatrix(filename);

    % Detect number of blocks (when index returns to 0)
    idxZeros = find(DataNum(:,1) == 0);
    nBlocks = numel(idxZeros);
    fprintf('  Blocks detected: %d\n', nBlocks);

    % Reconstruct values block by block
    results = cell(1,nBlocks);
    for b = 1:nBlocks
        base = idxZeros(b);
        vals = zeros(NoPoints, NoVar+1);

        for pnt = 1:NoPoints
            for var = 1:NoVar
                if var == 1
                    vals(pnt,1)     = DataNum(base+var-1+(pnt-1)*NoVar,1);
                    vals(pnt,var+1) = DataNum(base+var-1+(pnt-1)*NoVar,2);
                else
                    vals(pnt,var+1) = DataNum(base+var-1+(pnt-1)*NoVar,2);
                end
            end 
        end

        results{b}.NomEje = NomEje;
        results{b}.vals   = vals;
    end

    % Save results in .mat file
    [~, name, ~] = fileparts(filename);
    outname = strrep(name, 'Memoria', 'Resultados');
    outfile = fullfile(matFolder, [outname, '.mat']);
    save(outfile, 'results');
    fprintf('  Results saved in: %s\n', outfile);
end


%% ============================================================
% PART 2: FILTER MAT FILES FOR VERIFICATION
%% ============================================================
validResults = struct([]);
for f = 1:numel(fileList)
    [~, name, ~] = fileparts(fileList{f});
    outname = strrep(name, 'Memoria', 'Resultados');
    matFile = fullfile(matFolder, [outname, '.mat']);

    % Verify file existence before adding
    if exist(matFile,'file') == 2
        entry = dir(matFile);
        validResults = [validResults, entry];
    else
        fprintf('MAT file not found: %s\n', matFile);
    end
end

fprintf('\nSelected %d valid files for plotting.\n', numel(validResults));

%% ============================================================
% PART 3: GENERATE VOUT AND VRF PLOTS FROM FILE
%% ============================================================
for f = 1:numel(validResults)
    outfile = fullfile(matFolder, validResults(f).name);
    fprintf('Generating plot for: %s\n', outfile);

    try
        % Load results
        load(outfile, 'results');
        nBlocks = numel(results);

        % Create single figure for file
        figure('Name',['File: ',outfile],'NumberTitle','off');

        % Subplot 1: Vout vs time
        subplot(2,1,1); hold on;
        for b = 1:nBlocks
            vals = results{b}.vals;
            plot(vals(:,2), vals(:,5), 'LineWidth', 1.5, ...
                'DisplayName',['Block ',num2str(b)]);
        end
        grid on;
        xlabel(results{1}.NomEje(2), 'Interpreter','none'); % time
        ylabel(results{1}.NomEje(5), 'Interpreter','none'); % Vout
        title(sprintf('File: %s - Vout', outfile), 'Interpreter','none');
        legend('show','Location','best');

        % Subplot 2: vrf vs time
        subplot(2,1,2); hold on;
        for b = 1:nBlocks
            vals = results{b}.vals;
            plot(vals(:,2), vals(:,3), 'LineWidth', 1.5, ...
                'DisplayName',['Block ',num2str(b)]);
        end
        grid on;
        xlabel(results{1}.NomEje(2), 'Interpreter','none'); % time
        ylabel(results{1}.NomEje(3), 'Interpreter','none'); % vrf
        title(sprintf('File: %s - vrf', outfile), 'Interpreter','none');
        legend('show','Location','best');

    catch ME
        fprintf('  Error while plotting: %s\n', ME.message);
    end
end
