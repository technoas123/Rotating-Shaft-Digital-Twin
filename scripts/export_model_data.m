%% Day 4 – Manual Export of Healthy & Faulty Runs
% Author: Jens Martensson / Team
% You run the model manually between the two sections.
clear; clc;

root = fileparts(fileparts(mfilename('fullpath')));
dataPath = fullfile(root,'data');
if ~isfolder(dataPath), mkdir(dataPath); end

model = 'shaft_twin_base';
load_system(fullfile(root,'models',[model '.slx']));
set_param(model,'StopTime','5');

%% ------------------------------------------------------------------------
% STEP 1: Run Healthy case
% Ensure the fault/imbalance source is DISCONNECTED or COMMENTED OUT in the model.
disp('> Run #1 (Healthy system) ...');
outH = sim(model);

sig = outH.vibration_signal;
data_healthy = table(sig.time, sig.signals.values, ...
    'VariableNames',{'Time','Vibration'});
save(fullfile(dataPath,'healthy_run.mat'),'data_healthy');
disp('✅  Healthy data saved as data/healthy_run.mat')
fprintf('---- Now edit your model: UNCOMMENT or ENABLE fault wave, then rerun this script to the next line. ----\n');
keyboard   % pauses script so you can switch the model to "faulty"
%% ------------------------------------------------------------------------
% STEP 2: Run Faulty case
% At this point, you have enabled / un-commented the fault source in the model.
disp('> Run #2 (Faulty system) ...');
outF = sim(model);

sig = outF.vibration_signal;
data_faulty = table(sig.time, sig.signals.values, ...
    'VariableNames',{'Time','Vibration'});
save(fullfile(dataPath,'faulty_run.mat'),'data_faulty');
disp('✅  Faulty data saved as data/faulty_run.mat');

disp('✅  Both Healthy and Faulty data files now available in /data.');