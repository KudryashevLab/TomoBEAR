%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function environment_properties = getEnvironmentProperties(configuration)
path_to_script = mfilename("fullpath");
path_to_script_split = strsplit(path_to_script, string(filesep));
project_path = strjoin({path_to_script_split{1:end-2}}, string(filesep));
environment_properties = struct();
environment_properties.matlab_version = string(version());
environment_properties.matlab_release = string(version('-release'));
environment_properties.matlab_release_date = string(version('-date'));
environment_properties.matlab_release_description = string(version('-description'));
environment_properties.java_version = string(version('-java'));
environment_properties.matlab_toolboxes = ver();
if ~verLessThan('matlab', '9.2')
    environment_properties.matlab_toolboxes_string = string(evalc("ver()"));
else
    environment_properties.matlab_toolboxes_string = string(evalc('ver()'));
end
if isunix()
    environment_properties.system = "unix";
    [status, host_name] = unix("hostname | tail -1");
    host_name = string(host_name(1:end-1));

elseif ismac()
    environment_properties.system = "mac";
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
elseif ispc()
    environment_properties.system = "windows";
    [status, host_name] = system("hostname");
    host_name = string(host_name(1:end-1));
else
    error("Platform not supported!");
end
environment_properties.imod_version = getIMODVersion();
environment_properties.gpu_count = gpuDeviceCount;
% NOTE: doesn't work with double quotes, tested in MATLAB R2018b
environment_properties.cpu_count_physical = feature('numcores');
if ~verLessThan('matlab', '9.2')
    core_info = evalc("feature('numcores')");
    environment_properties.system_architecture = computer("arch");
else
    core_info = evalc('feature(''numcores'')');
    environment_properties.system_architecture = computer('arch');
end
matching_results = regexp(core_info, "\d+", "match");
environment_properties.cpu_count_logical = str2double(matching_results{2});
[environment_properties.computer_type, environment_properties.max_array_size, environment_properties.endianness] = computer();
environment_properties.host_name = host_name;
environment_properties.project_path = project_path;
environment_properties.debug = false;
end

