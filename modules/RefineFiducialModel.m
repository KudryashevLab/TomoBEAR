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


classdef RefineFiducialModel < Module
    methods
        function obj = RefineFiducialModel(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = process(obj)
            tilt_stacks = getTiltStacksFromPreviousPipelineStepFolders(obj.configuration, true);
            [status_realpath, output] = system("realpath " + tilt_stacks(current_tomogram_index).folder + string(filesep) +  tilt_stacks(current_tomogram_index).name);
            if fileExists(tilt_stacks(current_tomogram_index).folder + string(filesep) + "align.log")
                return_path = cd(tilt_stacks(current_tomogram_index).folder);
                [file_path, name, extension] = fileparts(tilt_stacks(current_tomogram_index).name);
                output = executeCommand("(echo 8 14 Bead\ Fixer 6 2 14 Bead\ Fixer 1 align.log) | 3dmod -L "...
                    + tilt_stacks(current_tomogram_index).folder + string(filesep) +  name + ".preali"...
                    + " " + tilt_stacks(current_tomogram_index).folder + string(filesep) + name + ".fid & echo $!", false, log_file_id);
                pause(obj.configuration.pid_wait_time);
                [status_system,  pid] = system("pgrep -n -U $(id -u) 3dmod");
                if contains(pid, "OK")
                    pid = erase(pid, "OK");
                end
                pid = str2num(pid);
                pid = pid(1);
                disp("INFO: Press a key to continue with the next stack!")
                pause;
                output = executeCommand("kill " + pid, true, log_file_id);
                cd(return_path);
            else
                % TODO: put some errorflag inside and process it in the
                % pipeline runner
                % obj.status or something similar
            end
            % TODO: perhaps introduce flg in showPipelineInfo
            obj.dynamic_configuration.previous_step_output_folder = obj.configuration.previous_step_output_folder;
        end
    end
end

