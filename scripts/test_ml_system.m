% TEST_ML_SYSTEM - Test the ML model manager

fprintf('=== TESTING ML MODEL MANAGER ===\n\n');

% SCENARIO 1: First time - Train and save models
fprintf('1. 🚀 FIRST RUN: Training new models...\n');
[params1, models1] = ml_model_manager.calibrate('data', false);
fprintf('   Parameters: Spring=%.0f, Damper=%.2f, Inertia=%.3f\n\n', ...
    params1.spring_stiffness, params1.damping_coefficient, params1.inertia);

% SCENARIO 2: Second time - Use saved models (should be fast)
fprintf('2. 🔄 SECOND RUN: Using saved models...\n');
[params2, models2] = ml_model_manager.calibrate('data', true);
fprintf('   Parameters: Spring=%.0f, Damper=%.2f, Inertia=%.3f\n\n', ...
    params2.spring_stiffness, params2.damping_coefficient, params2.inertia);

% SCENARIO 3: Just load models directly
fprintf('3. 📂 DIRECT LOAD: Loading models directly...\n');
models3 = ml_model_manager.load_models();
if ~isempty(models3)
    fprintf('   ✅ Successfully loaded %d models\n', length(fieldnames(models3)));
else
    fprintf('   ❌ No models found\n');
end

% SCENARIO 4: Update Simulink with calibrated parameters
fprintf('4. 🎯 UPDATING SIMULINK...\n');
try
    set_param('shaft_twin_base/Spring', 'spring_constant', num2str(params1.spring_stiffness));
    set_param('shaft_twin_base/Damper', 'damping_coefficient', num2str(params1.damping_coefficient));
    set_param('shaft_twin_base/Inertia', 'inertia', num2str(params1.inertia));
    fprintf('   ✅ Simulink parameters updated successfully!\n');
catch
    fprintf('   ⚠️  Could not update Simulink automatically\n');
    fprintf('   Manual parameters:\n');
    fprintf('      Spring: %.0f N·m/rad\n', params1.spring_stiffness);
    fprintf('      Damper: %.2f N·m·s/rad\n', params1.damping_coefficient);
    fprintf('      Inertia: %.3f kg·m²\n', params1.inertia);
end

fprintf('\n🎉 ML SYSTEM READY FOR PRODUCTION!\n');