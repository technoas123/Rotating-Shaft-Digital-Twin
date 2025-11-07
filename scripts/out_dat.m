%% ------------------------------------------------------------
%  DIGITAL TWIN – Healthy Shaft Combined Plot
%  Plots the 3 main signals exactly like the Simulink Scope
%  1. Angular velocity
%  2. Torque
%  3. Vibration
%% ------------------------------------------------------------

clc; clear; close all;

%% --- Run the simulation (or load existing results) -----------
modelName = 'shaft_twin_base';   % your Simulink model name (.slx)
disp('Simulating healthy shaft ...')
out = sim(modelName,'StopTime','5');   % change StopTime if required

%% --- Extract the three signals -------------------------------
omega_out        = out.omega_out;         % angular velocity
torque_out       = out.torque_out;        % torque
vibration_signal = out.vibration_signal;  % vibration

t   = omega_out.time;
w   = omega_out.signals.values;           % rad/s
T   = torque_out.signals.values;          % N·m
vib = vibration_signal.signals.values;    % angular accel or vib amplitude

%% --- Plot all three – scope‑style layout ---------------------
figure('Name','Healthy Shaft – 3‑Signal Scope','Color','w',...
       'Position',[100 100 900 600])

subplot(3,1,1)
plot(t,w,'b','LineWidth',1.3)
title('Angular Velocity  –  rises and stabilises')
xlabel('Time (s)'); ylabel('\omega (rad/s)')
grid on

subplot(3,1,2)
plot(t,T,'r','LineWidth',1.3)
title('Torque Output  –  constant steady‑state value')
xlabel('Time (s)'); ylabel('Torque (N·m)')
grid on

subplot(3,1,3)
plot(t,vib,'k','LineWidth',1)
title('Vibration Signal  –  low amplitude and stable')
xlabel('Time (s)'); ylabel('Vibration')
grid on

sgtitle('Healthy Shaft – Combined Scope Output','FontWeight','bold')

%% --- Optional: quick numeric summary --------------------------
fprintf('\n--- Healthy Shaft Summary ---\n');
fprintf('Average angular velocity  = %.3f  rad/s\n', mean(w));
fprintf('Average torque            = %.3f  N·m\n', mean(T));
fprintf('RMS vibration amplitude   = %.5f\n', rms(vib));
fprintf('-----------------------------\n');