%% File: ml_pipelines/02_degradation_engine/train_degradation_lstm_08.m
% ========================================================================
% Purpose (MODEL 2 – Degradation Engine, NO Deep Learning Toolbox):
%   Train a regression ensemble (bagged trees) to predict degradation:
%
%     Input  : last 30 windows of 36 features
%              (each X{i} is [36 × 30])
%     Output : Δspring, Δdamper, Δhealth   (3 values)
%
% Instead of an LSTM, we:
%   - Flatten each [36×30] sequence to a row vector [1×(36*30)]
%   - Train 3 separate regression ensembles (one per output)
%
% Uses:
%   data/sequences/degradation_sequences_m2.mat
%
% Saves:
%   data/models/degradation_model_m2.mat
%   results/plots/degradation_model_m2_perf.png
% ========================================================================
function train_degradation_lstm_08()

    fprintf('🚀 TRAINING MODEL 2: DEGRADATION MODEL (TREE-BASED)\n');
    fprintf('===================================================\n\n');

    %% 1. Resolve paths
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);                 % ...\02_degradation_engine
    projectRoot = fileparts(fileparts(scriptDir));

    seqDir     = fullfile(projectRoot,'data','sequences');
    modelsDir  = fullfile(projectRoot,'data','models');
    resultsDir = fullfile(projectRoot,'results','plots');
    if ~exist(modelsDir,'dir');  mkdir(modelsDir);  end
    if ~exist(resultsDir,'dir'); mkdir(resultsDir); end

    %% 2. Load degradation sequences
    dataPath = fullfile(seqDir,'degradation_sequences_m2.mat');
    if ~exist(dataPath,'file')
        error('File not found: %s. Run create_degradation_sequences_07() first.',dataPath);
    end

    S = load(dataPath,'XTrain','YTrain','XVal','YVal','XTest','YTest','historyLength');
    XTrain = S.XTrain;  YTrain = S.YTrain;
    XVal   = S.XVal;    YVal   = S.YVal;
    XTest  = S.XTest;   YTest  = S.YTest;
    historyLength = S.historyLength;

    nFeatures = 36;
    fprintf('📊 Loaded degradation dataset:\n');
    fprintf('   Train: %d, Val: %d, Test: %d samples\n', ...
        numel(XTrain), numel(XVal), numel(XTest));
    fprintf('   Each X{i}: %d×%d (features × timesteps)\n', ...
        nFeatures, historyLength);

    %% 3. Flatten sequences to feature vectors
    % Each [36×30] → [1×(36*30)] = [1×1080]
    flatten = @(Xcell) cell2mat(cellfun(@(x) x(:).', Xcell, ...
                                        'UniformOutput', false));

    XTrainMat = flatten(XTrain);
    XValMat   = flatten(XVal);
    XTestMat  = flatten(XTest);

    % Combine Train+Val for final model, keep Val for quick diagnostics
    XAll = [XTrainMat; XValMat];
    YAll = [YTrain;    YVal];

    fprintf('\n📐 Flattened feature sizes:\n');
    fprintf('   XTrainMat: %s\n', mat2str(size(XTrainMat)));
    fprintf('   XValMat:   %s\n', mat2str(size(XValMat)));
    fprintf('   XTestMat:  %s\n', mat2str(size(XTestMat)));

    %% 4. Train three regression ensembles (one for each Δ)
    fprintf('\n🌳 TRAINING ENSEMBLE FOR ΔSPRING...\n');
    mdl_dK = fitrensemble(XAll, YAll(:,1), ...
                          'Method','Bag', ...
                          'NumLearningCycles',100, ...
                          'Learners','tree');

    fprintf('🌳 TRAINING ENSEMBLE FOR ΔDAMPER...\n');
    mdl_dC = fitrensemble(XAll, YAll(:,2), ...
                          'Method','Bag', ...
                          'NumLearningCycles',100, ...
                          'Learners','tree');

    fprintf('🌳 TRAINING ENSEMBLE FOR ΔHEALTH...\n');
    mdl_dH = fitrensemble(XAll, YAll(:,3), ...
                          'Method','Bag', ...
                          'NumLearningCycles',100, ...
                          'Learners','tree');

    %% 5. Evaluate on test set
    YPred_dK = predict(mdl_dK, XTestMat);
    YPred_dC = predict(mdl_dC, XTestMat);
    YPred_dH = predict(mdl_dH, XTestMat);

    err_dK = YPred_dK - YTest(:,1);
    err_dC = YPred_dC - YTest(:,2);
    err_dH = YPred_dH - YTest(:,3);

    rmse_dK = sqrt(mean(err_dK.^2));
    rmse_dC = sqrt(mean(err_dC.^2));
    rmse_dH = sqrt(mean(err_dH.^2));

    mae_dK  = mean(abs(err_dK));
    mae_dC  = mean(abs(err_dC));
    mae_dH  = mean(abs(err_dH));

    fprintf('\n📊 TEST PERFORMANCE (TREE-BASED MODEL 2):\n');
    fprintf('   ΔSpring RMSE: %.2f N/m,   MAE: %.2f\n', rmse_dK, mae_dK);
    fprintf('   ΔDamper RMSE: %.4f N·s/m, MAE: %.4f\n', rmse_dC, mae_dC);
    fprintf('   ΔHealth RMSE: %.2f %% ,   MAE: %.2f\n', rmse_dH, mae_dH);

    %% 6. Save the degradation model
    degradation_model_m2 = struct();
    degradation_model_m2.type        = 'tree_ensemble';
    degradation_model_m2.mdl_dK      = mdl_dK;
    degradation_model_m2.mdl_dC      = mdl_dC;
    degradation_model_m2.mdl_dH      = mdl_dH;
    degradation_model_m2.historyLen  = historyLength;
    degradation_model_m2.nFeatures   = nFeatures;
    degradation_model_m2.performance = struct( ...
        'rmse',[rmse_dK,rmse_dC,rmse_dH], ...
        'mae', [mae_dK, mae_dC, mae_dH]);

    save(fullfile(modelsDir,'degradation_model_m2.mat'), 'degradation_model_m2');
    fprintf('\n💾 Saved degradation model to: %s\n', ...
        fullfile(modelsDir,'degradation_model_m2.mat'));

    %% 7. Simple performance plots (optional)
    fig = figure('Position',[100 100 900 300],'Visible','off');

    subplot(1,3,1);
    scatter(YTest(:,1),YPred_dK,20,'filled'); grid on;
    xlabel('True ΔK'); ylabel('Pred ΔK'); title('ΔSpring');

    subplot(1,3,2);
    scatter(YTest(:,2),YPred_dC,20,'filled'); grid on;
    xlabel('True ΔC'); ylabel('Pred ΔC'); title('ΔDamper');

    subplot(1,3,3);
    scatter(YTest(:,3),YPred_dH,20,'filled'); grid on;
    xlabel('True ΔHealth'); ylabel('Pred ΔHealth'); title('ΔHealth (%)');

    saveas(fig,fullfile(resultsDir,'degradation_model_m2_perf.png'));
    close(fig);
    fprintf('   Plot saved: %s\n', ...
        fullfile(resultsDir,'degradation_model_m2_perf.png'));

    fprintf('\n✅ MODEL 2 TRAINING COMPLETE (TREE-BASED, NO LSTM).\n');
end