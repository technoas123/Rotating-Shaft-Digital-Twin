%% File: ml_pipelines/01_system_identification/03_train_system_id_model_03.m
% ========================================================================
% Purpose:
%   MODEL 1 – System Identification
%   Train 3 regression-tree models that map 36 vibration features → 
%   [spring, damper, inertia].
%
%   - Loads feature matrix and targets from:
%         data/processed/shaft_features.mat
%         data/processed/feature_names.mat
%   - Splits data into Train / Validation / Test
%   - Trains 3 fitrtree models (with 5-fold cross-validation):
%         spring_model   : estimate shaft stiffness (N/m)
%         damper_model   : estimate damping coefficient (N·s/m)
%         inertia_model  : estimate inertia (kg·m²)
%   - Evaluates performance on test set
%   - Saves all models and metadata to:
%         data/models/system_id_model.mat
%
% Note:
%   This version does NOT generate plots to avoid graphics timeouts.
% ========================================================================
function train_system_id_model_03()

    fprintf('🚀 TRAINING MODEL 1: SYSTEM IDENTIFICATION\n');
    fprintf('============================================\n\n');

    % ----- 1. Resolve project paths from this file location ----------------
    thisFile    = mfilename('fullpath');          % full path of this .m
    scriptDir   = fileparts(thisFile);           % ...\01_system_identification
    projectRoot = fileparts(fileparts(scriptDir)); % go up two levels

    procDir    = fullfile(projectRoot,'data','processed');
    modelsDir  = fullfile(projectRoot,'data','models');

    if ~exist(modelsDir,'dir'); mkdir(modelsDir); end

    % ----- 2. Load features and targets -----------------------------------
    featuresPath = fullfile(procDir,'shaft_features.mat');
    namesPath    = fullfile(procDir,'feature_names.mat');

    if ~exist(featuresPath,'file')
        error('Cannot find %s. Run extract_shaft_features_corrected() first.',featuresPath);
    end

    load(featuresPath,'all_features','parameter_targets');
    load(namesPath,   'feature_names');

    fprintf('📊 Dataset loaded:\n');
    fprintf('   Features: %d samples × %d features\n', ...
            size(all_features,1), size(all_features,2));
    fprintf('   Targets:  %d samples × %d parameters\n', ...
            size(parameter_targets,1), size(parameter_targets,2));

    % ----- 3. Train/val/test split ---------------------------------------
    n_samples = size(all_features,1);
    rng(42);                       % reproducibility
    idx    = randperm(n_samples);
    nTrain = floor(0.7*n_samples);
    nVal   = floor(0.15*n_samples);

    train_idx = idx(1:nTrain);
    val_idx   = idx(nTrain+1:nTrain+nVal);
    test_idx  = idx(nTrain+nVal+1:end);

    X_train = all_features(train_idx,:);
    X_val   = all_features(val_idx,:);
    X_test  = all_features(test_idx,:);

    y_train = parameter_targets(train_idx,:);   % [spring, damper, inertia]
    y_val   = parameter_targets(val_idx,:);
    y_test  = parameter_targets(test_idx,:);

    fprintf('\n📈 DATA SPLIT:\n');
    fprintf('   Training:   %d samples\n', numel(train_idx));
    fprintf('   Validation: %d samples\n', numel(val_idx));
    fprintf('   Test:       %d samples\n', numel(test_idx));

    % ----- 4. Train SPRING model -----------------------------------------
    fprintf('\n🌳 TRAINING SPRING CONSTANT MODEL...\n');
    spring_tree = fitrtree(X_train, y_train(:,1), ...
                           'MinLeafSize',5, ...
                           'CrossVal','on','KFold',5);
    [~,best_id]  = min(kfoldLoss(spring_tree,'Mode','individual'));
    spring_model = spring_tree.Trained{best_id};

    y_pred_val = predict(spring_model,X_val);
    spring_rmse = sqrt(mean((y_pred_val - y_val(:,1)).^2));
    spring_r2   = 1 - sum((y_pred_val - y_val(:,1)).^2) / ...
                       sum((y_val(:,1) - mean(y_val(:,1))).^2);

    fprintf('   RMSE (val): %.2f N/m\n',spring_rmse);
    fprintf('   R²   (val): %.4f\n',spring_r2);

    % ----- 5. Train DAMPER model -----------------------------------------
    fprintf('\n🌳 TRAINING DAMPING COEFFICIENT MODEL...\n');
    damper_tree = fitrtree(X_train, y_train(:,2), ...
                           'MinLeafSize',5, ...
                           'CrossVal','on','KFold',5);
    [~,best_id]  = min(kfoldLoss(damper_tree,'Mode','individual'));
    damper_model = damper_tree.Trained{best_id};

    y_pred_val = predict(damper_model,X_val);
    damper_rmse = sqrt(mean((y_pred_val - y_val(:,2)).^2));
    damper_r2   = 1 - sum((y_pred_val - y_val(:,2)).^2) / ...
                        sum((y_val(:,2) - mean(y_val(:,2))).^2);

    fprintf('   RMSE (val): %.4f N·s/m\n',damper_rmse);
    fprintf('   R²   (val): %.4f\n',damper_r2);

    % ----- 6. Train INERTIA model ----------------------------------------
    fprintf('\n🌳 TRAINING INERTIA MODEL...\n');
    inertia_tree = fitrtree(X_train, y_train(:,3), ...
                            'MinLeafSize',5, ...
                            'CrossVal','on','KFold',5);
    [~,best_id]    = min(kfoldLoss(inertia_tree,'Mode','individual'));
    inertia_model  = inertia_tree.Trained{best_id};

    y_pred_val = predict(inertia_model,X_val);
    inertia_rmse = sqrt(mean((y_pred_val - y_val(:,3)).^2));
    inertia_r2   = 1 - sum((y_pred_val - y_val(:,3)).^2) / ...
                          sum((y_val(:,3) - mean(y_val(:,3))).^2);

    fprintf('   RMSE (val): %.6f kg·m²\n',inertia_rmse);
    fprintf('   R²   (val): %.4f\n',inertia_r2);

    % ----- 7. Final test on unseen data ----------------------------------
    fprintf('\n🧪 FINAL TEST ON UNSEEN DATA...\n');

    spring_pred_test  = predict(spring_model, X_test);
    damper_pred_test  = predict(damper_model, X_test);
    inertia_pred_test = predict(inertia_model,X_test);

    spring_rmse_test  = sqrt(mean((spring_pred_test  - y_test(:,1)).^2));
    damper_rmse_test  = sqrt(mean((damper_pred_test  - y_test(:,2)).^2));
    inertia_rmse_test = sqrt(mean((inertia_pred_test - y_test(:,3)).^2));

    fprintf('   Spring  RMSE (test):  %.2f N/m\n', spring_rmse_test);
    fprintf('   Damper  RMSE (test):  %.4f N·s/m\n', damper_rmse_test);
    fprintf('   Inertia RMSE (test):  %.6f kg·m²\n', inertia_rmse_test);

    % ----- 8. Save models ------------------------------------------------
    fprintf('\n💾 SAVING MODELS...\n');

    system_id_model = struct();
    system_id_model.spring_model  = spring_model;
    system_id_model.damper_model  = damper_model;
    system_id_model.inertia_model = inertia_model;
    system_id_model.feature_names = feature_names;
    system_id_model.training_date = datetime('now');
    system_id_model.performance   = struct( ...
        'spring_rmse',  spring_rmse_test, ...
        'damper_rmse',  damper_rmse_test, ...
        'inertia_rmse', inertia_rmse_test );

    save(fullfile(modelsDir,'system_id_model.mat'),'system_id_model');
    fprintf('   Saved to: %s\n', fullfile(modelsDir,'system_id_model.mat'));

    % ----- 9. Feature importance (text only) ------------------------------
    fprintf('\n📊 FEATURE IMPORTANCE ANALYSIS (Spring model):\n');
    spring_importance = predictorImportance(spring_model);
    [~, idxImp]       = sort(spring_importance,'descend');

    for k = 1:min(5,numel(idxImp))
        fprintf('      %-25s: %.4f\n', ...
            feature_names{idxImp(k)}, spring_importance(idxImp(k)));
    end

    fprintf('\n✅ MODEL 1 TRAINING COMPLETE (no plots generated).\n');
end