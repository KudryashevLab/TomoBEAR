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


function original_tifs = getOriginalTIFsFromStandardFolder(configuration, flatten)
if nargin == 1
    flatten = false;
end

if isfield(configuration, "raw_files_folder") && flatten == true
    tif_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.raw_files_folder + string(filesep)...
        + "**" + string(filesep) + "*.tif";
    original_tifs = dir(tif_path);
elseif isfield(configuration, "raw_files_folder") && flatten == false
    tif_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.raw_files_folder;
    original_tif_folders = dir(tif_path);
    if ~isempty(original_tif_folders)
        original_tif_folders(1:2) = [];
    end
    original_tifs = {};
    for i = 1:length(original_tif_folders)
        original_tifs{i} = dir(tif_path + string(filesep)...
            + original_tif_folders(i).name + string(filesep) + "*.tif");
    end
end

if isempty(original_tifs)
    disp("INFO: No micrographs found at standard location " + tif_path);
end
end

