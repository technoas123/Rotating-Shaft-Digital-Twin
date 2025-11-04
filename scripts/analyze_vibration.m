%% =======================================================================
%  DIGITAL TWIN PROJECT – Day 4: Signal Processing Pipeline
%  Author : Jens Martensson / Team
%  Purpose: Compare healthy vs faulty shaft vibration data
%% =======================================================================

clear; clc; close all;
disp('=== Day 4: Processing healthy vs faulty vibration data ===')

% --- Locate project paths ------------------------------------------------
thisFile    = mfilename('fullpath');
projectRoot = fileparts(fileparts(thisFile));
dataPath    = fullfile(projectRoot,'data');
resultsPath = fullfile(projectRoot,'results');
if ~isfolder(resultsPath), mkdir(resultsPath); end

% --- Load data from .mat files ------------------------------------------
H = load(fullfile(dataPath,'healthy_run.mat'));
F = load(fullfile(dataPath,'faulty_run.mat'));
Tbl_h = H.data_healthy;
Tbl_f = F.data_faulty;

t_h = Tbl_h.Time(:);  x_h = Tbl_h.Vibration(:);
t_f = Tbl_f.Time(:);  x_f = Tbl_f.Vibration(:);

% --- Compute FFT & RMS ---------------------------------------------------
[resultH,specH] = local_fft_analysis(x_h,t_h);
[resultF,specF] = local_fft_analysis(x_f,t_f);

% --- Plot FFT comparison -------------------------------------------------
figure('Color','w','Name','FFT Comparison');
plot(specH.f,specH.P1,'b','LineWidth',1.3); hold on
plot(specF.f,specF.P1,'r','LineWidth',1.3);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
legend('Healthy','Faulty');
title('FFT Spectrum – Healthy vs Faulty Shaft');
grid on;
saveas(gcf,fullfile(resultsPath,'vibration_fft.png'));

% --- Display and save metrics -------------------------------------------
resultsTbl = table(["Healthy";"Faulty"], ...
                   [resultH.RMS; resultF.RMS], ...
                   [resultH.PeakFreq; resultF.PeakFreq], ...
                   'VariableNames',{'Condition','RMS','PeakFreq_Hz'});
disp('--- RMS and Peak Frequency metrics ---');
disp(resultsTbl);

writetable(resultsTbl,fullfile(resultsPath,'rms_fft_metrics.csv'));

disp('✅  Analysis complete. Results saved in results/ folder.');

%% =======================================================================
function [out,spec] = local_fft_analysis(signal,time)
% Detrend & compute FFT/RMS
    dt = mean(diff(time));
    Fs = 1/dt;
    L  = numel(signal);
    Y  = fft(signal - mean(signal));
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:floor(L/2))/L;

    [~,idx]    = max(P1);
    out.RMS     = sqrt(mean(signal.^2));
    out.PeakFreq = f(idx);

    spec.f  = f;
    spec.P1 = P1;
end