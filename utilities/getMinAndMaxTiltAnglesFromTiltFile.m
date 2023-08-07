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

function min_and_max_tilt_angles = getMinAndMaxTiltAnglesFromTiltFile(configuration)
tomograms = getTomograms(configuration, true);
batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_batchruntomo_*");

if length(batchruntomo_folders) == 0
    batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_BatchRunTomo_*");
end

order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders);
for i = 1:length(tomograms)
    [path, name, extension] = fileparts(tomograms(i).name);
    tilt_file_id = fopen(batchruntomo_folders(order(1)).folder + string(filesep)...
        + batchruntomo_folders(order(1)).name + string(filesep) + name + string(filesep) + name + ".tlt", "r");
    tilt_file_content = textscan(tilt_file_id, "%s", "Delimiter", "", "endofline", "\n");
    tilt_file_content = tilt_file_content{1};
    min_and_max_tilt_angles{i} = [str2double(tilt_file_content{1}) str2double(tilt_file_content{end})];
end
end