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
environment.matlab_version = string(version());
environment.matlab_release = string(version('-release'));
environment.matlab_release_date = string(version('-date'));
environment.matlab_release_description = string(version('-description'));
environment.java_version = string(version('-java'));
environment.matlab_toolboxes = ver();

% TODO: verLessThan
if ~verLessThan('matlab','9.1')
    environment.matlab_toolboxes_string = string(evalc("ver()"));
else
    environment.matlab_toolboxes_string = string(evalc('ver()'));
end

if isunix()
    environment.system = "unix";
    [status, host_name] = unix("hostname | tail -1");
    host_name = string(host_name(1:end-1));
    emClarity_path = default_configuration.general.em_clarity_path;
    dynamo_path = default_configuration.general.dynamo_path;
    fid = fopen("./load_modules.sh", "w+");
    for i = 1:length(default_configuration.general.modules)
        fprintf(fid, "module load %s\n", string(default_configuration.general.modules(i)));
    end
    fclose(fid);
elseif ismac()
    environment.system = "mac";
    [status, host_name] = unix("hostname");
    host_name = string(host_name(1:end-1));
    % TODO
elseif ispc()
    environment.system = "windows";
    % TODO
else
    error("Platform not supported!");
end

disp("HOSTNAME = " + host_name);

% TODO:NOTE: doesn't work on cluster (without display)
environment.imod_version = getIMODVersion();
environment.gpu_count = gpuDeviceCount;

% NOTE: doesn't work with double quotes, tested in MATLAB R2018b
environment.cpu_count_physical = feature('numcores');
if ~verLessThan('matlab','9.1')
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
        pyversion(obj.configuration.python_path);
        pyversion();
    end
    
    project_sub_paths = {"dynamo", {"matlab", {"mbtools", {"src"}, "src", {"shorthands"}}, "mex", {"bin"}}, "utilities", "configuration", "json", "modules", "pipeline"};
    concatAndAddPathsRecursive(project_path, project_sub_paths, string(filesep));    
    
    if ~fileExists("DYNAMO_INITIALIZED") && default_configuration.general.dynamo_path ~= ""
        createDynamoLinks(default_configuration.general.dynamo_path)
        fid = fopen("DYNAMO_INITIALIZED", "w+");
        fclose(fid);
    end
    
    if default_configuration.general.SUSAN_path ~= ""
        addpath(default_configuration.general.SUSAN_path);
    end
end
end

