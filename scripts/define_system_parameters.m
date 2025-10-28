function params = define_system_parameters()
    % SHAFT PROPERTIES
    params.shaft.length = 1.0;             % meters
    params.shaft.diameter = 0.05;          % meters
    params.shaft.density = 7800;           % kg/m³ (steel)
    params.shaft.youngs_modulus = 2.0e11;  % Pa (steel)
    
    % MOTOR PROPERTIES
    params.motor.nominal_rpm = 1800;       % RPM
    params.motor.rated_torque = 10;        % N·m
    params.motor.power = 1.5;              % kW

    % SIMULATION SETTINGS
    params.simulation.time_total = 10;     % seconds
    params.simulation.sample_rate = 1000;  % Hz
    params.simulation.solver_type = 'ode4'; % Fixed-step solver

    % FAULT SETTINGS
    params.fault.imbalance_mass_range = [0.01, 0.05, 0.1]; % kg
    params.fault.imbalance_position = 0.3; % meters from motor

    fprintf('[✔] System parameters defined successfully.\n');
end