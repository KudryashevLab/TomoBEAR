classdef DynamoCleanStacks < Module
    methods
        function obj = DynamoCleanStacks(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "tilt_stacks_folder", false);
        end
        
        function obj = process(obj)
            create_stacks_input_path = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep)...
                + "*_CreateStacks_*");
            field_names = fieldnames(obj.configuration.tomograms);
            tilt_stack_path = create_stacks_input_path(1).folder + string(filesep) + create_stacks_input_path(1).name + string(filesep) + field_names{obj.configuration.set_up.j} + string(filesep) + "*.st";
            dir_list = dir(tilt_stack_path);
            stack_file = dir_list;
            [path, name, extension] = fileparts(stack_file(1).name);
            source = stack_file(1).folder + string(filesep) + stack_file(1).name;
            [status_realpath, real_source] = system("realpath " + source);
            real_source = string(regexprep(real_source,'[\n\r]+',''));
            disp("INFO: Cleaning tiltstack" + source + "!");
            stack_file_name_splitted = strsplit(stack_file(1).name, ".");
            dynamo_success_file = dir(obj.configuration.processing_path...
                + string(filesep) + obj.configuration.output_folder + string(filesep)...
                + "*DynamoTiltSeriesAlignment*" + string(filesep) + name + string(filesep)...
                + "SUCCESS_*");
            if ~isempty(dynamo_success_file)
                dynamo_success_file_splitted = strsplit(dynamo_success_file(obj.configuration.tomograms.(name).tilt_series_alignment_index).name, "_");
                dynamo_tilt_series_alignment_folder = dir(obj.configuration.processing_path...
                    + string(filesep) + obj.configuration.output_folder + string(filesep)...
                    + "*DynamoTiltSeriesAlignment*" + string(filesep) + name + string(filesep)...
                    + obj.configuration.project_name + "*" + strjoin({dynamo_success_file_splitted{2:end}}, "_") + ".AWF" + string(filesep) + "align"...
                    + string(filesep) + "reconstructionTiltIndices.txt");
                dlm = false;
                if isempty(dynamo_tilt_series_alignment_folder)
                    dynamo_tilt_series_alignment_folder = dir(obj.configuration.processing_path...
                        + string(filesep) + obj.configuration.output_folder + string(filesep)...
                        + "*DynamoTiltSeriesAlignment*" + string(filesep) + name + string(filesep)...
                        + obj.configuration.project_name + "*" + strjoin({dynamo_success_file_splitted{2:end}}, "_") + ".AWF" + string(filesep) + "align"...
                        + string(filesep) + "reconstructionTiltIndices.dlm");
                    dlm = true;
                end
                if ~isempty(dynamo_tilt_series_alignment_folder)
                    index = 1;
                    if dlm == true
                        try
                            tilt_indices = load(dynamo_tilt_series_alignment_folder(index).folder + string(filesep) + dynamo_tilt_series_alignment_folder(index).name, "-mat");
                            tilt_indices = tilt_indices.contents;
                        catch
                            tilt_indices = load(dynamo_tilt_series_alignment_folder(index).folder + string(filesep) + dynamo_tilt_series_alignment_folder(index).name);
                        end
                    else
                        tilt_indices = textread(dynamo_tilt_series_alignment_folder(index).folder + string(filesep) + dynamo_tilt_series_alignment_folder(index).name);
                    end
                    motion_corrected_files_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + "*CreateStacks*" + string(filesep) + stack_file_name_splitted{1};
                    motion_corrected_files_path_query = motion_corrected_files_path + "/*_norm.mrc";
                    %TODO: use commented below insetead of the line above
                    %motion_corrected_files = dir(motion_corrected_files_path + string(filesep) + "*_" + obj.configuration.normalized_postfix + ".mrc");
                    motion_corrected_files = dir(motion_corrected_files_path_query);
                    tilts_to_be_removed = setdiff(1:length(motion_corrected_files), tilt_indices);
                    tilts_to_keep = intersect(1:length(motion_corrected_files), tilt_indices);
                    motion_corrected_file_paths = strcat(string({motion_corrected_files(tilts_to_keep).folder}), string(filesep), string({motion_corrected_files(tilts_to_keep).name}));
                    tilt_stack_destination = obj.output_path + string(filesep) + name + ".st"; 
                    if length(motion_corrected_files) > length(tilts_to_keep)
                        executeCommand("newstack " + strjoin(motion_corrected_file_paths, " ") + " " + tilt_stack_destination, false, obj.log_file_id);
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                            motion_corrected_dose_weighted_files = string({obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_dose_weighted_files{tilts_to_keep}});
                            dose_weighted_tilt_stack_destination = obj.output_path + string(filesep) + name + "_dw.st"; 
                            executeCommand("newstack " + strjoin(motion_corrected_dose_weighted_files, " ") + " " + dose_weighted_tilt_stack_destination, false, obj.log_file_id);
                            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).modified_odd_tilt_stack_destination_symbolink_link = createSymbolicLinkInStandardFolder(obj.configuration, dose_weighted_tilt_stack_destination, "dose_weighted_tilt_stacks_folder", obj.log_file_id);
                        end
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                            motion_corrected_dose_weighted_sum_files = string({obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_dose_weighted_sum_files{tilts_to_keep}});
                            dose_weighted_sum_tilt_stack_destination = obj.output_path + string(filesep) + name + "_dws.st";                         
                            executeCommand("newstack " + strjoin(motion_corrected_dose_weighted_sum_files, " ") + " " + dose_weighted_sum_tilt_stack_destination, false, obj.log_file_id);
                            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).modified_odd_tilt_stack_destination_symbolink_link = createSymbolicLinkInStandardFolder(obj.configuration, dose_weighted_sum_tilt_stack_destination, "dose_weighted_sum_tilt_stacks_folder", obj.log_file_id);
                        end
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                            even_tilt_stack_destination = obj.output_path + string(filesep) + name + "_even.st"; 
                            motion_corrected_even_files = string({obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_even_files{tilts_to_keep}});
                            executeCommand("newstack " + strjoin(motion_corrected_even_files, " ") + " " + even_tilt_stack_destination, false, obj.log_file_id);
                            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).modified_odd_tilt_stack_destination_symbolink_link = createSymbolicLinkInStandardFolder(obj.configuration, even_tilt_stack_destination, "even_tilt_stacks_folder", obj.log_file_id);

                        end
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                            odd_tilt_stack_destination = obj.output_path + string(filesep) + name + "_odd.st"; 
                            motion_corrected_odd_files = string({obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_odd_files{tilts_to_keep}});
                            executeCommand("newstack " + strjoin(motion_corrected_odd_files, " ") + " " + odd_tilt_stack_destination, false, obj.log_file_id);
                            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).modified_odd_tilt_stack_destination_symbolink_link = createSymbolicLinkInStandardFolder(obj.configuration, odd_tilt_stack_destination, "odd_tilt_stacks_folder", obj.log_file_id);
                        end
                        
                        
                        %TODO: tilt_index_angle_mapping should come under tomogram and then the
                        %name in the structure
                        obj.dynamic_configuration.tilt_index_angle_mapping = struct;
                        obj.dynamic_configuration.tilt_index_angle_mapping.(name) = obj.configuration.tomograms.(name).tilt_index_angle_mapping;
                        obj.dynamic_configuration.tilt_index_angle_mapping.(name)(2,:) = sort(obj.dynamic_configuration.tilt_index_angle_mapping.(name)(2,:));
                        obj.dynamic_configuration.tilt_index_angle_mapping.(name)(3,tilts_to_be_removed) = false;
                        obj.dynamic_configuration.tilt_index_angle_mapping.(name)(4,:) = cumsum(obj.dynamic_configuration.tilt_index_angle_mapping.(name)(3,:));
                        obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).modified_tilt_stack_path = tilt_stack_destination;
                        obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).modified_tilt_stack_symbolink_link = createSymbolicLinkInStandardFolder(obj.configuration, tilt_stack_destination, "tilt_stacks_folder", obj.log_file_id);
                        if obj.configuration.keep_intermediates == false
                            delete(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_path);
                        end
                        if obj.configuration.show_truncated_stacks
                            command = "3dmod " + tilt_stack_destination + " & echo $!";
                            output = executeCommand(command, false, obj.log_file_id);
                            pause(obj.configuration.pid_wait_time);
                            pid_2 = executeCommand("pgrep -n -U $(id -u) 3dmod", false, obj.log_file_id);
                            pids = regexp(pid_2,"\d\d+" , "match");
                            pid_2 = str2num(pids(1));
                            pid_2 = pid_2(1);
                            disp("INFO: Press a key !")
                            pause;
                            if exist("pid_2", "var")
                                output = executeCommand("kill " + pid_2, true, obj.log_file_id);
                                clear("pid_2");
                            end
                        end
                    else
                        disp("INFO:REAL_SOURCE: " + real_source);
                        disp("INFO:TILT_STACK_DESTINATION: " + tilt_stack_destination);
                        createSymbolicLink(real_source, tilt_stack_destination, obj.log_file_id);
                        createSymbolicLinkInStandardFolder(obj.configuration, tilt_stack_destination, "tilt_stacks_folder", obj.log_file_id);
                    end
                else
                    if obj.configuration.propagate_failed_stacks == true
                        obj.status = 1;
                    else
                        obj.dynamic_configuration.tilt_index_angle_mapping.(name) = struct;
                        obj.dynamic_configuration.tilt_index_angle_mapping.(name) = [];
                        obj.status = 0;
                    end
                end
            else
                if obj.configuration.propagate_failed_stacks == true
                    obj.status = 1;
                else
                    obj.dynamic_configuration.tilt_index_angle_mapping.(name) = struct;
                    obj.dynamic_configuration.tilt_index_angle_mapping.(name) = [];
                    obj.status = 0;
                end
            end
        end
        
        function obj = cleanUp(obj)
            if obj.configuration.execute == false && obj.configuration.keep_intermediates == false
                
                field_names = fieldnames(obj.configuration.tomograms);
                
                % WARNING: modified_tilt_stack_path was set to
                % tilt_stack_destination above!!!
                %if contains(field_names, "modified_tilt_stack_path")
                %    delete(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_path);
                %end
                %delete(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).config_file_path);

                % Delete .AWF folder and its contents                
                folder = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).dynamo_tilt_series_alignment_folder;
                files = dir(folder + string(filesep) + "*");
                filesNames = {files.name};
                files = files(~ismember(filesNames,{'.','..'}));
                obj.deleteFilesOrFolders(files);
                obj.deleteFolderIfEmpty(folder);
                                
                % Delete normalized files from CreateStacks step
                files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_files_normalized;
                obj.deleteFilesOrFolders(files);
                
                % Delete additional motion corrected data (even/odd frames, DW/DWS)   
                % TODO: delete corresponding slinks directories
                % Q: are those additional mcor data not used anywhere further in processing? 
                % Q: (check BatchRunTomo module)
%                 if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")                    
%                     files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_dose_weighted_files;
%                     obj.deleteFilesOrFolders(files);
%                     [folder, ~, ~] = fileparts(files{1});
%                     obj.deleteFolderIfEmpty(folder);
%                     [parent_folder, ~, ~] = fileparts(folder);
%                     obj.deleteFolderIfEmpty(parent_folder);
%                 end
%                 
%                 if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                     files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_dose_weighted_sum_files;
%                     obj.deleteFilesOrFolders(files);
%                     [folder, ~, ~] = fileparts(files{1});
%                     obj.deleteFolderIfEmpty(folder);
%                     [parent_folder, ~, ~] = fileparts(folder);
%                     obj.deleteFolderIfEmpty(parent_folder);
%                 end
%                 
%                 if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
%                     files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_even_files;
%                     obj.deleteFilesOrFolders(files);
%                     [folder, ~, ~] = fileparts(files{1});
%                     obj.deleteFolderIfEmpty(folder);
%                     [parent_folder, ~, ~] = fileparts(folder);
%                     obj.deleteFolderIfEmpty(parent_folder);
%                 end
%                 
%                 if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
%                     files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_odd_files;
%                     obj.deleteFilesOrFolders(files);
%                     [folder, ~, ~] = fileparts(files{1});
%                     obj.deleteFolderIfEmpty(folder);
%                     [parent_folder, ~, ~] = fileparts(folder);
%                     obj.deleteFolderIfEmpty(parent_folder);
%                 end
            end
            obj = cleanUp@Module(obj);
        end
    end
    
end