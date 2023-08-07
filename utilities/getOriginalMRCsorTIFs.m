%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021,2022,2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published
% by the Free Software Foundation, either version 3 of the License,
% or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [original_files, tif_flag] = getOriginalMRCsorTIFs(configuration, grouped)
if nargin < 2
    grouped = false;
end
    
tif_flag = 0;
if isfield(configuration, "tomogram_input_prefix") && iscell(configuration.tomogram_input_prefix)
    counter = 1;
    for i = 1:length(configuration.tomogram_input_prefix)
        for j = 1:length(configuration.data_path)
            mrc_path(counter) = configuration.data_path{j} + string(filesep)...
                + configuration.tomogram_input_prefix{i} + "*.mrc";
            counter = counter + 1;
        end
    end
elseif isfield(configuration, "tomogram_input_prefix") && configuration.tomogram_input_prefix ~= ""
    mrc_path = configuration.data_path + string(filesep)...
        + configuration.tomogram_input_prefix + "*.mrc";
else
    mrc_path = configuration.data_path;
    if ~contains(mrc_path, ".mrc")
        mrc_path = mrc_path + string(filesep) + "*.mrc";
    end
end

counter = 1;
for i = 1:length(mrc_path)
    original_files{counter} = dir(mrc_path{i});
    if isempty(original_files{counter})
        continue;
    end
    counter = counter + 1;
end

if counter == 1
    [original_files, tif_flag] = getOriginalTIFs(configuration);
end

if isempty(original_files) || (iscell(original_files) && isempty(original_files{1}))
    [original_files, ~] = getOriginalEERs(configuration);
end

if isempty(original_files) || (iscell(original_files) && isempty(original_files{1}))
    if ~isfield(configuration, "live_data_mode") || ~configuration.live_data_mode
        error("ERROR: No micrographs found at location " + mrc_path);
    else
        original_files = [];
    end
elseif iscell(original_files)
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

