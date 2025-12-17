%% File: scripts/03_calibrate_simulink.m
function calibrate_simulink_model(csv_filename)
% CALIBRATE_SIMULINK_MODEL - Calibrate Simulink model using experimental data
%
% Input: csv_filename - Experimental data file to use for calibration
% Example: calibrate_simulink_model('data/experimental/0D.csv')

fprintf('=========================================\n');
fprintf('CALIBRATING SIMULINK MODEL WITH ML-ESTIMATED PARAMETERS\n');
fprintf('=========================================\n');

%% 1. Load experimental data for calibration
fprintf('\n1. Loading experimental data: %s\n', csv_filename);

data = readtable(csv_filename);
fprintf('   Samples: %d\n', height(data));
fprintf('   Duration: %.1f seconds\n', height(data)/4096);

% Extract data
voltage = data.V_in;
rpm = data.Measured_RPM;
vibration = [data.Vibration_1, data.Vibration_2, data.Vibration_3];

%% 2. Estimate parameters using ML model
fprintf('\n2. Estimating Simulink parameters using ML model...\n');

% Load the parameter estimator
addpath('ml_models/system_identification');

% Use middle 10 seconds of data for stable estimation
fs = 4096;
mid_start = floor(size(vibration,1)/2) - 5*fs;
mid_end = mid_start + 10*fs - 1;

if mid_start < 1, mid_start = 1; end
if mid_end > size(vibration,1), mid_end = size(vibration,1); end

vibration_mid = vibration(mid_start:mid_end, :);
rpm_mid = rpm(mid_start:mid_end);
voltage_mid = voltage(mid_start:mid_end);

% Estimate parameters
[spring_est, damper_est, inertia_est, confidence] = ...
    estimate_parameters(vibration_mid, rpm_mid, voltage_mid, fs);

fprintf('\nEstimated Parameters:\n');
fprintf('  Spring constant: %.1f N·m/rad (confidence: %.2f)\n', spring_est, confidence(1));
fprintf('  Damping coefficient: %.3f N·m·s/rad (confidence: %.2f)\n', damper_est, confidence(2));
fprintf('  Inertia: %.4f kg·m² (confidence: %.2f)\n', inertia_est, confidence(3));

%% 3. Update Simulink model with estimated parameters
fprintf('\n3. Updating Simulink model parameters...\n');

% Load your Simulink model
model_name = 'simulink_models/shaft_twin_base.slx';
fprintf('   Loading model: %s\n', model_name);

% Open the model (make sure Simulink is installed)
if bdIsLoaded('shaft_twin_base')
    close_system('shaft_twin_base', 0);
end

open_system(model_name);

% Set parameters in the model workspace
model_workspace = get_param('shaft_twin_base', 'ModelWorkspace');

% These parameter names should match your Simulink block parameters
% Adjust based on your actual Simulink model structure
model_workspace.assignin('SpringConstant', spring_est);
model_workspace.assignin('DampingCoefficient', damper_est);
model_workspace.assignin('Inertia', inertia_est);

% Also set operating conditions from experimental data
mean_rpm = mean(rpm);
mean_voltage = mean(voltage);
model_workspace.assignin('OperatingRPM', mean_rpm);
model_workspace.assignin('InputVoltage', mean_voltage);

fprintf('   Updated parameters in model workspace\n');
fprintf('   Operating RPM: %.0f\n', mean_rpm);
fprintf('   Input Voltage: %.2f V\n', mean_voltage);

%% 4. Save calibrated model
fprintf('\n4. Saving calibrated model...\n');

calibrated_model = 'simulink_models/shaft_twin_calibrated.slx';
save_system('shaft_twin_base', calibrated_model);

fprintf('   Calibrated model saved: %s\n', calibrated_model);

%% 5. Run simulation with calibrated parameters
fprintf('\n5. Running simulation with calibrated parameters...\n');

% Set simulation time based on data duration
sim_time = height(data) / fs;

% Configure simulation
set_param('shaft_twin_calibrated', 'StopTime', num2str(sim_time));

% Run simulation
sim_output = sim('shaft_twin_calibrated');

fprintf('   Simulation completed (%.1f seconds)\n', sim_time);

%% 6. Compare simulation output with experimental data
fprintf('\n6. Comparing simulation vs experimental data...\n');

% Extract simulation outputs
if isfield(sim_output, 'out_vibration_signal')
    sim_vibration = sim_output.out_vibration_signal.Data;
    sim_time_vec = sim_output.out_vibration_signal.Time;
    
    % Compare RMS values
    exp_rms = rms(vibration(:,1));  % Use first vibration sensor
    sim_rms = rms(sim_vibration);
    
    fprintf('   Experimental RMS: %.4f\n', exp_rms);
    fprintf('   Simulated RMS: %.4f\n', sim_rms);
    fprintf('   Difference: %.2f%%\n', abs(exp_rms - sim_rms)/exp_rms*100);
end

%% 7. Save calibration results
calibration_results.spring = spring_est;
calibration_results.damper = damper_est;
calibration_results.inertia = inertia_est;
calibration_results.confidence = confidence;
calibration_results.operating_rpm = mean_rpm;
calibration_results.input_voltage = mean_voltage;
calibration_results.calibration_file = csv_filename;

save('data/processed/calibration_results.mat', 'calibration_results');

fprintf('\nCalibration complete!\n');
fprintf('Results saved to: data/processed/calibration_results.mat\n');

end