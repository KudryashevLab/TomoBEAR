classdef RefineFiducialModel < Module
    methods
        function obj = RefineFiducialModel(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = process(obj)
            tilt_stacks = getTiltStacksFromPreviousPipelineStepFolders(obj.configuration, true);
            [status_realpath, output] = system("realpath " + tilt_stacks(current_tomogram_index).folder + string(filesep) +  tilt_stacks(current_tomogram_index).name);
            %for i = 1:length(tilt_stacks)
            %splitted_output  = strsplit(tilt_stacks(current_tomogram_index).folder, "/");
            if fileExists(tilt_stacks(current_tomogram_index).folder + string(filesep) + "align.log")
                return_path = cd(tilt_stacks(current_tomogram_index).folder);
                [file_path, name, extension] = fileparts(tilt_stacks(current_tomogram_index).name);
                % TODO: needs to be tested
                %    output = executeCommand("3dmod -E F "...
                %        + tilt_stacks(i).folder + string(filesep) +  name + ".preali"...
                %        + " " + tilt_stacks(i).folder + string(filesep) + name + ".fid & echo $!", false, log_file_id);
                output = executeCommand("(echo 8 14 Bead\ Fixer 6 2 14 Bead\ Fixer 1 align.log) | 3dmod -L "...
                    + tilt_stacks(current_tomogram_index).folder + string(filesep) +  name + ".preali"...
                    + " " + tilt_stacks(current_tomogram_index).folder + string(filesep) + name + ".fid & echo $!", false, log_file_id);
                pause(obj.configuration.pid_wait_time);
                %pid = executeCommand("pgrep -n -U $(id -u) 3dmod", false, log_file_id);
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
                %obj.dynamic_configuration.
            end
            %end
            
            % TODO: perhaps introduce flg in showPipelineInfo
            obj.dynamic_configuration.previous_step_output_folder = obj.configuration.previous_step_output_folder;
        end
    end
end

