% if isunix()
%     string(filesep) = "/";
% elseif ismac()
%     string(filesep) = "/";
% elseif ispc()
%     string(filesep) = "\";
% else
%     error("Platform is not supported!");
% end



% TODO: decide what to do with userpath
%userpath("clear");
%userpath(project_path);

% version_release = version('-release');

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
    %global environmentProperties;
    %environmentProperties = initializeEnvironment();
    initializeEnvironment();
end

clear project_path version_release

% setenv("KMP_STACKSIZE", "512k");
% [status, output] = system("env");
% regexp_match = regexp(output, "KMP_STACKSIZE=[\d]+[Mk]+", "match");
% new_env = erase(output, regexp_match{1});