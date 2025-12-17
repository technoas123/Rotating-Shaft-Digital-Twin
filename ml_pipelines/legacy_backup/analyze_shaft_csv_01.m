%% File: ml_pipelines/01_system_identification/01_analyze_shaft_csv_FIXED.m
% ========================================================================
% Purpose:
%   Quick exploratory analysis of ONE shaft CSV file to:
%     - Inspect timestamp column and estimate sampling interval / rate
%     - Inspect acceleration ranges and likely units
%     - Compute basic RMS and dominant frequency on a small segment
%
% Input:
%   data/raw/01 - m1_half_shaft_speed_no_mechanical_load.csv
%
% Output:
%   data/processed/analysis_corrected.mat  (struct with basic info)
%
% Notes:
%   This script is mainly for understanding the dataset, not for training.
% ========================================================================
function analyze_shaft_csv_fixed()

    fprintf('🚀 RE-ANALYZING WITH CORRECT TIMESTAMP INTERPRETATION\n');
    fprintf('=====================================================\n\n');
    
    % ---- Resolve project root & data folders ----
    thisFile    = mfilename('fullpath');
    scriptDir   = fileparts(thisFile);          % ...\01_system_identification
    projectRoot = fileparts(fileparts(scriptDir));
    rawDir      = fullfile(projectRoot,'data','raw');
    procDir     = fullfile(projectRoot,'data','processed');
    if ~exist(procDir,'dir'); mkdir(procDir); end
    
    % Use first file (healthy, no load)
    filename = '01 - m1_half_shaft_speed_no_mechanical_load.csv';
    filepath = fullfile(rawDir, filename);
    
    if ~exist(filepath,'file')
        error('CSV file not found: %s', filepath);
    end
    
    fprintf('🔍 Analyzing: %s\n', filename);
    
    % ---- Read first 50,000 samples ----
    fid = fopen(filepath, 'r');
    header_line = fgetl(fid); %#ok<NASGU>  % header not used further, but consumed
    
    fprintf('📥 Reading first 50,000 samples...\n');
    data = textscan(fid, '%f%f%f%f', 50000, 'Delimiter', ',');
    fclose(fid);
    
    % Convert to arrays
    timestamp = data{1};
    accX = data{2};
    accY = data{3};
    accZ = data{4};
    
    fprintf('\n📊 TIMESTAMP ANALYSIS:\n');
    fprintf('   First timestamp: %.0f\n', timestamp(1));
    fprintf('   Last timestamp (in read data): %.0f\n', timestamp(end));
    fprintf('   Difference: %.0f\n', timestamp(end) - timestamp(1));
    fprintf('   Number of samples: %d\n', length(timestamp));
    
    % ---- Time-interval analysis ----
    time_diffs = diff(timestamp);
    
    fprintf('\n⏱️  TIME INTERVAL ANALYSIS:\n');
    fprintf('   Min interval: %.2f\n', min(time_diffs));
    fprintf('   Max interval: %.2f\n', max(time_diffs));
    fprintf('   Mean interval: %.2f\n', mean(time_diffs));
    fprintf('   Std of intervals: %.2f\n', std(time_diffs));
    
    [counts, edges] = histcounts(time_diffs, 50);
    [max_count, max_idx] = max(counts);
    common_interval = (edges(max_idx) + edges(max_idx+1)) / 2;
    
    fprintf('   Most common interval: %.2f (appears %d times)\n', common_interval, max_count);
    
    fprintf('\n🔍 POSSIBLE INTERPRETATIONS:\n');
    
    sampling_rate_hz = NaN;
    
    % Interpretation 1: microseconds
    if common_interval < 1000
        fprintf('   1. MICROSECONDS (µs):\n');
        interval_seconds = common_interval / 1e6;
        sampling_rate_hz = 1 / interval_seconds;
        fprintf('      Interval: %.0f µs = %.6f seconds\n', common_interval, interval_seconds);
        fprintf('      Sampling rate: %.2f Hz\n', sampling_rate_hz);
    end
    
    % Interpretation 2: milliseconds
    if common_interval >= 1000 && common_interval < 1e6
        fprintf('   2. MILLISECONDS (ms):\n');
        interval_seconds = common_interval / 1e3;
        sampling_rate_hz = 1 / interval_seconds;
        fprintf('      Interval: %.0f ms = %.3f seconds\n', common_interval, interval_seconds);
        fprintf('      Sampling rate: %.2f Hz\n', sampling_rate_hz);
    end
    
    % Interpretation 3: sample indices
    if std(time_diffs) < 1
        fprintf('   3. SAMPLE NUMBERS (not time):\n');
        fprintf('      These might be sample indices, not timestamps!\n');
        fprintf('      Consistent difference: %.0f\n', common_interval);
    end
    
    % ---- Acceleration statistics ----
    fprintf('\n📈 ACCELERATION PATTERN ANALYSIS:\n');
    fprintf('   AccX range: %.0f to %.0f (likely ADC counts or mg)\n', min(accX), max(accX));
    fprintf('   AccY range: %.0f to %.0f\n', min(accY), max(accY));
    fprintf('   AccZ range: %.0f to %.0f (includes ~16,000 offset = gravity?)\n', min(accZ), max(accZ));
    
    fprintf('\n🔬 UNIT DETERMINATION:\n');
    max_abs_acc = max([abs(min(accX)), abs(max(accX)), ...
                       abs(min(accY)), abs(max(accY))]);
    
    if max_abs_acc < 3000
        fprintf('   Likely ±2g range in mg units (milli-g)\n');
        fprintf('   Divide by 1000 to get g units\n');
    elseif max_abs_acc < 7000
        fprintf('   Likely ±4g or ±8g range\n');
    else
        fprintf('   Large values - might be raw ADC counts\n');
    end
    
    % ---- Quick vibration analysis segment ----
    segment_size = 2000;
    if length(accX) > segment_size && ~isnan(sampling_rate_hz) && sampling_rate_hz > 0
        fprintf('\n📊 VIBRATION ANALYSIS (first %d samples):\n', segment_size);
        
        vib_x = accX(1:segment_size) - mean(accX(1:segment_size));
        vib_y = accY(1:segment_size) - mean(accY(1:segment_size));
        vib_z = accZ(1:segment_size) - mean(accZ(1:segment_size));
        
        rms_x = sqrt(mean(vib_x.^2));
        rms_y = sqrt(mean(vib_y.^2));
        rms_z = sqrt(mean(vib_z.^2));
        
        fprintf('   RMS vibration levels:\n');
        fprintf('      AccX: %.2f (raw units)\n', rms_x);
        fprintf('      AccY: %.2f (raw units)\n', rms_y);
        fprintf('      AccZ: %.2f (raw units)\n', rms_z);
        
        [freq_x, amp_x] = find_dominant_frequency(vib_x, sampling_rate_hz);
        [freq_y, amp_y] = find_dominant_frequency(vib_y, sampling_rate_hz);
        [freq_z, amp_z] = find_dominant_frequency(vib_z, sampling_rate_hz);
        
        fprintf('\n   Dominant frequencies (assuming fs = %.2f Hz):\n', sampling_rate_hz);
        fprintf('      AccX: %.2f Hz (ampl: %.2f)\n', freq_x, amp_x);
        fprintf('      AccY: %.2f Hz (ampl: %.2f)\n', freq_y, amp_y);
        fprintf('      AccZ: %.2f Hz (ampl: %.2f)\n', freq_z, amp_z);
    else
        fprintf('\n   Skipping vibration FFT (sampling rate unknown or not enough samples).\n');
    end
    
    % ---- Save corrected analysis ----
    analysis = struct();
    analysis.filename        = filename;
    analysis.timestamp_units = 'need_determination';
    analysis.common_interval = common_interval;
    analysis.acc_units       = 'raw_adc_counts_likely';
    analysis.acc_ranges      = [min(accX), max(accX); ...
                                min(accY), max(accY); ...
                                min(accZ), max(accZ)];
    
    save(fullfile(procDir,'analysis_corrected.mat'), 'analysis');
    fprintf('\n💾 Corrected analysis saved to data\\processed\\analysis_corrected.mat\n');
    
    fprintf('\n🎯 RECOMMENDATION:\n');
    fprintf('   1. The "Timestamp" column is NOT in seconds.\n');
    fprintf('   2. Most likely: microseconds or sample indices.\n');
    fprintf('   3. Acceleration values: likely raw ADC counts or mg.\n');
    fprintf('   4. For feature extraction, we can:\n');
    fprintf('      a) Use sample indices as time when fs is fixed.\n');
    fprintf('      b) Convert acceleration to g units if calibration is known.\n');
end

function [dominant_freq, amplitude] = find_dominant_frequency(signal, fs)
    if nargin < 2 || fs <= 0
        dominant_freq = 0;
        amplitude = 0;
        return;
    end
    
    N = length(signal);
    Y = fft(signal);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:floor(N/2))/N;
    
    [amplitude, idx] = max(P1);
    dominant_freq = f(idx);
end