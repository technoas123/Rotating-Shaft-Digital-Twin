%% File: ml_pipelines/01_system_identification/
%        02_extract_shaft_features_CORRECTED.m
% ========================================================================
% Purpose:
%   Extract time‑domain vibration features from all available motor/shaft
%   CSV files to train the System Identification model.
%
%   - Reads all selected CSVs in data/raw/
%   - Splits each into 10‑second windows with 50% overlap
%   - For each window and each channel (AccX, AccY, AccZ):
%       * computes 12 statistical / shape features
%       * stacks into 36‑dimensional feature vectors
%   - Assigns synthetic [spring, damper, inertia] targets per file
%   - Saves:
%       data/processed/shaft_features.mat
%       data/processed/feature_names.mat
% ========================================================================
function extract_shaft_features_corrected()

    fprintf('🚀 EXTRACTING SHAFT FEATURES (CORRECTED)\n');
    fprintf('============================================\n\n');
    
    % ---- Resolve project directories ----
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);
    projectRoot = fileparts(fileparts(scriptDir));
    rawDir      = fullfile(projectRoot,'data','raw');
    procDir     = fullfile(projectRoot,'data','processed');
    if ~exist(procDir,'dir'); mkdir(procDir); end
    
    % Sampling rate from timestamp analysis (~1852 µs)
    fs = 540;  % Hz
    window_samples = 10 * fs;  % 10-second windows
    
    % ---- File list: all 20 mechanical/electrical cases you listed ----
    shaft_files = {
        '01 - m1_half_shaft_speed_no_mechanical_load.csv'
        '02 - m1_load_0.5Nm_half_speed.csv'
        '03 - m1_mechanically_imbalanced_half_speed.csv'
        '04 - m1_mechanically_imbalanced_half_speed.csv'
        '05 - m1_mechanically_imbalanced_load_0.5Nm_half_speed.csv'
        '11 - m1_mechanically_imbalanced_electrically_50_ohm_fault_half_speed.csv'
        '12 - m1_mechanically_imbalanced_electrically_100_ohm_fault_half_speed.csv'
        '13 - m1_mechanically_imbalanced_electrically_150_ohm_fault_half_speed.csv'
        '14 - m1_mechanically_imbalanced_electrically_50_ohm_fault_load_0.5Nm_half_speed.csv'
        '15 - m1_with_m2_mechanicaly_umbalanced_on_background_half_speed.csv'
        '16 - m1_mechanically_imbalanced_with_m2_normal_on_background_half_speed.csv'
        '17 - m1_mechanically_imbalanced_with_m2_mechanicaly_imbalanced_on_background_half_speed.csv'
        '18 - m1_load_0.5Nm_m2_mechanically_imbalanced_on_background_half_speed.csv'
        '19 - m1_mechanically_imbalanced_load_0.5Nm_m2_mechanically_imbalanced_on_background_half_speed.csv'
        '25 - m1_mechanically_imbalanced_electrically_50_ohm_fault_m2_imbalanced_on_background_half_speed.csv'
        '26 - m1_mechanically_umbalanced_electrically_50_ohm_fault_load_0.5Nm_m2_umbalanced_on_background_half_speed.csv'
        '27 - m1_mechanically_imbalanced_electrically_100_ohm_fault_m2_imbalanced_on_background_half_speed.csv'
        '28 - m1_mechanically_imbalanced_electrically_100_ohm_fault_load_0.5Nm_m2_imbalanced_on_background_half_speed.csv'
        '29 - m1_mechanically_imbalanced_electrically_150_ohm_fault_m2_imbalanced_on_background_half_speed.csv'
        '30 - m1_mechanically_imbalanced_electrically_150_ohm_fault_m2_imbalanced_on_background_rotated_half_speed.csv'
    };
    
    all_features      = [];
    file_labels       = [];
    parameter_targets = [];  % [spring, damper, inertia]
    
    fprintf('📊 Using sampling rate: %.0f Hz\n', fs);
    fprintf('📊 Window size: %d samples = 10 seconds\n\n', window_samples);
    
    for file_idx = 1:numel(shaft_files)
        filename = shaft_files{file_idx};
        filepath = fullfile(rawDir, filename);
        
        if ~exist(filepath,'file')
            fprintf('❌ Missing: %s\n', filename);
            continue;
        end
        
        fprintf('📁 Processing: %s\n', filename);
        
        try
            data = readtable(filepath);
            accX = data.AccX;
            accY = data.AccY;
            accZ = data.AccZ - mean(data.AccZ); % remove DC
            
            total_samples = numel(accX);
            fprintf('   Samples: %d (%.1f seconds)\n', ...
                    total_samples, total_samples/fs);
            
            if total_samples < window_samples
                fprintf('   ⚠️  File too small for 10 s windows\n');
                continue;
            end
            
            step_size   = floor(window_samples/2);  % 50% overlap
            num_windows = floor((total_samples-window_samples)/step_size) + 1;
            
            [spring, damper, inertia] = get_shaft_parameters(filename);
            
            fprintf('   Windows: %d | Params: spring=%.0f, damper=%.3f, inertia=%.3f\n', ...
                    num_windows, spring, damper, inertia);
            
            for w = 1:num_windows
                start_idx = (w-1)*step_size + 1;
                end_idx   = start_idx + window_samples - 1;
                
                winX = detrend(accX(start_idx:end_idx));
                winY = detrend(accY(start_idx:end_idx));
                winZ = detrend(accZ(start_idx:end_idx));
                
                fx = extract_12_features(winX);
                fy = extract_12_features(winY);
                fz = extract_12_features(winZ);
                
                feat_vec = [fx, fy, fz];  % 36‑dim
                
                all_features      = [all_features; feat_vec];
                file_labels       = [file_labels; file_idx];
                parameter_targets = [parameter_targets; [spring, damper, inertia]];
                
                if mod(w,5)==0
                    fprintf('     Window %d/%d\n', w, num_windows);
                end
            end
            
            fprintf('   ✅ Extracted %d feature vectors\n\n', num_windows);
            
        catch ME
            fprintf('   ❌ Error while processing %s: %s\n',filename,ME.message);
        end
    end
    
    % ---- Save results ----
    features_file = fullfile(procDir,'shaft_features.mat');
    save(features_file,'all_features','file_labels', ...
                      'parameter_targets','fs','shaft_files');
    fprintf('💾 SAVED TO: %s\n', features_file);
    fprintf('📊 Total windows: %d\n', size(all_features,1));
    fprintf('📊 Features per window: %d\n', size(all_features,2));
    fprintf('📊 Parameter targets shape: %s\n', mat2str(size(parameter_targets)));
    
    feature_names = generate_feature_names();
    save(fullfile(procDir,'feature_names.mat'),'feature_names');
end

% ---------- synthetic mapping: filename → [spring, damper, inertia] ------
function [spring, damper, inertia] = get_shaft_parameters(filename)

    spring_healthy = 500;    % N/m
    damper_healthy = 0.50;   % N·s/m
    inertia_base   = 0.124;  % kg·m²

    % Basic idea:
    % - pure mechanical imbalance → stiffness ↓, damping ↑
    % - electrical faults → primarily damping ↑, stiffness slightly ↓
    % - load and "m2" background → more severe (larger changes)

    if contains(filename,'01')          % healthy, no load
        spring = spring_healthy;
        damper = damper_healthy;

    elseif contains(filename,'02')      % healthy, with load
        spring = spring_healthy*1.04;
        damper = damper_healthy*1.10;

    elseif contains(filename,'03') || contains(filename,'04') % mech imbalance
        spring = spring_healthy*0.85;
        damper = damper_healthy*1.20;

    elseif contains(filename,'05')      % mech imbalance + load
        spring = spring_healthy*0.80;
        damper = damper_healthy*1.30;

    elseif contains(filename,'11')      % mech + 50Ω electrical fault
        spring = spring_healthy*0.90;
        damper = damper_healthy*1.25;

    elseif contains(filename,'12')      % mech + 100Ω fault
        spring = spring_healthy*0.88;
        damper = damper_healthy*1.30;

    elseif contains(filename,'13')      % mech + 150Ω fault
        spring = spring_healthy*0.86;
        damper = damper_healthy*1.35;

    elseif contains(filename,'14')      % mech + 50Ω + load
        spring = spring_healthy*0.82;
        damper = damper_healthy*1.40;

    elseif contains(filename,'15')      % m2 unbalanced background
        spring = spring_healthy*0.98;
        damper = damper_healthy*1.05;

    elseif contains(filename,'16')      % m1 fault, m2 normal
        spring = spring_healthy*0.88;
        damper = damper_healthy*1.25;

    elseif contains(filename,'17')      % both m1 & m2 mech imbalanced
        spring = spring_healthy*0.86;
        damper = damper_healthy*1.30;

    elseif contains(filename,'18')      % load + m2 imbalance
        spring = spring_healthy*0.84;
        damper = damper_healthy*1.30;

    elseif contains(filename,'19')      % m1 mech + load + m2 mech
        spring = spring_healthy*0.78;
        damper = damper_healthy*1.35;

    elseif contains(filename,'25')      % mech+50Ω + m2 imbalanced
        spring = spring_healthy*0.80;
        damper = damper_healthy*1.40;

    elseif contains(filename,'26')      % umbalanced + 50Ω + load + m2 umbalanced
        spring = spring_healthy*0.78;
        damper = damper_healthy*1.45;

    elseif contains(filename,'27')      % mech+100Ω + m2 imbalanced
        spring = spring_healthy*0.78;
        damper = damper_healthy*1.45;

    elseif contains(filename,'28')      % mech+100Ω + load + m2 imbalanced
        spring = spring_healthy*0.76;
        damper = damper_healthy*1.50;

    elseif contains(filename,'29')      % mech+150Ω + m2 imbalanced
        spring = spring_healthy*0.74;
        damper = damper_healthy*1.50;

    elseif contains(filename,'30')      % mech+150Ω + m2 imbalanced rotated
        spring = spring_healthy*0.72;
        damper = damper_healthy*1.55;

    else
        % fallback
        spring = spring_healthy;
        damper = damper_healthy;
    end

    inertia = inertia_base;

    % add small variation for realism
    spring = spring * (0.98 + 0.04*rand());
    damper = damper * (0.95 + 0.10*rand());
end

% ---------- 12 time‑domain features for one channel ----------------------
function features = extract_12_features(signal)
    signal = signal(:);
    signal = signal(isfinite(signal));
    if numel(signal) < 10
        features = zeros(1,12); return;
    end

    mean_val = mean(signal);
    rms_val  = sqrt(mean(signal.^2));
    std_val  = std(signal);
    skew_val = skewness(signal);
    kurt_val = kurtosis(signal);
    peak_to_peak = max(signal) - min(signal);

    if rms_val > 0
        crest_factor = max(abs(signal))/rms_val;
    else
        crest_factor = 0;
    end

    mean_abs = mean(abs(signal));
    if mean_abs > 0
        shape_factor   = rms_val/mean_abs;
        impulse_factor = max(abs(signal))/mean_abs;
    else
        shape_factor   = 0;
        impulse_factor = 0;
    end

    mean_sqrt = mean(sqrt(abs(signal)));
    if mean_sqrt > 0
        clearance_factor = max(abs(signal))/(mean_sqrt^2);
    else
        clearance_factor = 0;
    end

    energy = sum(signal.^2);

    [counts,~] = histcounts(signal,50);
    prob = counts/sum(counts);
    prob = prob(prob>0);
    if ~isempty(prob)
        entropy_val = -sum(prob.*log2(prob));
    else
        entropy_val = 0;
    end

    features = [mean_val, rms_val, std_val, skew_val, kurt_val, ...
                peak_to_peak, crest_factor, shape_factor, ...
                impulse_factor, clearance_factor, energy, entropy_val];
end

% ---------- Feature name strings ----------------------------------------
function names = generate_feature_names()
    channels   = {'AccX','AccY','AccZ'};
    base_names = {'Mean','RMS','Std','Skewness','Kurtosis', ...
                  'PeakToPeak','CrestFactor','ShapeFactor', ...
                  'ImpulseFactor','ClearanceFactor','Energy','Entropy'};
    names = {};
    for c = 1:numel(channels)
        for b = 1:numel(base_names)
            names{end+1} = sprintf('%s_%s',channels{c},base_names{b}); %#ok<AGROW>
        end
    end
end