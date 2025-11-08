function find_simulink_blocks()
    % FIND_SIMULINK_BLOCKS - Discover your actual block names
    
    model_name = 'shaft_twin_base';
    
    fprintf('=== FINDING SIMULINK BLOCKS ===\n\n');
    
    if ~bdIsLoaded(model_name)
        try
            load_system(model_name);
            fprintf('✅ Loaded model: %s\n', model_name);
        catch
            fprintf('❌ Could not load model: %s\n', model_name);
            return;
        end
    end
    
    % List ALL blocks in the model
    all_blocks = find_system(model_name, 'SearchDepth', 1);
    fprintf('📋 ALL BLOCKS IN MODEL:\n');
    for i = 1:length(all_blocks)
        if i == 1
            continue; % Skip the model itself
        end
        block_name = all_blocks{i};
        block_type = get_param(block_name, 'BlockType');
        fprintf('   %s [%s]\n', block_name, block_type);
    end
    
    % Look for rotational components specifically
    fprintf('\n🎯 SEARCHING FOR ROTATIONAL COMPONENTS:\n');
    
    % Common rotational block types
    rotational_types = {
        'Revolute', 'RevoluteJoint', ...
        'Rotational', 'RotationalSpring', 'RotationalDamper', ...
        'Inertia', 'Disk', 'Mass', ...
        'Spring', 'Damper', 'TranslationalSpring', 'TranslationalDamper'
    };
    
    for i = 1:length(rotational_types)
        blocks = find_system(model_name, 'BlockType', rotational_types{i});
        if ~isempty(blocks)
            fprintf('   Found %s blocks:\n', rotational_types{i});
            for j = 1:length(blocks)
                fprintf('      %s\n', blocks{j});
                % Show parameters if it's likely a spring/damper/inertia
                if contains(rotational_types{i}, 'Spring')
                    try
                        param = get_param(blocks{j}, 'spring_constant');
                        fprintf('        spring_constant = %s\n', param);
                    catch
                    end
                elseif contains(rotational_types{i}, 'Damper')
                    try
                        param = get_param(blocks{j}, 'damping_coefficient');
                        fprintf('        damping_coefficient = %s\n', param);
                    catch
                    end
                elseif contains(rotational_types{i}, 'Inertia')
                    try
                        param = get_param(blocks{j}, 'inertia');
                        fprintf('        inertia = %s\n', param);
                    catch
                    end
                end
            end
        end
    end
    
    % Look for any blocks with "spring", "damper", "inertia" in name
    fprintf('\n🔍 SEARCHING BY NAME PATTERNS:\n');
    name_patterns = {'spring', 'damper', 'damp', 'inertia', 'mass', 'stiffness'};
    
    for i = 1:length(name_patterns)
        blocks = find_system(model_name, 'Name', name_patterns{i}, 'IgnoreCase', true);
        if ~isempty(blocks)
            fprintf('   Blocks with "%s" in name:\n', name_patterns{i});
            for j = 1:length(blocks)
                block_type = get_param(blocks{j}, 'BlockType');
                fprintf('      %s [%s]\n', blocks{j}, block_type);
            end
        end
    end
end

% Run the diagnostic
find_simulink_blocks();