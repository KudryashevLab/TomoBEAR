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


function file_paths = getFilePathsFromLastBatchruntomoRun(configuration, file_extension)
batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_BatchRunTomo_*");
if length(batchruntomo_folders) >= 1
    order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders, configuration);
    field_names = fieldnames(configuration.tomograms);
    if extractBetween(file_extension, 1, 1) == "_"
        file_paths{1} = batchruntomo_folders(order(1)).folder + string(filesep)...
            + batchruntomo_folders(order(1)).name + string(filesep)...
            + field_names{configuration.set_up.j} + string(filesep)...
            + field_names{configuration.set_up.j} + string(file_extension);
    else
        file_paths{1} = batchruntomo_folders(order(1)).folder + string(filesep)...
            + batchruntomo_folders(order(1)).name + string(filesep)...
            + field_names{configuration.set_up.j} + string(filesep)...
            + field_names{configuration.set_up.j} + "." + string(file_extension);
    end
else
    file_paths = {};
end
end

