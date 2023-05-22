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


function tilt_stacks = getCtfCorrectedBinnedAlignedTiltStacksFromStandardFolder(configuration, flatten)
if nargin == 1
    flatten = false;
end

if isfield(configuration, "ctf_corrected_binned_aligned_tilt_stacks_folder") && flatten == true
    tilt_stack_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.ctf_corrected_binned_aligned_tilt_stacks_folder...
        + string(filesep) + "**" + string(filesep) + "*.ali";
    tilt_stacks = dir(tilt_stack_path);
elseif isfield(configuration, "ctf_corrected_binned_aligned_tilt_stacks_folder") && flatten == false
    tilt_stack_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.ctf_corrected_binned_aligned_tilt_stacks_folder;
    tilt_stacks_folders = dir(tilt_stack_path);
    tilt_stacks = {};
    counter = 1;
    for i = 1:length(tilt_stacks_folders)
        if tilt_stacks_folders(i).isdir...
                && (tilt_stacks_folders(i).name ~= "."...
                && tilt_stacks_folders(i).name ~= "..")
            tilt_stacks{counter} = dir(tilt_stacks_folders(i).folder...
                + string(filesep) + tilt_stacks_folders(i).name...
                + string(filesep) + "*.ali");
            counter = counter + 1;
        end
    end
end

if isempty(tilt_stacks)
    disp("INFO: No aligned tilt stacks found at standard location " + tilt_stack_path);
end
end
