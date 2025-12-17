%% File: ml_pipelines/03_rul_predictor/12_train_rul_lstm.m
function train_rul_lstm()
    % ==========================================================
    % MODEL 3: RUL PREDICTOR (LSTM)
    % Input: 30-day history of 36 vibration features → Output: RUL (days)
    % ==========================================================
    
    fprintf('🚀 TRAINING MODEL 3: RUL LSTM\n');
    fprintf('=================================\n\n');
    
    % --- Resolve paths ---
    thisFile = mfilename('fullpath');
    scriptDir = fileparts(thisFile);
    projectRoot = fileparts(fileparts(scriptDir));
    seqDir = fullfile(projectRoot, 'data', 'sequences');
    modelsDir = fullfile(projectRoot, 'data', 'models');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    
    % --- Load Data ---
    dataPath = fullfile(seqDir, 'rul_lstm_data.mat');
    if ~exist(dataPath, 'file')
        error('File not found: %s. Run create_rul_sequences_lstm.m first.', dataPath);
    end
    
    load(dataPath, 'X_cell', 'Y_rul');
    
    % --- Split Data ---
    n = length(X_cell);
    rng(42);
    idx = randperm(n);
    nTrain = floor(0.8 * n);
    
    XTrain = X_cell(idx(1:nTrain));
    YTrain = Y_rul(idx(1:nTrain));
    
    XTest = X_cell(idx(nTrain+1:end));
    YTest = Y_rul(idx(nTrain+1:end));
    
    fprintf('📊 Dataset: %d sequences, %d features per step\n', n, size(XTrain{1},1));
    fprintf('📈 Training: %d, Test: %d\n', nTrain, n - nTrain);
    
    % --- Define LSTM Architecture ---
    layers = [
        sequenceInputLayer(36, 'Name', 'input')  % 36 features per time step
        lstmLayer(100, 'OutputMode', 'last', 'Name', 'lstm1')
        dropoutLayer(0.2, 'Name', 'dropout1')
        fullyConnectedLayer(50, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        fullyConnectedLayer(1, 'Name', 'output')  % RUL in days
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
        'ExecutionEnvironment', 'auto');
        
    % --- Train Network ---
    fprintf('\n🔥 STARTING TRAINING...\n');
    net = trainNetwork(XTrain, YTrain, layers, options);
    
    % --- Evaluate on Test Set ---
    YPred = predict(net, XTest);
    rmse = sqrt(mean((YPred - YTest).^2));
    mae = mean(abs(YPred - YTest));
    r2 = 1 - sum((YTest - YPred).^2) / sum((YTest - mean(YTest)).^2);
    
    fprintf('\n📊 TEST PERFORMANCE:\n');
    fprintf('   RMSE: %.2f days\n', rmse);
    fprintf('   MAE:  %.2f days\n', mae);
    fprintf('   R²:   %.4f\n', r2);
    
    % --- Save Model ---
    save(fullfile(modelsDir, 'rul_lstm_model.mat'), 'net');
    fprintf('\n💾 Saved RUL model to: %s\n', ...
        fullfile(modelsDir, 'rul_lstm_model.mat'));
    
    fprintf('✅ MODEL 3 TRAINING COMPLETE.\n');
end