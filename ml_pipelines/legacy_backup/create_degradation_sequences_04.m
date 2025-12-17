%% File: ml_pipelines/02_degradation_engine/create_degradation_sequences_07.m
% ========================================================================
% Purpose (MODEL 2 – Degradation Engine data):
%   Build training sequences for an LSTM that predicts degradation
%   of shaft parameters.
%
%   Input  per sample:
%       30-step history of 36 vibration features (12 feats × 3 channels)
%       → each sequence X{i} has size [36 × 30]
%
%   Output per sample:
%       Y(i,:) = [Δspring, Δdamper, Δhealth]
%       where:
%           spring = K, damper = C, health = (K / K_healthy * 100)
%
% Uses:
%   data/processed/shaft_features.mat
%       all_features      [N×36]
%       parameter_targets [N×3] = [spring, damper, inertia]
%       file_labels       [N×1] (index into shaft_files)
%       shaft_files       {20×1}
%
% Saves:
%   data/sequences/degradation_sequences_m2.mat
%       XTrain, YTrain, XVal, YVal, XTest, YTest, historyLength
% ========================================================================
function create_degradation_sequences_07()

    fprintf('🚀 CREATING DEGRADATION SEQUENCES (MODEL 2)\n');
    fprintf('===========================================\n\n');

    %% 1. Resolve paths
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);                 % ...\02_degradation_engine
    projectRoot = fileparts(fileparts(scriptDir));     % go up to project root
    procDir     = fullfile(projectRoot,'data','processed');
    seqDir      = fullfile(projectRoot,'data','sequences');
    if ~exist(seqDir,'dir'); mkdir(seqDir); end

    %% 2. Load features and targets
    S = load(fullfile(procDir,'shaft_features.mat'), ...
             'all_features','parameter_targets','file_labels','shaft_files');
    all_features      = S.all_features;        % [N×36]
    parameter_targets = S.parameter_targets;   % [N×3] (spring, damper, inertia)
    file_labels       = S.file_labels;
    shaft_files       = S.shaft_files;

    spring = parameter_targets(:,1);           % K
    damper = parameter_targets(:,2);           % C
    K_healthy = 500;                           % for health index
    health = (spring / K_healthy) * 100;       % 0–100 %

    fprintf('📊 Loaded %d windows, %d features each\n', ...
        size(all_features,1), size(all_features,2));

    %% 3. Group windows per file index
    n_files = numel(shaft_files);
    file_windows = cell(n_files,1);
    for i = 1:n_files
        file_windows{i} = sort(find(file_labels == i));  % ascending indices
    end

    %% 4. Define degradation paths (INDEX into shaft_files, NOT file numbers)
    % Index → file mapping from your directory listing:
    %  1→01,  2→02,  3→03,  4→04,  5→05,
    %  6→11,  7→12,  8→13,  9→14,
    % 10→15, 11→16, 12→17, 13→18, 14→19,
    % 15→25, 16→26, 17→27, 18→28, 19→29, 20→30
    degradation_paths = {
        [1, 3, 4, 5]                        % 01,03,04,05
        [2, 5, 13, 14]                      % 02,05,18,19
        [6, 7, 8, 9]                        % 11,12,13,14
        [10,11,12,15,16,17,18,19,20]        % 15,16,17,25,26,27,28,29,30
    };

    historyLength = 30;         % 30-step history
    noise_level   = 0.05;       % 5% noise on features

    X = {};                     % cell: each element [36×30]
    Y = [];                     % matrix: [Nsamples×3] = [ΔK, ΔC, ΔHealth]

    fprintf('📈 Using history length = %d windows\n', historyLength);

    %% 5. Build sequences for each path
    for p = 1:numel(degradation_paths)
        path = degradation_paths{p};
        fprintf('\n🔄 Path %d: %s\n', p, strjoin(string(path),' → '));

        % Collect all window indices for this path, preserving order
        path_idx = [];
        for f = path
            w = file_windows{f};
            path_idx = [path_idx; w(:)];
        end

        if numel(path_idx) <= historyLength+1
            fprintf('   ⚠️  Not enough windows for this path, skipping.\n');
            continue;
        end

        % Parameter sequences
        K_seq = spring(path_idx);
        C_seq = damper(path_idx);
        H_seq = health(path_idx);
        totalSteps = numel(path_idx);

        fprintf('   Total steps in path: %d\n', totalSteps);

        % For each time step t, use previous historyLength steps to predict
        % the change from t → t+1.
        for t = historyLength:(totalSteps-1)
            hist_idx = path_idx(t-historyLength+1:t); % 30‑step history
            next_idx = path_idx(t+1);

            % Features: [30×36] → add noise → transpose to [36×30]
            feat_seq   = all_features(hist_idx,:);          % [30×36]
            feat_std   = std(feat_seq,0,1);
            noisy_seq  = feat_seq + noise_level*randn(size(feat_seq)).*feat_std;
            X_sample   = noisy_seq';                        % [36×30]

            % Targets: ΔK, ΔC, ΔHealth between t and t+1
            K_t    = K_seq(t);
            K_next = K_seq(t+1);
            C_t    = C_seq(t);
            C_next = C_seq(t+1);
            H_t    = H_seq(t);
            H_next = H_seq(t+1);

            dK = K_next - K_t;
            dC = C_next - C_t;
            dH = H_next - H_t;

            X{end+1,1} = X_sample;           %#ok<AGROW>
            Y(end+1,:) = [dK, dC, dH];       %#ok<AGROW>
        end
    end

    nSamples = numel(X);
    fprintf('\n📊 Total degradation samples created: %d\n',nSamples);

    %% 6. Time-based split: 70% train, 15% val, 15% test
    nTrain = floor(0.7*nSamples);
    nVal   = floor(0.15*nSamples);
    nTest  = nSamples - nTrain - nVal;

    train_idx = 1:nTrain;
    val_idx   = (nTrain+1):(nTrain+nVal);
    test_idx  = (nTrain+nVal+1):nSamples;

    XTrain = X(train_idx);
    YTrain = Y(train_idx,:);
    XVal   = X(val_idx);
    YVal   = Y(val_idx,:);
    XTest  = X(test_idx);
    YTest  = Y(test_idx,:);

    %% 7. Save sequences
    save(fullfile(seqDir,'degradation_sequences_m2.mat'), ...
         'XTrain','YTrain','XVal','YVal','XTest','YTest','historyLength');

    fprintf('\n💾 Saved degradation sequences to: %s\n', ...
        fullfile(seqDir,'degradation_sequences_m2.mat'));
    fprintf('   Train: %d, Val: %d, Test: %d samples\n',nTrain,nVal,nTest);
end