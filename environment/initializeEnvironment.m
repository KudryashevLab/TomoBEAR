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

project_path = string(pwd);
environment = struct();
environment.matlab_version = string(version());
environment.matlab_release = string(version('-release'));
environment.matlab_release_date = string(version('-date'));
environment.matlab_release_description = string(version('-description'));
environment.java_version = string(version('-java'));
environment.matlab_toolboxes = ver();

if ~verLessThan('matlab', '9.2')
    environment.matlab_toolboxes_string = string(evalc("ver()"));
else
    environment.matlab_toolboxes_string = string(evalc('ver()'));
end

if isunix()
    environment.system = "unix";
    [status, host_name] = unix("hostname | tail -1");
    host_name = string(host_name(1:end-1));
    if ~fileExists("./load_modules.sh") || default_configuration.general.regenerate_load_modules_file == true
        fid = fopen("./load_modules.sh", "w+");
        if ~isempty(default_configuration.general.modules)
            for i = 1:length(default_configuration.general.modules)
                fprintf(fid, "module load %s\n", string(default_configuration.general.modules(i)));
            end
        end
        fclose(fid);
    end
elseif ismac()
    environment.system = "mac";
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));    
elseif ispc()
    environment.system = "windows";
    [status, host_name] = system("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
else
    error("Platform not supported!");
end

emClarity_path = default_configuration.general.em_clarity_path;
dynamo_path = default_configuration.general.dynamo_path;
project_path = default_configuration.general.pipeline_location;
disp("HOSTNAME = " + host_name);

% NOTE: imod specific code, chose old naming style for imod projects
disp("INFO:ENV_GET:ETOMO_NAMING_STYLE: " + getenv("ETOMO_NAMING_STYLE"));
setenv("ETOMO_NAMING_STYLE","0");
disp("INFO:ENV_SET:ETOMO_NAMING_STYLE: " + getenv("ETOMO_NAMING_STYLE"));

% TODO: make it work on cluster (os installation without display)
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

environment.host_name = host_name;
environment.project_path = project_path;

if ~isdeployed()
    environment.dynamo_path = default_configuration.general.dynamo_path;
    environment.emClarity_path = default_configuration.general.em_clarity_path;
end

environment.debug = false;

if ~isdeployed
    if default_configuration.general.astra_path ~= ""
        astra_path = default_configuration.general.astra_path;
        astra_sub_paths = {"algorithms", {"DART", {"examples", "tools"}, "plot_geom"}, "mex", "tools"};
        concatAndAddPathsRecursive(astra_path, astra_sub_paths);
        pyversion(default_configuration.general.python_path);
        pyversion();
        if isfield(default_configuration.general, "conv_net_path") && default_configuration.general.conv_net_path ~= ""
            run(default_configuration.general.conv_net_path + filesep + vl_setupnn);
        end
    end

    if isfield(default_configuration.general, "dip_image_path") && default_configuration.general.dip_image_path ~= ""
         addpath(default_configuration.general.dip_image_path);
        if isfield(default_configuration.general, "dip_image_images_path") && default_configuration.general.dip_image_images_path ~= ""
            dipsetpref('imagefilepath',char(default_configuration.general.dip_image_images_path));
        end
    end
    project_sub_paths = {"dynamo", {"matlab", {"mbtools", {"src"}, "src", {"shorthands"}}, "mex", {"bin"}}, "utilities", "configuration", "json", "modules", "pipeline", "helper", {"gpu"}}; %, "extern", {"semaphore"}, "imod", "offxca", "database", "nn", "playground", {"matlab", {"astra"}}, "extern", {"av3", {"utils"}, "bol_scripts", "tom", {"Filtrans", "Geom"}, "irt", "flatten", "window2"}
    concatAndAddPathsRecursive(project_path, project_sub_paths, string(filesep));    
    
    if ~fileExists("DYNAMO_INITIALIZED")
        createDynamoLinks(default_configuration.general.dynamo_path)
        fid = fopen("DYNAMO_INITIALIZED", "w+");
        fclose(fid);
    end
    
    addpath(default_configuration.general.SUSAN_path);
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

