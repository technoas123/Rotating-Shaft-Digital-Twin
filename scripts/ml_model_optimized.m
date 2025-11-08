classdef ml_model_optimized
    % ML_MODEL_OPTIMIZED - Complete ML system with training and prediction
    
    methods (Static)
        
        function train_and_save_models()
            % TRAIN AND SAVE MODELS - Complete training process
            fprintf('=== TRAINING ML MODELS ===\n\n');
            
            % STEP 1: Load and process data
            fprintf('1. 📊 Loading vibration data...\n');
            vibration_data = ml_model_optimized.load_vibration_data('../data');
            
            if isempty(fieldnames(vibration_data))
                fprintf('   ❌ No data loaded. Check data folder.\n');
                return;
            end
            
            % STEP 2: Train ML models
            fprintf('2. 🤖 Training ML models...\n');
            ml_models = ml_model_optimized.train_models(vibration_data);
            
            % STEP 3: Save models
            fprintf('3. 💾 Saving models...\n');
            ml_model_optimized.save_models(ml_models);
            
            fprintf('✅ Models trained and saved successfully!\n');
        end
        
        function [optimal_params, ml_models] = calibrate_from_models()
            % FAST CALIBRATION - Uses saved models
            fprintf('=== FAST ML CALIBRATION ===\n\n');
            
            % Load pre-trained models
            fprintf('1. 📥 Loading ML models...\n');
            ml_models = ml_model_optimized.load_models();
            
            if isempty(ml_models)
                fprintf('   ❌ No saved models found. Please run train_and_save_models() first.\n');
                optimal_params = [];
                return;
            end
            
            % Predict from models
            fprintf('2. 🎯 Predicting optimal parameters...\n');
            optimal_params = ml_model_optimized.predict_from_models(ml_models);
            
            fprintf('✅ Fast calibration complete!\n');
        end
        
        function vibration_data = load_vibration_data(data_folder)
            % LOAD VIBRATION DATA FROM CSV FILES
            fprintf('   Scanning: %s\n', data_folder);
            
            if ~isfolder(data_folder)
                fprintf('   ❌ Data folder not found: %s\n', data_folder);
                vibration_data = struct();
                return;
            end
            
            csv_files = dir(fullfile(data_folder, '*.csv'));
            vibration_data = struct();
            
            for i = 1:length(csv_files)
                filename = csv_files(i).name;
                filepath = fullfile(data_folder, filename);
                
                try
                    % Read CSV file
                    data_table = readtable(filepath);
                    
                    % Create valid field name
                    [~, dataset_name, ~] = fileparts(filename);
                    if ~isvarname(dataset_name)
                        dataset_name = ['dataset_', dataset_name];
                    end
                    
                    % Store data
                    vibration_data.(dataset_name) = struct();
                    vibration_data.(dataset_name).V_in = data_table.V_in;
                    vibration_data.(dataset_name).Measured_RPM = data_table.Measured_RPM;
                    vibration_data.(dataset_name).Vibration_1 = data_table.Vibration_1;
                    vibration_data.(dataset_name).Vibration_2 = data_table.Vibration_2;
                    vibration_data.(dataset_name).Vibration_3 = data_table.Vibration_3;
                    
                    % Extract features
                    vibration_data.(dataset_name).features = ml_model_optimized.extract_features(...
                        data_table.Vibration_1, data_table.Vibration_2, data_table.Vibration_3, ...
                        data_table.Measured_RPM, data_table.V_in);
                    
                    fprintf('   ✅ %s: %d samples\n', filename, height(data_table));
                    
                catch ME
                    fprintf('   ❌ Error reading %s: %s\n', filename, ME.message);
                end
            end
            
            fprintf('   📊 Loaded %d datasets\n', length(fieldnames(vibration_data)));
        end
        
        function ml_models = train_models(vibration_data)
            % TRAIN ML MODELS
            dataset_names = fieldnames(vibration_data);
            
            % Prepare training data
            features = [];
            targets_spring = [];
            targets_damper = [];
            targets_inertia = [];
            
            for i = 1:length(dataset_names)
                data = vibration_data.(dataset_names{i});
                features = [features; data.features.vector];
                
                [spring_k, damper_c, inertia_j] = ml_model_optimized.calculate_targets(data);
                targets_spring = [targets_spring; spring_k];
                targets_damper = [targets_damper; damper_c];
                targets_inertia = [targets_inertia; inertia_j];
            end
            
            % Train models
            ml_models = struct();
            ml_models.spring_model = fitrtree(features, targets_spring, 'MinLeafSize', 10);
            ml_models.damper_model = fitrtree(features, targets_damper, 'MinLeafSize', 10);
            ml_models.inertia_model = fitrtree(features, targets_inertia, 'MinLeafSize', 10);
            
            fprintf('   ✅ Models trained: Spring | Damper | Inertia\n');
        end
        
        function optimal_params = predict_from_models(ml_models)
            % PREDICT FROM MODELS - Fixed version
            % Representative features from your system (12 features total)
            representative_features = [
                2.730,   ... % 1. RMS (from your data)
                7.672,   ... % 2. Peak (typical value)
                2.81,    ... % 3. Crest Factor (from your data)
                3.5,     ... % 4. Kurtosis (typical for vibration)
                0.1,     ... % 5. Skewness (typical)
                24.72,   ... % 6. Dominant Frequency (1483 RPM / 60 ≈ 24.7 Hz)
                0.15,    ... % 7. Low Freq Energy (estimated)
                0.60,    ... % 8. Medium Freq Energy (estimated)
                0.25,    ... % 9. High Freq Energy (estimated)
                1483,    ... % 10. Mean RPM (from your data)
                0.05,    ... % 11. RPM Variation (estimated)
                12.0     ... % 12. Mean Voltage (typical)
            ];
            
            % Ensure it's a row vector with exactly 12 features
            representative_features = representative_features(:)'; % Make sure it's a row vector
            
            % Debug: Check dimensions
            fprintf('   Feature vector size: %d x %d\n', size(representative_features, 1), size(representative_features, 2));
            
            % Predict using ML models
            optimal_params = struct();
            optimal_params.spring_stiffness = predict(ml_models.spring_model, representative_features);
            optimal_params.damping_coefficient = predict(ml_models.damper_model, representative_features);
            optimal_params.inertia = predict(ml_models.inertia_model, representative_features);
            
            % Apply bounds
            optimal_params.spring_stiffness = max(500, min(8000, optimal_params.spring_stiffness));
            optimal_params.damping_coefficient = max(0.5, min(15, optimal_params.damping_coefficient));
            optimal_params.inertia = max(0.05, min(0.5, optimal_params.inertia));
            
            fprintf('   📋 Predicted Parameters:\n');
            fprintf('   Spring: %.0f N·m/rad\n', optimal_params.spring_stiffness);
            fprintf('   Damper: %.2f N·m·s/rad\n', optimal_params.damping_coefficient);
            fprintf('   Inertia: %.3f kg·m²\n', optimal_params.inertia);
        end

        
        function features = extract_features(vib1, vib2, vib3, rpm, voltage)
            % EXTRACT ML FEATURES
            features = struct();
            vibration = vib1;
            
            % Time domain features
            features.rms = rms(vibration);
            features.peak = max(abs(vibration));
            features.crest_factor = features.peak / features.rms;
            features.kurtosis = kurtosis(vibration);
            features.skewness = skewness(vibration);
            
            % Frequency domain features
            Fs = 4096;
            L = length(vibration);
            L_fft = 2^nextpow2(L);
            f = Fs * (0:(L_fft/2)) / L_fft;
            Y = fft(vibration, L_fft);
            P2 = abs(Y/L_fft);
            P1 = P2(1:L_fft/2+1);
            P1(2:end-1) = 2*P1(2:end-1);
            
            [~, dominant_idx] = max(P1);
            features.dominant_freq = f(dominant_idx);
            
            % Energy distribution
            total_energy = sum(P1.^2);
            features.low_freq_energy = sum(P1(f < 10).^2) / total_energy;
            features.medium_freq_energy = sum(P1(f >= 10 & f < 100).^2) / total_energy;
            features.high_freq_energy = sum(P1(f >= 100).^2) / total_energy;
            
            % Operating conditions
            features.mean_rpm = mean(rpm);
            features.rpm_variation = std(rpm) / mean(rpm);
            features.mean_voltage = mean(voltage);
            
            % Feature vector
            features.vector = [
                features.rms, features.peak, features.crest_factor, ...
                features.kurtosis, features.skewness, features.dominant_freq, ...
                features.low_freq_energy, features.medium_freq_energy, features.high_freq_energy, ...
                features.mean_rpm, features.rpm_variation, features.mean_voltage
            ];
        end
        
        function [spring_k, damper_c, inertia_j] = calculate_targets(data)
            % CALCULATE TARGET PARAMETERS
            features = data.features;
            
            base_inertia = 0.1;
            spring_k = (2 * pi * features.dominant_freq)^2 * base_inertia;
            
            if features.rms > 0.15
                spring_k = spring_k * 0.8;
            elseif features.rms < 0.05
                spring_k = spring_k * 1.2;
            end
            
            base_damping = 0.02;
            damper_c = 2 * base_damping * sqrt(spring_k * base_inertia);
            
            if features.crest_factor > 3
                damper_c = damper_c * 1.5;
            elseif features.crest_factor < 2
                damper_c = damper_c * 0.7;
            end
            
            inertia_j = base_inertia;
            if features.mean_rpm > 2000
                inertia_j = inertia_j * 0.8;
            elseif features.mean_rpm < 1000
                inertia_j = inertia_j * 1.3;
            end
            
            % Apply bounds
            spring_k = max(100, min(10000, spring_k));
            damper_c = max(0.1, min(50, damper_c));
            inertia_j = max(0.01, min(1.0, inertia_j));
        end
        
        function ml_models = load_models(model_path)
            % LOAD PRETRAINED MODELS
            if nargin < 1
                model_path = '../trained_models/ml_calibration_models.mat';
            end
            
            if exist(model_path, 'file')
                loaded_data = load(model_path);
                ml_models = loaded_data.model_package.ml_models;
                fprintf('   ✅ Models loaded from: %s\n', model_path);
            else
                fprintf('   ❌ No models found at: %s\n', model_path);
                ml_models = [];
            end
        end
        
        function save_models(ml_models, model_path)
            % SAVE MODELS
            if nargin < 2
                model_path = '../trained_models/ml_calibration_models.mat';
            end
            
            % Create folder if needed
            [model_dir, ~, ~] = fileparts(model_path);
            if ~isfolder(model_dir)
                mkdir(model_dir);
            end
            
            model_package = struct();
            model_package.ml_models = ml_models;
            model_package.training_date = datetime('now');
            
            save(model_path, 'model_package');
            fprintf('   💾 Models saved to: %s\n', model_path);
        end
    end
end