function create_degradation_sequences_lstm()
    fprintf('🚀 CREATING LSTM DATA (36 FEATURES, FULL RANGE)\n');
    
    % Paths
    thisFile = mfilename('fullpath');
    projectRoot = fileparts(fileparts(fileparts(thisFile)));
    procDir = fullfile(projectRoot, 'data', 'processed');
    seqDir = fullfile(projectRoot, 'data', 'sequences');
    
    load(fullfile(procDir, 'shaft_features.mat'), 'all_features', 'parameter_targets');
    
    % Use ALL 36 features
    feats = all_features; 
    
    n_sequences = 1000;
    seq_len = 30;
    path_len = 60;
    
    X_cell = {}; % Input {36 x 30}
    Y_deg = [];  % Output [ΔK, ΔC]
    
    fprintf('🔄 Generating %d paths...\n', n_sequences);
    
    for i = 1:n_sequences
        % Simulate K dropping from 500 to 50 (Failure)
        k_start = 500 + randn()*10;
        k_end = 50; % HARD FAILURE POINT
        c_start = 0.5; c_end = 0.9;
        
        t = linspace(0, 1, path_len)';
        
        % Exponential decay for realism
        k_path = k_start + (k_end - k_start) * (t.^2);
        c_path = c_start + (c_end - c_start) * (t.^1.5);
        
        % Generate synthetic features (noise for demo logic)
        % In reality, map K back to feature space using nearest neighbor
        path_feats = randn(path_len, 36); 
        
        for j = seq_len : (path_len - 1)
            % Input: [36 features x 30 steps]
            seq = path_feats(j-seq_len+1 : j, :)'; 
            X_cell{end+1, 1} = seq;
            
            % Output: Delta
            dk = k_path(j+1) - k_path(j);
            dc = c_path(j+1) - c_path(j);
            Y_deg = [Y_deg; dk, dc];
        end
    end
    
    save(fullfile(seqDir, 'degradation_lstm_data.mat'), 'X_cell', 'Y_deg');
    fprintf('💾 Saved degradation LSTM data.\n');
end