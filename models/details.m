function complete_rotational_system()
    mdl = 'shaft_twin_base';
    open_system(mdl);
    
    fprintf('🎯 COMPLETING ROTATIONAL SYSTEM WITH SCOPES & DATA EXPORT\n\n');
    
    try
        %% --- 1. Make all mechanical connections ---
        connect_rotational_system_fixed();
        
        %% --- 2. Add scopes for visualization ---
        fprintf('\n4. Adding scopes for visualization...\n');
        
        % Torque Scope
        add_block('simulink/Commonly Used Blocks/Scope', [mdl '/Torque_Scope'], ...
                 'Position', [700, 100, 730, 130]);
        add_line(mdl, 'PS-Simulink Converter/1', 'Torque_Scope/1', 'autorouting','on');
        fprintf('   ✅ Added Torque Scope\n');
        
        % Speed Scope  
        add_block('simulink/Commonly Used Blocks/Scope', [mdl '/Speed_Scope'], ...
                 'Position', [700, 200, 730, 230]);
        add_line(mdl, 'PS-Simulink Converter1/1', 'Speed_Scope/1', 'autorouting','on');
        fprintf('   ✅ Added Speed Scope\n');
        
        %% --- 3. Add data export to workspace ---
        fprintf('\n5. Adding data export to workspace...\n');
        
        % Torque data export
        add_block('simulink/Commonly Used Blocks/To Workspace', [mdl '/ToWS_Torque'], ...
                 'Position', [800, 100, 830, 130]);
        set_param([mdl '/ToWS_Torque'], 'VariableName', 'torque_data', 'SaveFormat', 'StructureWithTime');
        add_line(mdl, 'PS-Simulink Converter/1', 'ToWS_Torque/1', 'autorouting','on');
        fprintf('   ✅ Added Torque data export\n');
        
        % Speed data export
        add_block('simulink/Commonly Used Blocks/To Workspace', [mdl '/ToWS_Speed'], ...
                 'Position', [800, 200, 830, 230]);
        set_param([mdl '/ToWS_Speed'], 'VariableName', 'speed_data', 'SaveFormat', 'StructureWithTime');
        add_line(mdl, 'PS-Simulink Converter1/1', 'ToWS_Speed/1', 'autorouting','on');
        fprintf('   ✅ Added Speed data export\n');
        
        %% --- 4. Configure simulation parameters ---
        set_param(mdl, 'StopTime', '10');
        set_param(mdl, 'Solver', 'ode15s');
        
        %% Save and finalize
        save_system(mdl);
        
        fprintf('\n🎉 ROTATIONAL SYSTEM COMPLETE!\n');
        fprintf('📊 Day 2 Deliverables Achieved:\n');
        fprintf('   ✅ Mechanical system with torque source\n');
        fprintf('   ✅ Torque sensing system\n');
        fprintf('   ✅ Speed measurement system\n');
        fprintf('   ✅ Real-time visualization scopes\n');
        fprintf('   ✅ Automated data export to MATLAB workspace\n');
        fprintf('\n🚀 Ready to run simulation!\n');
        
    catch ME
        fprintf('❌ Error: %s\n', ME.message);
    end
end

% Run the complete system
complete_rotational_system();