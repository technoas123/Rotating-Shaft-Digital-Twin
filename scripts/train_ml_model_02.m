%% File: scripts/02_train_ml_model.m
function train_ml_model_for_simulink()
% TRAIN_ML_MODEL_FOR_SIMULINK - Train models to estimate Simulink parameters

fprintf('=========================================\n');
fprintf('TRAINING ML MODEL FOR SIMULINK PARAMETER ESTIMATION\n');
fprintf('=========================================\n');

%% Load training data
load('data/processed/training_data.mat');

%% Define realistic parameter ranges (for your shaft system)
% These should match your Simulink model parameters
param_ranges.spring = [300, 700];      % N·m/rad
param_ranges.damper = [0.2, 1.0];      % N·m·s/rad
param_ranges.inertia = [0.08, 0.2];    % kg·m²

fprintf('\nParameter ranges for Simulink calibration:\n');
fprintf('  Spring constant: %.0f to %.0f N·m/rad\n', ...
    param_ranges.spring(1), param_ranges.spring(2));
fprintf('  Damping coefficient: %.1f to %.1f N·m·s/rad\n', ...
    param_ranges.damper(1), param_ranges.damper(2));
fprintf('  Inertia: %.3f to %.3f kg·m²\n', ...
    param_ranges.inertia(1), param_ranges.inertia(2));

%% Train models with cross-validation
fprintf('\nTraining models with 5-fold cross-validation...\n');

% 1. Spring constant model
fprintf('\n1. Training spring constant model...\n');
spring_model = fitrtree(X_train, y_spring_train, ...
    'MinLeafSize', 20, ...           % Larger to prevent overfitting
    'CrossVal', 'on', ...
    'KFold', 5);

% Get cross-validation performance
spring_cv_loss = kfoldLoss(spring_model);
fprintf('   CV RMSE: %.2f N·m/rad (%.1f%% of range)\n', ...
    sqrt(spring_cv_loss), sqrt(spring_cv_loss)/diff(param_ranges.spring)*100);

% 2. Damping coefficient model
fprintf('\n2. Training damping coefficient model...\n');
damper_model = fitrtree(X_train, y_damper_train, ...
    'MinLeafSize', 20, ...
    'CrossVal', 'on', ...
    'KFold', 5);

damper_cv_loss = kfoldLoss(damper_model);
fprintf('   CV RMSE: %.3f N·m·s/rad (%.1f%% of range)\n', ...
    sqrt(damper_cv_loss), sqrt(damper_cv_loss)/diff(param_ranges.damper)*100);

% 3. Inertia model
fprintf('\n3. Training inertia model...\n');
inertia_model = fitrtree(X_train, y_inertia_train, ...
    'MinLeafSize', 20, ...
    'CrossVal', 'on', ...
    'KFold', 5);

inertia_cv_loss = kfoldLoss(inertia_model);
fprintf('   CV RMSE: %.4f kg·m² (%.1f%% of range)\n', ...
    sqrt(inertia_cv_loss), sqrt(inertia_cv_loss)/diff(param_ranges.inertia)*100);

%% Test on evaluation datasets
fprintf('\n\nTesting on evaluation datasets...\n');

% Predict on test set
y_spring_pred = predict(spring_model.Trained{1}, X_test);
y_damper_pred = predict(damper_model.Trained{1}, X_test);
y_inertia_pred = predict(inertia_model.Trained{1}, X_test);

% Calculate test errors
spring_rmse = sqrt(mean((y_spring_pred - y_spring_test).^2));
damper_rmse = sqrt(mean((y_damper_pred - y_damper_test).^2));
inertia_rmse = sqrt(mean((y_inertia_pred - y_inertia_test).^2));

fprintf('\nTest Performance:\n');
fprintf('  Spring RMSE: %.2f N·m/rad\n', spring_rmse);
fprintf('  Damper RMSE: %.3f N·m·s/rad\n', damper_rmse);
fprintf('  Inertia RMSE: %.4f kg·m²\n', inertia_rmse);

%% Save trained models
save('ml_models/trained_models/system_id_models.mat', ...
    'spring_model', 'damper_model', 'inertia_model', ...
    'param_ranges', 'spring_rmse', 'damper_rmse', 'inertia_rmse');

fprintf('\nModels saved to: ml_models/trained_models/system_id_models.mat\n');

%% Create parameter estimation function
create_parameter_estimator();

end

%% Helper function: Create parameter estimator
function create_parameter_estimator()
% CREATE_PARAMETER_ESTIMATOR - Create function to estimate params from new data

estimator_code = {
    'function [spring, damper, inertia, confidence] = estimate_parameters(vibration_data, rpm, voltage, fs)';
    '% ESTIMATE_PARAMETERS - Estimate Simulink parameters from vibration data';
    '%';
    '% Inputs:';
    '%   vibration_data - [N×3] matrix of vibration signals (3 sensors)';
    '%   rpm - [N×1] vector of RPM values';
    '%   voltage - [N×1] vector of voltage values';
    '%   fs - Sampling frequency (Hz)';
    '%';
    '% Outputs:';
    '%   spring - Estimated spring constant (N·m/rad)';
    '%   damper - Estimated damping coefficient (N·m·s/rad)';
    '%   inertia - Estimated inertia (kg·m²)';
    '%   confidence - Confidence scores [0-1] for each parameter';
    '';
    '% Load trained models';
    'persistent models loaded';
    'if isempty(loaded)';
    '    load(''ml_models/trained_models/system_id_models.mat'', ...';
    '        ''spring_model'', ''damper_model'', ''inertia_model'');';
    '    models.spring = spring_model.Trained{1};';
    '    models.damper = damper_model.Trained{1};';
    '    models.inertia = inertia_model.Trained{1};';
    '    loaded = true;';
    'end';
    '';
    '% Extract features from the vibration data';
    'features = extract_features_from_window(vibration_data, rpm, voltage, fs);';
    '';
    '% Predict parameters';
    'spring = predict(models.spring, features);';
    'damper = predict(models.damper, features);';
    'inertia = predict(models.inertia, features);';
    '';
    '% Calculate confidence (simplified - could use prediction intervals)';
    'confidence = [0.85, 0.80, 0.75]; % Placeholder';
    '';
    'end';
    '';
    'function features = extract_features_from_window(vibration_data, rpm, voltage, fs)';
    '% Extract the same 36 features used during training';
    '    % Your feature extraction code here';
    '    features = []; % Placeholder';
    'end';
};

% Save to file
fid = fopen('ml_models/system_identification/estimate_parameters.m', 'w');
for i = 1:length(estimator_code)
    fprintf(fid, '%s\n', estimator_code{i});
end
fclose(fid);

fprintf('Parameter estimator created: ml_models/system_identification/estimate_parameters.m\n');
end