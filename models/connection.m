%% ═══════════════════════════════════════════════════════════════════
%%  FIXED SIMULINK MODEL DIAGNOSTIC TOOL
%%  Handles variable structure fields properly
%% ═══════════════════════════════════════════════════════════════════

clear; clc;

%% CONFIGURATION
modelName = 'rotating_shaft_core';  % ← YOUR MODEL NAME

%% ═══════════════════════════════════════════════════════════════════
%% LOAD MODEL
%% ═══════════════════════════════════════════════════════════════════

fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════════════════╗\n');
fprintf('║              SIMULINK/SIMSCAPE MODEL DIAGNOSTIC TOOL                  ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════════════╝\n\n');

if ~exist([modelName '.slx'], 'file') && ~exist([modelName '.mdl'], 'file')
    fprintf('❌ ERROR: Model "%s" not found!\n', modelName);
    fprintf('   Current directory: %s\n', pwd);
    return;
end

fprintf('📂 Loading model: %s\n', modelName);
try
    load_system(modelName);
    open_system(modelName);
    fprintf('✅ Model loaded successfully\n\n');
catch ME
    fprintf('❌ Error: %s\n\n', ME.message);
    return;
end

%% ═══════════════════════════════════════════════════════════════════
%% SECTION 1: MODEL OVERVIEW
%% ═══════════════════════════════════════════════════════════════════

fprintf('┌───────────────────────────────────────────────────────────────────────┐\n');
fprintf('│  SECTION 1: MODEL OVERVIEW                                            │\n');
fprintf('└───────────────────────────────────────────────────────────────────────┘\n\n');

fprintf('📋 MODEL INFORMATION:\n');
fprintf('   Name: %s\n', modelName);
fprintf('   File: %s\n', get_param(modelName, 'FileName'));
fprintf('   Last Modified: %s\n', get_param(modelName, 'LastModifiedDate'));
fprintf('   Solver: %s\n', get_param(modelName, 'Solver'));
fprintf('   Start Time: %s\n', get_param(modelName, 'StartTime'));
fprintf('   Stop Time: %s s\n', get_param(modelName, 'StopTime'));
fprintf('   Simulation Status: %s\n\n', get_param(modelName, 'SimulationStatus'));

%% Find all blocks
allBlocks = find_system(modelName, 'SearchDepth', 1, 'Type', 'block');
allBlocks = allBlocks(2:end);

fprintf('📦 BLOCK STATISTICS:\n');
fprintf('   Total Blocks: %d\n\n', length(allBlocks));

%% ═══════════════════════════════════════════════════════════════════
%% SECTION 2: DETAILED BLOCK ANALYSIS
%% ═══════════════════════════════════════════════════════════════════

fprintf('┌───────────────────────────────────────────────────────────────────────┐\n');
fprintf('│  SECTION 2: DETAILED BLOCK-BY-BLOCK ANALYSIS                          │\n');
fprintf('└───────────────────────────────────────────────────────────────────────┘\n\n');

% Pre-allocate cell array instead of structure array
blockDataCell = cell(length(allBlocks), 1);

for i = 1:length(allBlocks)
    blockPath = allBlocks{i};
    [~, blockName, ~] = fileparts(blockPath);
    
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    fprintf('BLOCK #%d: %s\n', i, blockName);
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    % Initialize with ALL possible fields
    block = struct();
    block.index = i;
    block.name = blockName;
    block.path = blockPath;
    block.type = '';
    block.parent = '';
    block.library = '';
    block.position = [];
    block.width = 0;
    block.height = 0;
    block.centerX = 0;
    block.centerY = 0;
    block.orientation = '';
    block.parameters = struct();
    block.ports = struct();
    block.totalPorts = 0;
    
    %% BASIC PROPERTIES
    fprintf('\n📋 BASIC PROPERTIES:\n');
    
    try
        block.type = get_param(blockPath, 'BlockType');
        fprintf('   ├─ Block Type: %s\n', block.type);
    catch
        block.type = 'Unknown';
        fprintf('   ├─ Block Type: Unknown\n');
    end
    
    try
        block.parent = get_param(blockPath, 'Parent');
        fprintf('   ├─ Parent: %s\n', block.parent);
    catch
        block.parent = '';
    end
    
    try
        sourceBlock = get_param(blockPath, 'ReferenceBlock');
        if ~isempty(sourceBlock)
            block.library = sourceBlock;
            fprintf('   ├─ Library: %s\n', sourceBlock);
        else
            block.library = 'Built-in';
            fprintf('   ├─ Library: Built-in block\n');
        end
    catch
        block.library = 'Unknown';
    end
    
    try
        pos = get_param(blockPath, 'Position');
        block.position = pos;
        fprintf('   ├─ Position: [%d, %d, %d, %d]\n', pos(1), pos(2), pos(3), pos(4));
        block.width = pos(3) - pos(1);
        block.height = pos(4) - pos(2);
        block.centerX = (pos(1) + pos(3)) / 2;
        block.centerY = (pos(2) + pos(4)) / 2;
        fprintf('   ├─ Size: %d × %d pixels\n', block.width, block.height);
        fprintf('   ├─ Center: (%.1f, %.1f)\n', block.centerX, block.centerY);
    catch
        block.position = [];
    end
    
    try
        block.orientation = get_param(blockPath, 'Orientation');
        fprintf('   └─ Orientation: %s\n', block.orientation);
    catch
        block.orientation = 'right';
    end
    
    %% BLOCK PARAMETERS
    fprintf('\n⚙️  BLOCK PARAMETERS:\n');
    
    try
        dialogParams = get_param(blockPath, 'DialogParameters');
        paramNames = fieldnames(dialogParams);
        
        if ~isempty(paramNames)
            for j = 1:min(length(paramNames), 10)
                paramName = paramNames{j};
                try
                    paramValue = get_param(blockPath, paramName);
                    block.parameters.(paramName) = paramValue;
                    
                    if ischar(paramValue)
                        fprintf('   ├─ %s: "%s"\n', paramName, paramValue);
                    elseif isnumeric(paramValue) && length(paramValue) == 1
                        fprintf('   ├─ %s: %g\n', paramName, paramValue);
                    else
                        fprintf('   ├─ %s: [%s]\n', paramName, class(paramValue));
                    end
                catch
                end
            end
            
            if length(paramNames) > 10
                fprintf('   └─ ... and %d more parameters\n', length(paramNames) - 10);
            end
        else
            fprintf('   └─ No configurable parameters\n');
        end
    catch
        fprintf('   └─ Cannot read parameters\n');
    end
    
    %% PORT ANALYSIS
    fprintf('\n🔌 PORT ANALYSIS:\n');
    
    try
        ph = get_param(blockPath, 'PortHandles');
        portConn = get_param(blockPath, 'PortConnectivity');
        
        % Initialize port substructures
        block.ports.Inport = [];
        block.ports.Outport = [];
        block.ports.LConn = [];
        block.ports.RConn = [];
        
        numInports = length(ph.Inport);
        numOutports = length(ph.Outport);
        numLConn = 0;
        numRConn = 0;
        
        if isfield(ph, 'LConn'), numLConn = length(ph.LConn); end
        if isfield(ph, 'RConn'), numRConn = length(ph.RConn); end
        
        totalPorts = numInports + numOutports + numLConn + numRConn;
        block.totalPorts = totalPorts;
        
        fprintf('   ├─ Total Ports: %d\n', totalPorts);
        fprintf('   │\n');
        
        %% INPORTS
        if numInports > 0
            fprintf('   ├─ 🖤 SIMULINK INPORTS: %d\n', numInports);
            inportData = cell(numInports, 1);
            
            for j = 1:numInports
                portData = struct();
                portData.handle = ph.Inport(j);
                portData.index = j;
                portData.type = 'Inport';
                portData.position = [];
                portData.side = '';
                
                for k = 1:length(portConn)
                    if portConn(k).Type == 1 && k <= numInports
                        portData.position = portConn(k).Position;
                        portData.side = determinePortSide(block.position, portConn(k).Position);
                        break;
                    end
                end
                
                inportData{j} = portData;
                
                fprintf('   │  ├─ Inport #%d\n', j);
                fprintf('   │  │  ├─ Handle: %.0f\n', portData.handle);
                if ~isempty(portData.position)
                    fprintf('   │  │  ├─ Position: [%.0f, %.0f]\n', portData.position(1), portData.position(2));
                    fprintf('   │  │  ├─ Side: %s\n', portData.side);
                end
                fprintf('   │  │  └─ Connects FROM: Another block''s Outport\n');
            end
            block.ports.Inport = inportData;
            fprintf('   │\n');
        end
        
        %% OUTPORTS
        if numOutports > 0
            fprintf('   ├─ 🖤 SIMULINK OUTPORTS: %d\n', numOutports);
            outportData = cell(numOutports, 1);
            
            for j = 1:numOutports
                portData = struct();
                portData.handle = ph.Outport(j);
                portData.index = j;
                portData.type = 'Outport';
                portData.position = [];
                portData.side = '';
                
                for k = 1:length(portConn)
                    if portConn(k).Type == 1 && k > numInports
                        portData.position = portConn(k).Position;
                        portData.side = determinePortSide(block.position, portConn(k).Position);
                        break;
                    end
                end
                
                outportData{j} = portData;
                
                fprintf('   │  ├─ Outport #%d\n', j);
                fprintf('   │  │  ├─ Handle: %.0f\n', portData.handle);
                if ~isempty(portData.position)
                    fprintf('   │  │  ├─ Position: [%.0f, %.0f]\n', portData.position(1), portData.position(2));
                    fprintf('   │  │  ├─ Side: %s\n', portData.side);
                end
                fprintf('   │  │  └─ Connects TO: Another block''s Inport\n');
            end
            block.ports.Outport = outportData;
            fprintf('   │\n');
        end
        
        %% LCONN
        if numLConn > 0
            fprintf('   ├─ 🟠 LCONN PORTS (Physical Signal): %d\n', numLConn);
            lconnData = cell(numLConn, 1);
            
            for j = 1:numLConn
                portData = struct();
                portData.handle = ph.LConn(j);
                portData.index = j;
                portData.type = 'LConn';
                portData.position = [];
                portData.side = '';
                
                for k = 1:length(portConn)
                    if strcmp(portConn(k).Type, sprintf('LConn%d', j))
                        portData.position = portConn(k).Position;
                        portData.side = determinePortSide(block.position, portConn(k).Position);
                        break;
                    end
                end
                
                lconnData{j} = portData;
                
                fprintf('   │  ├─ LConn #%d\n', j);
                fprintf('   │  │  ├─ Handle: %.0f\n', portData.handle);
                if ~isempty(portData.position)
                    fprintf('   │  │  ├─ Position: [%.0f, %.0f]\n', portData.position(1), portData.position(2));
                    fprintf('   │  │  ├─ Side: %s\n', portData.side);
                end
                fprintf('   │  │  └─ Domain: Physical Signal\n');
            end
            block.ports.LConn = lconnData;
            fprintf('   │\n');
        end
        
        %% RCONN
        if numRConn > 0
            fprintf('   └─ 🟢 RCONN PORTS (Conserving): %d\n', numRConn);
            rconnData = cell(numRConn, 1);
            
            for j = 1:numRConn
                portData = struct();
                portData.handle = ph.RConn(j);
                portData.index = j;
                portData.type = 'RConn';
                portData.position = [];
                portData.side = '';
                portData.role = sprintf('Port %d', j);
                
                if j == 1
                    portData.role = 'R (Reference/Base)';
                elseif j == 2
                    portData.role = 'C (Case/Follower)';
                end
                
                for k = 1:length(portConn)
                    if strcmp(portConn(k).Type, sprintf('RConn%d', j))
                        portData.position = portConn(k).Position;
                        portData.side = determinePortSide(block.position, portConn(k).Position);
                        break;
                    end
                end
                
                rconnData{j} = portData;
                
                fprintf('      ├─ RConn #%d\n', j);
                fprintf('      │  ├─ Handle: %.0f\n', portData.handle);
                if ~isempty(portData.position)
                    fprintf('      │  ├─ Position: [%.0f, %.0f]\n', portData.position(1), portData.position(2));
                    fprintf('      │  ├─ Side: %s\n', portData.side);
                end
                fprintf('      │  ├─ Role: %s\n', portData.role);
                fprintf('      │  └─ Domain: Conserving\n');
            end
            block.ports.RConn = rconnData;
        end
        
        if totalPorts == 0
            fprintf('   └─ ⚠️  NO PORTS\n');
        end
        
    catch ME
        fprintf('   └─ ❌ Error: %s\n', ME.message);
    end
    
    fprintf('\n');
    
    % Store in cell array
    blockDataCell{i} = block;
end

% Convert cell array to structure array
blockData = [blockDataCell{:}]';

%% ═══════════════════════════════════════════════════════════════════
%% SECTION 3: SUMMARY TABLE
%% ═══════════════════════════════════════════════════════════════════

fprintf('┌───────────────────────────────────────────────────────────────────────┐\n');
fprintf('│  SECTION 3: SUMMARY TABLE                                             │\n');
fprintf('└───────────────────────────────────────────────────────────────────────┘\n\n');

fprintf('═══════════════════════════════════════════════════════════════════════════════\n');
fprintf('%-4s | %-35s | %-20s | Ports\n', '#', 'Block Name', 'Type');
fprintf('─────┼─────────────────────────────────────┼──────────────────────┼────────\n');

for i = 1:length(blockData)
    b = blockData(i);
    
    numIn = 0; numOut = 0; numL = 0; numR = 0;
    if ~isempty(b.ports.Inport), numIn = length(b.ports.Inport); end
    if ~isempty(b.ports.Outport), numOut = length(b.ports.Outport); end
    if ~isempty(b.ports.LConn), numL = length(b.ports.LConn); end
    if ~isempty(b.ports.RConn), numR = length(b.ports.RConn); end
    
    portStr = sprintf('In:%d Out:%d L:%d R:%d', numIn, numOut, numL, numR);
    
    fprintf('%-4d | %-35s | %-20s | %s\n', ...
        i, ...
        truncate(b.name, 35), ...
        truncate(b.type, 20), ...
        portStr);
end

fprintf('\n');

%% ═══════════════════════════════════════════════════════════════════
%% SECTION 4: CONNECTION CODE GENERATOR
%% ═══════════════════════════════════════════════════════════════════

fprintf('┌───────────────────────────────────────────────────────────────────────┐\n');
fprintf('│  SECTION 4: AUTO-GENERATED PORT HANDLE CODE                           │\n');
fprintf('└───────────────────────────────────────────────────────────────────────┘\n\n');

fprintf('%% Copy this code to get port handles:\n\n');
fprintf('modelName = ''%s'';\n', modelName);
fprintf('h = struct();\n\n');

for i = 1:length(blockData)
    b = blockData(i);
    safeName = matlab.lang.makeValidName(b.name);
    
    fprintf('%% %d. %s\n', i, b.name);
    fprintf('ph = get_param([modelName ''/%s''], ''PortHandles'');\n', b.name);
    
    if ~isempty(b.ports.Inport)
        for j = 1:length(b.ports.Inport)
            fprintf('h.%s_In%d = ph.Inport(%d);  %% Handle: %.0f\n', ...
                safeName, j, j, b.ports.Inport{j}.handle);
        end
    end
    
    if ~isempty(b.ports.Outport)
        for j = 1:length(b.ports.Outport)
            fprintf('h.%s_Out%d = ph.Outport(%d);  %% Handle: %.0f\n', ...
                safeName, j, j, b.ports.Outport{j}.handle);
        end
    end
    
    if ~isempty(b.ports.LConn)
        for j = 1:length(b.ports.LConn)
            fprintf('h.%s_L%d = ph.LConn(%d);  %% Handle: %.0f [Physical Signal]\n', ...
                safeName, j, j, b.ports.LConn{j}.handle);
        end
    end
    
    if ~isempty(b.ports.RConn)
        for j = 1:length(b.ports.RConn)
            fprintf('h.%s_R%d = ph.RConn(%d);  %% Handle: %.0f [%s]\n', ...
                safeName, j, j, b.ports.RConn{j}.handle, b.ports.RConn{j}.role);
        end
    end
    
    fprintf('\n');
end

%% ═══════════════════════════════════════════════════════════════════
%% SAVE DATA
%% ═══════════════════════════════════════════════════════════════════

fprintf('┌───────────────────────────────────────────────────────────────────────┐\n');
fprintf('│  SECTION 5: DATA SAVED                                                │\n');
fprintf('└───────────────────────────────────────────────────────────────────────┘\n\n');

assignin('base', 'modelData', blockData);
assignin('base', 'modelName', modelName);
save('model_diagnostic_data.mat', 'blockData', 'modelName');

fprintf('✅ Data saved:\n');
fprintf('   • Workspace: modelData, modelName\n');
fprintf('   • File: model_diagnostic_data.mat\n\n');

fprintf('╔═══════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                     ✅ DIAGNOSTIC COMPLETE                             ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════════════╝\n\n');

%% HELPER FUNCTIONS

function side = determinePortSide(blockPos, portPos)
    if isempty(blockPos) || isempty(portPos)
        side = 'Unknown';
        return;
    end
    
    blockCenterX = (blockPos(1) + blockPos(3)) / 2;
    blockCenterY = (blockPos(2) + blockPos(4)) / 2;
    
    portX = portPos(1);
    portY = portPos(2);
    
    if portX < blockPos(1) + 5
        hPos = 'LEFT';
    elseif portX > blockPos(3) - 5
        hPos = 'RIGHT';
    elseif abs(portX - blockCenterX) < 10
        hPos = 'CENTER';
    elseif portX < blockCenterX
        hPos = 'LEFT-CENTER';
    else
        hPos = 'RIGHT-CENTER';
    end
    
    if portY < blockPos(2) + 5
        vPos = 'TOP';
    elseif portY > blockPos(4) - 5
        vPos = 'BOTTOM';
    elseif abs(portY - blockCenterY) < 10
        vPos = 'MIDDLE';
    elseif portY < blockCenterY
        vPos = 'UPPER';
    else
        vPos = 'LOWER';
    end
    
    side = sprintf('%s %s', hPos, vPos);
end

function str = truncate(input, maxLen)
    if length(input) > maxLen
        str = [input(1:maxLen-3) '...'];
    else
        str = input;
    end
end