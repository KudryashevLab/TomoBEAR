% TODO: decide what to do with userpath
%userpath("clear");
%userpath(project_path);

if ~verLessThan("matlab", "9.4")
    project_path = string(pwd());
    if ~isdeployed()
        setenv("MATLAB_SHELL", project_path + string(filesep) + "matlab_shell.sh");
        addpath(project_path + string(filesep) + "environment");
        addpath(project_path + string(filesep) + "utilities");
    end
else
    project_path = pwd();
    if ~isdeployed()
        setenv('MATLAB_SHELL', char(project_path + string(filesep) + 'matlab_shell.sh'));
        addpath(char(project_path + string(filesep) + "environment"));
        addpath(char(project_path + string(filesep) + "utilities"));
    end
end


if ~isdeployed()
    initializeEnvironment();
end

clear project_path;
