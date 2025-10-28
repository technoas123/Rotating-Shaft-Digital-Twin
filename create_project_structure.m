function create_project_structure()
    % CREATE_PROJECT_STRUCTURE Create folder structure for digital twin project
    %
    % This function creates the necessary folder organization for the project
    
    folders = {
        'models';    % For Simulink/Simscape models
        'scripts';   % For MATLAB scripts and main code
        'data';      % For input/output data files
        'utils';     % For utility functions
        'docs';      % For documentation
        'tests';     % For test scripts and validation
        'results'    % For simulation results and plots
    };
    
    fprintf('Creating project folder structure...\n\n');
    
    for i = 1:length(folders)
        if ~exist(folders{i}, 'dir')
            mkdir(folders{i});
            fprintf('📁 Created folder: %s\n', folders{i});
        else
            fprintf('📁 Folder already exists: %s\n', folders{i});
        end
    end
    
    fprintf('\n✅ Project structure created successfully!\n');
end