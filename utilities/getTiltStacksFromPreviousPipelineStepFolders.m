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


function tilt_stacks = getTiltStacksFromPreviousPipelineStepFolders(configuration, flatten)
if nargin == 1
   flatten = false;
end
previous_step_output_folder = strsplit(configuration.previous_step_output_folder, "/");
previous_step_output_folder = strjoin(previous_step_output_folder(1:end-1), "/");

if flatten == true
    tilt_stack_path_without_file_extension = previous_step_output_folder...
        + string(filesep) + "**" + string(filesep) + "*";
    tilt_stack_path = tilt_stack_path_without_file_extension + ".ali";
    tilt_stacks = dir(tilt_stack_path);
    if isempty(tilt_stacks)
        tilt_stack_path = tilt_stack_path_without_file_extension + ".st";
        tilt_stacks = dir(tilt_stack_path);
    end
elseif flatten == false
    tilt_stack_path = previous_step_output_folder + string(filesep) + "*";
    tilt_stack_folders = dir(tilt_stack_path);
    tilt_stack_folders = dir(tilt_stack_folders(end).folder + string(filesep) + tilt_stack_folders(end).name);
    tilt_stacks = {};
    counter = 1;
    for i = 1:length(tilt_stack_folders)
        if tilt_stack_folders(i).isdir...
                && (tilt_stack_folders(i).name ~= "." && tilt_stack_folders(i).name ~= "..")
            tilt_stack_path_without_file_extension = tilt_stack_folders(i).folder...
                + string(filesep) + tilt_stack_folders(i).name + string(filesep);
            tilt_stacks{counter} = dir(tilt_stack_path_without_file_extension + "*.ali");
            if isempty(tilt_stacks{counter})
                tilt_stack_path = tilt_stack_path_without_file_extension + ".st";
                tilt_stacks = dir(tilt_stack_path);
            end
            counter = counter + 1;
        end    
    end
end

if isempty(tilt_stacks)
    % TODO: perhaps make switch for error and exit or warning or throw
    % exception and catch it...
    disp("INFO: No tilt stacks found at location " + tilt_stack_path);
end
end

