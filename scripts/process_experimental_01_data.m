%% File: scripts/01_process_experimental_data.m
clear; clc; close all;

fprintf('=========================================\n');
fprintf('PROCESSING EXPERIMENTAL DATA FOR SIMULINK CALIBRATION\n');
fprintf('=========================================\n');

%% 1. Create directories
if ~exist('data/features', 'dir')
    mkdir('data/features');
end
if ~exist('data/processed', 'dir')
    mkdir('data/processed');
end
if ~exist('ml_models/trained_models', 'dir')
    mkdir('ml_models/trained_models');
end

%% 2. Extract features from experimental CSV files
fprintf('\n1. Extracting features from experimental data...\n');

% Customized feature extraction for your data
extract_unbalance_features();

%% 3. Prepare training dataset
fprintf('\n2. Preparing training dataset...\n');
prepare_training_data();

%% 4. Load the prepared data
load('data/processed/training_data.mat');

fprintf('\nDataset Statistics:\n');
fprintf('  Training samples: %d\n', size(X_train, 1));
fprintf('  Testing samples: %d\n', size(X_test, 1));
fprintf('  Features per sample: %d\n', size(X_train, 2));