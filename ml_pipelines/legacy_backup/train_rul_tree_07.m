%% File: ml_pipelines/03_rul_predictor/12_train_rul_tree_03.m
% ========================================================================
% Purpose (MODEL 3 – RUL Prediction without Deep Learning Toolbox):
%   Train a regression-ensemble model (bagged trees) that predicts
%   Remaining Useful Life (RUL in days) from 30×12 feature sequences:
%
%     Input : flattened feature vector [1×360] (30 timesteps × 12 features)
%     Output: RUL_days (scalar)
%
% Uses:
%   data/sequences/rul_cnn_sequences.mat
%
% Saves:
%   data/models/rul_tree_model_03.mat
%   results/plots/rul_tree_performance_03.png
% ========================================================================
function train_rul_tree_03()

    fprintf('🚀 TRAINING MODEL 3: RUL PREDICTOR (TREE ENSEMBLE)\n');
    fprintf('==================================================\n\n');

    %% 1. Resolve paths
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);
    projectRoot = fileparts(fileparts(scriptDir));

    seqDir     = fullfile(projectRoot,'data','sequences');
    modelsDir  = fullfile(projectRoot,'data','models');
    resultsDir = fullfile(projectRoot,'results','plots');
    if ~exist(modelsDir,'dir');  mkdir(modelsDir);  end
    if ~exist(resultsDir,'dir'); mkdir(resultsDir); end

    %% 2. Load RUL sequences
    dataPath = fullfile(seqDir,'rul_cnn_sequences.mat');
    if ~exist(dataPath,'file')
        error('File not found: %s. Run create_rul_sequences_03() first.',dataPath);
    end

    S = load(dataPath,'XTrain','YTrain','XTest','YTest','historyLength','nFeatures','Xmin','Xmax');
    XTrain = S.XTrain;  YTrain = S.YTrain;
    XTest  = S.XTest;   YTest  = S.YTest;
    historyLength = S.historyLength;
    nFeatures     = S.nFeatures;

    fprintf('📊 Loaded RUL dataset:\n');
    fprintf('   Train: %d samples, Test: %d samples\n', numel(YTrain), numel(YTest));
    fprintf('   Each X: %d timesteps × %d features (flattened to %d)\n', ...
        historyLength, nFeatures, size(XTrain,2));

    %% 3. Train tree-based RUL regressor
    fprintf('\n🌳 TRAINING REGRESSION ENSEMBLE FOR RUL...\n');

    rng(42);
    rul_model = fitrensemble(XTrain, YTrain, ...
                             'Method','Bag', ...
                             'NumLearningCycles',200, ...
                             'Learners','tree');

    %% 4. Evaluate on test set
    YPred = predict(rul_model,XTest);
    errors = YPred - YTest;

    rmse = sqrt(mean(errors.^2));
    mae  = mean(abs(errors));
    r2   = 1 - sum(errors.^2) / sum((YTest - mean(YTest)).^2);

    acc5  = mean(abs(errors) <=  5) * 100;
    acc10 = mean(abs(errors) <= 10) * 100;
    acc15 = mean(abs(errors) <= 15) * 100;

    fprintf('\n📊 TEST PERFORMANCE (RUL Tree Model):\n');
    fprintf('   MAE : %.2f days\n', mae);
    fprintf('   RMSE: %.2f days\n', rmse);
    fprintf('   R²  : %.4f\n', r2);
    fprintf('   %% within ±5 days : %.1f%%\n', acc5);
    fprintf('   %% within ±10 days: %.1f%%\n', acc10);
    fprintf('   %% within ±15 days: %.1f%%\n', acc15);

    %% 5. Save model
    rul_tree_model_03 = struct();
    rul_tree_model_03.type        = 'bagged_trees';
    rul_tree_model_03.model       = rul_model;
    rul_tree_model_03.historyLen  = historyLength;
    rul_tree_model_03.nFeatures   = nFeatures;
    rul_tree_model_03.Xmin        = S.Xmin;
    rul_tree_model_03.Xmax        = S.Xmax;
    rul_tree_model_03.performance = struct( ...
            'mae_days', mae, ...
            'rmse_days', rmse, ...
            'r2_score', r2, ...
            'acc_5_days', acc5, ...
            'acc_10_days', acc10, ...
            'acc_15_days', acc15 );

    save(fullfile(modelsDir,'rul_tree_model_03.mat'),'rul_tree_model_03');
    fprintf('\n💾 Saved RUL tree model to: %s\n', ...
        fullfile(modelsDir,'rul_tree_model_03.mat'));

    %% 6. Simple performance plot
    fig = figure('Position',[100 100 900 400],'Visible','off');

    subplot(1,2,1);
    scatter(YTest,YPred,25,'filled'); hold on;
    plot([min(YTest) max(YTest)],[min(YTest) max(YTest)],'r--','LineWidth',2);
    xlabel('True RUL (days)'); ylabel('Predicted RUL (days)'); grid on;
    title(sprintf('RUL Prediction (MAE=%.2f, RMSE=%.2f)',mae,rmse));

    subplot(1,2,2);
    histogram(errors,30,'FaceColor',[0.2 0.6 0.8],'EdgeColor','k');
    xlabel('Prediction Error (days)'); ylabel('Count'); grid on;
    title('RUL Error Distribution');

    saveas(fig, fullfile(resultsDir,'rul_tree_performance_03.png'));
    close(fig);
    fprintf('   Plot saved: %s\n', ...
        fullfile(resultsDir,'rul_tree_performance_03.png'));

    fprintf('\n✅ MODEL 3 TRAINING COMPLETE (Tree-based RUL predictor).\n');
end