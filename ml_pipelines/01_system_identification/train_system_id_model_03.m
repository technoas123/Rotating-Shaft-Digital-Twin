%% File: ml_pipelines/01_system_identification/03_train_system_id_model.m
function train_system_id_model()
    % ==========================================================
    % MODEL 1: System Identification (Corrected)
    % Input:  14 features (12 vib + 2 rpm) per 1-sec window
    % Output: [spring, damper, inertia]
    % Splits: Random 70/15/15 across the thousands of windows
    % ==========================================================
    
    fprintf('🚀 TRAINING MODEL 1: SYSTEM IDENTIFICATION\n');
    fprintf('============================================\n\n');
    
    % --- Paths ---
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);
    projectRoot = fileparts(fileparts(scriptDir));
    procDir     = fullfile(projectRoot,'data','processed');
    modelsDir   = fullfile(projectRoot,'data','models');
    if ~exist(modelsDir,'dir'); mkdir(modelsDir); end
    
    % --- Load Data ---
    load(fullfile(procDir, 'shaft_features.mat'), 'all_features', 'parameter_targets');
    load(fullfile(procDir, 'feature_names.mat'), 'feature_names');
    
    fprintf('📊 Dataset: %d samples × %d features\n', size(all_features));
    
    % --- Split Data (Random shuffle of windows) ---
    n = size(all_features,1);
    rng(42);
    idx = randperm(n);
    
    nTrain = floor(0.7*n);
    nVal   = floor(0.15*n);
    
    X_train = all_features(idx(1:nTrain), :);
    y_train = parameter_targets(idx(1:nTrain), :);
    
    X_val   = all_features(idx(nTrain+1:nTrain+nVal), :);
    y_val   = parameter_targets(idx(nTrain+1:nTrain+nVal), :);
    
    X_test  = all_features(idx(nTrain+nVal+1:end), :);
    y_test  = parameter_targets(idx(nTrain+nVal+1:end), :);
    
    fprintf('📈 Split: Train=%d, Val=%d, Test=%d\n', nTrain, nVal, size(X_test,1));
    
    % --- Train Models ---
    % MinLeafSize = 5 prevents overfitting (memorizing single windows)
    
    fprintf('\n🌳 Training Spring Model...\n');
    mdl_spring = fitrtree(X_train, y_train(:,1), 'MinLeafSize', 5);
    
    fprintf('🌳 Training Damper Model...\n');
    mdl_damper = fitrtree(X_train, y_train(:,2), 'MinLeafSize', 5);
    
    fprintf('🌳 Training Inertia Model...\n');
    mdl_inertia = fitrtree(X_train, y_train(:,3), 'MinLeafSize', 5);
    
    % --- Evaluate ---
    fprintf('\n🧪 TEST RESULTS:\n');
    
    % Spring
    y_pred = predict(mdl_spring, X_test);
    rmse = sqrt(mean((y_pred - y_test(:,1)).^2));
    r2 = 1 - sum((y_pred - y_test(:,1)).^2) / sum((y_test(:,1) - mean(y_test(:,1))).^2);
    fprintf('   Spring: RMSE = %.2f N/m, R² = %.4f\n', rmse, r2);
    
    % Damper
    y_pred = predict(mdl_damper, X_test);
    rmse = sqrt(mean((y_pred - y_test(:,2)).^2));
    r2 = 1 - sum((y_pred - y_test(:,2)).^2) / sum((y_test(:,2) - mean(y_test(:,2))).^2);
    fprintf('   Damper: RMSE = %.4f N·s/m, R² = %.4f\n', rmse, r2);
    
    % Inertia (Should be constant/zero error if J is constant)
    y_pred = predict(mdl_inertia, X_test);
    rmse = sqrt(mean((y_pred - y_test(:,3)).^2));
    fprintf('   Inertia: RMSE = %.6f kg·m² (Constant parameter)\n', rmse);
    
    % --- Save ---
    system_id_model = struct();
    system_id_model.spring_model = mdl_spring;
    system_id_model.damper_model = mdl_damper;
    system_id_model.inertia_model = mdl_inertia;
    system_id_model.feature_names = feature_names;
    
    save(fullfile(modelsDir, 'system_id_model.mat'), 'system_id_model');
    fprintf('\n💾 Saved model to data/models/system_id_model.mat\n');
end