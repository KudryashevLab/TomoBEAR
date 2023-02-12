% NOTE: https://bio3d.colorado.edu/imod/betaDoc/alignframesGuide.html
% NOTE: https://bio3d.colorado.edu/imod/download.html
classdef BatchRunTomo < Module
    methods
        function obj = BatchRunTomo(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            output_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.pipeline_step_output_folder;
            % string(filesep) = getstring(filesep)();
            splitted_path = strsplit(output_folder, string(filesep));
            % NOTE -1 because now the pipelinestep is executed for every
            % tomogram separately
            splitted_folder = strsplit(splitted_path(end - 1), "_");
            % NOTE: 2 because of previous processing step and the
            % general section which is skipped in numbering
            % NOTE: assumes only that non-universal scripts are
            % not placed twice in the configuration file
            previous_output_folder = strjoin([splitted_path(1:end-2) "*_" + strjoin(splitted_folder(2:end), "_") splitted_path(end)], string(filesep));
            dir_list = dir(previous_output_folder + "*");
            if ~isempty(dir_list)
                order = sortDirOutputByPipelineStepNumbering(dir_list, obj.configuration);
                threshold = obj.configuration.link_files_threshold_in_mb * 1024 * 1024;
                for k = order
                    splitted_name = strsplit(dir_list(k).folder, "/");
                    splitted_name = splitted_name(end);
                    splitted_name = strsplit(splitted_name{1}, "_");
                    number = str2double(splitted_name(1));
                    if number < obj.configuration.set_up.i - 1
                        copyOrLinkFilesBasedOnSizeThreshold(dir_list(k).folder + string(filesep) + dir_list(k).name,...
                            output_folder, threshold, obj.log_file_id);
                        %[status, message, message_id] = copyfile(dir_list(j).folder + string(filesep) + dir_list(j).name, output_folder);
                        %                         executeCommand("rm -f " + output_folder + string(filesep) + "SUCCESS");
                        executeCommand("rm -f " + output_folder + string(filesep) + obj.configuration.directive_file_name + ".adoc");
                        break;
                    end
                end
            end
            
            if obj.configuration.aligned_stack_binning > 1
                createStandardFolder(obj.configuration, "binned_aligned_tilt_stacks_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_binned_aligned_tilt_stacks_folder", false);
                createStandardFolder(obj.configuration, "aligned_tilt_stacks_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_aligned_tilt_stacks_folder", false);
                createStandardFolder(obj.configuration, "binned_tilt_stacks_folder", false);
            end
            
            if isfield(obj.configuration, "reconstruct_binned_stacks") && obj.configuration.reconstruct_binned_stacks == false
                createStandardFolder(obj.configuration, "tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_tomograms_folder", false);
            else
                createStandardFolder(obj.configuration, "binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_binned_tomograms_folder", false);
            end
            
            if length(fieldnames(obj.configuration.tomograms))>=3
                if isfield(obj.configuration.tomograms.tomogram_001, "motion_corrected_even_files") || isfield(obj.configuration.tomograms.tomogram_002, "motion_corrected_even_files") || isfield(obj.configuration.tomograms.tomogram_003, "motion_corrected_even_files")
                    createStandardFolder(obj.configuration, "aligned_even_tilt_stacks_folder", false);
                    createStandardFolder(obj.configuration, "aligned_odd_tilt_stacks_folder", false);
                end
            end
        end
        
        function obj = process(obj)
            if isfield(obj.configuration, "reconstruct_binned_stacks") && obj.configuration.reconstruct_binned_stacks == false
                % TODO: restructure next statement, extract
                % configuration.tomogram_output_prefix or
                % configuration.tomogram_input_prefix into a variable
                %if isfield(obj.configuration, "tomogram_output_prefix") && ~isempty(obj.configuration.tomogram_output_prefix)
                tilt_stacks_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.tilt_stacks_folder;
                dir_list = dir(tilt_stacks_path + string(filesep) + "**" + string(filesep) + "*.st");
                field_names = fieldnames(obj.configuration.tomograms);
                dir_list = dir_list(contains({dir_list.name}, field_names(obj.configuration.set_up.j)));
                %else
                %dir_list = dir(obj.input_path + string(filesep) + "*.st");
                %end
                % NOTE: filter dir list for ".mat" files
                %dir_list = dir_list(~contains({dir_list.name}, ".mat"));
                %tomogram_counter = length(dir_list);
                tomogram_counter = 1;
            else
                dir_list = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.binned_tilt_stacks_folder + string(filesep) + "**" + string(filesep) + "*.ali");
                if isempty(dir_list)
                    dir_list = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.binned_tilt_stacks_folder + string(filesep) + "**" + string(filesep) + "*.st");
                end
                output_folder = strsplit(obj.output_path, "/");
                dir_list = dir_list(contains({dir_list.name}, output_folder{end}));
                for i = 1:length(dir_list)
                    splitted_stack_path = strsplit(dir_list(i).folder, string(filesep));
                    createSymbolicLink(...
                        dir_list(i).folder + string(filesep) + dir_list(i).name,...
                        obj.output_path...
                        + string(filesep) + dir_list(i).name, obj.log_file_id);
                end
                tomogram_counter = length(dir_list);
            end
            
            % TODO: all the other previous input paths could have also been
            % batchruntomo not only the last one, introduce flag if batchruntomo
            % already ran
            if ~contains(obj.input_path, "BatchRunTomo") && obj.configuration.starting_step == 0
                filtered_dir_list = struct([]);
                tomogram_counter = 1;
                for i = 1:length(dir_list)
                    filtered_dir_list(tomogram_counter).name = dir_list(i).name;
                    filtered_dir_list(tomogram_counter).folder = dir_list(i).folder;
                    tilt_stack_file_path = string(dir_list(i).folder) + string(filesep) + string(dir_list(i).name);
                    tilt_stack_file = dir(tilt_stack_file_path);
                    
                    % NOTE: 3 for third entry because of "." and ".."
                    source = tilt_stack_file.folder + string(filesep) + tilt_stack_file.name;
                    source_path_split = strsplit(tilt_stack_file.folder, string(filesep));
                    
                    destination_path = obj.output_path;
                    destination = destination_path + string(filesep) + tilt_stack_file.name;
                    [status_mkdir, message, message_id] = mkdir(destination_path);
                    
                    disp("INFO: Linking from " + source + newline + " to "...
                        + destination + "!");
                    % TODO: Check status and / or output
                    createSymbolicLink(source, destination, obj.log_file_id);
                    tomogram_counter = tomogram_counter + 1;
                end
                dir_list = filtered_dir_list;
                % NOTE: correct the counter, because of matlabs plus one indexing
                tomogram_counter = tomogram_counter - 1;
            end
            
            % NOTE: contains(obj.input_path, "view_stacks") should be changed to better
            % condition because view_stacks may change
            if obj.configuration.starting_step == 10 && ~contains(obj.input_path, "view_stacks") % isfield(obj.configuration, "reconstruct_binned_stacks") && obj.configuration.reconstruct_binned_stacks ~= true &&
                ctf_correction_folder = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + "*CTFCorrection*");
                if isempty(ctf_correction_folder)
                    error("ERROR: forgot to run ctf correction module?");
                end
                defocus_file_path = string(ctf_correction_folder(1).folder) + string(filesep) + ctf_correction_folder(1).name;
                defocus_file = dir(defocus_file_path + string(filesep) + field_names(obj.configuration.set_up.j) + string(filesep) + field_names(obj.configuration.set_up.j) + ".defocus");
                if isempty(ctf_correction_folder)
                    disp("WARNING: no defocus file found!");
                    
                elseif obj.configuration.starting_step == 10 && ~isempty(ctf_correction_folder)
                    %defocus_dirs = unique({dir_list(:).folder});
                    %                     for i = 1:length(defocus_file)
                    %[folder, name, extension] = fileparts(defocus_file(obj.configuration.set_up.adjusted_j).folder);
                    
                    
                    % NOTE: 3 for third entry because of "." and ".."
                    source = defocus_file(1).folder + string(filesep) + defocus_file(1).name;
                    %                         source_path_split = strsplit(defocus_file(obj.configuration.set_up.adjusted_j).folder, "/");
                    
                    destination_path = obj.output_path;
                    destination = destination_path + string(filesep) + defocus_file(1).name;
                    %[status, message, message_id] = mkdir(destination_path);
                    
                    % TODO: Check status and / or output
                    if ~fileExists(destination)
                        disp("INFO: Linking from " + source + newline + " to "...
                            + destination + "!");
                        createSymbolicLink(source, destination, obj.log_file_id);
                    else
                        disp("INFO: File exists already!");
                    end
                    %                     end
                end
            end
            
            current_location = obj.output_path;
            
            % TODO: write out template file if the contents are given instead of the
            % file path itself
            if (isfield(obj.configuration, "skip_steps") && ~isempty(obj.configuration.skip_steps)) || obj.configuration.reconstruct_binned_stacks == true
                % TODO: skipping steps is probably working only for single skipped
                % steps not in row skipped ones, needs to be tested
                if obj.configuration.starting_step > 0
                    step_range = zeros([1 obj.configuration.starting_step]);
                else
                    step_range = [];
                end
                step_range = [step_range(:)' obj.configuration.starting_step:1:obj.configuration.ending_step];
                if isfield(obj.configuration, "skip_steps") && ~isempty(obj.configuration.skip_steps)
                    step_range(obj.configuration.skip_steps + 1) = -1;
                end
                %steps_to_be_skipped = find(step_range == -1);
                steps_to_be_skipped = step_range == -1;
                steps_to_be_skipped_1 = ~steps_to_be_skipped;
                steps_to_be_skipped_2 = cumsum(steps_to_be_skipped_1);
                steps_to_be_skipped_3 = steps_to_be_skipped_2 - 1;
                steps_to_be_skipped_4 = ones(size(steps_to_be_skipped_3));
                steps_to_be_skipped_4(2:end) = diff(steps_to_be_skipped_3);
                diff_steps_to_be_skipped = diff(steps_to_be_skipped_4);
                end_steps = [step_range(diff_steps_to_be_skipped == -1) obj.configuration.ending_step];
                begin_steps = [obj.configuration.starting_step step_range(find(diff_steps_to_be_skipped == 1) + 1)];
                for i = 1:length(end_steps)
                    if i > length(begin_steps)
                        break;
                    end
                    remove_index = end_steps(i) < begin_steps(i);
                    if any(remove_index)
                        end_steps(i) = [];
                        begin_steps(i) = [];
                    end
                end
                if length(end_steps) > length(begin_steps)
                    end_steps(length(begin_steps) + 1:end) = [];
                end
                for i = 1:tomogram_counter
                    directive_file_path = obj.configuration.processing_path + string(filesep) + obj.configuration.pipeline_step_output_folder + string(filesep) + obj.configuration.directive_file_name + ".adoc";
                    if obj.configuration.reconstruct_binned_stacks == true
                        splitted_name = strsplit(dir_list(i).name, "_");
                        binning_and_extension_splitted = strsplit(splitted_name{end}, ".");
                        directive_file_path = obj.configuration.processing_path + string(filesep) + obj.configuration.pipeline_step_output_folder + string(filesep) + obj.configuration.directive_file_name + "_" + "bin_" + string(binning_and_extension_splitted{1}) + ".adoc";
                        directives.setupset_copyarg_userawtlt = 0;
                        directives.runtime_AlignedStack_any_binByFactor = str2double(binning_and_extension_splitted{1}) / obj.configuration.ft_bin;
                        directives.comparam_tilt_tilt_THICKNESS = obj.configuration.reconstruction_thickness / directives.runtime_AlignedStack_any_binByFactor;
                        source = obj.output_path + string(filesep) + dir_list(i).name;
                        destination = obj.output_path + string(filesep) + strjoin(splitted_name(1:obj.configuration.angle_position - 1), "_");
                        if obj.configuration.starting_step >= 7
                            destination = destination + ".ali";
                        elseif obj.configuration.starting_step < 7
                            destination = destination + ".st";
                        else
                            error("ERROR: case for this starting step is not implemented!");
                        end
                        if fileExists(destination)
                            delete(destination);
                        end
                        [status_movefile, message, message_id] = movefile(source, destination);
                    else
                        directives.comparam_tilt_tilt_THICKNESS = obj.configuration.reconstruction_thickness / obj.configuration.aligned_stack_binning;
                    end
                    obj.dynamic_configuration.directive_file_struct = obj.generateDirectiveFile(directive_file_path, directives);
                    [folder, name, extension] = fileparts(dir_list(i).name);
                    tilt_stack_file_path = string(dir_list(i).folder) + string(filesep) + string(dir_list(i).name);
                    
                    for j = 1:length(end_steps)
                        splitted_name = strsplit(dir_list(1).name, ".");
                        if j == 1 && begin_steps(j) == 0
                            fid = fopen(current_location + string(filesep) + splitted_name{1} + ".rawtlt", "wt+");
                            %TODO: tilt_index_angle_mapping should come under tomogram and then the
                            %name in the structure
                            % NOTE: DIRTY
                            if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, splitted_name{1}) || isempty(obj.configuration.tilt_index_angle_mapping.(splitted_name{1}))
                                angles = sort(obj.configuration.tomograms.(splitted_name{1}).tilt_index_angle_mapping(2,:));
                                angles = angles(find(obj.configuration.tomograms.(splitted_name{1}).tilt_index_angle_mapping(3,:)));
                            else
                                angles = sort(obj.configuration.tilt_index_angle_mapping.(splitted_name{1})(2,:));
                                angles = angles(find(obj.configuration.tilt_index_angle_mapping.(splitted_name{1})(3,:)));
                            end
                            %                             angles = sort(angles);
                            for k = 1:length(angles)
                                %                                 if obj.configuration.tomograms.(splitted_name{1}).tilt_index_angle_mapping(5,k) == 0
                                fprintf(fid, "%0.2f\n", angles(k));
                                %                                 else
                                %                                     fprintf(fid, "%0.2f\n", 0);
                                %                                 end
                            end
                            fclose(fid);
                        end
                        
                        if end_steps(j) == 3 && ~fileExists(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".point") && ~obj.configuration.reconstruct_binned_stacks
                            end_steps(j) = 5;
                            %obj.dynamic_configuration.ending_step = obj.configuration.ending_step;
                            %disp("INFO: updated ending step to step " + obj.dynamic_configuration.ending_step + " due to incorrect DynamoTiltSeriesAlignment!");
                        end
                        
                        command = "batchruntomo"...
                            + " -DirectiveFile "  + directive_file_path;
                        if obj.configuration.reconstruct_binned_stacks == false
                            command = command + " -CurrentLocation " + obj.output_path...
                                + " -RootName " + splitted_name{1};
                        else
                            % TODO: needs test
                            splitted_splitted_name = strsplit(splitted_name{1}, "_");
                            command = command + " -CurrentLocation " + obj.output_path...
                                + " -RootName " + strjoin(splitted_splitted_name(1:obj.configuration.angle_position - 1), "_");
                        end
                        
                        %command = command + " -StartingStep " + starting_step;
                        command = command + " -StartingStep " + begin_steps(j);
                        command = command + " -EndingStep " + end_steps(j);
                        %                         if j == length(steps_to_be_skipped) + 1
                        %                             command = command + " -EndingStep " + obj.configuration.ending_step;
                        %                         else
                        %                             command = command + " -EndingStep " + (steps_to_be_skipped(j) - 1);
                        %                         end
                        
                        % TODO: check if the second flag in execute command is needed
                        if obj.configuration.exit_on_error == true
                            command = command + " -ExitOnError";
                        end
                        
                        if obj.configuration.cpu_machine_list ~= ""
                            command = command + " -CPUMachineList " + obj.configuration.cpu_machine_list;
                        end
                        
                        
                        % TODO: remove misha flag
                        if (end_steps(j) == 6 || end_steps(j) == 8)...
                                && (~fileExists(current_location + string(filesep) + splitted_name{1} + ".seed") || ~fileExists(current_location + string(filesep) + splitted_name{1} + ".fid"))...
                                && fileExists(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".point")...
                                && obj.configuration.take_fiducials_from_dynamo && ~obj.configuration.reconstruct_binned_stacks
                            
                            if begin_steps(j) == 5 || begin_steps(j) == 6
                                point_file = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".point");
                                % TODO: parse output from executeCommand and
                                % replace system, make symbolic link instead of
                                % copy file
                                [status_system, realpath_output] = system("realpath " + point_file(1).folder + string(filesep) + point_file(1).name);
                                [status_copyfile, message, message_id] = copyfile(realpath_output(1:end-1), current_location + string(filesep) + point_file(1).name);
                                
                                fid = fopen(realpath_output(1:end-1), 'rt');
                                point_file_content = textscan(fid, '%d %f %f %d');
                                fclose(fid);
                                prexg_file = dir(current_location + string(filesep) + splitted_name{1} + ".prexg");
                                fid = fopen(prexg_file(1).folder + string(filesep) + prexg_file(1).name, 'rt');
                                prexg_file_content = textscan(fid, '%f %f %f %f %f %f');
                                fclose(fid);
                            end
                            
                            %                                                     prexg_file = dir(current_location + string(filesep) + splitted_name{1} + ".prexg");
                            %                             fid = fopen(prexg_file(1).folder + string(filesep) + prexg_file(1).name, 'rt');
                            %                             prexg_file_content = textscan(fid, '%f %f %f %f %f %f');
                            %                             fclose(fid);
                            
                            % x_shifts = (point_file_content{1,2} + prexg_file_content{1,5}(point_file_content{1,4} + 1)) / obj.configuration.pre_aligned_stack_binning;
                            % y_shifts = (point_file_content{1,3} + prexg_file_content{1,6}(point_file_content{1,4} + 1)) / obj.configuration.pre_aligned_stack_binning;
                            x_shifts = (point_file_content{1,2} / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin)...
                                + (prexg_file_content{1,5}(point_file_content{1,4} + 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin);
                            y_shifts = (point_file_content{1,3} / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin)...
                                + (prexg_file_content{1,6}(point_file_content{1,4} + 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin);
                            fid = fopen(current_location + string(filesep) + point_file(1).name, "wt+");
                            for k = 1:length(point_file_content{1,1})
                                fprintf(fid, "%0.0f %0.2f %0.2f %0.0f\n", point_file_content{1,1}(k), x_shifts(k), y_shifts(k), point_file_content{1,4}(k));
                            end
                            fclose(fid);
                            if begin_steps(j) == 6
                                [status_system, poin2model_output] = system("point2model " + current_location + string(filesep) + point_file(1).name + " " + current_location + string(filesep) + splitted_name{1} + ".fid -image " + current_location + string(filesep) + splitted_name{1} + ".preali");
                            elseif begin_steps(j) == 5
                                [status_system, poin2model_output] = system("point2model " + current_location + string(filesep) + point_file(1).name + " " + current_location + string(filesep) + splitted_name{1} + ".seed -image " + current_location + string(filesep) + splitted_name{1} + ".preali");
                            elseif begin_steps(j) == 0 || begin_steps(j) == 8
                            else
                                error("ERROR: skip steps " + num2str(begin_steps(j)) - 1 + " not implementend");
                            end
                        end
                        if end_steps(j) == 6 && begin_steps(j) == 5
                            fid = fopen(current_location + string(filesep) + "track.com", "r");
                            tline = {};
                            counter = 1;
                            while ~feof(fid)
                                tmp = fgetl(fid);
                                if ~contains(string(tmp), "SeparateGroup")
                                    tline{counter} = tmp;
                                    counter = counter + 1;
                                end
                            end
                            fclose(fid);
                            
                            fid = fopen(current_location + string(filesep) + "track.com", "w");
                            for k = 1:length(tline)
                                fprintf(fid, "%s\n", tline{k});
                            end
                            fclose(fid);
                            
                        end
                        %% ERROR: batchruntomo - A value was expected but not found for the last option on the command line
                        
                        output = executeCommand(command, true, obj.log_file_id);
                            
                        % NOTE: just removing some garbage
                        if contains(output, "processchunks ERROR: align.com has given processing error")
                            disp("WARNING:COMMAND_OUTPUT: " + output);
                            output = erase(output, "ERROR: align.com has given processing error");
                        end

                        if contains(output, "ERROR: TILTALIGN - TOO FEW DATA POINTS TO DO ROBUST FITTING")
                            disp("WARNING:COMMAND_OUTPUT: " + output);
                            new_output = erase(output, "ERROR: TILTALIGN - TOO FEW DATA POINTS TO DO ROBUST FITTING");
                            if contains(new_output, "ERROR:")
                                disp("WARNING:NEW_COMMAND_OUTPUT: " + new_output);
                                obj.status = 0;
                                return;
                            end
                        elseif contains(output, "ERROR: FINDBEADS3D - No histogram dip found for initial peaks; enter positive -thresh to proceed")
                            % TODO: needs testing if this works without
                            %                             % following code lines
                            %                             rmdir(obj.configuration.processing_path...
                            %                                 + string(filesep) + obj.configuration.output_folder...
                            %                                 + string(filesep) + obj.configuration.binned_aligned_tilt_stacks_folder...
                            %                                 + string(filesep) + splitted_name{1}, "s");
                            %                             rmdir(obj.configuration.processing_path...
                            %                                 + string(filesep) + obj.configuration.output_folder...
                            %                                 + string(filesep) + obj.configuration.aligned_tilt_stacks_folder...
                            %                                 + string(filesep) + splitted_name{1}, "s");
                            %                             obj.status = 0;
                            %                             return;
                            %                         elseif contains(output, "ERROR: align.com has given processing error 1 times") && contains(output, "ERROR: TILTALIGN - Search failed even after varying step factor")
                            %                             new_output = erase(output, "ERROR: align.com has given processing error 1 times");
                            %                             new_output = erase(new_output, "ERROR: TILTALIGN - Search failed even after varying step factor");
                            %                             if contains(new_output, "ERROR:")
                            %                                 disp("WARNING:NEW_COMMAND_OUTPUT: " + new_output);
                            %                                 obj.status = 0;
                            %                                 return;
                            %                             end
                        elseif contains(output, "ERROR:")
                            disp("WARNING:COMMAND_OUTPUT: " + output);
                            obj.status = 0;
                            return;
                        elseif contains(output, "ABORT SET:")
                            disp("WARNING:COMMAND_OUTPUT: " + output);
                            obj.status = 0;
                            return;
                        end
                        
                        % TODO: remove misha flag
                        if end_steps(j) == 3 ...
                                && fileExists(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".point")...
                                && ~obj.configuration.reconstruct_binned_stacks && obj.configuration.take_fiducials_from_dynamo == true
                            point_file = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".point");
                            % TODO: parse output from executeCommand and
                            % replace system, make symbolic link instead of
                            % copy file
                            [status_system, realpath_output] = system("realpath " + point_file(1).folder + string(filesep) + point_file(1).name);
                            [status_copyfile, message, message_id] = copyfile(realpath_output(1:end-1), current_location + string(filesep) + point_file(1).name);
                            
                            fid = fopen(realpath_output(1:end-1), 'rt');
                            point_file_content = textscan(fid, '%d %f %f %d');
                            fclose(fid);
                            prexg_file = dir(current_location + string(filesep) + splitted_name{1} + ".prexg");
                            fid = fopen(prexg_file(1).folder + string(filesep) + prexg_file(1).name, 'rt');
                            prexg_file_content = textscan(fid, '%f %f %f %f %f %f');
                            fclose(fid);
                            %
                            %                             x_shifts = (point_file_content{1,2}) / obj.configuration.pre_aligned_stack_binning; %(point_file_content{1,2} + prexg_file_content{1,5}(point_file_content{1,4} + 1)) / obj.configuration.pre_aligned_stack_binning;
                            %                             y_shifts = (point_file_content{1,3}) / obj.configuration.pre_aligned_stack_binning; %(point_file_content{1,3} + prexg_file_content{1,6}(point_file_content{1,4} + 1)) / obj.configuration.pre_aligned_stack_binning;
                            %
                            %                             fid = fopen(current_location + string(filesep) + point_file(1).name, "wt+");
                            %                             for k = 1:length(point_file_content{1,1})
                            %                                 fprintf(fid, "%0.0f %0.2f %0.2f %0.0f\n", point_file_content{1,1}(k), x_shifts(k), y_shifts(k), point_file_content{1,4}(k));
                            %                             end
                            %                             fclose(fid);
                            %
                            %                             [status, poin2model_output] = system("point2model " + current_location + string(filesep) + point_file(1).name + " " + current_location + string(filesep) + splitted_name{1} + ".fid");
                            %
                            % TODO: needs to be adapted for other angular
                            % increments
                            
                            fid = fopen(current_location + string(filesep) + splitted_name{1} + ".seed_model", "wt+");
                            if obj.configuration.generate_seed_model_with_all_fiducials_from_dynamo == true
                                seed_points_x = (point_file_content{1,2} / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin)...
                                    + (prexg_file_content{1,5}(point_file_content{1,4} + 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin);
                                seed_points_y = (point_file_content{1,3} / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin)...
                                    + (prexg_file_content{1,6}(point_file_content{1,4} + 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin);
                                seed_points_tilt = point_file_content{1, 4};
                                seed_points_contour = point_file_content{1, 1};
                            else
                                seed_points_x = (point_file_content{1,2}(point_file_content{1,4} == find(angles == 0) - 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin)...
                                    + (prexg_file_content{1,5}(point_file_content{1,4}(point_file_content{1,4} == find(angles == 0) - 1) + 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin);
                                seed_points_y = (point_file_content{1,3}(point_file_content{1,4} == find(angles == 0) - 1)  / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin)...
                                    + (prexg_file_content{1,6}(point_file_content{1,4}(point_file_content{1,4} == find(angles == 0) - 1) + 1) / obj.configuration.pre_aligned_stack_binning * obj.configuration.ft_bin);
                                seed_points_tilt = point_file_content{1, 4}(point_file_content{1,4} == find(angles == 0) - 1);
                                seed_points_contour = point_file_content{1, 1}(point_file_content{1,4} == find(angles == 0) - 1);
                            end
                            for k = 1:length(seed_points_x)
                                fprintf(fid, "%0.0f %0.2f %0.2f %0.0f\n", seed_points_contour(k), seed_points_x(k) , seed_points_y(k), seed_points_tilt(k));
                            end
                            fclose(fid);
                            if begin_steps(j+1) == 5
                                if fileExists(current_location + string(filesep) + splitted_name{1} + ".preali")
                                    [status_system, poin2model_output] = system("point2model " + current_location + string(filesep) + splitted_name{1} + ".seed_model" + " " + current_location + string(filesep) + splitted_name{1} + ".seed -image " + current_location + string(filesep) + splitted_name{1} + ".preali"); % -circle
                                else
                                    [status_system, poin2model_output] = system("point2model " + current_location + string(filesep) + splitted_name{1} + ".seed_model" + " " + current_location + string(filesep) + splitted_name{1} + ".seed -image " + current_location + string(filesep) + splitted_name{1} + "_preali.mrc"); % -circle
                                end
                            elseif begin_steps(j+1) == 6
                                if fileExists(current_location + string(filesep) + splitted_name{1} + ".preali")
                                    [status_system, poin2model_output] = system("point2model " + current_location + string(filesep) + splitted_name{1} + ".seed_model" + " " + current_location + string(filesep) + splitted_name{1} + ".fid -image " + current_location + string(filesep) + splitted_name{1} + ".preali"); % -circle
                                else
                                    [status_system, poin2model_output] = system("point2model " + current_location + string(filesep) + splitted_name{1} + ".seed_model" + " " + current_location + string(filesep) + splitted_name{1} + ".fid -image " + current_location + string(filesep) + splitted_name{1} + "_preali.mrc"); % -circle
                                end
                            end
                            
                            % % % % % %                             %[success, message, message_id] = copyfile(current_location + string(filesep) + splitted_name{1} + ".fid", current_location + string(filesep) + splitted_name{1} + ".seed");
                            % % % % % %                             %                         field_names = fieldnames(obj.configuration.tomograms);
                            % % % % % %                             %                         angles = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping(2,:);
                            % % % % % %                             %                         % TODO: save falgs as boolean in CreateStacks
                            % % % % % %                             %                         % module
                            % % % % % %                             %                         angles = angles(boolean(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping(3,:)));
                            % % % % % %                             %                         tlt_file_name = current_location + string(filesep) + string(field_names{obj.configuration.set_up.j}) + ".rawtlt";
                            % % % % % %                             %                         fileID = fopen(tlt_file_name, "w");
                            % % % % % %                             %                         for i = 1:length(angles)
                            % % % % % %                             %                             fprintf(fileID, "%0.2f\n", angles(i));
                            % % % % % %                             %                         end
                            % % % % % %                             %                         fclose(fileID);
                        end
                        % TODO: reconstruction without full
                        if obj.configuration.ending_step > 14 && end_steps(j) > 14 && ~obj.configuration.reconstruct_binned_stacks
                            if fileExists(obj.configuration, current_location + string(filesep) + name + ".rec")
                                createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + ".rec", "ctf_corrected_tomograms_folder", obj.log_file_id);
                            else
                                createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + "_rec.mrc", "ctf_corrected_tomograms_folder", obj.log_file_id);
                            end
                        end
                        if end_steps(j) >= 8 % obj.configuration.ending_step == 8
                            if obj.configuration.aligned_stack_binning > 1
                                [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder + string(filesep) + name);
                                if fileExists(current_location + string(filesep) + name + ".ali")
                                    createSymbolicLink(current_location + string(filesep) + name + ".ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + "_bin_" + obj.configuration.aligned_stack_binning + ".ali", obj.log_file_id);
                                else
                                    createSymbolicLink(current_location + string(filesep) + name + "_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + "_bin_" + obj.configuration.aligned_stack_binning + ".ali", obj.log_file_id);
                                end
                                if end_steps(j) == 8
                                    xf_file = dir(current_location + string(filesep) + name + ".xf");
                                    [status, command_output] = system("header -s " + tilt_stack_file_path);
                                    command_output = str2num(command_output);
                                    status = system("newstack -InputFile " + tilt_stack_file_path...
                                        + " -OutputFile " + current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali -TransformFile "...
                                        + xf_file(i).folder + string(filesep) + xf_file(i).name + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin -SizeToOutputInXandY "...
                                        + num2str(command_output(2)) + "," + num2str(command_output(1))  + " -TaperAtFill 1,0");
                                    [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_tilt_stacks_folder + string(filesep) + name);
                                    if fileExists(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali")
                                        createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                    else
                                        createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                    end
                                    
                                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                                        even_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, false);
                                        status = system("newstack -InputFile " + even_tilt_stacks{obj.configuration.set_up.adjusted_j}.folder + filesep + even_tilt_stacks{obj.configuration.set_up.adjusted_j}.name...
                                            + " -OutputFile " + current_location + string(filesep) + name + "_bin_" + num2str(1) + "_even.ali -TransformFile "...
                                            + xf_file(i).folder + string(filesep) + xf_file(i).name + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin -SizeToOutputInXandY "...
                                            + num2str(command_output(2)) + "," + num2str(command_output(1))  + " -TaperAtFill 1,0");
                                        [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_even_tilt_stacks_folder + string(filesep) + name);
                                        if fileExists(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali")
                                            createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_even.ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_even_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                        else
                                            createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_even_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_even_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                        end
                                        
                                        odd_tilt_stacks = getOddTiltStacksFromStandardFolder(obj.configuration, false);
                                        status = system("newstack -InputFile " + odd_tilt_stacks{obj.configuration.set_up.adjusted_j}.folder + filesep + odd_tilt_stacks{obj.configuration.set_up.adjusted_j}.name...
                                            + " -OutputFile " + current_location + string(filesep) + name + "_bin_" + num2str(1) + "_odd.ali -TransformFile "...
                                            + xf_file(i).folder + string(filesep) + xf_file(i).name + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin -SizeToOutputInXandY "...
                                            + num2str(command_output(2)) + "," + num2str(command_output(1))  + " -TaperAtFill 1,0");
                                        [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_odd_tilt_stacks_folder + string(filesep) + name);
                                        if fileExists(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali")
                                            createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_odd.ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_odd_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                        else
                                            createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_odd_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_odd_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                        end
                                    end
                                end
                            else
                                if fileExists(obj.configuration, current_location + string(filesep) + name + ".ali")
                                    createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + ".ali", "ctf_corrected_aligned_tilt_stacks_folder", obj.log_file_id);
                                else
                                    createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + "_ali.mrc", "ctf_corrected_aligned_tilt_stacks_folder", obj.log_file_id);
                                end
                            end
                        end
                        
                        %                         if j < length(steps_to_be_skipped) + 1
                        %                             starting_step = steps_to_be_skipped(j) + 1;
                        %                         end
                    end
                    if obj.configuration.reconstruct_binned_stacks == true
                        [status_movefile, message, message_id] = movefile(destination, source);
                        
                        destination_splitted = strsplit(destination, ".");
                        destination_splitted(end) = "rec";
                        
                        source_splitted = strsplit(source, ".");
                        source_splitted(end) = "rec";
                        
                        tomogram_destination = strjoin(destination_splitted, ".");
                        tomogram_source = strjoin(source_splitted, ".");
                        [status_movefile, message, message_id] = movefile(tomogram_destination, tomogram_source);
                        binned_tomograms_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_tomograms_folder + string(filesep);
                        link_destination_path = binned_tomograms_path + strjoin(splitted_splitted_name(1:end - 2), "_");
                        if ~exist(link_destination_path, "dir")
                            [status_mkdir, message, message_id] = mkdir(link_destination_path);
                        end
                        
                        link_destination = link_destination_path + string(filesep) + strjoin([splitted_splitted_name(1:end-1), binning_and_extension_splitted(1)],"_") + ".rec";
                        if fileExists(link_destination)
                            createSymbolicLink(tomogram_source, link_destination, obj.log_file_id);
                        else
                            link_destination = link_destination_path + string(filesep) + strjoin([splitted_splitted_name(1:end-1), binning_and_extension_splitted(1)],"_") + "_rec.mrc";
                            createSymbolicLink(tomogram_source, link_destination, obj.log_file_id);
                        end
                    end
                end
            else
                for i = 1:tomogram_counter
                    directive_file_path = obj.configuration.processing_path + string(filesep) + obj.configuration.pipeline_step_output_folder + string(filesep) + obj.configuration.directive_file_name + ".adoc";
                    obj.dynamic_configuration.directive_file_struct = obj.generateDirectiveFile(directive_file_path);
                    
                    splitted_name = strsplit(dir_list(i).name, ".");
                    
                    
                    if (obj.configuration.starting_step == 10 && obj.configuration.ending_step == 13)
                        [status, output] = system("cp " + current_location + string(filesep) + splitted_name{1} + ".rawtlt " + current_location + string(filesep) + splitted_name{1} + ".tlt");
                        fid = fopen(current_location + string(filesep) + "ctfcorrection.com", "r+");
                        file_content = textscan(fid, "%s", "Delimiter", "", "endofline", "\n");
                        file_content = file_content{1};
                        %status = fseek(fid, 0, "bof");
                        fclose(fid);
                        fid = fopen(current_location + string(filesep) + "ctfcorrection.com", "w+");
                        for k = 1:length(file_content)-1
                            fprintf(fid,"%s\n",file_content{k});
                        end
                        fprintf(fid,"MaximumStripWidth = %s\n", num2str(obj.configuration.maximum_strip_width));
                        fprintf(fid,"%s\n",file_content{length(file_content)});
                        fclose(fid);
                    end
                    
                    % NOTE: DIRTY HACK FOR MISHA
                    if obj.configuration.starting_step == 0 % (obj.configuration.starting_step == 8 && obj.configuration.ending_step == 8) ||
                        if fileExists(current_location + string(filesep) + splitted_name{1} + ".rawtlt")
                            delete(current_location + string(filesep) + splitted_name{1} + ".rawtlt");
                        end
                        
                        fid = fopen(current_location + string(filesep) + splitted_name{1} + ".rawtlt", "wt+");
                        %TODO: tilt_index_angle_mapping should come under tomogram and then the
                        %name in the structure
                        % NOTE: DIRTY
                        if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, splitted_name{1})
                            angles = sort(obj.configuration.tomograms.(splitted_name{1}).tilt_index_angle_mapping(2,:));
                            angles = angles(find(obj.configuration.tomograms.(splitted_name{1}).tilt_index_angle_mapping(3,:)));
                        else
                            angles = sort(obj.configuration.tilt_index_angle_mapping.(splitted_name{1})(2,:));
                            angles = angles(find(obj.configuration.tilt_index_angle_mapping.(splitted_name{1})(3,:)));
                        end
                        
                        %                         angles = sort(angles);
                        
                        for k = 1:length(angles)
                            if obj.configuration.tomograms.(splitted_name{1}).tilt_index_angle_mapping(5,k) == 0
                                fprintf(fid, "%0.2f\n", angles(k));
                            else
                                fprintf(fid, "%0.2f\n", 0);
                            end
                        end
                        fclose(fid);
                    end
                    
                    
                    
                    if obj.configuration.starting_step == 0 && obj.configuration.ending_step == 3 && fileExists(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".fid")
                        point_file_content = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".fid");
                        % TODO: parse output from executeCommand and
                        % replace system, make symbolic link instead of
                        % copy file
                        [status_system, realpath_output] = system("realpath " + point_file_content(1).folder + string(filesep) + point_file_content(1).name);
                        [status_copyfile, message, message_id] = copyfile(realpath_output(1:end-1), current_location + string(filesep) + point_file_content(1).name);
                        
                        %                         field_names = fieldnames(obj.configuration.tomograms);
                        %                         angles = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping(2,:);
                        %                         % TODO: save falgs as boolean in CreateStacks
                        %                         % module
                        %                         angles = angles(boolean(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping(3,:)));
                        %                         tlt_file_name = current_location + string(filesep) + string(field_names{obj.configuration.set_up.j}) + ".rawtlt";
                        %                         fileID = fopen(tlt_file_name, "w");
                        %                         for i = 1:length(angles)
                        %                             fprintf(fileID, "%0.2f\n", angles(i));
                        %                         end
                        %                         fclose(fileID);
                    elseif obj.configuration.starting_step == 0 && obj.configuration.ending_step == 3 && ~fileExists(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.fid_files_folder + string(filesep) + splitted_name{1} + string(filesep) + splitted_name{1} + ".fid")
                        obj.configuration.ending_step = 5;
                        %obj.dynamic_configuration.ending_step = obj.configuration.ending_step;
                        %disp("INFO: updated ending step to step " + obj.dynamic_configuration.ending_step + " due to incorrect DynamoTiltSeriesAlignment!");
                    end
                    
                    command = "batchruntomo"...
                        + " -DirectiveFile "  + directive_file_path...
                        + " -CurrentLocation " + current_location...
                        + " -RootName " + splitted_name{1}...
                        + " -StartingStep " + obj.configuration.starting_step...
                        + " -EndingStep " + obj.configuration.ending_step;
                    
                    % TODO: check if the second flag in execute command is needed
                    if obj.configuration.exit_on_error == true
                        command = command + " -ExitOnError";
                    end
                    
                    if obj.configuration.cpu_machine_list ~= ""
                        command = command + " -CPUMachineList " + obj.configuration.cpu_machine_list;
                    end
                    
                    
                    output = executeCommand(command, true, obj.log_file_id);
                    
                    % NOTE: just removing some garbage
                    if contains(output, "processchunks ERROR: align.com has given processing error")
                        disp("WARNING:COMMAND_OUTPUT: " + output);
                        output = erase(output, "ERROR: align.com has given processing error");
                    end

                    if contains(output, "ERROR: TILTALIGN - TOO FEW DATA POINTS TO DO ROBUST FITTING")
                        disp("WARNING:COMMAND_OUTPUT: " + output);
                        new_output = erase(output, "ERROR: TILTALIGN - TOO FEW DATA POINTS TO DO ROBUST FITTING");
                        if contains(new_output, "ERROR:")
                            disp("WARNING:NEW_COMMAND_OUTPUT: " + new_output);
                            obj.status = 0;
                            return;
                        end
                    elseif contains(output, "ERROR: FINDBEADS3D - No histogram dip found for initial peaks; enter positive -thresh to proceed")
                        % TODO: needs testing if this works without
                        %                             % following code lines
                        %                             rmdir(obj.configuration.processing_path...
                        %                                 + string(filesep) + obj.configuration.output_folder...
                        %                                 + string(filesep) + obj.configuration.binned_aligned_tilt_stacks_folder...
                        %                                 + string(filesep) + splitted_name{1}, "s");
                        %                             rmdir(obj.configuration.processing_path...
                        %                                 + string(filesep) + obj.configuration.output_folder...
                        %                                 + string(filesep) + obj.configuration.aligned_tilt_stacks_folder...
                        %                                 + string(filesep) + splitted_name{1}, "s");
                        %                             obj.status = 0;
                        %                             return;
                    elseif contains(output, "ERROR:")
                        disp("WARNING:COMMAND_OUTPUT: " + output);
                        obj.status = 0;
                        return;
                    elseif contains(output, "ABORT SET:")
                        disp("WARNING:COMMAND_OUTPUT: " + output);
                        obj.status = 0;
                        return;
                    end
                    % TODO: parse output for error
                    %"INFO:VARIABLE:command: batchruntomo -DirectiveFile /sbdata/PTMP/nibalysc/wechen/2019-10-07_wechen_triad/output_three_tomograms/9_BatchRunTomo_1/tomogram_001/DirectiveFile.adoc -CurrentLocation /sbdata/PTMP/nibalysc/wechen/2019-10-07_wechen_triad/output_three_tomograms/9_BatchRunTomo_1/tomogram_001 -RootName tomogram_001 -StartingStep 10 -EndingStep 13 -ExitOnError -CPUMachineList
                    %INFO:VARIABLE:command_output: ERROR: batchruntomo - A value was expected but not found for the last option on the command line"
                    [folder, name, extension] = fileparts(dir_list(i).name);
                    tilt_stack_file_path = string(dir_list(i).folder) + string(filesep) + string(dir_list(i).name);
                    
                    if obj.configuration.ending_step >= 8
                        if obj.configuration.aligned_stack_binning > 1
                            [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder + string(filesep) + name);
                            if fileExists(current_location + string(filesep) + name + "_ali.mrc")
                                createSymbolicLink(current_location + string(filesep) + name + "_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + "_bin_" + obj.configuration.aligned_stack_binning + ".ali", obj.log_file_id);
                            else
                                createSymbolicLink(current_location + string(filesep) + name + ".ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + "_bin_" + obj.configuration.aligned_stack_binning + ".ali", obj.log_file_id);
                            end
                            if obj.configuration.ending_step == 8
                                xf_file = dir(current_location + string(filesep) + name + ".xf");
                                [status, command_output] = system("header -s " + tilt_stack_file_path);
                                command_output = str2num(command_output);
                                status = system("newstack -InputFile " + tilt_stack_file_path...
                                    + " -OutputFile " + current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali -TransformFile "...
                                    + xf_file(i).folder + string(filesep) + xf_file(i).name + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin -SizeToOutputInXandY "...
                                    + num2str(command_output(2)) + "," + num2str(command_output(1))  + " -TaperAtFill 1,0");
                                [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_tilt_stacks_folder + string(filesep) + name);
                                if fileExists(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali")
                                    createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                else
                                    createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                end
                                
                                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                                    even_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
                                    status = system("newstack -InputFile " + even_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + even_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                                        + " -OutputFile " + current_location + string(filesep) + name + "_bin_" + num2str(1) + "_even.ali -TransformFile "...
                                        + xf_file(i).folder + string(filesep) + xf_file(i).name + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin -SizeToOutputInXandY "...
                                        + num2str(command_output(2)) + "," + num2str(command_output(1))  + " -TaperAtFill 1,0");
                                    [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_even_tilt_stacks_folder + string(filesep) + name);
                                    if fileExists(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali")
                                        createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_even.ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_even_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                    else
                                        createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_even_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_even_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                    end
                                    
                                    odd_tilt_stacks = getOddTiltStacksFromStandardFolder(obj.configuration, true);
                                    status = system("newstack -InputFile " + odd_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + odd_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                                        + " -OutputFile " + current_location + string(filesep) + name + "_bin_" + num2str(1) + "_odd.ali -TransformFile "...
                                        + xf_file(i).folder + string(filesep) + xf_file(i).name + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin -SizeToOutputInXandY "...
                                        + num2str(command_output(2)) + "," + num2str(command_output(1))  + " -TaperAtFill 1,0");
                                    [success, message, message_id] = mkdir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_odd_tilt_stacks_folder + string(filesep) + name);
                                    if fileExists(current_location + string(filesep) + name + "_bin_" + num2str(1) + ".ali")
                                        createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_odd.ali", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_odd_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                    else
                                        createSymbolicLink(current_location + string(filesep) + name + "_bin_" + num2str(1) + "_odd_ali.mrc", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.aligned_odd_tilt_stacks_folder + string(filesep) + name + string(filesep) + name + ".ali", obj.log_file_id);
                                    end
                                end
                            end
                        else
                            [folder, name, extension] = fileparts(dir_list(i).name);
                            if fileExists(obj.configuration, current_location + string(filesep) + name + ".ali")
                                createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + ".ali", "ctf_corrected_aligned_tilt_stacks_folder", obj.log_file_id);
                            else
                                createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + "_ali.mrc", "ctf_corrected_aligned_tilt_stacks_folder", obj.log_file_id);
                            end
                        end
                    end
                    % TODO:NOTE: infact step 21
                    if obj.configuration.ending_step > 14
                        if fileExists(obj.configuration, current_location + string(filesep) + name + ".rec")
                            createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + ".rec", "ctf_corrected_tomograms_folder", obj.log_file_id);
                        else
                            createSymbolicLinkInStandardFolder(obj.configuration, current_location + string(filesep) + name + "_rec.mrc", "ctf_corrected_tomograms_folder", obj.log_file_id);
                        end
                    end
                end
            end
            
            % TODO: decide if dynamic_configuration is needed at all because it makes sometimes hard to change parameters during runs
            %obj.dynamic_configuration.pre_aligned_stack_binning = obj.configuration.pre_aligned_stack_binning;
            %obj.dynamic_configuration.aligned_stack_binning = obj.configuration.aligned_stack_binning;
            % TODO: need to do error checking of output of batchruntomo
            % commadn to set the flag properly
            disp("INFO: Batchruntomo from step " + obj.configuration.starting_step + " to step " + obj.configuration.ending_step + " done!");
        end
        
        function directive_file_struct = generateDirectiveFile(obj, directive_file_path, directives)
            if nargin == 2
                directives = obj.configuration.directives;
            else
                directives = obj.mergeConfigurations(obj.configuration.directives, directives);
            end
            field_names = fieldnames(obj.configuration.tomograms);
            [path, name, extension] = fileparts(directive_file_path);
            splitted_path = strsplit(path, string(filesep));
            tilt_index_angle_mapping = obj.configuration.tomograms.(splitted_path{end}).tilt_index_angle_mapping;
            
            
            starting_angle_index = find(tilt_index_angle_mapping(3,:) == 1, 1, "first");
            ending_angle_index = find(tilt_index_angle_mapping(3,:) == 1, 1, "last");
            starting_angle = tilt_index_angle_mapping(2, starting_angle_index);
            
            % TODO: make a more robust condition for angle_increment or provide a
            % configuration parameter
            angle_increment = abs(starting_angle - tilt_index_angle_mapping(2, starting_angle_index + 1));
            
            directive_file_id = fopen(directive_file_path, 'w');
            % NOTE: merge values from configuration file (json) into template file, if
            % not applicable let them as are and replace some importnat variables
            % automaically, remove entries from configuration file
            if isfield(obj.configuration, "template_file") && ~isempty(obj.configuration.template_file) && fileExists(obj.configuration.template_file)
                tilt_index_angle_mapping = obj.configuration.tomograms.(splitted_path{end});
                template_file_id  = fopen(obj.configuration.template_file,'r');
                template_file = textscan(template_file_id,"%s","Delimiter","","endofline","\n");
                template_file = template_file{1};
                directive_file_struct = struct();
                for i = 1:length(template_file)
                    template_file_line = template_file{i};
                    template_file_line_trimmed = strtrim(template_file_line);
                    if template_file_line_trimmed(1) == "#"
                        continue;
                    end
                    value = textscan(template_file_line_trimmed,"%s","Delimiter","=","endofline","\n");
                    key_value = value{1};
                    key = key_value{1};
                    % NOTE: need to replace '.' with '_'
                    key_trimmed = strtrim(key);
                    key_cleaned = strrep(key_trimmed,".","_");
                    if isfield(directives, key_cleaned)
                        value_trimmed = directives.(key_cleaned);
                    else
                        value_trimmed = strtrim(key_value{2});
                    end
                    if isstring(value_trimmed) && value_trimmed == "<REPLACE>"
                        switch key_trimmed
                            case "setupset.copyarg.pixel"
                                if isfield(obj.configuration, "apix")
                                    apix = obj.configuration.apix * obj.configuration.ft_bin;
                                else
                                    apix = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix * obj.configuration.ft_bin;
                                end
                                value_trimmed = num2str(apix / 10);
                            case "runtime.AlignedStack.any.binByFactor"
                                value_trimmed = num2str(obj.configuration.aligned_stack_binning / obj.configuration.ft_bin);
                            case "setupset.copyarg.Cs"
                                value_trimmed = num2str(obj.configuration.spherical_aberation);
                            case "comparam.tilt.tilt.THICKNESS"
                                value_trimmed = num2str(obj.configuration.reconstruction_thickness);
                            case "runtime.GoldErasing.any.thickness"
                                value_trimmed = num2str(obj.configuration.reconstruction_thickness);
                            case "setupset.copyarg.voltage"
                                value_trimmed = num2str(obj.configuration.keV);
                            case "comparam.prenewst.newstack.BinByFactor"
                                %value = num2str(obj.configuration.aligned_stack_binning);
                                value_trimmed = num2str(obj.configuration.pre_aligned_stack_binning / obj.configuration.ft_bin);
                            case "setupset.copyarg.firstinc"
                                value_trimmed = num2str(starting_angle) + " " + num2str(angle_increment);
                            case "setupset.copyarg.gold"
                                value_trimmed = num2str(obj.configuration.gold_bead_size_in_nm);
                            case "setupset.copyarg.rotation"
                                value_trimmed = num2str(obj.configuration.rotation_tilt_axis);
                            case "setupset.copyarg.defocus"
                                value_trimmed = num2str(obj.configuration.nominal_defocus_in_nm);
                            case "comparam.align.tiltalign.SeparateGroup"
                                %value_trimmed = num2str(starting_angle_index) + "-" + num2str(ending_angle_index);%"";
                                value_trimmed = "";
                            case "runtime.GoldErasing.any.extraDiameter"
                                value_trimmed = num2str(floor(obj.configuration.gold_erasing_extra_diameter / obj.configuration.aligned_stack_binning));
                            otherwise
                                error("ERROR: Key to be replaced not found!");
                        end
                    else
                        value_trimmed = num2str(value_trimmed);
                    end
                    
                    % TODO:NOTE: special case to keep gold beads, perhaps exclude in
                    % own parameter name
                    if key_trimmed == "runtime.AlignedStack.any.eraseGold" && obj.configuration.reconstruct_binned_stacks == true
                        value_trimmed = "1";
                    end
                    
                    directives_new = rmfield(directives, key_cleaned);
                    directives = directives_new;
                    directive_file_struct.(key_cleaned) = value_trimmed;
                    % TODO: add argument type checks
                    if contains(key_trimmed, "xcorr.pt")
                        key_trimmed = strrep(key_trimmed, "xcorr.pt", "xcorr_pt");
                    end
                    fprintf(directive_file_id,"%s = %s\n",key_trimmed,value_trimmed);
                end
                fclose(template_file_id);
            end
            % NOTE: write rest of key values from configuration file out, some important variables
            % can be replaced automatically
            directive_names = fieldnames(directives);
            for i = 1:length(directive_names)
                key = directive_names{i};
                key_cleaned = strrep(key,"_",".");
                value = directives.(key);
                if isstring(value) && value == "<REPLACE>"
                    switch key_cleaned
                        case "setupset.copyarg.pixel"
                            if isfield(obj.configuration, "apix")
                                apix = obj.configuration.apix * obj.configuration.ft_bin;
                            else
                                apix = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix * obj.configuration.ft_bin;
                            end
                            value = num2str(apix / 10);
                        case "runtime.AlignedStack.any.binByFactor"
                            value = num2str(obj.configuration.aligned_stack_binning / obj.configuration.ft_bin);
                        case "setupset.copyarg.Cs"
                            value = num2str(obj.configuration.spherical_aberation);
                        case "comparam.tilt.tilt.THICKNESS"
                            value = num2str(obj.configuration.reconstruction_thickness);
                        case "runtime.GoldErasing.any.thickness"
                            value = num2str(obj.configuration.reconstruction_thickness);
                        case "setupset.copyarg.voltage"
                            value = num2str(obj.configuration.keV);
                        case "comparam.prenewst.newstack.BinByFactor"
                            %value = num2str(obj.configuration.aligned_stack_binning);
                            value = num2str(obj.configuration.pre_aligned_stack_binning / obj.configuration.ft_bin);
                        case "setupset.copyarg.firstinc"
                            value = num2str(starting_angle) + " " + num2str(angle_increment);
                        case "setupset.copyarg.gold"
                            value = num2str(obj.configuration.gold_bead_size_in_nm);
                        case "setupset.copyarg.rotation"
                            value = num2str(obj.configuration.rotation_tilt_axis);
                        case "setupset.copyarg.defocus"
                            value = num2str(obj.configuration.nominal_defocus_in_nm);
                        case "comparam.align.tiltalign.SeparateGroup"
                            %value = num2str(starting_angle_index) + "-" + num2str(ending_angle_index);
                            value = "";
                        case "runtime.GoldErasing.any.extraDiameter"
                            value = num2str(floor(obj.configuration.gold_erasing_extra_diameter / obj.configuration.aligned_stack_binning));
                        otherwise
                            error("ERROR: Key to be replaced not found!");
                    end
                else
                    value = num2str(value);
                end
                % TODO:NOTE: special case to keep gold beads, perhaps exclude in
                % own parameter name
                if key_cleaned == "runtime.AlignedStack.any.eraseGold" && obj.configuration.reconstruct_binned_stacks == true
                    value = "1";
                end
                
                directive_file_struct.(key) = value;
                % TODO: add argument type checks
                if contains(key_cleaned, "xcorr.pt")
                    key_cleaned = strrep(key_cleaned, "xcorr.pt", "xcorr_pt");
                end
                fprintf(directive_file_id,"%s = %s\n", key_cleaned, value);
            end
            fclose(directive_file_id);
        end
        
        function merged_configurations = mergeConfigurations(obj,...
                first_configuration, second_configuration)
            printVariable(first_configuration);
            printVariable(second_configuration);
            field_names = fieldnames(second_configuration);
            merged_configurations = first_configuration;
            for i = 1:length(field_names)
                merged_configurations.(field_names{i}) =...
                    second_configuration.(field_names{i});
            end
            printVariable(merged_configurations);
        end

% TOREVIEW: deletion of data here may cause troubles on further steps
%         function obj = cleanUp(obj)
%             if obj.configuration.execute == false && obj.configuration.keep_intermediates == false
%                 if obj.configuration.ending_step >=13
%                     field_names = fieldnames(obj.configuration.tomograms);
%                     files = dir(obj.output_path);
%                     files(1) = [];
%                     files(1) = [];
%                     file_ali = endsWith({files(:).name}, ".ali");
%                     file_tlt = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".tlt");
%                     file_rawtlt = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".rawtlt");
%                     file_xf = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".xf");
%                     file_defocus = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".defocus");
%                     file_success = endsWith({files(:).name}, "SUCCESS");
%                     file_failure = endsWith({files(:).name}, "FAILURE");
%                     file_time = endsWith({files(:).name}, "TIME");
%                     json_output = endsWith({files(:).name}, "output.json");
%                     files = files(~(file_ali + file_tlt + file_xf + file_defocus + file_rawtlt + file_success + file_failure + file_time + json_output));
%                     obj.deleteFilesOrFolders(files);
%                     
%                     files = dir(obj.configuration.processing_path + string(filesep)...
%                         + obj.configuration.output_folder + string(filesep)...
%                         + "*_BatchRunTomo_*" + string(filesep) + field_names{obj.configuration.set_up.j});
%                     files = files(~contains({files(:).folder}, obj.configuration.set_up.i - 1 + "_BatchRunTomo_1"));
%                     files(1) = [];
%                     files(1) = [];
%                     file_ali = endsWith({files(:).name}, ".ali");
%                     file_tlt = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".tlt");
%                     file_rawtlt = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".rawtlt");
%                     file_xf = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".xf");
%                     file_defocus = endsWith({files(:).name}, field_names{obj.configuration.set_up.j} + ".defocus");
%                     file_success = endsWith({files(:).name}, "SUCCESS");
%                     file_failure = endsWith({files(:).name}, "FAILURE");
%                     file_time = endsWith({files(:).name}, "TIME");
%                     json_output = endsWith({files(:).name}, "output.json");
%                     files = files(~(file_ali + file_tlt + file_xf + file_rawtlt + file_defocus + file_success + file_time + file_failure + json_output));
%                     obj.deleteFilesOrFolders(files);
%                     
%                     %                     for i = 1:length(files)
%                     %                         if files(i).isdir == true
%                     %                             [success, message,message_id] = rmdir(files(i).folder + string(filesep) + files(i).name, "s");
%                     %                         else
%                     %                             delete(files(i).folder + string(filesep) + files(i).name)
%                     %                         end
%                     %                     end
%                 end
%             end
%             obj = cleanUp@Module(obj);
%         end
    end
end
