%% Digital Twin Project – Day 6: Dashboard Built in Code - FIXED VERSION
clear; close all; clc;
disp('=== Starting coded Digital‑Twin Dashboard ===')

root = fileparts(fileparts(mfilename('fullpath')));
dataPath    = fullfile(root,'data');
resultsPath = fullfile(root,'results');

%% ---------- UI LAYOUT ----------
fig = uifigure('Name','Digital Twin Dashboard','Position',[100 100 1000 600]);

% Axes
axTime   = uiaxes(fig,'Position',[30 350 450 220]);
title(axTime,'Vibration – Time Domain');

axFFT    = uiaxes(fig,'Position',[30 90 450 220]);
title(axFFT,'Vibration – FFT');

axTorque = uiaxes(fig,'Position',[520 350 450 180]);
title(axTorque,'Torque');

% Gauges & Lamp - FIXED PROPERTIES
gaugeRMS = uigauge(fig,'linear','Position',[560 230 120 70]);
gaugeRMS.Limits = [0 20];
gaugeRMS.ScaleColors = {'green','red'};
gaugeRMS.Value = 0;

gaugeSpeed = uigauge(fig,'linear','Position',[720 230 120 70]);
gaugeSpeed.Limits = [0 1000];
gaugeSpeed.Value = 0;

lampStatus = uilamp(fig,'Position',[880 260 30 30],'Color','green');

% Labels for gauges
uilabel(fig,'Position',[560 300 120 20],'Text','RMS Vibration','HorizontalAlignment','center');
uilabel(fig,'Position',[720 300 120 20],'Text','Speed (RPM)','HorizontalAlignment','center');
uilabel(fig,'Position',[870 300 50 20],'Text','Status','HorizontalAlignment','center');

% Knob and Button
uilabel(fig,'Position',[520 190 100 22],'Text','Select Mode:');
knob = uiknob(fig,'discrete','Position',[610 170 60 60], ...
              'Items',{'Healthy','Faulty'});
btn  = uibutton(fig,'push','Text','Run Analysis','Position',[720 180 120 35], ...
                'BackgroundColor',[0.2 0.6 1],'FontColor','white');

%% ---------- Callbacks ----------

btn.ButtonPushedFcn = @(src,event) runAnalysis();

    function runAnalysis()
        try
            modeSel = knob.Value;
            if isempty(modeSel)
                modeSel = 'Healthy'; % Default value
            end
            disp(['Running analysis for ' modeSel{1}]);
            
            file = fullfile(dataPath,[lower(modeSel{1}) '_run.mat']);
            if ~isfile(file)
                uialert(fig,'Data file not found. Run the simulations first.', ...
                            'Missing Data'); 
                return;
            end
            
            S = load(file);
            
            % Check data structure and extract
            if isfield(S, 'data_healthy') || isfield(S, 'data_faulty')
                % New table format
                fieldName = ['data_' lower(modeSel{1})];
                dataTbl = S.(fieldName);
                time = dataTbl.Time;
                vibration = dataTbl.Vibration;
                omega = dataTbl.Omega;
                torque = dataTbl.Torque;
            else
                % Old structure format
                time = S.out.vibration_signal.time;
                vibration = S.out.vibration_signal.signals.values;
                omega = S.out.omega_out.signals.values;
                torque = S.out.torque_out.signals.values;
            end
            
            % -- Time plot --
            cla(axTime);
            plot(axTime, time, vibration, 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
            xlabel(axTime, 'Time (s)'); 
            ylabel(axTime, 'Vibration');
            title(axTime, [modeSel{1} ' – Vibration Signal']); 
            grid(axTime, 'on');
            
            % -- FFT --
            cla(axFFT);
            [an, spect] = local_fft(vibration, time);
            plot(axFFT, spect.f, spect.P1, 'LineWidth', 1.5, 'Color', [0.85 0.33 0.1]);
            xlabel(axFFT, 'Frequency (Hz)'); 
            ylabel(axFFT, 'Amplitude');
            title(axFFT, [modeSel{1} ' – Frequency Spectrum']); 
            grid(axFFT, 'on');
            xlim(axFFT, [0 100]); % Focus on relevant frequencies
            
            % Update RMS gauge
            gaugeRMS.Value = an.RMS;
            
            % -- Torque plot --
            cla(axTorque);
            plot(axTorque, time, torque, 'LineWidth', 1.5, 'Color', [0.47 0.67 0.19]);
            xlabel(axTorque, 'Time (s)'); 
            ylabel(axTorque, 'Torque (N·m)');
            title(axTorque, [modeSel{1} ' – Torque']); 
            grid(axTorque, 'on');
            
            % -- Speed calculation and gauge --
            avgSpd = mean(omega) * 60 / (2*pi); % Convert rad/s to RPM
            gaugeSpeed.Value = avgSpd;
            
            % -- Status lamp --
            if strcmpi(modeSel{1}, 'Healthy')
                lampStatus.Color = 'green';
                statusMsg = '✅ System Healthy';
            else
                lampStatus.Color = 'red';
                statusMsg = '🚨 Fault Detected';
            end
            
            % -- Display results --
            msg = sprintf('%s\nRMS Vibration: %.4f\nAverage Speed: %.1f RPM\nPeak Frequency: %.2f Hz', ...
                           statusMsg, an.RMS, avgSpd, an.PeakFreq);
            uialert(fig, msg, [modeSel{1} ' Analysis Complete']);
            
        catch ME
            uialert(fig, sprintf('Error: %s', ME.message), 'Analysis Error');
        end
    end

%% ---------- Helper FFT ----------
function [out, spec] = local_fft(signal, time)
    dt = mean(diff(time)); 
    Fs = 1/dt; 
    N = numel(signal);
    
    % Remove DC offset and apply window
    signal_detrend = signal - mean(signal);
    window = hanning(N);
    signal_windowed = signal_detrend .* window;
    
    % Compute FFT
    Y = fft(signal_windowed);
    P2 = abs(Y/N); 
    P1 = P2(1:floor(N/2)+1); 
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:floor(N/2))/N;
    
    [~, idx] = max(P1);
    out.RMS = sqrt(mean(signal.^2));
    out.PeakFreq = f(idx);
    spec.f = f; 
    spec.P1 = P1;
end

%% ---------- Add Real-time Monitoring Button ----------
monitorBtn = uibutton(fig, 'push', 'Text', 'Start Real-time Monitor', ...
                      'Position', [520 130 150 35], ...
                      'BackgroundColor', [0.9 0.7 0.1], 'FontColor', 'white');

monitorBtn.ButtonPushedFcn = @(src, event) startRealTimeMonitor();

    function startRealTimeMonitor()
        % Simple real-time monitoring simulation
        uialert(fig, 'Real-time monitoring started. Close this to begin.', ...
                'Monitor Mode');
        
        % Create monitoring figure
        monitorFig = uifigure('Name', 'Real-time Monitor', 'Position', [200 200 800 400]);
        monitorAxes = uiaxes(monitorFig, 'Position', [50 50 700 300]);
        title(monitorAxes, 'Real-time Vibration Monitoring');
        xlabel(monitorAxes, 'Time (s)'); ylabel(monitorAxes, 'Vibration');
        grid(monitorAxes, 'on');
        
        % Simulate real-time data (you can replace this with actual data acquisition)
        for i = 1:100
            % Generate simulated real-time data
            t_monitor = (1:i) * 0.1;
            vib_monitor = 0.5 * sin(2*pi*5*t_monitor) + 0.1 * randn(1,i);
            
            % Update plot
            plot(monitorAxes, t_monitor, vib_monitor, 'b-', 'LineWidth', 1.5);
            title(monitorAxes, sprintf('Real-time Monitoring - Time: %.1fs', i*0.1));
            
            % Check for fault conditions
            current_rms = rms(vib_monitor);
            if current_rms > 0.8
                title(monitorAxes, sprintf('🚨 HIGH VIBRATION DETECTED - RMS: %.3f', current_rms), ...
                      'Color', 'red');
            end
            
            drawnow;
            pause(0.1); % Simulate 100ms update rate
        end
    end

disp('✅ Dashboard initialized. Click "Run Analysis" to begin.');