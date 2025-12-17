%% File: ml_pipelines/02_degradation_engine/08_train_degradation_lstm.m
function train_degradation_lstm()
    % ==========================================================
    % MODEL 2: DEGRADATION ENGINE (LSTM)
    % Input: 30-day history of 36 vibration features → Output: [ΔK, ΔC]
    % ==========================================================
    
    fprintf('🚀 TRAINING MODEL 2: DEGRADATION LSTM\n');
    fprintf('========================================\n\n');
    
    % --- Resolve paths ---
    thisFile = mfilename('fullpath');
    scriptDir = fileparts(thisFile);
    projectRoot = fileparts(fileparts(scriptDir));
    seqDir = fullfile(projectRoot, 'data', 'sequences');
    modelsDir = fullfile(projectRoot, 'data', 'models');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    
    % --- Load Data ---
    dataPath = fullfile(seqDir, 'degradation_lstm_data.mat');
    if ~exist(dataPath, 'file')
        error('File not found: %s. Run create_degradation_sequences_lstm.m first.', dataPath);
    end
    
    load(dataPath, 'X_cell', 'Y_deg');
    
    % --- Split Data ---
    n = length(X_cell);
    rng(42);
    idx = randperm(n);
    nTrain = floor(0.8 * n);
    
    XTrain = X_cell(idx(1:nTrain));
    YTrain = Y_deg(idx(1:nTrain), :);
    
    XTest = X_cell(idx(nTrain+1:end));
    YTest = Y_deg(idx(nTrain+1:end), :);
    
    fprintf('📊 Dataset: %d sequences, %d features per step\n', n, size(XTrain{1},1));
    fprintf('📈 Training: %d, Test: %d\n', nTrain, n - nTrain);
    
    % --- Define LSTM Architecture ---
    layers = [
        sequenceInputLayer(36, 'Name', 'input')  % 36 features per time step
        lstmLayer(100, 'OutputMode', 'last', 'Name', 'lstm1')
        dropoutLayer(0.2, 'Name', 'dropout1')
        fullyConnectedLayer(50, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        fullyConnectedLayer(2, 'Name', 'output')  % ΔK, ΔC
        regressionLayer('Name', 'loss')
    ];
    
    % --- Training Options ---
    options = trainingOptions('adam', ...
        'MaxEpochs', 50, ...
        'MiniBatchSize', 64, ...
        'InitialLearnRate', 0.01, ...
        'GradientThreshold', 1, ...
        'Shuffle', 'every-epoch', ...
        'Plots', 'training-progress', ...
        'Verbose', 1, ...
        'ValidationData', {XTest, YTest}, ...
        'ValidationPatience', 15, ...
        'ExecutionEnvironment', 'auto'); % Use GPU if available
    
    % --- Train Network ---
    fprintf('\n🔥 STARTING TRAINING...\n');
    net = trainNetwork(XTrain, YTrain, layers, options);
    
    % --- Evaluate on Test Set ---
    YPred = predict(net, XTest);
    rmse = sqrt(mean((YPred - YTest).^2));
    
    fprintf('\n📊 TEST PERFORMANCE:\n');
    fprintf('   ΔK RMSE: %.4f N/m\n', rmse(1));
    fprintf('   ΔC RMSE: %.6f N·s/m\n', rmse(2));
    
    % --- Save Model ---
    save(fullfile(modelsDir, 'degradation_lstm.mat'), 'net');
    fprintf('\n💾 Saved degradation model to: %s\n', ...
        fullfile(modelsDir, 'degradation_lstm.mat'));
    
    fprintf('✅ MODEL 2 TRAINING COMPLETE.\n');
end