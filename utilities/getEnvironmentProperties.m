function environment_properties = getEnvironmentProperties(configuration)


% TODO: extract python, dynamo, motioncor2 etc. path into config
path_to_script = mfilename("fullpath");
path_to_script_split = strsplit(path_to_script, string(filesep));
project_path = strjoin({path_to_script_split{1:end-2}}, string(filesep));

%if ~isdeployed()
%    if nargin == 0
%        default_configuration_path = "./configurations/defaults.json";
%    end
%else
%    default_configuration_path = configuration;
%end

configuration_parser = ConfigurationParser();
%[default_configuration, ~] = configuration_parser.parse(default_configuration_path);
environment_properties = struct();
environment_properties.matlab_version = string(version());
environment_properties.matlab_release = string(version('-release'));
environment_properties.matlab_release_date = string(version('-date'));
environment_properties.matlab_release_description = string(version('-description'));
environment_properties.java_version = string(version('-java'));
environment_properties.matlab_toolboxes = ver();
if environment_properties.matlab_release == "2018a" || environment_properties.matlab_release == "2018b" || environment_properties.matlab_release == "2019a"
    environment_properties.matlab_toolboxes_string = string(evalc("ver()"));
else
    environment_properties.matlab_toolboxes_string = string(evalc('ver()'));
end

if isunix()
    environment_properties.system = "unix";
    [status, host_name] = unix("hostname | tail -1");
    host_name = string(host_name(1:end-1));
% 
%     if host_name == "xps9570linux"
% %        emClarity_path = "/home/nibalysc/Projects/public/emClarity";
% %        dynamo_path = "/home/nibalysc/Programs/dynamo-v-1.1.509_MCR-9.6.0_GLNXA64_withMCR";
% %         project_path = "/home/nibalysc/Projects/private/phd";
%     elseif host_name == "sbnode201" || host_name == "sbnode202" || host_name == "swift"
% %                 emClarity_path = "/home/nibalysc/Projects/public/emClarity";
% %         dynamo_path = "/home/nibalysc/Programs/dynamo-v-1.1.509_MCR-9.6.0_GLNXA64_withMCR";
% %        emClarity_path = default_configuration.general.em_clarity_path;
% %        dynamo_path = default_configuration.general.dynamo_path;
% %         project_path = "/home/nibalysc/Projects/private/phd";
%     end
elseif ismac()
    environment_properties.system = "mac";
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
    
%    emClarity_path = "";
%    dynamo_path = "";
%     project_path = "";
elseif ispc()
    environment_properties.system = "windows";
    %[status, host_name] = unix("echo  %computername%");
    % Get fully qualified domain name
    %[status, host_name] = unix("net config workstation | findstr /C:""Full Computer name""");
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
%    emClarity_path = "C:\Users\Nikita\Projects\public\emClarity";
%    dynamo_path = "C:\Users\Nikita\Software\dynamo1401";
%     project_path = "C:\Users\Nikita\Projects\private\git\phd";
else
    error("Platform not supported!");
end


environment_properties.imod_version = getIMODVersion();

environment_properties.gpu_count = gpuDeviceCount;
% NOTE: doesn't work with double quotes, tested in MATLAB R2018b
environment_properties.cpu_count_physical = feature('numcores');
if environment_properties.matlab_release == "2018a" || environment_properties.matlab_release == "2018b" || environment_properties.matlab_release == "2019a"
    core_info = evalc("feature('numcores')");
    environment_properties.system_architecture = computer("arch");
else
    core_info = evalc('feature(''numcores'')');
    environment_properties.system_architecture = computer('arch');
end
matching_results = regexp(core_info, "\d+", "match");
environment_properties.cpu_count_logical = str2double(matching_results{2});

[environment_properties.computer_type, environment_properties.max_array_size, environment_properties.endianness] = computer();
%environment_properties.
environment_properties.host_name = host_name;
environment_properties.project_path = project_path;
%environment_properties.dynamo_path = dynamo_path;
%environment_properties.emClarity_path = emClarity_path;
environment_properties.debug = false;
end

