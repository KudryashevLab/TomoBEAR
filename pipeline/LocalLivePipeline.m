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

classdef LocalLivePipeline < Pipeline
    methods
        function obj = LocalLivePipeline(configuration_path, default_configuration_path)
            if nargin == 0
                configuration_path = "";
                default_configuration_path = "";
            elseif nargin == 1
                default_configuration_path = "";
            end
            obj@Pipeline(configuration_path, default_configuration_path);
        end
        
        function execute(obj, tomogram_begin, tomogram_end, pipeline_ending_step, gpu)
            disp("INFO: Executing pipeline...");
            
            if ~isempty(obj.default_configuration)
                configuration = obj.initializeDefaults();
            else
                configuration = obj.configuration;
            end
            
            if nargin == 1
                tomogram_begin = -1;
                tomogram_end = -1;
                pipeline_ending_step = -1;
                gpu = -2;
            elseif nargin == 2
                tomogram_end = -1;
                pipeline_ending_step = -1;
                gpu = -2;
            elseif nargin == 3
                pipeline_ending_step = -1;
                gpu = -2;
            elseif nargin == 4
                gpu = -2;
            end
            
            configuration.general.tomogram_begin = tomogram_begin;
            configuration.general.tomogram_end = tomogram_end;
            
            configuration.general.live_data_mode = true;
            
            pipeline_definition = fieldnames(configuration);
            
%             if configuration.general.random_number_generator_seed > -1
%                 if configuration.general.random_number_generator_seed == 0
%                     rng("default")
%                 else
%                     rng(configuration.general.random_number_generator_seed);
%                 end
%             end
            
            %             obj.semaphore_key = randi(999999);
            
            %             try
            %                 semaphore('destroy', obj.semaphore_key, 1);
            %             catch
            %             end
            %
            %             semaphore('create', obj.semaphore_key, 1);
            
            
            
            if configuration.general.cuda_forward_compatibility == true && ~verLessThan("matlab", "9.9")
                parallel.gpu.enableCUDAForwardCompatibility(true)
            end
            
            distcomp.feature( 'LocalUseMpiexec', false );
            % NOTE: not really useful, because toolkit needs to be run from
            % project folder or needs to be added to path
            if configuration.general.data_path == ""
                configuration.general.data_path = string(pwd);
                configuration.general.processing_path = configuration.general.data_path;
            end
            
            if configuration.general.processing_path ~= ""
                processing_path = configuration.general.processing_path;
            else
                configuration.general.processing_path = configuration.general.data_path;
                processing_path = configuration.general.processing_path;
            end
            
            disp("INFO:PROCESSING_PATH: " + configuration.general.processing_path);
            disp("INFO:DATA_PATH: " + configuration.general.data_path);
            %             dynamic_configuration = struct();
            
            if configuration.general.debug == true
                % TODO: check return value
                if exist(processing_path + string(filesep) + configuration.general.output_folder, "dir")
                    rmdir(processing_path + string(filesep) + configuration.general.output_folder, "s");
                end
                
                if exist(processing_path + string(filesep) + configuration.general.scratch_folder, "dir")
                    rmdir(processing_path + string(filesep) + configuration.general.scratch_folder, "s");
                end
                
            end
            
            output_path = processing_path + string(filesep) + configuration.general.output_folder;
            
            if ~exist(output_path, "dir")
                [status_mkdir, message, message_id] = mkdir(output_path);
            end
            
            pipeline_log_file_path = output_path + string(filesep) + "pipeline.log";
            
            if fileExists(pipeline_log_file_path)
                log_file_id = fopen(pipeline_log_file_path, "a");
            else
                log_file_id = fopen(pipeline_log_file_path, "w");
            end
            
            meta_data_folder_path = getMetaDataFolderPath(configuration.general);
            
            if ~exist(meta_data_folder_path, "dir")
                [status_mkdir, message, message_id] = mkdir(meta_data_folder_path);
            end
            
            meta_data_file_path = getMetaDataFilePath(configuration.general);
            [folder, name, extension] = fileparts(meta_data_file_path);
            
            if fileExists(folder + string(filesep) + name + ".json") %exist(meta_data_file_path, "file") == 2 ||
                configuration_history = obj.loadJSON(folder + string(filesep) + name + ".json");
                %                 try
                %                     load(meta_data_file_path, "configuration_history");
                %
                %                 catch
                %
                %                     try
                %                         load(folder + string(filesep) + name + "_backup" + extension, "configuration_history");
                %                     catch
                %                         load(folder + string(filesep) + name + "_backup_backup" + extension, "configuration_history");
                %                     end
                %
                %                 end
                
                configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
            else
                configuration_history = struct();
                configuration_history.processing_step_times = struct;
            end
            
            % TODO:NOTE: not needed
            % if configuration.general.wipe_cache == true
            % 	 if exist(meta_data_path, "file")
            %        % TODO: Check status and message and message_id
            %        [status, message, message_id] = rmdir(meta_data_path, "s");
            %    end
            % end
            
            
            
            if obj.configuration_path ~= ""
                [success, message, message_id] = copyfile(obj.configuration_path, folder + string(filesep) + "project.json");
            end
            
            if obj.default_configuration_path ~= ""
                [success, message, message_id] = copyfile(obj.default_configuration_path, folder + string(filesep) + "defaults.json");
            end
            
            % TODO:NOTE: last processed tomogram number needs to be loaded
            % TODO: look if this is needed
            if isfield(configuration.general, "tomogram_indices_original")
                tomogram_indices = configuration.general.tomogram_indices_original;
            elseif isfield(configuration.general, "tomogram_indices") && ~isempty(configuration.general.tomogram_indices)
                tomogram_indices = configuration.general.tomogram_indices;
            elseif isfield(configuration.general, "tomogram_begin")...
                    && isfield(configuration.general, "tomogram_end")...
                    && 0 < configuration.general.tomogram_begin...
                    && 0 < configuration.general.tomogram_end...
                    && configuration.general.tomogram_end >= configuration.general.tomogram_begin...
                    && configuration.general.tomogram_step ~= 0
                tomogram_indices = configuration.general.tomogram_begin:configuration.general.tomogram_step:configuration.general.tomogram_end;
            else
                tomogram_indices = [];
            end
            
            if isfield(configuration.general, "tomogram_indices_processed")
                tomogram_indices_processed = configuration.general.tomogram_indices_processed;
            else
                tomogram_indices_processed = [];
            end
            
            tomogram_status = {};
            dynamic_configuration = [];
            % "listening" mode
            while true
                
                if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
                    error("ERROR: skip_data_check cannot be used in live data processing mode!");
%                     dynamic_configuration = struct;
%                     dynamic_configuration.file_count = configuration.general.file_count;
%                     if ~isfield(configuration, "starting_tomogram")
%                         dynamic_configuration.starting_tomogram = 1;
%                     else
%                         dynamic_configuration.starting_tomogram = configuration.starting_tomogram;
%                     end
%                     dynamic_configuration.tomograms_count = configuration.general.tomograms_count;
%                     file_count_changed = false;
                elseif ~isempty(tomogram_indices) && all(ismember(tomogram_indices,tomogram_indices_processed))
                    disp("INFO: All requested tilt series were processed!");
                    break;
                else
                    [file_list, ~] = getOriginalMRCsorTIFs(configuration.general, false);
                    if (isempty(dynamic_configuration) && ~isempty(file_list)) || (~isempty(dynamic_configuration) && isfield(dynamic_configuration, "file_count") && dynamic_configuration.file_count < length(file_list))
                        [dynamic_configuration, ~] = getUnprocessedTomograms(configuration.general, log_file_id);
                    else
                        continue;
                    end
                end
                
                %                 obj.saveJSON(folder + string(filesep) + "tomogram_meta_data.json", dynamic_configuration);
%                 sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
                
%                 if file_count_changed == true
%                     sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
%                     
%                     for i = 1:length(sucess_files_to_be_deleted)
%                         delete(sucess_files_to_be_deleted(i).folder + string(filesep) + sucess_files_to_be_deleted(i).name);
%                     end
%                     
%                 elseif file_count_changed == false && length(sucess_files_to_be_deleted) < length(pipeline_definition)
%                 elseif file_count_changed == false && isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
%                 else
%                     disp("INFO: File count has not changed therefor further execution of the pipeline is abandoned!")
%                     break;
%                 end
                
%                 if isfield(configuration_history, "general")
%                     configuration_history.general = obj.mergeConfigurations(configuration_history.general, dynamic_configuration, 0, "dynamic");
%                 else
%                     configuration_history.general = dynamic_configuration;
%                 end
%                 
%                 configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
                
                %                 tomogram_names = fieldnames(configuration.general.tomograms);
                
                % NOTE: possibly overwrites the currently loaded file
                %save(meta_data_file_path, "configuration_history", "-v7.3");
                %                 obj.parforSave(meta_data_file_path, configuration_history);
                
                % for j = 1:length(tomogram_names)
                %     tomogram_number  = j;
                %     % TODO:NOTE: what if new pipeline steps were added?
                %     if ~isfield(configuration.general.tomograms.(tomogram_names{tomogram_number}), "processed_pipeline_steps")
                %         configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps = zeros(length(pipeline_definition)-1, 1);
                %     else
                %         if length(pipeline_definition) > length(configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps)
                %             % TODO: needs to be tested if count pipeline steps
                %             % is changed and processed pipelinesteps are kept
                %             processed_pipeline_steps_tmp = configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps;
                %             configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps = zeros(length(pipeline_definition), 1);
                %             configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps(1:length(processed_pipeline_steps_tmp)) = processed_pipeline_steps_tmp;
                %         elseif length(pipeline_definition) < configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps
                %             error("ERROR: reducing pipeline steps is not implemented!");
                %         else
                %             disp("NOTE: pipeline stayed unchanged, nothing to be done here!");
                %         end
                %     end
                % end
                
                tomogram_indices_available = 1:dynamic_configuration.tomograms_count;
                if ~isempty(tomogram_indices)
                    tomogram_indices_to_check = tomogram_indices_available(ismember(tomogram_indices_available, tomogram_indices));
                else
                    tomogram_indices_to_check = tomogram_indices_available;
                end
                tomogram_to_process_mask = zeros([1 dynamic_configuration.tomograms_count]);
                tomogram_to_process_mask(tomogram_indices_to_check) = 1;
                
                if ~isfield(dynamic_configuration, "tomograms") || isempty(dynamic_configuration.tomograms)
                    dynamic_configuration.tomograms = configuration.general.tomograms;
                end
                tomogram_names = fieldnames(dynamic_configuration.tomograms);
                
                tomogram_enough_files_mask = zeros([1 dynamic_configuration.tomograms_count]);
                for tomogram_idx = tomogram_indices_to_check
                    tomogram_enough_files_mask(tomogram_idx) = ~dynamic_configuration.tomograms.(tomogram_names{tomogram_idx}).skipped;
                    
                    if ~tomogram_enough_files_mask(tomogram_idx)
                        last_collected_frame_datetime_string = dynamic_configuration.tomograms.(tomogram_names{tomogram_idx}).last_collected_frame_date + " " + dynamic_configuration.tomograms.(tomogram_names{tomogram_idx}).last_collected_frame_time;

                        if isfield(configuration.general, "date_position") && configuration.general.date_position ~= 0
                            month_day_format = "MMMdd";
                        else
                            month_day_format = "yyyy-MM-dd";
                        end
                        if isfield(configuration.general, "time_position") && configuration.general.time_position ~= 0
                            time_format = "HH.mm.ss";
                        else
                            time_format = "HH:mm:ss.SSSSSSSSS";
                        end

                        last_collected_frame_datetime = datetime(last_collected_frame_datetime_string, "Format", month_day_format + " " + time_format, "TimeZone", "local");
                        current_datetime = datetime("now", "Format", month_day_format + " " + time_format, "TimeZone", "local");
                        tomogram_last_collected_frame_criteria = minutes(current_datetime-last_collected_frame_datetime) > configuration.general.listening_time_threshold_in_minutes;
                        tomogram_enough_files_mask(tomogram_idx) = tomogram_last_collected_frame_criteria;
                    end 
                    
                end
                
                tomogram_processed_mask = zeros([1 dynamic_configuration.tomograms_count]);                
                tomogram_processed_mask(tomogram_indices_processed) = 1;
                
                tomogram_mask = tomogram_to_process_mask & tomogram_enough_files_mask & ~tomogram_processed_mask;
                
                if ~any(tomogram_mask)
                    disp("INFO: No new fully collected tilt series to process!");
                    disp("INFO: Continue listening...");
                    continue;
                end
                
                disp("INFO: Starting processing of the newly collected tilt series...");
                previous_tomogram_status = tomogram_mask;
                dynamic_configuration.tomogram_indices = tomogram_indices_to_check;
                dynamic_configuration.tomogram_indices_original = tomogram_indices;

                
                
                % add tomograms to be processed to the list of
                % already processed tomograms
                tomogram_indices_to_be_processed = tomogram_indices_to_check(tomogram_mask(tomogram_indices_to_check)==1);
%                 if ~isempty(tomogram_indices_processed)
%                     tomogram_indices_processed_extention_mask = ~ismember(tomogram_indices_to_be_processed, tomogram_indices_processed);
%                     tomogram_indices_processed_extention = tomogram_indices_to_be_processed(tomogram_indices_processed_extention_mask);
%                     dynamic_configuration.tomogram_indices_processed = [tomogram_indices_processed; tomogram_indices_processed_extention'];
%                 else
%                     dynamic_configuration.tomogram_indices_processed = tomogram_indices_to_be_processed';
%                 end
%                 tomogram_indices_processed = dynamic_configuration.tomogram_indices_processed;
                
                
                
                if isfield(configuration_history, "general")
                    configuration_history.general = obj.mergeConfigurations(configuration_history.general, dynamic_configuration, 0, "dynamic");
                else
                    configuration_history.general = dynamic_configuration;
                end
                
                configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
                sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
                for i = 1:length(sucess_files_to_be_deleted)
                    delete(sucess_files_to_be_deleted(i).folder + string(filesep) + sucess_files_to_be_deleted(i).name);
                end
                
                tomogram_status = {};
                %                 meta_data_file_path = getMetaDataFilePath(configuration.general);
                
                for i = 1:length(pipeline_definition)
                    % TODO: Make it independent of position, rrather not,
                    % delete comment
                    if (i == 1 && obj.pipeline_definition{i} == "general")
                        continue;
                    elseif (i == 1 && obj.pipeline_definition{i} ~= "general")
                        error("ERROR: General section in configuration missing or" ...
                            + " it is not in the first position!");
                    end
                    
                    configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}) = struct;
                    
                    if ~isfield(configuration_history, pipeline_definition{i})
                        configuration_history.(pipeline_definition{i}) = struct;
                    end
                    
                    if ~isempty(fieldnames(dynamic_configuration))
                        configuration.(pipeline_definition{i}) = obj.mergeConfigurations(configuration.(pipeline_definition{i}), dynamic_configuration, 0, "dynamic");
                    end
                    
                    % NOTE: Everything is merged into general
                    % configuration, this means that fields defined in the
                    % pipeline processing step are overwriting fields from
                    % general configuration
                    merged_configuration = obj.mergeConfigurations(...
                        configuration.general, ...
                        configuration.(pipeline_definition{i}), i - 1, obj.pipeline_definition{i});
                    
                    merged_configuration = obj.fillSetUpStructPipelineStep(merged_configuration, i);
                    % TODO: perhaps should also look for corresponding
                    % scratch folder
                    
                    merged_configuration.output_path = processing_path + string(filesep) + merged_configuration.pipeline_step_output_folder;
                    merged_configuration.scratch_path = processing_path + string(filesep) + merged_configuration.pipeline_step_scratch_folder;
                    ignore_success_files = merged_configuration.ignore_success_files;
                    
                    time_file_path = merged_configuration.output_path + string(filesep) + "TIME";
                    success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
                    failure_file_path = merged_configuration.output_path + string(filesep) + "FAILURE";
                    if gpu ~= -2
                        merged_configuration.gpu = gpu;
                    end
                    
                    if fileExists(success_file_path)
                        success_file_id = fopen(success_file_path, "r");
                        status_flags = textscan(success_file_id, "%s");
                        status_flags = status_flags{1};
                        status_flags = [str2double(status_flags)]';
                        if length(status_flags) < length(previous_tomogram_status)
                            status_flags_tmp = zeros([1 length(previous_tomogram_status)]);
                            status_flags_tmp(1:length(status_flags)) =  status_flags;
                            status_flags = status_flags_tmp;
                        end
                        if any(~status_flags & previous_tomogram_status) && pipeline_ending_step ~= -1
                            status_flags = double(status_flags | previous_tomogram_status);
                            previous_tomogram_status = status_flags;
                            ignore_success_files = true;
                        end
                        tomogram_status{i - 1} = status_flags & tomogram_mask;
                    end
                    
                    
                    
                    if ignore_success_files == false && fileExists(success_file_path)
                        %                         success_file_id = fopen(success_file_path);
                        %                         status_flags = textscan(success_file_id, "%s");
                        %                         status_flags = status_flags{1};
                        %                         status_flags = [str2double(status_flags)]';
                        %                         tomogram_status{i - 1} = status_flags;
                        if obj.pipeline_definition{i} ~= "StopPipeline"
                            dynamic_configuration_in = dynamic_configuration;
                            dynamic_configuration_out = obj.finishPipelineStep(...
                                dynamic_configuration, pipeline_definition{i}, ...
                                configuration_history, i);
                            dynamic_configuration = dynamic_configuration_out;
                        end
                        disp("INFO: Skipping pipeline step (" + obj.pipeline_definition{i} + ") due to availability of a SUCCESS file!")
                        if pipeline_ending_step + 1 == i
                            disp("INFO: processing reached given pipeline step " + pipeline_ending_step);
                            return;
                        else
                            continue;
                        end
                    elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
                        disp("INFO: Aborting execution of the pipeline step (" + obj.pipeline_definition{i} + ") due to availability of a FAILURE file!");
                        return;
                    else
                        %configuration_history.(pipelineDefinition{i}) = struct;
                        %                         if i == 2
                        %                             previous_tomogram_status = {ones([1 dynamic_configuration.tomograms_count])};
                        %                         else
                        if i > 2
                            previous_tomogram_status = tomogram_status{i - 2};
                        end
                        
                        processing_step_start_time = tic;
                        
                        % TODO: pack module execution path description somewhere else
                        if isfield(merged_configuration, "execution_method")...
                                && (merged_configuration.execution_method == "once"...
                                || merged_configuration.execution_method == "in_order"...
                                || merged_configuration.execution_method == "sequential"...
                                || merged_configuration.execution_method == "parallel")
                            
                            if (merged_configuration.execution_method == "in_order"...
                                    || merged_configuration.execution_method == "parallel") && pipeline_ending_step ~= -1
                                pool_folder = merged_configuration.processing_path + string(filesep) + merged_configuration.output_folder + string(filesep) +  "jobs" + string(filesep) + "pool_" + merged_configuration.tomogram_end;
                                if ~exist(pool_folder, "dir")
                                    [status_mkdir, message, message_id] = mkdir(pool_folder);
                                end
                                % if merged_configuration.execution_method == "parallel"
                                %     generatePool(merged_configuration.cpu_fraction, false, pool_folder);
                                % elseif merged_configuration.execution_method == "in_order"
                                disp("INFO:VARIABLE:merged_configuration.environment_properties.gpu_count: " + merged_configuration.environment_properties.gpu_count);
                                generatePool(merged_configuration.environment_properties.gpu_count, false, pool_folder);
                                % end
                            end
                            [dynamic_configuration_out, tomogram_status{i - 1}] = obj.("execution_" + merged_configuration.execution_method)(merged_configuration, obj.pipeline_definition{i}, previous_tomogram_status);
                        elseif isfield(merged_configuration, "execution_method") && merged_configuration.execution_method == "control"
                            if fileExists(success_file_path)
                                if pipeline_ending_step + 1 == i
                                    disp("INFO: processing reached given pipeline step " + pipeline_ending_step);
                                    %exit(0);
                                    return;
                                end
                                continue;
                            else
                                tomogram_status{i - 1} = tomogram_status{i - 2};
                                obj.createOutputAndScratchFoldersForPipelineStep(merged_configuration);
                                fid = fopen(success_file_path, 'wt');
                                fprintf(fid, "%s", string(num2str(tomogram_status{i - 1})));
                                fclose(fid);
                                disp("INFO: reached control block (" + obj.pipeline_definition{i} + ") pipeline is stopping! ")
                                return;
                            end
                        else
                            error("ERROR: no execution method defined for this module in json file.");
                        end
                        
                        processing_step_end_time = toc(processing_step_start_time);
                        
                        dynamic_configuration = obj.mergeConfigurations(dynamic_configuration, dynamic_configuration_out, 0, "dynamic");
                        
                        if ~isfield(configuration_history, pipeline_definition{i})
                            configuration_history.(pipeline_definition{i}) = struct;
                        end
                        
                        configuration_history.(pipeline_definition{i}) = obj.mergeConfigurations(configuration_history.(pipeline_definition{i}), dynamic_configuration_out, 0, "dynamic");
                        
                        
                        % TODO: does this condition make really sense
                        %if (~isfield(configuration_history.processing_step_times, "Step_" + (i - 1) + "_" + pipeline_definition{i}))...
                        %       ||...
                        %      (isfield(configuration_history.processing_step_times, pipeline_definition{i}) &&  ~fileExists(success_file_path))
                        if ~isfield(configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}), "overall_time")
                            configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}).overall_time = processing_step_end_time;
                        else
                            configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}).overall_time = ...
                                configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}) + processing_step_end_time;
                        end
                        
                        %end
                        


                        
                        %                         TODO: needs revision if only one both variables is set
                        %                         if (isfield(merged_configuration, "tomogram_interval") && isempty(merged_configuration.tomogram_interval) ...
                        %                                 && (isfield(merged_configuration, "tomogram_begin") && isfield(merged_configuration, "tomogram_end") && merged_configuration.tomogram_begin == -1 && merged_configuration.tomogram_end == -1)) ...
                        %                                 || (isfield(merged_configuration, "tomogram_interval") && length(merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)) == length(tomogram_names) ...
                        %                                 || (isfield(merged_configuration, "tomogram_begin") && isfield(merged_configuration, "tomogram_end") && isfield(merged_configuration, "tomogram_step") && length(merged_configuration.tomogram_begin:merged_configuration.tomogram_step:merged_configuration.tomogram_end) == length(tomogram_names)))
                        %                             fid = fopen(success_file_path, 'wt');
                        %                             fprintf(fid, "%s", string(num2str(tomogram_status{i - 1})));
                        %                             fclose(fid);
                        %                         else
                        if (dynamic_configuration.tomograms_count == tomogram_end && tomogram_begin == 1) || (tomogram_end == -1 && tomogram_begin == -1)                            
                            if fileExists(time_file_path) && merged_configuration.execution_method ~= "once"
                                fid = fopen(time_file_path, 'r');
                                previous_time = textscan(fid, "%s");
                                previous_time = previous_time{1};
                                previous_time = str2double(previous_time);
                                processing_step_end_time = processing_step_end_time + previous_time;
                            end
                            fid = fopen(time_file_path, 'wt');
                            fprintf(fid, "%s", string(num2str(processing_step_end_time)));
                            fclose(fid);
                            
                            fid = fopen(success_file_path, 'wt');
                            fprintf(fid, "%s", string(num2str(tomogram_status{i - 1})));
                            fclose(fid);
                            
                            combined_configuration = obj.readAndCombineConfigurationsFromFolder(merged_configuration.output_path);
                            obj.saveJSON(merged_configuration.output_path + string(filesep) + "partial_output.json", combined_configuration);
                            obj.saveJSON(merged_configuration.output_path + string(filesep) + "combined_output.json", dynamic_configuration);
                            obj.saveJSON(folder + string(filesep) + name + ".json", configuration_history);
                            % TODO: implement case for skipping whole pipeline steps,
                            % but what to do if new tomograms were added? add automatic an ignore
                            % flag?
%                             if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
%                                 file_count_changed = false;
%                             else
%                                 file_count_changed = getFileCountChanged(configuration.general);
%                             end
%                             
%                             if file_count_changed == true
%                                 break;
%                             end
                            
                        end
                    end
                    if pipeline_ending_step + 1 == i
                        disp("INFO: processing reached given pipeline step " + pipeline_ending_step);
                        return;
                    end
                end
                
                % update list of the already processed tomograms
                if ~isempty(tomogram_indices_processed)
                    tomogram_indices_processed_extention_mask = ~ismember(tomogram_indices_to_be_processed, tomogram_indices_processed);
                    tomogram_indices_processed_extention = tomogram_indices_to_be_processed(tomogram_indices_processed_extention_mask);
                    dynamic_configuration.tomogram_indices_processed = [tomogram_indices_processed; tomogram_indices_processed_extention'];
                else
                    dynamic_configuration.tomogram_indices_processed = tomogram_indices_to_be_processed';
                end
                tomogram_indices_processed = dynamic_configuration.tomogram_indices_processed;
                
            end
            disp("INFO: Execution finished!");
        end
        
        function [dynamic_configuration_out, status] = execution_once(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            if (isfield(merged_configuration, "skip") && merged_configuration.skip == true) || (~isempty(previous_tomogram_status) && ~any(previous_tomogram_status))
                status = previous_tomogram_status;
                dynamic_configuration_out = struct;
                return;
            end
            
            obj.createOutputAndScratchFoldersForPipelineStep(merged_configuration);
            
            obj.saveJSON(merged_configuration.output_path + string(filesep) + "input.json", merged_configuration);
            
            function_handle = str2func(pipeline_definition);
            
            disp("INFO: Executing processing step " + num2str(merged_configuration.set_up.i - 1) + ...
                ": " + pipeline_definition + "...");
            
            instantiated_class = function_handle(merged_configuration);
            
            instantiated_class = instantiated_class.setUp();
            
            if merged_configuration.execute == true
                instantiated_class = instantiated_class.process();
                dynamic_configuration_out = instantiated_class.dynamic_configuration;
            else
                dynamic_configuration_out = loadJSON(instantiated_class.output_path + string(filesep) + "output.json");
            end
            
            instantiated_class = instantiated_class.cleanUp();
            
            status = instantiated_class.status;

            if status == 1
                success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
                status = previous_tomogram_status;
                fid = fopen(success_file_path, 'wt');
                obj.saveJSON(instantiated_class.output_path + string(filesep) + "output.json", instantiated_class.dynamic_configuration);
            elseif status == 0
                failure_file_path = merged_configuration.output_path + string(filesep) + "FAILURE";
                status = zeros(1, length(previous_tomogram_status));
                fid = fopen(failure_file_path, 'wt');
            else
                error("ERROR: status " + status + " unknown ");
            end
            
            fclose(fid);

            disp("INFO: Execution for processing step " + num2str(merged_configuration.set_up.i - 1) + ...
                " (" + pipeline_definition + ") has finished!");
        end
        
        function [dynamic_configuration_out, status] = execution_parallel(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            tomogram_names = fieldnames(merged_configuration.tomograms);
            
            status = cell([1 length(previous_tomogram_status)]);
            for j = 1:length(previous_tomogram_status)
                status{j} = 0;
            end
            
            indices = find(previous_tomogram_status);
            parfor j = 1:length(indices)
                merged_configuration_tmp = fillSetUpStructIteration(merged_configuration, indices(j), previous_tomogram_status);
                [dynamic_configurations_out{j}, status_tmp{j}] = iteration(merged_configuration_tmp, pipeline_definition, tomogram_names{indices(j)}, previous_tomogram_status(indices(j)));
            end
            
            if ~any(previous_tomogram_status)
                dynamic_configuration_out = struct;
            else
                dynamic_configuration_out = obj.combineConfigurations(dynamic_configurations_out);
            end

            for k = 1:length(indices)
                status{indices(k)} = status_tmp{k};
            end
            status = [status{:}];
        end
        
        function [dynamic_configuration_out, status] = execution_in_order(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            tomogram_names = fieldnames(merged_configuration.tomograms);

            counter = 0;
            
            % TODO: revise for better parametrization
            if isfield(obj.configuration.general, "gpu_worker_multiplier")...
                    && (~isfield(merged_configuration, "method")...
                    || (isfield(merged_configuration, "method")...
                    && merged_configuration.method ~= "MotionCor2"))
                if isscalar(merged_configuration.gpu) && merged_configuration.gpu == -1
                    workers = merged_configuration.environment_properties.gpu_count * merged_configuration.configuration.gpu_worker_multiplier;
                else
                    workers = length(merged_configuration.gpu) * merged_configuration.gpu_worker_multiplier;
                end
            else
                if isscalar(merged_configuration.gpu) && merged_configuration.gpu == -1
                    workers = merged_configuration.environment_properties.gpu_count;
                else
                    workers = length(merged_configuration.gpu);
                end
            end
            
            status = cell([1 length(previous_tomogram_status)]);
            for j = 1:length(previous_tomogram_status)
                status{j} = 0;
            end
            
            pool_folder = merged_configuration.processing_path + string(filesep) + merged_configuration.output_folder + string(filesep) +  "jobs" + string(filesep) + "pool_" + merged_configuration.tomogram_end;
            if ~exist(pool_folder, "dir")
                [status_mkdir, message, message_id] = mkdir(pool_folder);
            end

            poolobj = generatePool(workers, false, pool_folder);
            
            cumulative_sum_previous_tomogram_status = cumsum(previous_tomogram_status);
            indices = find(previous_tomogram_status);
            for j = 1:max(cumulative_sum_previous_tomogram_status)
                if mod(j - 1, workers) == 0 && j > 1
                    wait(f);
                    [dynamic_configuration_tmp, status_tmp] = fetchOutputs(f, 'UniformOutput', false);
                    
                    for k = 1:workers
                        dynamic_configurations_out{counter + 1} = dynamic_configuration_tmp{k};
                        status{indices(counter + 1)} = status_tmp{k};
                        counter = counter + 1;
                    end
                    clear f;
                end
                merged_configurations{j} = merged_configuration;
                merged_configurations{j} = obj.fillSetUpStructIteration(merged_configurations{j}, indices(j), previous_tomogram_status);
                % TODO intermediate configurations need to be saved to be
                % consistent
                f(mod(j - 1, workers) + 1) = ...
                    parfeval(poolobj, @iteration, 2, merged_configurations{j}, pipeline_definition, tomogram_names{indices(j)}, previous_tomogram_status(indices(j)));
            end
            
            if exist("f", "var") && ~isempty(f)
                wait(f);
                [dynamic_configuration_tmp, status_tmp] = fetchOutputs(f, 'UniformOutput', false);
                % TODO: needs to be adjusted for arbitrary number of
                % gpus
                for j = 1:length(dynamic_configuration_tmp)
                    dynamic_configurations_out{counter + 1} = dynamic_configuration_tmp{j};
                    status{indices(counter + 1)} = status_tmp{j};
                    counter = counter + 1;
                end
                
            end
            
            if ~any(previous_tomogram_status)
                dynamic_configuration_out = struct;
            else
                dynamic_configuration_out = obj.combineConfigurations(dynamic_configurations_out);
            end
            status = [status{:}];
        end
        
        function [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, tomogram_name, previous_tomogram_status)
            [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, tomogram_name, previous_tomogram_status);
        end
        
        function tomogram_names = setUpInterval(obj, merged_configuration, previous_tomogram_status)
            tomogram_names = fieldnames(merged_configuration.tomograms);
            if isfield(merged_configuration, "tomogram_interval") && ~isempty(merged_configuration.tomogram_interval)
                tomogram_names = {tomogram_names{1:length(previous_tomogram_status)}};
            elseif isfield(merged_configuration, "tomogram_start") && isfield(merged_configuration, "tomogram_end") && merged_configuration.tomogram_start ~= -1 && merged_configuration.tomogram_end ~= -1
                tomogram_names = {tomogram_names{merged_configuration.tomogram_start:merged_configuration.tomogram_step:merged_configuration.tomogram_end}};
            end
        end
        
        function [dynamic_configuration_out, status] = execution_sequential(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            tomogram_names = obj.setUpInterval(merged_configuration, previous_tomogram_status);
            status = cell([1 length(previous_tomogram_status)]);
            dynamic_configurations = cell([1 length(previous_tomogram_status)]);
            
            for j = 1:length(previous_tomogram_status)
                status{j} = 0;
                dynamic_configurations{j} = struct;
            end
            
            for j = find(previous_tomogram_status)
                disp("INFO: Executing pipeline step " + num2str(merged_configuration.set_up.i - 1) + ...
                    ": " + pipeline_definition + " for tomogram " + j + "...");
                merged_configuration = obj.fillSetUpStructIteration(merged_configuration, j, previous_tomogram_status);
                [dynamic_configurations{j}, status{j}] = iteration(merged_configuration, pipeline_definition, tomogram_names{j}, previous_tomogram_status(j));
                disp("INFO: Execution of pipeline step " + num2str(merged_configuration.set_up.i - 1) + ...
                    " (" + pipeline_definition + ") for tomogram " + j + " has finished!");
            end
            
            dynamic_configuration_out = obj.combineConfigurations(dynamic_configurations);
            status = [status{:}];            
        end
        
        function configurations = readConfigurationsFromFolder(obj, folder)
            configurations = readConfigurationsFromFolder(folder);
        end
        
        function configuration = loadJSON(obj, file_path)
            configuration = loadJSON(file_path);
        end
        
        function combined_configuration = readAndCombineConfigurationsFromFolder(obj, folder)
            configurations = obj.readConfigurationsFromFolder(folder);
            combined_configuration = obj.combineConfigurations(configurations);
        end
        
        function [first_configuration_out, second_configuration_out] = combineConfigurations(obj, first_configurations_in, second_configurations_in)
            if nargin == 2
                first_configuration_out = combineConfigurations(first_configurations_in);
            elseif nargin == 3
                [first_configuration_out, second_configuration_out] = combineConfigurations(first_configurations_in, second_configurations_in);
            end
        end
        
        function dynamic_configuration_out = finishPipelineStep(obj, ...
                dynamic_configuration_in, pipeline_definition, ...
                configuration_history, i)
            % TODO: merge only dynamic_configuration in, first it
            % needs to be stored or is it already stored? seems so...
            if ~isfield(configuration_history, pipeline_definition)
                disp("INFO: No history available for step " + num2str(i - 1) + ...
                    " (" + pipeline_definition + ")!")
                dynamic_configuration_temporary = struct();
            else
                dynamic_configuration_temporary = configuration_history.(pipeline_definition);
            end
            disp("INFO: Skipping processing step " + num2str(i - 1) + ...
                " (" + pipeline_definition + ")!");
            % NOTE: downstreams all properties of every
            % dynamic_configuration_temporary and possibly overwrites
            % with new values
            if ~isempty(fieldnames(dynamic_configuration_temporary))
                dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_in, dynamic_configuration_temporary, 0, "dynamic");
            else
                dynamic_configuration_out = dynamic_configuration_temporary;
            end
        end
        
        function createOutputAndScratchFoldersForPipelineStep(obj, merged_configuration)
            createOutputAndScratchFoldersForPipelineStep(merged_configuration);
        end
        
        function parforSave(obj, path, variable)
            parforSave(obj.semaphore_key, path, variable)
        end
        
        function saveJSON(obj, path, variable)
            saveJSON(path, variable);
        end
        
        function configuration = fillSetUpStructPipelineStep(obj, configuration, i)
            configuration = fillSetUpStructPipelineStep(configuration, i);
        end
        
        function configuration = fillSetUpStructIteration(obj, configuration, j, previous_tomogram_status)
            configuration = fillSetUpStructIteration(configuration, j, previous_tomogram_status);
        end
    end
end
