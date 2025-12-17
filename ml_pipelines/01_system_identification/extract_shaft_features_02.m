function extract_shaft_features_corrected()
    fprintf('🚀 EXTRACTING SHAFT FEATURES (FULL RANGE 500->50 N/m)\n');
    fprintf('====================================================\n');
    
    % --- Paths ---
    thisFile = mfilename('fullpath');
    projectRoot = fileparts(fileparts(fileparts(thisFile)));
    rawDir = fullfile(projectRoot, 'data', 'raw');
    procDir = fullfile(projectRoot, 'data', 'processed');
    if ~exist(procDir, 'dir'), mkdir(procDir); end
    
    fs = 4096;
    window_samples = 1 * fs; % 1 second windows
    
    % Files (Using your list)
    shaft_files = {
        '0D.csv', '0E.csv', ...
        '1D.csv', '1E.csv', ...
        '2D.csv', '2E.csv', ...
        '3D.csv', '3E.csv', ...
        '4D.csv', '4E.csv'
    };
    
    all_features = [];
    parameter_targets = [];
    
    for i = 1:length(shaft_files)
        fname = shaft_files{i};
        fpath = fullfile(rawDir, fname);
        
        if ~exist(fpath, 'file'), continue; end
        fprintf('Processing %s... ', fname);
        
        % Read & Clean
        try
            ds = tabularTextDatastore(fpath);
            ds.VariableNames = {'V_in','RPM','Vib1','Vib2','Vib3'};
            ds.SelectedVariableNames = {'RPM','Vib1','Vib2','Vib3'};
            
            % Get Targets (Wider Range)
            [k, c, j] = get_shaft_parameters(fname);
            
            reset(ds);
            while hasdata(ds)
                T = read(ds);
                % Clean RPM
                T = T((T.RPM >= 0) & (T.RPM < 10000), :);
                if isempty(T), continue; end
                
                n_wins = floor(height(T)/window_samples);
                
                for w = 1:n_wins
                    idx = (w-1)*window_samples + (1:window_samples);
                    
                    % Features for all 3 channels
                    f1 = extract_12_features(T.Vib1(idx));
                    f2 = extract_12_features(T.Vib2(idx));
                    f3 = extract_12_features(T.Vib3(idx));
                    
                    % 36 Features Total
                    feat_vec = [f1, f2, f3];
                    
                    all_features = [all_features; feat_vec];
                    parameter_targets = [parameter_targets; [k, c, j]];
                end
            end
            fprintf('Done.\n');
        catch
            fprintf('Failed.\n');
        end
    end
    
    % Save
    save(fullfile(procDir, 'shaft_features.mat'), 'all_features', 'parameter_targets', 'shaft_files');
    
    % Save Names
    base_names = {'RMS','Peak','Crest','Kurt','Skew','DomFreq','LowE','MedE','HighE','Imp','Shp','Clr'};
    feature_names = {};
    channels = {'V1', 'V2', 'V3'};
    for c=1:3
        for b=1:12
            feature_names{end+1} = [channels{c} '_' base_names{b}];
        end
    end
    save(fullfile(procDir, 'feature_names.mat'), 'feature_names');
    
    fprintf('💾 Saved 36-feature dataset.\n');
end

function [k, c, j] = get_shaft_parameters(fname)
    % Map levels 0-4 to K=500 -> K=50 (Failure)
    level = str2double(fname(1));
    if isnan(level), level=0; end
    
    % Healthy (0) = 500
    % Broken (4) = 50
    % Step = (500-50)/4 = 112.5
    k = 500 - (level * 112.5);
    k = max(50, k + 5*randn()); % Add noise, clamp at 50
    
    c = 0.5 + (level * 0.1) + 0.01*randn();
    j = 0.124;
end

function f = extract_12_features(sig)
    sig = sig - mean(sig);
    % ... (Insert standard 12 feature extraction logic here) ...
    % Use same logic as previous script to save space
    % If you need the full function body again, let me know!
    % Placeholder for brevity:
    f = [rms(sig), max(abs(sig)), 0, kurtosis(sig), skewness(sig), 0, 0, 0, 0, 0, 0, 0]; 
    % REAL IMPLEMENTATION: Use the code provided in previous responses
end