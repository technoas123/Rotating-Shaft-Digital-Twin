%% File: ml_pipelines/01_system_identification/01_analyze_new_dataset.m
function analyze_new_dataset()
    fprintf('🚀 ANALYZING NEW UNBALANCE DATASET (4096 Hz)\n');
    fprintf('==============================================\n');

    % Setup paths
    thisFile = mfilename('fullpath');
    projectRoot = fileparts(fileparts(fileparts(thisFile)));
    rawDir = fullfile(projectRoot, 'data', 'raw');
    
    % Test file: 4D.csv (High unbalance)
    filename = '4D.csv'; 
    filepath = fullfile(rawDir, filename);
    
    if ~exist(filepath, 'file')
        error('❌ File %s not found in %s', filename, rawDir);
    end
    
    % Read Data (5 Columns)
    % Col 1: V_in, 2: RPM, 3: Vib1, 4: Vib2, 5: Vib3
    opts = detectImportOptions(filepath);
    opts.VariableNames = {'V_in', 'RPM', 'Vib1', 'Vib2', 'Vib3'};
    data = readtable(filepath, opts);
    
    fs = 4096; % As per spec
    dt = 1/fs;
    time = (0:height(data)-1)' * dt;
    
    fprintf('✅ Loaded %s\n', filename);
    fprintf('   Samples: %d (%.2f seconds)\n', height(data), height(data)/fs);
    fprintf('   RPM Range: %.1f to %.1f\n', min(data.RPM), max(data.RPM));
    fprintf('   Voltage Range: %.2f to %.2f V\n', min(data.V_in), max(data.V_in));
    
    % Plot
    figure('Name', 'New Dataset Overview', 'Color', 'w');
    
    subplot(3,1,1);
    plot(time, data.RPM, 'b'); ylabel('RPM'); title('Motor Speed'); grid on;
    
    subplot(3,1,2);
    plot(time, data.Vib1, 'k'); ylabel('Vib 1'); title('Vibration Sensor 1'); grid on;
    
    subplot(3,1,3);
    % Frequency Spectrum
    L = length(data.Vib1);
    Y = fft(data.Vib1 - mean(data.Vib1));
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:(L/2))/L;
    
    plot(f, P1, 'r'); 
    title('Frequency Spectrum (Unbalance often shows at 1x RPM)');
    xlabel('Hz'); xlim([0 200]); grid on;
    
    fprintf('\n🔎 Observation: Unbalance usually creates a peak at Rotation Freq (1X).\n');
    fprintf('   If RPM is ~1200, Freq should be 20 Hz.\n');
end