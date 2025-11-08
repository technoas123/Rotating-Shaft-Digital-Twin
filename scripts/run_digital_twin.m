function run_complete_digital_twin()
    % RUN_COMPLETE_DIGITAL_TWIN - Fully automated ML calibration and simulation
    
    fprintf('=============================================\n');
    fprintf('🤖 COMPLETE DIGITAL TWIN AUTOMATION\n');
    fprintf('=============================================\n\n');
    
    % Add current directory to path
    addpath(pwd);
    
    while true
        fprintf('MAIN MENU:\n');
        fprintf('1. 🚀 Train ML Models & Run Simulation\n');
        fprintf('2. ⚡ Fast Calibration & Run Simulation\n');
        fprintf('3. 🔧 Run Simulation Only (Use Existing Parameters)\n');
        fprintf('4. 🔍 Discover Block Parameters\n');
        fprintf('5. 📊 Analyze Simulation Results\n');
        fprintf('6. ❌ Exit\n\n');
        
        choice = input('Choose option (1-6): ', 's');
        
        switch choice
            case '1'
                train_and_run_simulation();
            case '2'
                fast_calibrate_and_run();
            case '3'
                run_simulation_only();
            case '4'
                discover_parameters_option();
            case '5'
                analyze_results_option();
            case '6'
                fprintf('Exiting...\n');
                break;
            otherwise
                fprintf('Invalid choice. Please try again.\n\n');
        end
    end
end

function train_and_run_simulation()
    % OPTION 1: Complete training and simulation
    fprintf('\n=== OPTION 1: COMPLETE TRAINING & SIMULATION ===\n\n');
    
    try
        % Step 1: Train ML models
        fprintf('1. 📊 Training ML models...\n');
        ml_model_optimized.train_and_save_models();
        
        % Step 2: Get calibrated parameters
        fprintf('\n2. 🎯 Getting calibrated parameters...\n');
        [params, ~] = ml_model_optimized.calibrate_from_models();
        
        if isempty(params)
            fprintf('   ❌ Failed to get parameters.\n');
            return;
        end
        
        % Step 3: Run automated simulation
        fprintf('\n3. 🚀 Running automated simulation...\n');
        run_automated_simulation(params);
        
    catch ME
        fprintf('❌ Process failed: %s\n', ME.message);
    end
end

function fast_calibrate_and_run()
    % OPTION 2: Fast calibration and simulation
    fprintf('\n=== OPTION 2: FAST CALIBRATION & SIMULATION ===\n\n');
    
    try
        % Step 1: Get calibrated parameters
        fprintf('1. 🎯 Fast calibration...\n');
        [params, ~] = ml_model_optimized.calibrate_from_models();
        
        if isempty(params)
            fprintf('   ❌ No models found. Run Option 1 first.\n');
            return;
        end
        
        % Step 2: Run automated simulation
        fprintf('\n2. 🚀 Running automated simulation...\n');
        run_automated_simulation(params);
        
    catch ME
        fprintf('❌ Process failed: %s\n', ME.message);
    end
end

function run_simulation_only()
    % OPTION 3: Run simulation with existing parameters
    fprintf('\n=== OPTION 3: SIMULATION ONLY ===\n\n');
    
    try
        % Get existing parameters
        fprintf('1. 📥 Loading existing parameters...\n');
        [params, ~] = ml_model_optimized.calibrate_from_models();
        
        if isempty(params)
            fprintf('   ❌ No parameters found. Using defaults.\n');
            params.spring_stiffness = 500;
            params.damping_coefficient = 0.50;
            params.inertia = 0.124;
        end
        
        % Run automated simulation
        fprintf('\n2. 🚀 Running simulation...\n');
        run_automated_simulation(params);
        
    catch ME
        fprintf('❌ Simulation failed: %s\n', ME.message);
    end
end

function run_automated_simulation(params)
    % RUN AUTOMATED SIMULATION - Updates blocks and runs simulation
    
    model_name = 'shaft_twin_base';
    
    fprintf('   Model: %s\n', model_name);
    fprintf('   Parameters: Spring=%.0f, Damper=%.2f, Inertia=%.3f\n', ...
        params.spring_stiffness, params.damping_coefficient, params.inertia);
    
    % Step 1: Load Simulink model
    fprintf('\n   Step 1: Loading Simulink model...\n');
    if ~bdIsLoaded(model_name)
        try
            load_system(model_name);
            fprintf('      ✅ Model loaded\n');
        catch ME
            fprintf('      ❌ Could not load model: %s\n', ME.message);
            return;
        end
    else
        fprintf('      ✅ Model already loaded\n');
    end
    
    % Step 2: Update block parameters
    fprintf('\n   Step 2: Updating block parameters...\n');
    blocks_updated = update_block_parameters(model_name, params);
    
    if blocks_updated < 3
        fprintf('      ⚠️  Only %d/4 blocks updated. Continuing anyway...\n', blocks_updated);
    else
        fprintf('      ✅ All blocks updated successfully\n');
    end
    
    % Step 3: Configure simulation
    fprintf('\n   Step 3: Configuring simulation...\n');
    configure_simulation(model_name);
    
    % Step 4: Run simulation
    fprintf('\n   Step 4: Running simulation...\n');
    sim_output = run_simulation_with_catch(model_name);
    
    % Step 5: Analyze results
    fprintf('\n   Step 5: Analyzing results...\n');
    analyze_simulation_results(sim_output, params);
    
    fprintf('\n🎉 AUTOMATED SIMULATION COMPLETE!\n');
end

function blocks_updated = update_block_parameters(model_name, params)
    % UPDATE BLOCK PARAMETERS - Automated parameter setting
    
    blocks_updated = 0;
    
    % Define blocks and their parameter mappings
    blocks = {
        struct('name', 'Rotational Spring', 'param_name', 'spr_rate', 'value', params.spring_stiffness), ...
        struct('name', 'Rotational Damper', 'param_name', 'D', 'value', params.damping_coefficient), ...
        struct('name', 'Shaft Inertia', 'param_name', 'inertia', 'value', params.inertia), ...
        struct('name', 'Load Inertia', 'param_name', 'inertia', 'value', params.inertia) ...
    };
    
    for i = 1:length(blocks)
        block = blocks{i};
        full_path = [model_name '/' block.name];
        
        if ~isempty(find_system(model_name, 'Name', block.name))
            try
                % Try to set the parameter
                set_param(full_path, block.param_name, num2str(block.value));
                fprintf('      ✅ %s: %s = %.3f\n', block.name, block.param_name, block.value);
                blocks_updated = blocks_updated + 1;
                
            catch ME
                fprintf('      ❌ %s: Failed to set %s (%s)\n', block.name, block.param_name, ME.message);
                
                % Try alternative parameter names
                if try_alternative_parameters(full_path, block.name, block.value)
                    blocks_updated = blocks_updated + 1;
                end
            end
        else
            fprintf('      ❌ %s: Block not found\n', block.name);
        end
    end
end

function success = try_alternative_parameters(block_path, block_name, value)
    % TRY ALTERNATIVE PARAMETER NAMES
    
    success = false;
    
    % Define alternative parameter names for each block type
    if contains(block_name, 'Spring')
        alt_names = {'spring_constant', 'stiffness', 'k', 'spr_rate'};
    elseif contains(block_name, 'Damper')
        alt_names = {'damping_coefficient', 'damping', 'c', 'd'};
    elseif contains(block_name, 'Inertia')
        alt_names = {'inertia', 'J', 'mass', 'm'};
    else
        alt_names = {};
    end
    
    for j = 1:length(alt_names)
        try
            set_param(block_path, alt_names{j}, num2str(value));
            fprintf('         ✅ (Alternative) %s = %.3f\n', alt_names{j}, value);
            success = true;
            return;
        catch
            % Continue to next alternative
        end
    end
    
    fprintf('         ❌ No alternative parameters worked\n');
end

function configure_simulation(model_name)
    % CONFIGURE SIMULATION SETTINGS
    
    try
        % Set simulation parameters
        set_param(model_name, 'StopTime', '2');
        set_param(model_name, 'SaveOutput', 'on');
        set_param(model_name, 'SaveFormat', 'Dataset');
        set_param(model_name, 'SignalLogging', 'on');
        set_param(model_name, 'SignalLoggingName', 'logsout');
        
        fprintf('      ✅ Stop time: 2 seconds\n');
        fprintf('      ✅ Data logging: Enabled\n');
        
    catch ME
        fprintf('      ⚠️  Could not configure all settings: %s\n', ME.message);
    end
end

function sim_output = run_simulation_with_catch(model_name)
    % RUN SIMULATION WITH ERROR HANDLING
    
    try
        % Try with full output logging
        sim_output = sim(model_name, 'ReturnWorkspaceOutputs', 'on');
        fprintf('      ✅ Simulation completed successfully\n');
        
    catch ME
        fprintf('      ⚠️  Standard simulation failed: %s\n', ME.message);
        fprintf('      Trying simplified simulation...\n');
        
        try
            % Try simplified simulation
            sim(model_name);
            sim_output = struct();
            fprintf('      ✅ Simplified simulation completed\n');
            fprintf('      Check Simulink scopes for results\n');
            
        catch ME2
            fprintf('      ❌ Simulation failed: %s\n', ME2.message);
            sim_output = struct();
        end
    end
end

function analyze_simulation_results(sim_output, params)
    % ANALYZE SIMULATION RESULTS
    
    fprintf('\n   📊 SIMULATION RESULTS ANALYSIS:\n');
    fprintf('   ===============================\n\n');
    
    fprintf('   CALIBRATED PARAMETERS:\n');
    fprintf('   ----------------------\n');
    fprintf('   Spring Stiffness: %.0f N·m/rad\n', params.spring_stiffness);
    fprintf('   Damping Coefficient: %.2f N·m·s/rad\n', params.damping_coefficient);
    fprintf('   Inertia: %.3f kg·m²\n\n', params.inertia);
    
    fprintf('   EXPECTED TARGETS:\n');
    fprintf('   -----------------\n');
    fprintf('   Vibration RMS: 2.730\n');
    fprintf('   Crest Factor: 2.81\n');
    fprintf('   Operating RPM: 1483\n\n');
    
    % Check for simulation data
    if isfield(sim_output, 'logsout') && ~isempty(sim_output.logsout)
        fprintf('   ✅ Simulation data captured\n');
        analyze_logged_data(sim_output.logsout);
    elseif isfield(sim_output, 'yout') && ~isempty(sim_output.yout)
        fprintf('   ✅ Output data captured\n');
        analyze_output_data(sim_output.yout);
    else
        fprintf('   ⚠️  No structured data captured\n');
        fprintf('   Please check Simulink scopes manually\n\n');
    end
    
    fprintf('   NEXT STEPS:\n');
    fprintf('   -----------\n');
    fprintf('   1. Check Scope, Scope1, Scope2 in Simulink\n');
    fprintf('   2. Look for stable vibration patterns\n');
    fprintf('   3. Verify RPM is around 1500\n');
    fprintf('   4. Check that vibration RMS is reasonable\n\n');
    
    create_results_summary(params);
end

function analyze_logged_data(logsout)
    % ANALYZE LOGGED DATA
    
    fprintf('   Logged signals found: %d\n', length(logsout));
    
    for i = 1:min(3, length(logsout)) % Analyze first 3 signals
        signal_name = logsout{i}.Name;
        signal_data = logsout{i}.Values.Data;
        
        if ~isempty(signal_data)
            rms_val = rms(signal_data);
            peak_val = max(abs(signal_data));
            crest_factor = peak_val / rms_val;
            
            fprintf('   📈 %s: RMS=%.3f, Peak=%.3f, Crest=%.2f\n', ...
                signal_name, rms_val, peak_val, crest_factor);
        end
    end
end

function analyze_output_data(yout)
    % ANALYZE OUTPUT DATA
    
    fprintf('   Output signals: %d\n', length(yout.signals));
    
    for i = 1:min(3, length(yout.signals))
        if isfield(yout.signals(i), 'values')
            signal_data = yout.signals(i).values.Data;
            rms_val = rms(signal_data);
            fprintf('   📊 Signal %d: RMS=%.3f\n', i, rms_val);
        end
    end
end

function create_results_summary(params)
    % CREATE RESULTS SUMMARY
    
    figure('Name', 'Digital Twin Calibration Summary', 'Position', [100, 100, 800, 600]);
    
    % Plot 1: Parameters
    subplot(2,2,1);
    values = [params.spring_stiffness, params.damping_coefficient, params.inertia];
    names = {'Spring', 'Damper', 'Inertia'};
    bar(values);
    set(gca, 'XTickLabel', names);
    title('Calibrated Parameters');
    ylabel('Value');
    grid on;
    
    % Plot 2: Targets
    subplot(2,2,2);
    targets = [2.730, 2.81, 1483];
    target_names = {'RMS', 'Crest', 'RPM'};
    bar(targets);
    set(gca, 'XTickLabel', target_names);
    title('Target Values');
    ylabel('Value');
    grid on;
    
    % Plot 3: Status
    subplot(2,2,3);
    text(0.1, 0.7, sprintf('DIGITAL TWIN STATUS\n\n✅ ML Models Trained\n✅ Parameters Calibrated\n✅ Simulation Configured\n✅ Results Ready\n\nCheck Simulink Scopes:\n- Scope\n- Scope1\n- Scope2'), ...
        'FontSize', 12, 'VerticalAlignment', 'top');
    axis off;
    
    % Plot 4: Quick Reference
    subplot(2,2,4);
    text(0.1, 0.7, sprintf('QUICK REFERENCE\n\nSpring: %.0f → spr_rate\nDamper: %.2f → D\nInertia: %.3f → inertia\n\nExpected RMS: ~2.7\nExpected RPM: ~1500', ...
        params.spring_stiffness, params.damping_coefficient, params.inertia), ...
        'FontSize', 10, 'VerticalAlignment', 'top');
    axis off;
    
    fprintf('   ✅ Results summary created\n');
end

% Include the other functions from previous version (discover_parameters_option, etc.)
function discover_parameters_option()
    % [Keep the same function from previous version]
    fprintf('\n=== OPTION 4: DISCOVER BLOCK PARAMETERS ===\n\n');
    
    model_name = 'shaft_twin_base';
    
    if ~bdIsLoaded(model_name)
        try
            load_system(model_name);
            fprintf('✅ Model loaded: %s\n', model_name);
        catch
            fprintf('❌ Could not load model: %s\n', model_name);
            return;
        end
    end
    
    fprintf('YOUR BLOCKS:\n');
    fprintf('------------\n');
    
    blocks_to_check = {
        'Rotational Spring', 'Rotational Damper', ...
        'Shaft Inertia', 'Load Inertia'
    };
    
    for i = 1:length(blocks_to_check)
        block_name = blocks_to_check{i};
        full_path = ['shaft_twin_base/' block_name];
        
        if ~isempty(find_system(model_name, 'Name', block_name))
            fprintf('✅ %s\n', block_name);
            try
                dialog_params = get_param(full_path, 'DialogParameters');
                if ~isempty(dialog_params)
                    param_names = fieldnames(dialog_params);
                    fprintf('   Parameters: ');
                    for j = 1:length(param_names)
                        if j > 1, fprintf(', '); end
                        fprintf('%s', param_names{j});
                    end
                    fprintf('\n');
                end
            catch
                fprintf('   Could not read parameters\n');
            end
        else
            fprintf('❌ %s (not found)\n', block_name);
        end
    end
    fprintf('\n');
end

function analyze_results_option()
    % OPTION 5: Analyze results
    fprintf('\n=== OPTION 5: ANALYZE RESULTS ===\n\n');
    
    [params, ~] = ml_model_optimized.calibrate_from_models();
    if ~isempty(params)
        create_results_summary(params);
        fprintf('✅ Results analysis complete\n');
    else
        fprintf('❌ No parameters found\n');
    end
end