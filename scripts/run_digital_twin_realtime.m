%% File: scripts/run_digital_twin_final.m
function run_digital_twin_final()
    clc; close all;
    fprintf('🚀 STARTING DIGITAL TWIN (LSTM EDITION - FINAL)\n');
    
    % --- Paths ---
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    modelsDir = fullfile(projectRoot, 'data', 'models');
    
    % --- Load Models ---
    load(fullfile(modelsDir, 'system_id_model.mat'), 'system_id_model');
    load(fullfile(modelsDir, 'degradation_lstm.mat'), 'net'); degradationNet = net;
    load(fullfile(modelsDir, 'rul_lstm_model.mat'), 'net'); rulNet = net;
    
    fprintf('✅ Models Loaded.\n');
    
    % --- Simulation Init ---
    K = 500; C = 0.5; J = 0.124; H = 100;
    history30 = zeros(36, 30); % Buffer for last 30 steps (36 features)
    
    % --- Live Loop ---
    nCycles = 50;
    
    figure('Name','Digital Twin Live Monitor','Color','w', 'Position', [100 100 1000 600]);
    subplot(2,2,1); hK = animatedline('Color','b','LineWidth',2); title('Stiffness (K)'); ylabel('N/m'); grid on;
    subplot(2,2,2); hC = animatedline('Color','r','LineWidth',2); title('Damping (C)'); ylabel('Ns/m'); grid on;
    subplot(2,2,3); hH = animatedline('Color','g','LineWidth',2); title('Health %'); ylim([0 110]); grid on;
    subplot(2,2,4); hR = animatedline('Color','k','LineWidth',2); title('RUL (Days)'); ylabel('Days'); grid on;
    
    for t = 1:nCycles
        % 1. Simulate 36 Features based on current K, C
        % Higher K → Lower RMS
        base_rms = 5000 / K; 
        f1 = [base_rms, zeros(1,11)] + randn(1,12)*0.1; % AccX
        f2 = [base_rms, zeros(1,11)] + randn(1,12)*0.1; % AccY
        f3 = [base_rms, zeros(1,11)] + randn(1,12)*0.1; % AccZ
        
        current_36_feats = [f1, f2, f3];
        
        % 2. Update History for LSTMs
        history30 = [history30(:, 2:end), current_36_feats'];
        
        % 3. Model 1: System ID (Sanity Check)
        k_est = predict(system_id_model.spring_model, current_36_feats);
        
        % 4. Model 2: Predict Degradation (LSTM)
        deltas = predict(degradationNet, {history30});
        dK = deltas(1); 
        dC = deltas(2);
        
        % 5. Model 3: Predict RUL (LSTM)
        rul_pred = predict(rulNet, {history30});
        
        % 6. Update Physics State with SAFETY
        K_new = K + dK;
        
        if K_new < 100
            fprintf('🔴 CRITICAL FAILURE DETECTED at Cycle %d! Stiffness K=%.1f < 100. Stopping.\n', t, K_new);
            break;
        end
        
        K = K_new;
        C = C + abs(dC);
        H = (K / 500) * 100;
        
        % 7. Visualize
        addpoints(hK, t, K);
        addpoints(hC, t, C);
        addpoints(hH, t, H);
        addpoints(hR, t, rul_pred);
        drawnow;
        
        fprintf('Cycle %d: K=%.1f (Est: %.1f), RUL=%.1f days\n', t, K, k_est, rul_pred);
        pause(0.1);
    end
    fprintf('✅ Demo Complete.\n');
end