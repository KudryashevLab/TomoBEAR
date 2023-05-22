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


function original_files = getOriginalFiles(configuration, grouped)
if nargin == 1
    grouped = false;
end

if isfield(configuration, "tomogram_input_prefix")...
        && ~isStringScalar(configuration.tomogram_input_prefix)...
        && ~isStringScalar(configuration.data_path)
    counter = 1;
    for i = 1:length(configuration.tomogram_input_prefix)
        for j = 1:length(configuration.data_path)
            file_paths(counter) = configuration.data_path{j} + string(filesep)...
                + configuration.tomogram_input_prefix{i};
            counter = counter + 1;
        end
    end
elseif isfield(configuration, "tomogram_input_prefix")...
        && isStringScalar(configuration.tomogram_input_prefix)...
        && configuration.tomogram_input_prefix ~= ""...
        && ~isStringScalar(configuration.data_path)
    file_paths = configuration.data_path + string(filesep)...
        + configuration.tomogram_input_prefix;
elseif isfield(configuration, "tomogram_input_prefix")...
        && isStringScalar(configuration.tomogram_input_prefix)...
        && configuration.tomogram_input_prefix ~= ""...
        && isStringScalar(configuration.data_path)
    file_paths = configuration.data_path + string(filesep)...
        + configuration.tomogram_input_prefix;
else
    file_paths = configuration.data_path;
end

for i=1:length(file_paths)
    if ~contains(file_paths{i}, "*") &&...
        ~contains(file_paths{i}, ".mrc") &&...
        ~contains(file_paths{i}, "mrc") &&...
        ~contains(file_paths{i}, ".tif") &&...
        ~contains(file_paths{i}, "tif") 
        if iscell(file_paths)
            file_paths{i} = file_paths{i} + "*";
        else
            file_paths = file_paths + "*";
        end
    end
end

original_files = getOriginalFilesFromFilePaths(file_paths, grouped);

if isempty(original_files)
	error("ERROR: No micrographs found at location " + file_paths);
end

if iscell(original_files) && grouped ~= true
    original_files_tmp = struct("name", '', "folder", '', "date", '',...
        "bytes", 0, "isdir", false, "datenum", 0);
    for i = 1:length(original_files)
        if i == 1
            original_files_tmp(1:length(original_files{i})) = original_files{i};
        else
            original_files_tmp(end + 1:end + length(original_files{i})) = original_files{i};
        end
    end
    original_files = original_files_tmp;
end
end
