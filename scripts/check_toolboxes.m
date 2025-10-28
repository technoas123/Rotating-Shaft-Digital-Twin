function check_toolboxes()
    % CHECK_TOOLBOXES Verify availability of required MATLAB toolboxes
    
    required_toolboxes = {
        'Simulink',                    'Simulink';
        'Simscape',                    'Simscape'; 
        'Simscape_Multibody',          'SimMechanics';
        'Signal_Toolbox',              'Signal_Toolbox';
        'Statistics_and_Machine_Learning_Toolbox', 'Statistics_Toolbox';
        'MATLAB',                      'MATLAB'
    };
    
    fprintf('Checking toolbox availability...\n\n');
    
    for i = 1:size(required_toolboxes, 1)
        display_name = required_toolboxes{i, 1};
        license_name = required_toolboxes{i, 2};
        
        try
            if license('test', license_name)
                fprintf('✅ %s is available\n', display_name);
            else
                fprintf('❌ %s is MISSING - Please install it!\n', display_name);
            end
        catch ME
            fprintf('⚠️  Error checking %s: %s\n', display_name, ME.message);
        end
    end
    
    fprintf('\nToolbox check complete.\n');
end