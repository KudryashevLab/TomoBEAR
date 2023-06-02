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

function file_paths = getFilesFromLastModuleRun(configuration, module_name, file_extension, choice)
if nargin == 3
    choice = "last";
end
% TODO: prepend dot to extension if it is missing
% TODO: check for file existence
module_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_" + module_name + "_*");
if length(module_folders) >= 1
    order = sortDirOutputByPipelineStepNumbering(module_folders, configuration);
    field_names = fieldnames(configuration.tomograms);
    if choice == "last"
        file_paths{1} = module_folders(order(1)).folder + string(filesep)...
            + module_folders(order(1)).name;
        if file_extension ~= ""
            if isfield(configuration.set_up, "j")
                if extractBetween(file_extension,1,1) ~= "."
                    if module_name ~= "GCTFCtfphaseflipCTFCorrection"
                        file_paths{1} = file_paths{1} + string(filesep)...
                            + field_names{configuration.set_up.j} + string(filesep)...
                            + field_names{configuration.set_up.j} + "." + string(file_extension);
                    else
                        file_paths{1} = file_paths{1} + string(filesep)...
                            + field_names{configuration.set_up.j} + string(filesep)...
                            + string(file_extension);
                    end
                else
                    if module_name ~= "GCTFCtfphaseflipCTFCorrection"
                        file_paths{1} = file_paths{1} + string(filesep)...
                            + field_names{configuration.set_up.j} + string(filesep)...
                            + field_names{configuration.set_up.j} + string(file_extension);
                    else
                        file_paths{1} = file_paths{1} + string(filesep)...
                            + field_names{configuration.set_up.j} + string(filesep)...
                            + string(file_extension);
                    end
                end
            else
                if extractBetween(file_extension,1,1) ~= "."
                    file_paths{1} = file_paths{1} + string(filesep)...
                        + field_names{configuration.set_up.j} + string(filesep)...
                        + field_names{configuration.set_up.j} + "." + string(file_extension);
                else
                    file_paths{1} = file_paths{1} + string(filesep)...
                        + "*" + string(filesep)...
                        + "*" + string(file_extension);
                end
            end
        end
    elseif choice == "prelast" && length(module_folders) >= 2
        file_paths{1} = module_folders(order(2)).folder + string(filesep)...
            + module_folders(order(2)).name;
        if file_extension ~= ""
            file_paths{1} = file_paths{1} + string(filesep)...
                + field_names{configuration.set_up.j} + string(filesep)...
                + field_names{configuration.set_up.j} + "." + string(file_extension);
        end
    elseif choice == "first"
        file_paths{1} = module_folders(order(end)).folder + string(filesep)...
            + module_folders(order(end)).name;
        if file_extension ~= ""
            file_paths{1} = file_paths{1} + string(filesep)...
                + field_names{configuration.set_up.j} + string(filesep)...
                + field_names{configuration.set_up.j} + "." + string(file_extension);
        end
    else
        file_paths = {};
    end
else
    file_paths = {};
end
end

