% TODO: decide what to do with userpath
%userpath("clear");
%userpath(project_path);

project_path = string(pwd());

if ~isdeployed()
    addpath("configuration");
    addpath("json");
    addpath(project_path + string(filesep) + "environment");
    addpath(project_path + string(filesep) + "utilities");
end

if fileExists("CONFIGURATION")
    default_configuration_path = string(fread(fopen("CONFIGURATION"), "*char")');
else
    default_configuration_path = "./configurations/defaults.json";
end

configuration_parser = ConfigurationParser();
[default_configuration, ~] = configuration_parser.parse(default_configuration_path);

if isunix()
    if ~fileExists("./load_modules.sh") || default_configuration.general.regenerate_load_modules_file == true
        if ~isempty(default_configuration.general.modules)
            fid = fopen("./load_modules.sh", "w+");
            for i = 1:length(default_configuration.general.modules)
                fprintf(fid, "module load %s\n", string(default_configuration.general.modules(i)));
            end
            fclose(fid);
            system("chmod ug+x ./load_modules.sh");
        end
    end
    
    if ~fileExists(default_configuration.general.matlab_shell) || default_configuration.general.regenerate_load_modules_file == true
        fid = fopen(default_configuration.general.matlab_shell, "w+");
        fprintf(fid, "%s\n", "#!/bin/bash");
        fprintf(fid, "%s\n", "SCRIPTPATH=""$( cd -- ""$(dirname ""$0"")"" >/dev/null 2>&1 ; pwd -P )""");
        
        if fileExists("./load_modules.sh")
            fprintf(fid, "%s\n", "source $SCRIPTPATH/load_modules.sh");
        end
        
        if default_configuration.general.additional_shell_initialization_script ~= ""
            fprintf(fid, "%s\n", "source " + default_configuration.general.additional_shell_initialization_script);
        end
        if isfield(default_configuration.general, "conda_path") && default_configuration.general.conda_path ~= ""
            fprintf(fid, "%s\n", "# >>> conda initialize >>>");
            fprintf(fid, "%s\n", "# !! Contents within this block are managed by 'conda init' !!");
            fprintf(fid, "%s\n", "__conda_setup=""$('" + default_configuration.general.conda_path + "/2020.02/bin/conda' 'shell.bash' 'hook' 2> /dev/null)""");
            fprintf(fid, "%s\n", "if [ $? -eq 0 ]; then");
            fprintf(fid, "%s\n", "eval ""$__conda_setup""");
            fprintf(fid, "%s\n", "else");
            fprintf(fid, "%s\n", "if [ -f """ + default_configuration.general.conda_path + "/etc/profile.d/conda.sh""]; then");
            fprintf(fid, "%s\n", ". """ + default_configuration.general.conda_path + "/etc/profile.d/conda.sh""");
            fprintf(fid, "%s\n", "else");
            fprintf(fid, "%s\n", "export PATH=""" + default_configuration.general.conda_path + "/2020.02/bin:$PATH""");
            fprintf(fid, "%s\n", "fi");
            fprintf(fid, "%s\n", "fi");
            fprintf(fid, "%s\n", "unset __conda_setup");
            fprintf(fid, "%s\n", "# <<< conda initialize <<<");
        end
        % NOTE: use old naming style from IMOD
        fprintf(fid, "%s\n", "export ETOMO_NAMING_STYLE=0");
        fprintf(fid, "%s\n", "eval $2");
        fclose(fid);
        system("chmod ug+x " + default_configuration.general.matlab_shell);
    end 
end

setenv("MATLAB_SHELL", project_path + string(filesep) + default_configuration.general.matlab_shell);
addpath(project_path + string(filesep) + "environment");
addpath(project_path + string(filesep) + "utilities");

initializeEnvironment(default_configuration_path);

clear project_path configuration_parser configuration_path default_configuration default_configuration_path;