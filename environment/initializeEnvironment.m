%function environment = initializeEnvironment(default_configuration_path)
function initializeEnvironment(default_configuration_path)
if ~isdeployed()
    addpath("configuration");
    addpath("json");
    
    if nargin == 0
        default_configuration_path = "./configurations/defaults.json";
    end
end
configuration_parser = ConfigurationParser();
[default_configuration, ~] = configuration_parser.parse(default_configuration_path);

% TODO: extract python, dynamo, motioncor2 etc. path into config
project_path = string(pwd);
environment = struct();
%
environment.matlab_version = string(version());
environment.matlab_release = string(version('-release'));
environment.matlab_release_date = string(version('-date'));
environment.matlab_release_description = string(version('-description'));
environment.java_version = string(version('-java'));
environment.matlab_toolboxes = ver();

% TODO: verLessThan
if environment.matlab_release == "2018a" || environment.matlab_release == "2018b" || environment.matlab_release == "2019a" || environment.matlab_release == "2020a"
    environment.matlab_toolboxes_string = string(evalc("ver()"));
else
    environment.matlab_toolboxes_string = string(evalc('ver()'));
end

if isunix()
    environment.system = "unix";
    [status, host_name] = unix("hostname | tail -1");
    host_name = string(host_name(1:end-1));
    
    %     if host_name == "xps9570linux"
    %         emClarity_path = "/home/nibalysc/Projects/public/emClarity";
    %         dynamo_path = "/home/nibalysc/Programs/dynamo11514";
    % %         project_path = "/home/nibalysc/Projects/private/phd";
    %     elseif host_name == "X080-ubuntu"
    %         emClarity_path = "/home/nibalysc/Projects/public/emClarity";
    %         dynamo_path = "/home/nibalysc/Programs/Dynamo_1.1.524";
    % %         project_path = "/home/nibalysc/Projects/private/phd";
    %
    %     elseif host_name == "sbnode201" || host_name == "sbnode202" || host_name == "swift" || host_name == "log04" || host_name == "log03"
    % %                 emClarity_path = "/home/nibalysc/Projects/public/emClarity";
    % %         dynamo_path = "/home/nibalysc/Programs/dynamo-v-1.1.509_MCR-9.6.0_GLNXA64_withMCR";
    %         if ~isdeployed
    
    emClarity_path = default_configuration.general.em_clarity_path;
    dynamo_path = default_configuration.general.dynamo_path;
    if ~fileExists("./load_modules.sh") || default_configuration.general.regenerate_load_modules_file == true
%     if ~isempty(default_configuration.general.modules)
        fid = fopen("./load_modules.sh", "w+");
        if ~isempty(default_configuration.general.modules)
            for i = 1:length(default_configuration.general.modules)
                fprintf(fid, "module load %s\n", string(default_configuration.general.modules(i)));
            end
        end
        fclose(fid);
    end
%     end
    %         end
    % %         project_path = "/home/nibalysc/Projects/private/phd";
    %     end
elseif ismac()
    environment.system = "mac";
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
    
%     emClarity_path = "";
%     dynamo_path = "";
%     project_path = "";
elseif ispc()
    environment.system = "windows";
    %[status, host_name] = unix("echo  %computername%");
    % Get fully qualified domain name
    %[status, host_name] = unix("net config workstation | findstr /C:""Full Computer name""");
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
%     emClarity_path = "C:\Users\Nikita\Projects\public\emClarity";
%     dynamo_path = "C:\Users\Nikita\Software\dynamo1401";
%     project_path = "C:\Users\Nikita\Projects\private\git\phd";
else
    error("Platform not supported!");
end
disp("HOSTNAME = " + host_name);
%if ~isdeployed()
%    if default_configuration.general.em_clarity_path ~= ""
%
%% emClarity
%        emClarity_sub_paths = {"alignment", "coordinates", "ctf", "logicals",...
%            "masking", "metaData", "statistics", "synthetic", "testScripts",...
%            "transformations"};
%
%        concatAndAddPathsRecursive(emClarity_path, emClarity_sub_paths, string(filesep));
%    end
%
%% dynamo
%    run(dynamo_path + string(filesep) + "dynamo_activate.m");
%
%end




% imod
%NOTE: chose old naming style for imod projects
disp("INFO:ENV_GET:ETOMO_NAMING_STYLE: " + getenv("ETOMO_NAMING_STYLE"));
setenv("ETOMO_NAMING_STYLE","0");
disp("INFO:ENV_SET:ETOMO_NAMING_STYLE: " + getenv("ETOMO_NAMING_STYLE"));
%TODO:NOTE: doesn't work on cluster (without display)
environment.imod_version = getIMODVersion();

environment.gpu_count = gpuDeviceCount;
% NOTE: doesn't work with double quotes, tested in MATLAB R2018b
environment.cpu_count_physical = feature('numcores');
if environment.matlab_release == "2018a" || environment.matlab_release == "2018b" || environment.matlab_release == "2019a"
    core_info = evalc("feature('numcores')");
    environment.system_architecture = computer("arch");
else
    core_info = evalc('feature(''numcores'')');
    environment.system_architecture = computer('arch');
end
matching_results = regexp(core_info, "\d+", "match");
environment.cpu_count_logical = str2double(matching_results{2});

[environment.computer_type, environment.max_array_size, environment.endianness] = computer();
% environment.
environment.host_name = host_name;
environment.project_path = project_path;
if ~isdeployed()
    environment.dynamo_path = default_configuration.general.dynamo_path;
    environment.emClarity_path = default_configuration.general.em_clarity_path;
end
environment.debug = false;
if ~isdeployed
    % if environment.host_name == "xps9570linux"
    % TODO: append version string from environment.matlab_release
    % TODO: clean up
    %     if environment.matlab_release == "2017b"
    if default_configuration.general.astra_path ~= ""
        astra_path = "/home/nibalysc/Programs/astra/matlab";
        
        %     elseif environment.matlab_release == "2018b"
        %         astra_path = "/home/nibalysc/Programs/astra_R2018b/matlab";
        %     elseif environment.matlab_release == "2019a"
        %         astra_path = "/home/nibalysc/Programs/astra_R2019a/matlab";
        %     elseif environment.matlab_release == "2019b"
        %         astra_path = "/home/nibalysc/Programs/astra/matlab";
        %
        %     end
        %     if configuration.general ~= ""
        astra_sub_paths = {"algorithms", {"DART", {"examples", "tools"}, "plot_geom"}, "mex", "tools"};
        concatAndAddPathsRecursive(astra_path, astra_sub_paths);
        pyversion("/home/nibalysc/Programs/miniconda3/bin/python");
        pyversion();
        % TODO: matconvnet is probabaly not needed
        %run /home/nibalysc/Projects/public/matconvnet/matlab/vl_setupnn
        %     end
    end
    %    addpath('/usr/local/share/DIPimage');
    %    dipsetpref('imagefilepath','/home/nibalysc/Projects/private/data/images');
    
    % end
    project_sub_paths = {"dynamo", {"matlab", {"mbtools", {"src"}, "src", {"shorthands"}}, "mex", {"bin"}}, "utilities", "configuration", "json", "modules", "pipeline", "helper", {"gpu"}}; %, "extern", {"semaphore"}, "imod", "offxca", "database", "nn", "playground", {"matlab", {"astra"}}, "extern", {"av3", {"utils"}, "bol_scripts", "tom", {"Filtrans", "Geom"}, "irt", "flatten", "window2"}
    concatAndAddPathsRecursive(project_path, project_sub_paths, string(filesep));    
    
    if ~fileExists("DYNAMO_INITIALIZED")
        createDynamoLinks(default_configuration.general.dynamo_path)
        fid = fopen("DYNAMO_INITIALIZED", "w+");
        fclose(fid);
    end
    
    if default_configuration.general.SUSAN_path ~= ""
        addpath(default_configuration.general.SUSAN_path);
        %TODO: remove else path
    else
        addpath("/home/risanche/Projects/SUSAN");
    end
    
    %     run /sbdata/EM/projects/nibalysc/programs/dynamo-v-1.1.514_MCR-9.6.0_GLNXA64_withMCR/dynamo_activate.m

end
% if host_name ~= "xps9570linux"
%     project_sub_paths{end + 1} = "extern";
%     project_sub_paths{end + 1} = {"dip", {"common", {"dipimage", {"demos"}}}};
% else
%     addpath("/home/nibalysc/Programs/dip");
%     addpath("/home/nibalysc/Programs/dip/common");
%     addpath("/home/nibalysc/Programs/dip/common/dipimage");
%     addpath("/home/nibalysc/Programs/dip/common/dipimage/demos");
% end


% TODO: check if it is needed here because variable project_path is not available
% or implement some logic to detect the project_path if it is not in pwd
% change pwd
% project_path = string(pwd);
% cd(project_path);



% dip_initialise;
%
%  if string(host_name) ~= "xps9570linux"
% %     dipsetpref('imagefilepath','/home/nibalysc/Projects/phd/extern/dip/images');
%     generatePool(environment.cpu_count_physical, true);
%  else
% %     dipsetpref('imagefilepath','/home/nibalysc/Programs/dip/images');
%     generatePool(environment.cpu_count_physical, true);
% end

end

