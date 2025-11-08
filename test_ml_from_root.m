% TEST_ML_FROM_ROOT.M - Run from root folder
fprintf('=== TESTING ML MANAGER FROM ROOT FOLDER ===\n\n');

% Add scripts folder to path
addpath('scripts');

% TEST 1: Default usage (data in root/data, uses saved models)
fprintf('1. 🎯 DEFAULT CALIBRATION:\n');
[params1, models1] = ml_model_manager.calibrate();
fprintf('   Spring: %.0f, Damper: %.2f, Inertia: %.3f\n\n', ...
    params1.spring_stiffness, params1.damping_coefficient, params1.inertia);

% TEST 2: Force retrain
fprintf('2. 🔄 FORCE RETRAIN:\n');
[params2, models2] = ml_model_manager.calibrate('data', false);
fprintf('   Spring: %.0f, Damper: %.2f, Inertia: %.3f\n\n', ...
    params2.spring_stiffness, params2.damping_coefficient, params2.inertia);

% TEST 3: Just load models
fprintf('3. 📂 LOAD MODELS ONLY:\n');
models3 = ml_model_manager.load_models();
if ~isempty(models3)
    fprintf('   ✅ Loaded %d models\n\n', length(fieldnames(models3)));
end

fprintf('🎉 ML SYSTEM WORKING FROM SCRIPTS FOLDER!\n');

% Remove path if needed
% rmpath('scripts');