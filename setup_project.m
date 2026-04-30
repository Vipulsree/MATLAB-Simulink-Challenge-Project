% setup_project.m
% Add subdirectories to the MATLAB path so all scripts and models can find
% each other after restructuring.

disp('Setting up project paths...');

% Get the full path to the current directory
projectRoot = fileparts(mfilename('fullpath'));

% List of directories to add to the path
directoriesToAdd = {
    'models', ...
    'scripts', ...
    'data', ...
    'tests'
};

% Add each directory to the path
for i = 1:length(directoriesToAdd)
    dirPath = fullfile(projectRoot, directoriesToAdd{i});
    if exist(dirPath, 'dir')
        addpath(dirPath);
        disp(['Added to path: ', dirPath]);
    else
        warning(['Directory not found: ', dirPath]);
    end
end

% Save the path so it persists across sessions (optional)
% savepath;

disp('Project setup complete.');
