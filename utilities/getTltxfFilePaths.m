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


function tiltxf_file_paths = getTltxfFilePaths(configuration)
original_mrcs = getOriginalMRCsFromStandardFolder(configuration);
batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_batchruntomo_*");
order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders);
for i = 1:length(original_mrcs)
    [path, name, extension] = fileparts(original_mrcs{i}(1).folder);
    tiltxf_file_paths{i} = batchruntomo_folders(order(1)).folder + string(filesep)...
        + batchruntomo_folders(order(1)).name + string(filesep) + name + string(filesep) + name + ".tltxf";
end
end

