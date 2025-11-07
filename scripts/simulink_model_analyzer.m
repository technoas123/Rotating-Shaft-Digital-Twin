function simulink_model_analyzer(modelName)
    % COMPLETE SIMULINK MODEL ANALYZER - FIXED VERSION
    % Analyzes blocks, connections, parameters, and generates detailed reports
    % Usage: simulink_model_analyzer('shaft_twin_base')
    
    % Clear command window but keep figures
    clc;
    
    fprintf('=================================================\n');
    fprintf('🚀 SIMULINK MODEL ANALYZER\n');
    fprintf('=================================================\n');
    fprintf('Model: %s\n\n', modelName);
    
    % Check if model exists and load it
    if ~bdIsLoaded(modelName)
        try
            load_system(modelName);
            fprintf('✅ Model loaded successfully\n');
        catch ME
            fprintf('❌ Error loading model: %s\n', ME.message);
            return;
        end
    else
        fprintf('✅ Model already loaded\n');
    end
    
    % Run all analysis functions
    quick_block_summary(modelName);
    find_specific_blocks(modelName);
    generate_connection_map(modelName);
    analyze_block_parameters(modelName);
    check_model_configuration(modelName);
    
    fprintf('\n=================================================\n');
    fprintf('✅ ANALYSIS COMPLETE\n');
    fprintf('=================================================\n');
end

%% QUICK BLOCK SUMMARY FUNCTION - FIXED
function quick_block_summary(modelName)
    fprintf('\n📊 1. BLOCK TYPE SUMMARY\n');
    fprintf('-------------------------------------------------\n');
    
    % Get all blocks EXCEPT the root model itself
    allBlocks = find_system(modelName, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'block');
    
    fprintf('Total blocks in model: %d\n', length(allBlocks));
    
    % Count by block type
    blockTypes = {};
    for i = 1:length(allBlocks)
        try
            blockType = get_param(allBlocks{i}, 'BlockType');
            blockTypes{end+1} = blockType;
        catch
            % Skip blocks that can't be analyzed
            continue;
        end
    end
    
    if isempty(blockTypes)
        fprintf('❌ No blocks found or accessible\n');
        return;
    end
    
    [uniqueTypes, ~, ic] = unique(blockTypes);
    counts = accumarray(ic, 1);
    
    % Display block counts
    for i = 1:length(uniqueTypes)
        fprintf('   %-20s: %d blocks\n', uniqueTypes{i}, counts(i));
    end
    
    % Show key blocks in detail
    fprintf('\n🔧 KEY BLOCKS DETAIL:\n');
    importantTypes = {'Sine', 'Sum', 'ToWorkspace', 'Gain', 'Scope', 'Outport', 'Inport'};
    
    for i = 1:length(importantTypes)
        try
            blocks = find_system(modelName, 'BlockType', importantTypes{i}, 'Type', 'block');
            if ~isempty(blocks)
                fprintf('\n   %s blocks:\n', importantTypes{i});
                for j = 1:length(blocks)
                    blockName = get_param(blocks{j}, 'Name');
                    fprintf('     - %s\n', blockName);
                    
                    % Show specific parameters
                    switch importantTypes{i}
                        case 'Sine'
                            try
                                amp = get_param(blocks{j}, 'Amplitude');
                                freq = get_param(blocks{j}, 'Frequency');
                                phase = get_param(blocks{j}, 'Phase');
                                fprintf('       Amplitude: %s, Frequency: %s, Phase: %s\n', amp, freq, phase);
                            catch
                            end
                        case 'ToWorkspace'
                            try
                                varName = get_param(blocks{j}, 'VariableName');
                                saveFormat = get_param(blocks{j}, 'SaveFormat');
                                fprintf('       Variable: %s, Format: %s\n', varName, saveFormat);
                            catch
                            end
                        case 'Gain'
                            try
                                gain = get_param(blocks{j}, 'Gain');
                                fprintf('       Gain: %s\n', gain);
                            catch
                            end
                        case 'Sum'
                            try
                                inputs = get_param(blocks{j}, 'Inputs');
                                fprintf('       Inputs: %s\n', inputs);
                            catch
                            end
                    end
                end
            end
        catch ME
            fprintf('   Error analyzing %s blocks: %s\n', importantTypes{i}, ME.message);
        end
    end
end

%% FIND SPECIFIC BLOCKS FUNCTION - FIXED
function find_specific_blocks(modelName)
    fprintf('\n🎯 2. FINDING CRITICAL BLOCKS\n');
    fprintf('-------------------------------------------------\n');
    
    % Blocks we're specifically interested in for your digital twin
    targetNames = {'sine', 'torque', 'omega', 'vibration', 'fault', 'sum', 'gain', 'scope', 'workspace', 'out'};
    
    allBlocks = find_system(modelName, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'block');
    foundCount = 0;
    
    for i = 1:length(allBlocks)
        try
            blockPath = allBlocks{i};
            blockName = get_param(blockPath, 'Name');
            
            for j = 1:length(targetNames)
                if contains(lower(blockName), lower(targetNames{j}))
                    foundCount = foundCount + 1;
                    fprintf('\n🔍 FOUND: %s\n', blockName);
                    fprintf('   Path: %s\n', blockPath);
                    fprintf('   Type: %s\n', get_param(blockPath, 'BlockType'));
                    
                    % Get detailed parameters
                    display_block_details(blockPath);
                    break;
                end
            end
        catch
            % Skip blocks that cause errors
            continue;
        end
    end
    
    if foundCount == 0
        fprintf('❌ No critical blocks found matching search patterns\n');
    else
        fprintf('\n✅ Found %d critical blocks\n', foundCount);
    end
end

%% DISPLAY BLOCK DETAILS FUNCTION
function display_block_details(blockPath)
    try
        blockType = get_param(blockPath, 'BlockType');
        
        % Display parameters based on block type
        switch blockType
            case 'Sine'
                try
                    amplitude = get_param(blockPath, 'Amplitude');
                    frequency = get_param(blockPath, 'Frequency');
                    phase = get_param(blockPath, 'Phase');
                    sampleTime = get_param(blockPath, 'SampleTime');
                    fprintf('   Parameters:\n');
                    fprintf('     Amplitude: %s\n', amplitude);
                    fprintf('     Frequency: %s\n', frequency);
                    fprintf('     Phase: %s\n', phase);
                    fprintf('     SampleTime: %s\n', sampleTime);
                    
                    % Try to interpret frequency in Hz
                    try
                        freq_val = eval(frequency);
                        fprintf('     → Frequency: %.2f Hz\n', freq_val/(2*pi));
                    catch
                    end
                catch ME
                    fprintf('   Could not read Sine parameters: %s\n', ME.message);
                end
                
            case 'ToWorkspace'
                try
                    varName = get_param(blockPath, 'VariableName');
                    saveFormat = get_param(blockPath, 'SaveFormat');
                    limitData = get_param(blockPath, 'LimitDataPoints');
                    maxPoints = get_param(blockPath, 'MaxDataPoints');
                    decimation = get_param(blockPath, 'Decimation');
                    sampleTime = get_param(blockPath, 'SampleTime');
                    fprintf('   Parameters:\n');
                    fprintf('     VariableName: %s\n', varName);
                    fprintf('     SaveFormat: %s\n', saveFormat);
                    fprintf('     LimitDataPoints: %s\n', limitData);
                    fprintf('     MaxDataPoints: %s\n', maxPoints);
                    fprintf('     Decimation: %s\n', decimation);
                    fprintf('     SampleTime: %s\n', sampleTime);
                catch ME
                    fprintf('   Could not read ToWorkspace parameters: %s\n', ME.message);
                end
                
            case 'Sum'
                try
                    inputs = get_param(blockPath, 'Inputs');
                    fprintf('   Parameters:\n');
                    fprintf('     Inputs: %s\n', inputs);
                catch ME
                    fprintf('   Could not read Sum parameters: %s\n', ME.message);
                end
                
            case 'Gain'
                try
                    gain = get_param(blockPath, 'Gain');
                    fprintf('   Parameters:\n');
                    fprintf('     Gain: %s\n', gain);
                catch ME
                    fprintf('   Could not read Gain parameters: %s\n', ME.message);
                end
                
            otherwise
                % Try to get common parameters for any block
                try
                    position = get_param(blockPath, 'Position');
                    fprintf('   Position: [%s]\n', num2str(position));
                catch
                end
        end
        
        % Show port connections
        try
            portHandles = get_param(blockPath, 'PortHandles');
            fprintf('   Connections: %d inputs, %d outputs\n', ...
                length(portHandles.Inport), length(portHandles.Outport));
        catch
        end
        
    catch ME
        fprintf('   Error analyzing block details: %s\n', ME.message);
    end
end

%% CONNECTION MAP FUNCTION - FIXED
function generate_connection_map(modelName)
    fprintf('\n🔄 3. CONNECTION MAP\n');
    fprintf('-------------------------------------------------\n');
    
    % Get all lines in the model
    try
        allLines = find_system(modelName, 'FindAll', 'on', 'Type', 'line');
        fprintf('Total signal lines: %d\n', length(allLines));
        
        connectionCount = 0;
        
        for i = 1:length(allLines)
            try
                lineHandle = allLines(i);
                srcPort = get_param(lineHandle, 'SrcPortHandle');
                dstPorts = get_param(lineHandle, 'DstPortHandle');
                
                if srcPort ~= -1
                    srcBlock = get_param(srcPort, 'Parent');
                    srcBlockName = get_param(srcBlock, 'Name');
                    
                    if ~isempty(dstPorts) && any(dstPorts ~= -1)
                        connectionCount = connectionCount + 1;
                        
                        % Only show connections for important blocks to avoid clutter
                        importantBlocks = {'sine', 'torque', 'omega', 'vibration', 'fault', 'sum'};
                        showConnection = false;
                        for j = 1:length(importantBlocks)
                            if contains(lower(srcBlockName), lower(importantBlocks{j}))
                                showConnection = true;
                                break;
                            end
                        end
                        
                        if showConnection && connectionCount <= 20 % Limit output
                            fprintf('\n📡 Connection %d:\n', connectionCount);
                            fprintf('   Source: %s (%s)\n', srcBlockName, get_param(srcBlock, 'BlockType'));
                            
                            fprintf('   Destinations:\n');
                            for j = 1:length(dstPorts)
                                if dstPorts(j) ~= -1
                                    dstBlock = get_param(dstPorts(j), 'Parent');
                                    dstBlockName = get_param(dstBlock, 'Name');
                                    fprintf('     → %s (%s)\n', dstBlockName, get_param(dstBlock, 'BlockType'));
                                end
                            end
                        end
                    end
                end
            catch
                % Skip connection errors
                continue;
            end
        end
        
        fprintf('\n✅ Mapped %d important connections (showing first 20)\n', connectionCount);
        
    catch ME
        fprintf('Error analyzing connections: %s\n', ME.message);
    end
end

%% BLOCK PARAMETERS ANALYSIS FUNCTION - FIXED
function analyze_block_parameters(modelName)
    fprintf('\n⚙️  4. DETAILED PARAMETERS ANALYSIS\n');
    fprintf('-------------------------------------------------\n');
    
    % Focus on critical block types
    criticalTypes = {'Sine', 'ToWorkspace', 'Sum', 'Gain'};
    
    for t = 1:length(criticalTypes)
        try
            blocks = find_system(modelName, 'BlockType', criticalTypes{t}, 'Type', 'block');
            
            if ~isempty(blocks)
                fprintf('\n%s Blocks Analysis:\n', criticalTypes{t});
                
                for i = 1:length(blocks)
                    blockPath = blocks{i};
                    blockName = get_param(blockPath, 'Name');
                    
                    fprintf('   %s:\n', blockName);
                    
                    switch criticalTypes{t}
                        case 'Sine'
                            display_sine_parameters(blockPath);
                        case 'ToWorkspace'
                            display_toworkspace_parameters(blockPath);
                        case 'Sum'
                            display_sum_parameters(blockPath);
                        case 'Gain'
                            display_gain_parameters(blockPath);
                    end
                end
            end
        catch ME
            fprintf('Error analyzing %s blocks: %s\n', criticalTypes{t}, ME.message);
        end
    end
end

%% PARAMETER DISPLAY FUNCTIONS
function display_sine_parameters(blockPath)
    try
        amplitude = get_param(blockPath, 'Amplitude');
        frequency = get_param(blockPath, 'Frequency');
        phase = get_param(blockPath, 'Phase');
        sampleTime = get_param(blockPath, 'SampleTime');
        
        fprintf('     Amplitude: %s\n', amplitude);
        fprintf('     Frequency: %s\n', frequency);
        fprintf('     Phase: %s\n', phase);
        fprintf('     SampleTime: %s\n', sampleTime);
        
        % Interpret the values
        try
            amp_val = eval(amplitude);
            freq_val = eval(frequency);
            fprintf('     → Waveform: %.4f * sin(2*pi*%.2f*t + %.4f)\n', ...
                amp_val, freq_val/(2*pi), eval(phase));
        catch
        end
        
    catch ME
        fprintf('     Error reading parameters: %s\n', ME.message);
    end
end

function display_toworkspace_parameters(blockPath)
    try
        varName = get_param(blockPath, 'VariableName');
        saveFormat = get_param(blockPath, 'SaveFormat');
        limitData = get_param(blockPath, 'LimitDataPoints');
        maxPoints = get_param(blockPath, 'MaxDataPoints');
        decimation = get_param(blockPath, 'Decimation');
        sampleTime = get_param(blockPath, 'SampleTime');
        
        fprintf('     VariableName: %s\n', varName);
        fprintf('     SaveFormat: %s\n', saveFormat);
        fprintf('     LimitDataPoints: %s\n', limitData);
        fprintf('     MaxDataPoints: %s\n', maxPoints);
        fprintf('     Decimation: %s\n', decimation);
        fprintf('     SampleTime: %s\n', sampleTime);
        
    catch ME
        fprintf('     Error reading parameters: %s\n', ME.message);
    end
end

function display_sum_parameters(blockPath)
    try
        inputs = get_param(blockPath, 'Inputs');
        fprintf('     Input configuration: %s\n', inputs);
        
        % Interpret the input pattern
        if contains(inputs, '|')
            fprintf('     → Multiple inputs with different signs\n');
        elseif strcmp(inputs, '++')
            fprintf('     → Two positive inputs\n');
        elseif strcmp(inputs, '+-')
            fprintf('     → One positive, one negative input\n');
        else
            fprintf('     → Custom input pattern\n');
        end
        
    catch ME
        fprintf('     Error reading parameters: %s\n', ME.message);
    end
end

function display_gain_parameters(blockPath)
    try
        gain = get_param(blockPath, 'Gain');
        fprintf('     Gain value: %s\n', gain);
        
        % Try to evaluate and interpret
        try
            gain_val = eval(gain);
            if gain_val == 0
                fprintf('     → Effect: Blocks signal completely\n');
            elseif gain_val == 1
                fprintf('     → Effect: Pass-through (no change)\n');
            elseif gain_val > 1
                fprintf('     → Effect: Amplifies signal by %.2fx\n', gain_val);
            elseif gain_val < 1 && gain_val > 0
                fprintf('     → Effect: Attenuates signal by %.2fx\n', gain_val);
            elseif gain_val < 0
                fprintf('     → Effect: Inverts signal (%.2fx)\n', abs(gain_val));
            end
        catch
        end
        
    catch ME
        fprintf('     Error reading parameters: %s\n', ME.message);
    end
end

%% MODEL CONFIGURATION CHECK FUNCTION
function check_model_configuration(modelName)
    fprintf('\n🔍 5. MODEL CONFIGURATION CHECK\n');
    fprintf('-------------------------------------------------\n');
    
    try
        % Get model configuration
        solverType = get_param(modelName, 'SolverType');
        solver = get_param(modelName, 'Solver');
        stopTime = get_param(modelName, 'StopTime');
        
        fprintf('Solver Configuration:\n');
        fprintf('   SolverType: %s\n', solverType);
        fprintf('   Solver: %s\n', solver);
        fprintf('   StopTime: %s\n', stopTime);
        
        % Try to get fixed step if applicable
        try
            fixedStep = get_param(modelName, 'FixedStep');
            fprintf('   FixedStep: %s\n', fixedStep);
        catch
        end
        
        % Check data logging configuration
        try
            saveFormat = get_param(modelName, 'SaveFormat');
            saveOutput = get_param(modelName, 'SaveOutput');
            saveTime = get_param(modelName, 'SaveTime');
            
            fprintf('\nData Logging Configuration:\n');
            fprintf('   SaveFormat: %s\n', saveFormat);
            fprintf('   SaveOutput: %s\n', saveOutput);
            fprintf('   SaveTime: %s\n', saveTime);
            
        catch
            fprintf('\nData Logging: Using ToWorkspace blocks\n');
        end
        
        % Recommendations
        fprintf('\n💡 RECOMMENDATIONS:\n');
        if ~strcmp(solver, 'ode23t') && ~strcmp(solver, 'ode15s')
            fprintf('   ⚠️  Consider using ode23t or ode15s for mechanical systems\n');
        else
            fprintf('   ✅ Solver appropriate for mechanical systems\n');
        end
        
        if str2double(stopTime) < 1
            fprintf('   ⚠️  Short simulation time - consider increasing for steady-state analysis\n');
        end
        
    catch ME
        fprintf('Error reading model configuration: %s\n', ME.message);
    end
end