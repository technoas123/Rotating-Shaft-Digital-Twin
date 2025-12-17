%% File: ml_pipelines/03_rul_predictor/11_create_rul_sequences_03.m
% ========================================================================
% Purpose (MODEL 3 – RUL data creation):
%   Build training data for a RUL predictor:
%     Input sequence: 30 timesteps × 12 features
%     Output label  : RUL in "days" (synthetic)
%
% Uses:
%   data/processed/shaft_features.mat
%     all_features      [N×36]  (12 feats × 3 channels)
%     parameter_targets [N×3]   (spring, damper, inertia)
%     file_labels       [N×1]
%     shaft_files       {20×1}
%
% Saves:
%   data/sequences/rul_cnn_sequences.mat
%     XTrain, YTrain, XTest, YTest, historyLength, nFeatures
% ========================================================================
function create_rul_sequences_03()

    fprintf('🚀 CREATING RUL SEQUENCES (MODEL 3)\n');
    fprintf('===================================\n\n');

    %% 1. Resolve paths
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);                 % ...\03_rul_predictor
    projectRoot = fileparts(fileparts(scriptDir));     % project root
    procDir     = fullfile(projectRoot,'data','processed');
    seqDir      = fullfile(projectRoot,'data','sequences');
    if ~exist(seqDir,'dir'); mkdir(seqDir); end

    %% 2. Load features & parameters
    S = load(fullfile(procDir,'shaft_features.mat'), ...
             'all_features','parameter_targets','file_labels','shaft_files');
    all_features      = S.all_features;        % [N×36]
    parameter_targets = S.parameter_targets;   % [N×3]
    file_labels       = S.file_labels;
    shaft_files       = S.shaft_files;

    fprintf('📊 Loaded %d windows, %d raw features each\n', ...
            size(all_features,1), size(all_features,2));

    %% 3. Reduce 36 → 12 features (average across 3 accelerometer channels)
    [n_windows,n_features_raw] = size(all_features);
    if n_features_raw ~= 36
        error('Expected 36 features (12×3 channels); got %d',n_features_raw);
    end

    % Reshape to [N×3×12], then mean across 2nd dim (channels)
    all3d = reshape(all_features,[n_windows,3,12]);
    all_features_12 = squeeze(mean(all3d,2));  % [N×12]

    nFeatures = 12;

    %% 4. Build file→window index mapping
    n_files = numel(shaft_files);
    file_windows = cell(n_files,1);
    for i = 1:n_files
        file_windows{i} = sort(find(file_labels == i));
    end

    %% 5. Define degradation paths (indices into shaft_files)
    % Mapping index→filename prefix (for reference):
    %  1→01, 2→02, 3→03, 4→04, 5→05,
    %  6→11, 7→12, 8→13, 9→14,
    % 10→15,11→16,12→17,13→18,14→19,
    % 15→25,16→26,17→27,18→28,19→29,20→30
    degradation_paths = {
        [1, 3, 4, 5]                        % 01,03,04,05
        [2, 5, 13, 14]                      % 02,05,18,19
        [6, 7, 8, 9]                        % 11,12,13,14
        [10,11,12,15,16,17,18,19,20]        % 15,16,17,25,26,27,28,29,30
    };

    historyLength = 30;   % 30-day history
    Xseq = [];            % will be [Ns×(30*12)]
    Yseq = [];            % RUL in "days"

    fprintf('📈 Using sequence length = %d, features = %d\n', historyLength, nFeatures);

    %% 6. Build RUL sequences from each path
    for p = 1:numel(degradation_paths)
        path = degradation_paths{p};
        fprintf('\n🔄 Path %d: %s\n',p,strjoin(string(path),' → '));

        % Collect window indices for full lifetime
        path_idx = [];
        for f = path
            path_idx = [path_idx; file_windows{f}(:)];
        end

        totalSteps = numel(path_idx);
        fprintf('   Total steps in path: %d\n',totalSteps);
        if totalSteps < historyLength
            fprintf('   ⚠️  Path too short, skipping.\n');
            continue;
        end

        feats_path = all_features_12(path_idx,:);  % [totalSteps×12]

        % For each possible 30-step window, create a sequence and RUL label
        for t0 = 1:(totalSteps - historyLength + 1)
            tEnd = t0 + historyLength - 1;
            seq_window = feats_path(t0:tEnd,:);    % [30×12]

            % RUL (in steps) = remaining steps after last point
            remaining_steps = totalSteps - tEnd;
            RUL_days = max(0, remaining_steps);    % 1 step = 1 "day" here

            Xseq(end+1,:) = seq_window(:).';      % flatten to [1×360]
            Yseq(end+1,1) = RUL_days;
        end

        fprintf('   ➕ Added %d sequences from this path\n', ...
            size(Xseq,1));
    end

    nSeq = size(Xseq,1);
    fprintf('\n📊 Total RUL sequences: %d\n',nSeq);

    %% 7. Normalize features (0–1 per feature) [optional, good practice]
    Xmin = min(Xseq,[],1);
    Xmax = max(Xseq,[],1);
    range = Xmax - Xmin;
    range(range == 0) = 1;

    Xnorm = (Xseq - Xmin) ./ range;

    %% 8. Time-based train/test split (first 70%, last 30%)
    splitIdx = floor(0.7*nSeq);
    trainIdx = 1:splitIdx;
    testIdx  = splitIdx+1:nSeq;

    XTrain = Xnorm(trainIdx,:);
    YTrain = Yseq(trainIdx);
    XTest  = Xnorm(testIdx,:);
    YTest  = Yseq(testIdx);

    save(fullfile(seqDir,'rul_cnn_sequences.mat'), ...
         'XTrain','YTrain','XTest','YTest', ...
         'historyLength','nFeatures','Xmin','Xmax');

    fprintf('\n💾 Saved RUL sequences to: %s\n', ...
        fullfile(seqDir,'rul_cnn_sequences.mat'));
    fprintf('   Train: %d sequences, Test: %d sequences\n', ...
        numel(YTrain), numel(YTest));
end