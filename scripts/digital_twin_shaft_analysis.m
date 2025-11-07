function digital_twin_shaft_analysis()
    % DIGITAL TWIN ANALYSIS FOR YOUR SIMSCAPE SHAFT MODEL
    % Uses your existing shaft_twin_base model
    % Performs predictive fault analysis on simulation outputs
    
    fprintf('=== DIGITAL TWIN: SHAFT FAULT PREDICTION ANALYSIS ===\n');
    
    % 1. RUN YOUR EXISTING SIMULATION
    simulation_data = run_simscape_simulation();
    
    % 2. ENHANCE DATA WITH FAULT INJECTION
    enhanced_data = inject_fault_scenarios(simulation_data);
    
    % 3. PERFORM COMPREHENSIVE FAULT ANALYSIS
    fault_predictions = analyze_shaft_faults(enhanced_data);
    
    % 4. GENERATE PREDICTIVE MAINTENANCE REPORT
    generate_digital_twin_report(fault_predictions);
    
    % 5. CREATE INTERACTIVE DASHBOARD
    create_fault_dashboard(fault_predictions);
    
    fprintf('✅ Digital Twin Analysis Complete!\n');
end

function simulation_data = run_simscape_simulation()
    % RUN YOUR EXISTING SIMSCAPE SIMULATION AND COLLECT DATA
    
    fprintf('Running Simscape simulation...\n');
    
    % Use your existing model
    modelName = 'shaft_twin_base';
    
    % Set simulation parameters (adjust based on your needs)
    set_param(modelName, 'StopTime', '5'); % 5 seconds for good data
    set_param(modelName, 'Solver', 'ode23t'); % Better for mechanical systems
    
    % Run simulation
    simOut = sim(modelName);
    
    % Extract data from your ToWorkspace blocks
    simulation_data = struct();
    
    % Vibration data (from vibration_signal)
    if exist('vibration_signal', 'var')
        simulation_data.vibration = vibration_signal;
        simulation_data.time = vibration_signal.time;
    elseif isfield(simOut, 'vibration_signal')
        simulation_data.vibration = simOut.vibration_signal.Data;
        simulation_data.time = simOut.vibration_signal.Time;
    else
        % Try to find vibration data in other outputs
        simulation_data = find_vibration_data(simOut);
    end
    
    % Torque data (from torque_out)
    if exist('torque_out', 'var')
        simulation_data.torque = torque_out;
    elseif isfield(simOut, 'torque_out')
        simulation_data.torque = simOut.torque_out.Data;
    end
    
    % Omega data (from omega_out)
    if exist('omega_out', 'var')
        simulation_data.omega = omega_out;
    elseif isfield(simOut, 'omega_out')
        simulation_data.omega = simOut.omega_out.Data;
    end
    
    % If no data found, create sample data for demonstration
    if ~isfield(simulation_data, 'vibration')
        fprintf('⚠️  No vibration data found. Creating sample data...\n');
        simulation_data = create_sample_shaft_data();
    end
    
    fprintf('✅ Collected %d data samples\n', length(simulation_data.time));
end

function enhanced_data = inject_fault_scenarios(simulation_data)
    % ENHANCE DATA WITH DIFFERENT FAULT SCENARIOS FOR ANALYSIS
    
    fprintf('Injecting fault scenarios for analysis...\n');
    
    enhanced_data = simulation_data;
    
    % Extract base healthy signal
    time = simulation_data.time;
    vib_healthy = simulation_data.vibration;
    
    % Define fault scenarios
    fault_scenarios = {
        'healthy',      0.00, 0;    % No fault
        'imbalance',    0.05, 1;    % 1Hz imbalance
        'misalignment', 0.03, 2;    % 2Hz misalignment  
        'bearing',      0.08, 5;    % 5Hz bearing fault
        'resonance',    0.15, 25    % 25Hz resonance
    };
    
    enhanced_data.fault_scenarios = struct();
    
    for i = 1:size(fault_scenarios, 1)
        fault_name = fault_scenarios{i, 1};
        fault_amp = fault_scenarios{i, 2};
        fault_freq = fault_scenarios{i, 3};
        
        % Create fault signal
        if fault_amp > 0
            fault_signal = fault_amp * sin(2*pi*fault_freq*time);
            fault_vibration = vib_healthy + fault_signal;
        else
            fault_vibration = vib_healthy; % Healthy case
        end
        
        % Store fault scenario
        enhanced_data.fault_scenarios.(fault_name) = struct(...
            'vibration', fault_vibration, ...
            'amplitude', fault_amp, ...
            'frequency', fault_freq, ...
            'time', time ...
        );
    end
    
    fprintf('✅ Created %d fault scenarios\n', size(fault_scenarios, 1));
end

function fault_predictions = analyze_shaft_faults(enhanced_data)
    % COMPREHENSIVE FAULT ANALYSIS FOR SHAFT SYSTEM
    
    fprintf('\n=== PERFORMING SHAFT FAULT ANALYSIS ===\n');
    
    fault_predictions = struct();
    scenarios = fieldnames(enhanced_data.fault_scenarios);
    
    for i = 1:length(scenarios)
        scenario = scenarios{i};
        scenario_data = enhanced_data.fault_scenarios.(scenario);
        
        fprintf('Analyzing scenario: %s\n', scenario);
        
        % Analyze this fault scenario
        analysis = analyze_single_scenario(scenario_data, scenario);
        
        fault_predictions.(scenario) = analysis;
    end
    
    % Compare all scenarios
    fault_predictions.comparison = compare_scenarios(fault_predictions);
    
    fprintf('✅ Analyzed %d fault scenarios\n', length(scenarios));
end

function analysis = analyze_single_scenario(scenario_data, scenario_name)
    % ANALYZE A SINGLE FAULT SCENARIO
    
    vibration = scenario_data.vibration;
    time = scenario_data.time;
    
    analysis = struct();
    analysis.scenario_name = scenario_name;
    
    % 1. TIME DOMAIN ANALYSIS
    analysis.time_domain = time_domain_analysis_shaft(vibration);
    
    % 2. FREQUENCY DOMAIN ANALYSIS
    analysis.frequency_domain = frequency_domain_analysis_shaft(vibration, time);
    
    % 3. FAULT DETECTION
    analysis.fault_detection = detect_shaft_faults(analysis);
    
    % 4. SEVERITY ASSESSMENT
    analysis.severity = assess_fault_severity(analysis);
    
    % 5. MAINTENANCE RECOMMENDATIONS
    analysis.maintenance = generate_shaft_maintenance_recommendations(analysis);
end

function results = time_domain_analysis_shaft(vibration)
    % SHAFT-SPECIFIC TIME DOMAIN ANALYSIS
    
    results = struct();
    
    % Basic statistics
    results.rms = rms(vibration);
    results.peak = max(abs(vibration));
    results.peak_to_peak = max(vibration) - min(vibration);
    
    % Advanced indicators
    results.crest_factor = results.peak / results.rms;
    results.kurtosis = kurtosis(vibration);
    results.skewness = skewness(vibration);
    
    % Shaft-specific metrics
    results.zero_crossing_rate = sum(diff(sign(vibration)) ~= 0) / length(vibration);
    
    % Industry standards for shaft vibration (ISO 10816)
    if results.rms < 0.1
        results.health_status = 'Good';
        results.health_color = 'green';
    elseif results.rms < 0.2
        results.health_status = 'Satisfactory';
        results.health_color = 'yellow';
    elseif results.rms < 0.4
        results.health_status = 'Unsatisfactory';
        results.health_color = 'orange';
    else
        results.health_status = 'Unacceptable';
        results.health_color = 'red';
    end
end

function results = frequency_domain_analysis_shaft(vibration, time)
    % SHAFT-SPECIFIC FREQUENCY DOMAIN ANALYSIS
    
    % Compute FFT
    Fs = 1/mean(diff(time));
    L = length(vibration);
    
    % Apply windowing for better frequency analysis
    window = hann(L);
    vibration_windowed = vibration .* window;
    
    Y = fft(vibration_windowed);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;
    
    results = struct();
    results.frequencies = f;
    results.magnitudes = P1;
    
    % Find dominant frequencies
    [peak_mag, peak_idx] = max(P1);
    results.dominant_frequency = f(peak_idx);
    results.dominant_magnitude = peak_mag;
    
    % Find top 5 frequencies
    [sorted_mags, sorted_idx] = sort(P1, 'descend');
    results.top_frequencies = f(sorted_idx(1:5));
    results.top_magnitudes = sorted_mags(1:5);
    
    % Energy in typical fault frequency bands
    fault_bands = {
        'imbalance',        0.5, 2.5;    % 0.5-2.5 Hz (1X running speed)
        'misalignment',     2.5, 5;      % 2.5-5 Hz (2X running speed)  
        'bearing',          5, 50;       % 5-50 Hz (bearing frequencies)
        'resonance',        50, 100      % 50-100 Hz (structural resonance)
    };
    
    total_energy = sum(P1.^2);
    
    for i = 1:size(fault_bands, 1)
        band_name = fault_bands{i, 1};
        low_freq = fault_bands{i, 2};
        high_freq = fault_bands{i, 3};
        
        band_mask = (f >= low_freq) & (f <= high_freq);
        band_energy = sum(P1(band_mask).^2);
        results.([band_name '_energy_ratio']) = band_energy / total_energy;
    end
end

function fault_detection = detect_shaft_faults(analysis)
    % DETECT SPECIFIC SHAFT FAULTS
    
    td = analysis.time_domain;
    fd = analysis.frequency_domain;
    
    fault_detection = struct();
    
    % Imbalance detection (high 1X component)
    fault_detection.imbalance = fd.imbalance_energy_ratio > 0.3;
    fault_detection.imbalance_confidence = min(fd.imbalance_energy_ratio * 2, 1);
    
    % Misalignment detection (high 2X component)  
    fault_detection.misalignment = fd.misalignment_energy_ratio > 0.2;
    fault_detection.misalignment_confidence = min(fd.misalignment_energy_ratio * 3, 1);
    
    % Bearing fault detection (high frequency content)
    fault_detection.bearing = fd.bearing_energy_ratio > 0.15;
    fault_detection.bearing_confidence = min(fd.bearing_energy_ratio * 4, 1);
    
    % Resonance detection
    fault_detection.resonance = fd.resonance_energy_ratio > 0.1;
    fault_detection.resonance_confidence = min(fd.resonance_energy_ratio * 5, 1);
    
    % Overall health score (0-100%)
    health_factors = [
        1 - min(td.rms/0.4, 1),          % RMS health
        1 - min((td.crest_factor-2)/4, 1), % Crest factor health
        1 - min((td.kurtosis-3)/5, 1)    % Kurtosis health
    ];
    
    fault_detection.health_score = mean(health_factors) * 100;
    
    % Severity classification
    if fault_detection.health_score >= 80
        fault_detection.severity = 'Normal';
        fault_detection.urgency = 'Low';
    elseif fault_detection.health_score >= 60
        fault_detection.severity = 'Minor';
        fault_detection.urgency = 'Medium';
    elseif fault_detection.health_score >= 40
        fault_detection.severity = 'Moderate';
        fault_detection.urgency = 'High';
    else
        fault_detection.severity = 'Severe';
        fault_detection.urgency = 'Critical';
    end
end

function severity = assess_fault_severity(analysis)
    % ASSESS OVERALL FAULT SEVERITY
    
    fd = analysis.fault_detection;
    
    severity = struct();
    severity.overall_score = fd.health_score;
    severity.level = fd.severity;
    severity.urgency = fd.urgency;
    
    % Calculate Remaining Useful Life (RUL) in hours
    switch fd.severity
        case 'Normal'
            severity.rul_hours = 2000;
        case 'Minor'
            severity.rul_hours = 1000;
        case 'Moderate'
            severity.rul_hours = 500;
        case 'Severe'
            severity.rul_hours = 100;
    end
    
    % Next inspection date (80% of RUL)
    severity.next_inspection = datetime('now') + hours(severity.rul_hours * 0.8);
end

function maintenance = generate_shaft_maintenance_recommendations(analysis)
    % GENERATE SHAFT-SPECIFIC MAINTENANCE RECOMMENDATIONS
    
    fd = analysis.fault_detection;
    
    maintenance = struct();
    maintenance.recommendations = {};
    maintenance.priority = 'Routine';
    
    % Specific recommendations based on detected faults
    if fd.imbalance
        maintenance.recommendations{end+1} = 'Perform dynamic balancing of rotating assembly';
        maintenance.priority = 'High';
    end
    
    if fd.misalignment
        maintenance.recommendations{end+1} = 'Check and correct shaft alignment using laser alignment tools';
        maintenance.priority = 'High';
    end
    
    if fd.bearing
        maintenance.recommendations{end+1} = 'Inspect bearings for wear and replace if necessary';
        maintenance.priority = 'High';
    end
    
    if fd.resonance
        maintenance.recommendations{end+1} = 'Investigate and address structural resonance issues';
        maintenance.priority = 'Medium';
    end
    
    % General maintenance based on severity
    if fd.health_score < 70
        maintenance.recommendations{end+1} = 'Perform comprehensive vibration analysis';
    end
    
    if fd.health_score < 50
        maintenance.recommendations{end+1} = 'Schedule shutdown for detailed inspection';
        maintenance.priority = 'Critical';
    end
    
    % Always include basic maintenance
    maintenance.recommendations{end+1} = 'Check lubrication levels and quality';
    maintenance.recommendations{end+1} = 'Inspect couplings and seals for wear';
    
    % Remove duplicates and sort by importance
    maintenance.recommendations = unique(maintenance.recommendations, 'stable');
end

function comparison = compare_scenarios(fault_predictions)
    % COMPARE ALL FAULT SCENARIOS
    
    scenarios = fieldnames(fault_predictions);
    scenarios = scenarios(~strcmp(scenarios, 'comparison'));
    
    comparison = struct();
    
    for i = 1:length(scenarios)
        scenario = scenarios{i};
        analysis = fault_predictions.(scenario);
        
        comparison.health_scores(i) = analysis.fault_detection.health_score;
        comparison.rms_values(i) = analysis.time_domain.rms;
        comparison.crest_factors(i) = analysis.time_domain.crest_factor;
        comparison.scenario_names{i} = scenario;
    end
    
    % Find best and worst scenarios
    [~, best_idx] = max(comparison.health_scores);
    [~, worst_idx] = min(comparison.health_scores);
    
    comparison.best_scenario = comparison.scenario_names{best_idx};
    comparison.worst_scenario = comparison.scenario_names{worst_idx};
    comparison.performance_range = range(comparison.health_scores);
end

function generate_digital_twin_report(fault_predictions)
    % GENERATE COMPREHENSIVE DIGITAL TWIN REPORT
    
    fprintf('\n=== DIGITAL TWIN SHAFT ANALYSIS REPORT ===\n');
    fprintf('Generated: %s\n', datestr(now));
    fprintf('Model: shaft_twin_base (Simscape)\n');
    fprintf('\n');
    
    scenarios = fieldnames(fault_predictions);
    scenarios = scenarios(~strcmp(scenarios, 'comparison'));
    
    % Executive Summary
    fprintf('EXECUTIVE SUMMARY:\n');
    fprintf('  Best Scenario: %s (Score: %.1f%%)\n', ...
        fault_predictions.comparison.best_scenario, ...
        max(fault_predictions.comparison.health_scores));
    fprintf('  Worst Scenario: %s (Score: %.1f%%)\n', ...
        fault_predictions.comparison.worst_scenario, ...
        min(fault_predictions.comparison.health_scores));
    fprintf('  Performance Range: %.1f%%\n', fault_predictions.comparison.performance_range);
    fprintf('\n');
    
    % Detailed Scenario Analysis
    fprintf('DETAILED SCENARIO ANALYSIS:\n');
    for i = 1:length(scenarios)
        scenario = scenarios{i};
        analysis = fault_predictions.(scenario);
        fd = analysis.fault_detection;
        
        fprintf('\n  SCENARIO: %s\n', upper(scenario));
        fprintf('    Health Score: %.1f%% (%s)\n', fd.health_score, fd.severity);
        fprintf('    RMS Vibration: %.4f (%s)\n', analysis.time_domain.rms, analysis.time_domain.health_status);
        fprintf('    Crest Factor: %.2f\n', analysis.time_domain.crest_factor);
        fprintf('    Dominant Frequency: %.1f Hz\n', analysis.frequency_domain.dominant_frequency);
        
        % Detected Faults
        faults_detected = {};
        if fd.imbalance, faults_detected{end+1} = 'Imbalance'; end
        if fd.misalignment, faults_detected{end+1} = 'Misalignment'; end
        if fd.bearing, faults_detected{end+1} = 'Bearing Fault'; end
        if fd.resonance, faults_detected{end+1} = 'Resonance'; end
        
        if isempty(faults_detected)
            fprintf('    Detected Faults: None\n');
        else
            fprintf('    Detected Faults: %s\n', strjoin(faults_detected, ', '));
        end
        
        % Top Maintenance Recommendation
        if ~isempty(analysis.maintenance.recommendations)
            fprintf('    Key Action: %s\n', analysis.maintenance.recommendations{1});
        end
    end
    
    fprintf('\n=== END OF REPORT ===\n');
end

function create_fault_dashboard(fault_predictions)
    % CREATE INTERACTIVE FAULT ANALYSIS DASHBOARD
    
    fprintf('\nCreating interactive dashboard...\n');
    
    fig = figure('Name', 'Shaft Digital Twin Dashboard', ...
                 'Position', [100, 100, 1200, 800], ...
                 'Color', 'white');
    
    scenarios = fieldnames(fault_predictions);
    scenarios = scenarios(~strcmp(scenarios, 'comparison'));
    
    % 1. Health Scores Bar Chart
    subplot(2, 3, 1);
    health_scores = arrayfun(@(x) fault_predictions.(scenarios{x}).fault_detection.health_score, 1:length(scenarios));
    bar(health_scores, 'FaceColor', 'flat');
    
    for i = 1:length(scenarios)
        if health_scores(i) >= 80
            color = [0, 0.8, 0]; % Green
        elseif health_scores(i) >= 60
            color = [1, 0.8, 0]; % Yellow
        elseif health_scores(i) >= 40
            color = [1, 0.5, 0]; % Orange
        else
            color = [1, 0, 0]; % Red
        end
        bar(i, health_scores(i), 'FaceColor', color);
        hold on;
    end
    
    set(gca, 'XTickLabel', scenarios);
    xtickangle(45);
    ylabel('Health Score (%)');
    title('Shaft Health by Scenario');
    grid on;
    
    % 2. Fault Detection Radar Chart
    subplot(2, 3, 2);
    fault_types = {'imbalance', 'misalignment', 'bearing', 'resonance'};
    fault_data = zeros(length(scenarios), length(fault_types));
    
    for i = 1:length(scenarios)
        for j = 1:length(fault_types)
            if fault_predictions.(scenarios{i}).fault_detection.([fault_types{j}])
                fault_data(i, j) = fault_predictions.(scenarios{i}).fault_detection.([fault_types{j} '_confidence']);
            end
        end
    end
    
    spider_plot(fault_data, 'Labels', fault_types, 'Legend', scenarios);
    title('Fault Detection Confidence');
    
    % 3. Vibration Statistics
    subplot(2, 3, 3);
    rms_values = arrayfun(@(x) fault_predictions.(scenarios{x}).time_domain.rms, 1:length(scenarios));
    crest_factors = arrayfun(@(x) fault_predictions.(scenarios{x}).time_domain.crest_factor, 1:length(scenarios));
    
    yyaxis left;
    bar(rms_values);
    ylabel('RMS Vibration');
    
    yyaxis right;
    plot(crest_factors, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    ylabel('Crest Factor');
    
    set(gca, 'XTickLabel', scenarios);
    xtickangle(45);
    title('Vibration Statistics');
    legend('RMS', 'Crest Factor');
    grid on;
    
    % 4. Maintenance Recommendations
    subplot(2, 3, 4);
    maintenance_counts = zeros(length(scenarios), 1);
    for i = 1:length(scenarios)
        maintenance_counts(i) = length(fault_predictions.(scenarios{i}).maintenance.recommendations);
    end
    
    bar(maintenance_counts);
    set(gca, 'XTickLabel', scenarios);
    xtickangle(45);
    ylabel('Number of Maintenance Actions');
    title('Maintenance Complexity');
    grid on;
    
    % 5. Frequency Analysis
    subplot(2, 3, 5);
    dominant_freqs = arrayfun(@(x) fault_predictions.(scenarios{x}).frequency_domain.dominant_frequency, 1:length(scenarios));
    stem(dominant_freqs, 'filled', 'LineWidth', 2);
    set(gca, 'XTickLabel', scenarios);
    xtickangle(45);
    ylabel('Dominant Frequency (Hz)');
    title('Dominant Vibration Frequencies');
    grid on;
    
    % 6. Urgency Indicator
    subplot(2, 3, 6);
    urgency_levels = {'Low', 'Medium', 'High', 'Critical'};
    urgency_values = [1, 2, 3, 4];
    
    scenario_urgency = zeros(1, length(scenarios));
    for i = 1:length(scenarios)
        urgency_str = fault_predictions.(scenarios{i}).fault_detection.urgency;
        scenario_urgency(i) = urgency_values(strcmp(urgency_levels, urgency_str));
    end
    
    [sorted_urgency, sort_idx] = sort(scenario_urgency, 'descend');
    sorted_scenarios = scenarios(sort_idx);
    
    h = bar(sorted_urgency, 'FaceColor', 'flat');
    for i = 1:length(sorted_urgency)
        switch sorted_urgency(i)
            case 1, color = [0, 1, 0];   % Green
            case 2, color = [1, 1, 0];   % Yellow
            case 3, color = [1, 0.5, 0]; % Orange
            case 4, color = [1, 0, 0];   % Red
        end
        h.CData(i, :) = color;
    end
    
    set(gca, 'XTickLabel', sorted_scenarios);
    xtickangle(45);
    ylabel('Urgency Level');
    title('Maintenance Urgency');
    yticks(1:4);
    yticklabels(urgency_levels);
    
    sgtitle('Shaft Digital Twin - Fault Analysis Dashboard', 'FontSize', 16, 'FontWeight', 'bold');
    
    fprintf('✅ Interactive dashboard created\n');
end

% Helper function for radar chart
function spider_plot(data, varargin)
    % Simple spider plot implementation
    [n_scenarios, n_vars] = size(data);
    angles = linspace(0, 2*pi, n_vars+1);
    angles = angles(1:end-1);
    
    % Normalize data to 0-1 scale
    data_norm = data ./ max(data(:));
    
    hold on;
    for i = 1:n_scenarios
        radii = [data_norm(i, :), data_norm(i, 1)];
        polarplot(angles, radii, 'LineWidth', 2);
    end
    
    thetaticks(rad2deg(angles));
    thetaticklabels(varargin{2});
    rlim([0 1]);
end

function data = find_vibration_data(simOut)
    % TRY TO FIND VIBRATION DATA IN SIMULATION OUTPUT
    data = struct();
    
    % Look for common vibration signal names
    possible_names = {'vibration', 'Vibration', 'vib', 'accel', 'Acceleration'};
    
    for i = 1:length(possible_names)
        if isfield(simOut, possible_names{i})
            data.vibration = simOut.(possible_names{i}).Data;
            data.time = simOut.(possible_names{i}).Time;
            fprintf('Found vibration data: %s\n', possible_names{i});
            return;
        end
    end
    
    % If no vibration data found, use first available signal
    fields = fieldnames(simOut);
    if ~isempty(fields)
        first_field = fields{1};
        if isstruct(simOut.(first_field)) && isfield(simOut.(first_field), 'Data')
            data.vibration = simOut.(first_field).Data;
            data.time = simOut.(first_field).Time;
            fprintf('Using available data: %s\n', first_field);
        end
    end
end

function data = create_sample_shaft_data()
    % CREATE SAMPLE SHAFT DATA FOR DEMONSTRATION
    fprintf('Creating realistic shaft vibration data...\n');
    
    Fs = 1000; % Sampling frequency (Hz)
    t = 0:1/Fs:5; % 5 seconds
    
    % Healthy shaft vibration (base signal)
    healthy_vib = 0.1 * sin(2*pi*25*t) + 0.02 * randn(size(t));
    
    data.time = t';
    data.vibration = healthy_vib';
    data.torque = 50 + 10 * sin(2*pi*0.5*t)';
    data.omega = 100 + 20 * sin(2*pi*1*t)';
    
    fprintf('Created sample data with %d samples\n', length(t));
end