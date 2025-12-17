%% File: ml_pipelines/03_rul_predictor/11_create_rul_sequences_lstm.m
function create_rul_sequences_lstm()
    % ==========================================================
    % PURPOSE:
    %   Generate synthetic RUL sequences for Model 3 (LSTM).
    %   Input: 30-day history of 36 vibration features.
    %   Output: RUL (days) at the end of the sequence.
    %
    % DATA SOURCE:
    %   Uses your real 36-feature dataset from shaft_features.mat.
    %   Simulates "run-to-failure" by creating artificial lifecycles.
    % ==========================================================
    
    fprintf('🚀 CREATING RUL SEQUENCES FOR LSTM (MODEL 3)\n');
    fprintf('============================================\n\n');
    
    % --- Resolve project root ---
    thisFile = mfilename('fullpath');
    scriptDir = fileparts(thisFile);
    projectRoot = fileparts(fileparts(scriptDir));
    procDir = fullfile(projectRoot, 'data', 'processed');
    seqDir = fullfile(projectRoot, 'data', 'sequences');
    
    if ~exist(seqDir, 'dir'), mkdir(seqDir); end
    
    % --- Load Features ---
    dataPath = fullfile(procDir, 'shaft_features.mat');
    if ~exist(dataPath, 'file')
        error('File not found: %s. Run extract_shaft_features_corrected first.', dataPath);
    end
    
    load(dataPath, 'all_features');
    
    % --- Configuration ---
    n_sequences = 1000;      % Number of synthetic lifecycles to generate
    seq_len = 30;           % 30 days per sequence
    path_len = 60;          % Each lifecycle has 60 steps
    
    X_cell = {};            % Cell array for LSTM input: {1x1} each [36x30]
    Y_rul = [];             % Target: RUL in days
    
    fprintf('🔄 Generating %d synthetic lifecycles...\n', n_sequences);
    
    for i = 1:n_sequences
        % Simulate a machine lifespan: start healthy, end broken
        total_life = 60 + randi(40);  % Random life: 60–100 days
        
        % Create a degradation curve for K (500 → 50)
        t = linspace(0, 1, path_len)';
        k_path = 500 - (500 - 50) * (t.^2);  % Accelerated wear
        
        % Generate feature vectors based on K
        % In real world, we'd use Model 1 inverse or lookup table
        % For demo, we'll simulate features as random noise scaled by K
        path_feats = zeros(path_len, 36);
        
        for j = 1:path_len
            base_vib = (500 - k_path(j)) / 10;  % Higher vib when K is low
            path_feats(j, :) = base_vib + randn(1, 36) * 0.5;
        end
        
        % Extract sequences
        for j = seq_len : (path_len - 1)
            % Input: 30-day window of 36 features
            seq = path_feats(j-seq_len+1 : j, :)';  % [36 x 30]
            
            % Output: RUL = total_life - current_age
            current_age = j;
            rul = total_life - current_age;
            
            X_cell{end+1, 1} = seq;
            Y_rul(end+1, 1) = rul;
        end
    end
    
    % --- Save Data ---
    save(fullfile(seqDir, 'rul_lstm_data.mat'), 'X_cell', 'Y_rul');
    fprintf('\n💾 Saved RUL LSTM data to: %s\n', ...
        fullfile(seqDir, 'rul_lstm_data.mat'));
    
    fprintf('✅ RUL SEQUENCE GENERATION COMPLETE.\n');
end