function initialize_project()
    clear; close all; clc;
    
    % Add folders to path (will create next)
    addpath(genpath('models'));
    addpath(genpath('scripts'));
    addpath(genpath('utils'));
    addpath(genpath('tests'));

    % Load parameters
    params = define_system_parameters();
    
    fprintf('=====================================\n');
    fprintf('   DIGITAL TWIN PROJECT INITIALIZED\n');
    fprintf('=====================================\n');
    fprintf('Shaft Length ....: %.2f m\n', params.shaft.length);
    fprintf('Motor Speed .....: %d RPM\n', params.motor.nominal_rpm);
    fprintf('Sample Rate .....: %d Hz\n', params.simulation.sample_rate);
    fprintf('=====================================\n');

    assignin('base', 'params', params);
end