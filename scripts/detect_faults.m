%% Digital Twin Project – Day 5: Machine‑Learning Fault Detection (toolbox‑free)
clear; clc;
disp('=== Day 5: ML‑Based Fault Detection ===')

root = fileparts(fileparts(mfilename('fullpath')));
resultsPath = fullfile(root,'results');
dataFile = fullfile(resultsPath,'rms_fft_metrics.csv');
Tbl = readtable(dataFile);

disp('Loaded feature table:');
disp(Tbl)

labels = string(Tbl.Condition);
RMS     = Tbl.RMS;
Freq    = Tbl.PeakFreq_Hz;

% ---------------------------------------------------------------------
% 1️⃣ Simple threshold‑based classifier (RMS)
% ---------------------------------------------------------------------
threshold = mean(RMS);
pred = repmat("Healthy",size(RMS));
pred(RMS > threshold) = "Faulty";   % classify high RMS as faulty

% Confusion matrix counts
TP = sum(pred=="Faulty" & labels=="Faulty");
TN = sum(pred=="Healthy" & labels=="Healthy");
FP = sum(pred=="Faulty" & labels=="Healthy");
FN = sum(pred=="Healthy" & labels=="Faulty");

accuracy  = (TP+TN)/(TP+TN+FP+FN);
precision = TP/(TP+FP+eps);
recall    = TP/(TP+FN+eps);

fprintf('\n--- Threshold‑Based Classifier ---\n');
fprintf('Decision threshold (RMS)   : %.2f\n',threshold);
fprintf('Accuracy  : %.2f  Precision  : %.2f  Recall  : %.2f\n',...
    accuracy,precision,recall);

% ---------------------------------------------------------------------
% 2️⃣ Tiny built‑in "feature‑based" rule (for demo)
% ---------------------------------------------------------------------
% Use both RMS and Frequency: low freq + high RMS => faulty
fault_score = rescale(RMS) .* (1 - rescale(Freq));   % 0→healthy, 1→faulty
confidence  = fault_score;                           % same 0–1 range
pred_rule   = repmat("Healthy",size(confidence));
pred_rule(confidence>0.5) = "Faulty";

AccuracyRule = mean(pred_rule==labels);
fprintf('\n--- Custom Two‑Feature Rule ---\nAccuracy : %.2f\n',AccuracyRule);

% Save results
Tbl.Prediction   = pred_rule;
Tbl.Confidence   = confidence;
Tbl.TrueLabel    = labels;

writetable(Tbl,fullfile(resultsPath,'fault_detection_results.csv'));
disp('✅  Results saved → results/fault_detection_results.csv');

disp('--- Classified table ---');
disp(Tbl(:,{'Condition','RMS','PeakFreq_Hz','Prediction','Confidence'}));