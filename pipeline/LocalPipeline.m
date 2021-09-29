classdef LocalPipeline < Pipeline
    methods
        function obj = LocalPipeline(configuration_path, default_configuration_path)
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
            
            file_count_changed = true;
            
            while file_count_changed == true
                
                if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
                    dynamic_configuration = struct;
                    dynamic_configuration.file_count = configuration.general.file_count;
                    dynamic_configuration.starting_tomogram = configuration.general.starting_tomogram;
                    dynamic_configuration.tomograms_count = configuration.general.tomograms_count;
                    file_count_changed = false;
                else
                    [dynamic_configuration, file_count_changed] = getUnprocessedTomograms(configuration.general, log_file_id);
                end
                
                %                 obj.saveJSON(folder + string(filesep) + "tomogram_meta_data.json", dynamic_configuration);
                sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
                
                if file_count_changed == true
                    sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
                    
                    for i = 1:length(sucess_files_to_be_deleted)
                        delete(sucess_files_to_be_deleted(i).folder + string(filesep) + sucess_files_to_be_deleted(i).name);
                    end
                    
                elseif file_count_changed == false && length(sucess_files_to_be_deleted) < length(pipeline_definition)
                else
                    disp("INFO: File count has not changed therefor further execution of the pipeline is abandoned!")
                    break;
                end
                
                if isfield(configuration_history, "general")
                    configuration_history.general = obj.mergeConfigurations(configuration_history.general, dynamic_configuration, 0, "dynamic");
                else
                    configuration_history.general = dynamic_configuration;
                end
                
                configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
                
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
                tomogram_status = {};
                
                previous_tomogram_status = zeros([1 dynamic_configuration.tomograms_count]);
                if isfield(configuration.general, "tomogram_indices") && ~isempty(configuration.general.tomogram_indices)
                    previous_tomogram_status(configuration.general.tomogram_indices) = 1;
                elseif isfield(configuration.general, "tomogram_begin")...
                        && isfield(configuration.general, "tomogram_end")...
                        && 0 < configuration.general.tomogram_begin...
                        && 0 < configuration.general.tomogram_end...
                        && configuration.general.tomogram_end >= configuration.general.tomogram_begin...
                        && configuration.general.tomogram_step ~= 0
                    tomogram_indices = configuration.general.tomogram_begin:configuration.general.tomogram_step:configuration.general.tomogram_end;
                    previous_tomogram_status(tomogram_indices) = 1;
                else
                    previous_tomogram_status = ones([1 dynamic_configuration.tomograms_count]);
                end
                tomogram_mask = previous_tomogram_status;
                
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
                            if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
                                file_count_changed = false;
                            else
                                file_count_changed = getFileCountChanged(configuration.general);
                            end
                            
                            if file_count_changed == true
                                break;
                            end
                            
                        end
                        %                         end
                        
                    end
                    %
                    %                     if nargin < 4
                    %                         %                         obj.parforSave(meta_data_file_path, configuration_history);
                    %
                    %                     end
                    if pipeline_ending_step + 1 == i
                        disp("INFO: processing reached given pipeline step " + pipeline_ending_step);
                        %exit(0);
                        return;
                    end
                end
            end
            disp("INFO: Execution finished!");
        end
        
        %         function merged_configurations = mergeConfigurations(obj,...
        %                 first_configuration, second_configuration, pipeline_step, script_name)
        %             %printVariable(first_configuration);
        %             %printVariable(second_configuration);
        %             field_names = fieldnames(second_configuration);
        %             merged_configurations = first_configuration;
        %             for i = 1:length(field_names)
        %                 if field_names{i} ~= "output_folder" && field_names{i} ~= "scratch_folder"
        %                     if isstruct(second_configuration.(field_names{i})) && (field_names{i}) ~= "environmentProperties"
        %                         if ~isfield(first_configuration, (field_names{i}))
        %                             first_configuration.(field_names{i}) = struct;
        %                         end
        %                         field_names_second = fieldnames(second_configuration.(field_names{i}));
        %                         for k = 1:length(field_names_second)
        %                             for l = 1:length(second_configuration.(field_names{i}))
        %                                 if isstruct(second_configuration.(field_names{i}).(field_names_second{k}))
        %                                     merged_configurations.(field_names{i})(l).(field_names_second{k}) = struct;
        %                                     if ~isfield(first_configuration.(field_names{i})(l), field_names_second{k})
        %                                         first_configuration.(field_names{i})(l).(field_names_second{k}) = struct;
        %                                     end
        %                                 else
        %                                     merged_configurations.(field_names{i})(l).(field_names_second{k}) = [];
        %                                     if ~isfield(first_configuration.(field_names{i})(l), field_names_second{k})
        %                                         first_configuration.(field_names{i})(l).(field_names_second{k}) = [];
        %                                     end
        %                                 end
        %                             end
        %                         end
        %                         for j = 1:length(second_configuration.(field_names{i}))
        %                             merged_configurations.(field_names{i})(j) =...
        %                                 obj.mergeConfigurations(first_configuration.(field_names{i})(j),...
        %                                 second_configuration.(field_names{i})(j), pipeline_step, "dynamic");
        %                         end
        %                     else
        %                         merged_configurations.(field_names{i}) =...
        %                             second_configuration.(field_names{i});
        %                     end
        %                 elseif (field_names{i} == "output_folder" || field_names{i} == "scratch_folder")
        %                     merged_configurations.(field_names{i}) =...
        %                         merged_configurations.(field_names{i})...
        %                         + string(filesep)...
        %                         + pipeline_step + "_" + second_configuration.(field_names{i});
        %                 end
        %             end
        %             % NOTE: be careful if a script outputs output_folder field as
        %             % dynamic variable
        %             if ~any(ismember(field_names, "output_folder")) && script_name ~= "dynamic"
        %                 merged_configurations.pipeline_step_output_folder = first_configuration.output_folder + string(filesep) + pipeline_step + "_" + script_name;
        %             end
        %             if ~any(ismember(field_names, "scratch_folder")) && script_name ~= "dynamic"
        %                 merged_configurations.pipeline_step_scratch_folder = first_configuration.scratch_folder + string(filesep) + pipeline_step + "_" + script_name;
        %             end
        %             %printVariable(merged_configurations);
        %         end
        
        
        
        function [dynamic_configuration_out, status] = execution_once(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            
            
            % TODO: needs also to handle
            % merged_configuration.tomogram_begin,
            % merged_configuration.tomogram_end,
            % merged_configuration.tomogram_step
            %             if ~isempty(merged_configuration.tomogram_interval)
            %
            %                 if min([merged_configuration.tomogram_interval(1), merged_configuration.tomogram_interval(3)]) > 1
            %                     tomogram_count = max([merged_configuration.tomogram_interval(1), merged_configuration.tomogram_interval(3)]);
            %                 else
            %                     tomogram_count = length([merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)]);
            %                 end
            %
            %             else
            %                 tomogram_count = length(fieldnames(merged_configuration.tomograms));
            %             end
            
            if (isfield(merged_configuration, "skip") && merged_configuration.skip == true) || (~isempty(previous_tomogram_status) && ~any(previous_tomogram_status))
                
                %                 if isempty(previous_tomogram_status)
                %                     status = ones(1, tomogram_count);
                %                 else
                %                 if ~isempty(previous_tomogram_status)
                status = previous_tomogram_status;
                %                 end
                dynamic_configuration_out = struct;
                return;
                %                 configuration_history.(pipeline_definition) = obj.finishPipelineStep(...
                %                     dynamic_configuration_in, pipeline_definition, ...
                %                     configuration_history, i);
            end
            
            %             dynamic_configuration_out = dynamic_configuration_in;
            %                 if fileExists(success_file_path) && merged_configuration.ignore_success_files == false
            %                     disp("INFO: Skipping pipeline step due to availability of a SUCCESS file!")
            %                     dynamic_configuration_out = obj.finishPipelineStep(...
            %                         dynamic_configuration_in, pipeline_definition,...
            %                         configuration_history, i);
            %                     if isempty(previous_tomogram_status)
            %                         status = ones(1, tomogram_count);
            %                     else
            %                         status = previous_tomogram_status;
            %                     end
            %                     return;
            %                 elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
            %                     disp("INFO: Skipping pipeline step due to availability of a FAILURE file!")
            %                     dynamic_configuration_out = obj.finishPipelineStep(...
            %                         dynamic_configuration_in, pipeline_definition,...
            %                         configuration_history, i);
            %                     status = zeros(1, tomogram_count);
            %                     return;
            %                 else
            obj.createOutputAndScratchFoldersForPipelineStep(merged_configuration);
            
            %             merged_configuration.set_up = struct;
            %             merged_configuration.set_up.i = i;
            obj.saveJSON(merged_configuration.output_path + string(filesep) + "input.json", merged_configuration);
            
            function_handle = str2func(pipeline_definition);
            disp("INFO: Executing processing step " + num2str(merged_configuration.set_up.i - 1) + ...
                ": " + pipeline_definition + "...");
            %processing_step_start_time = tic;
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
            
            
            %                 dynamic_configuration_tmp.duration = instantiated_class.duration;
            %                 if fileExists(meta_data_folder_path + string(filesep)...
            %                         + obj.configuration.general.project_name...
            %                         + "_times.mat")
            %                     save(meta_data_folder_path + string(filesep)...
            %                         + obj.configuration.general.project_name...
            %                         + "_times", "processing_step_times",...
            %                         "-append");
            %                 else
            %                     save(meta_data_folder_path + string(filesep)...
            %                         + obj.configuration.general.project_name...
            %                         + "_times", "processing_step_times");
            %                 end
            
            %             dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, dynamic_configuration_tmp, 0, "dynamic");
            %             configuration_history.(pipeline_definition) = obj.mergeConfigurations(configuration_history.(pipeline_definition), instantiated_class.dynamic_configuration, 0, "dynamic");
            
            % tomogram_names = fieldnames(merged_configuration.tomograms);
            % for k = 1:length(tomogram_names)
            %     configuration_history.(pipeline_definition).tomograms.(tomogram_names{k}).processed_pipeline_steps = merged_configuration.tomograms.(tomogram_names{k}).processed_pipeline_steps;
            %     configuration_history.(pipeline_definition).tomograms.(tomogram_names{k}).processed_pipeline_steps(i-1) = 1;
            % end
            
            %dynamic_configuration = obj.mergeConfigurations(dynamic_configuration, configuration_history.(pipeline_definition), 0, "dynamic");
            
            %processing_step_end_time = toc(processing_step_start_time);
            %                 if (~isfield(processing_step_times, pipeline_definition))...
            %                         ||...
            %                         (isfield(processing_step_times, pipeline_definition) &&  ~fileExists(success_file_path))
            %                 dynamic_configuration_out.processing_step_duration = instantiated_class.duration;
            %                 end
            
            if status == 1
                success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
                % NOTE:TODO: could be problematic if this execution
                % method is in the middle of a pipeline, better
                % propagate previous pipeline state
                %                 if isempty(previous_tomogram_status)
                %                     if ~isempty(merged_configuration.tomogram_interval)
                %                         status = zeros(1, tomogram_count);
                %                         status(merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)) = 1;
                %                     else
                %                         status = ones(1, tomogram_count);
                %                     end
                %                 else
                status = previous_tomogram_status;
                %                 end
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
            %             obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history);
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_history", "configuration_history",...
            %                     "-append");
            
            disp("INFO: Execution for processing step " + num2str(merged_configuration.set_up.i - 1) + ...
                " (" + pipeline_definition + ") has finished!");
        end
        
        function [dynamic_configuration_out, status] = execution_parallel(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            %           configuration_history.(pipeline_definition) = struct;
            tomogram_names = fieldnames(merged_configuration.tomograms);
            
            %             status = {};
            %             parfor j = 1:length(tomogram_names)
            %                 status{j} = 0;
            %             end
            
            %             if isfield(merged_configuration, "tomogram_interval") &&~isempty(merged_configuration.tomogram_interval)
            %                 %                 previous_tomogram_status = previous_tomogram_status(merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3));
            %                 %                 tomogram_names = {tomogram_names{merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)}};
            %                 tomogram_names = {tomogram_names{1:length(previous_tomogram_status)}};
            %             elseif isfield(merged_configuration, "tomogram_start") && isfield(merged_configuration, "tomogram_end") && merged_configuration.tomogram_start ~= -1 && merged_configuration.tomogram_end ~= -1
            %                 previous_tomogram_status = previous_tomogram_status(merged_configuration.tomogram_start:merged_configuration.tomogram_step:merged_configuration.tomogram_end);
            %                 tomogram_names = {tomogram_names{merged_configuration.tomogram_start:merged_configuration.tomogram_step:merged_configuration.tomogram_end}};
            %             end
            
            % tomogram_indices = find(previous_tomogram_status);
            % tomogram_names = {tomogram_names{tomogram_indices}};
            % processing_step_start_time = tic;
            
            % merged_configurations = {};
            % parfor j = 1:length(tomogram_names)
            %     merged_configurations{j} = merged_configuration;
            % 	  merged_configurations{j} = generateSetUpStruct(merged_configurations{j}, previous_tomogram_status, i, j);
            %     configuration_histories{j} = configuration_history;
            %     dynamic_configurations{j} = dynamic_configuration_in;
            %     status_tmp{j} = 0;
            % end
            
            %for j = 1:length(tomogram_names)
            
            %parfor (j = 1:length(tomogram_names), 0)
            %
            %             semaphore_key = obj.semaphore_key;
            %             dynamic_configuration_out = dynamic_configuration_in;
            
            status = cell([1 length(previous_tomogram_status)]);
            for j = 1:length(previous_tomogram_status)
                status{j} = 0;
            end
            
            indices = find(previous_tomogram_status);
            for j = 1:length(indices) %par
                merged_configuration_tmp = fillSetUpStructIteration(merged_configuration, indices(j), previous_tomogram_status);
                [dynamic_configurations_out{j}, status_tmp{j}] = iteration(merged_configuration_tmp, pipeline_definition, tomogram_names{indices(j)}, previous_tomogram_status(indices(j)));
                % merged_configurations{j} = merged_configuration;
                % merged_configurations{j} = generateSetUpStruct(merged_configurations{j}, previous_tomogram_status, i, j);
                % configuration_histories{j} = configuration_history;
                % dynamic_configurations{j} = dynamic_configuration_out;
                % status_tmp{j} = 0;
                % fid = -1;
                % output_folder = "";
                % scratch_folder = "";
                % %status{tomogram_indices(j)} = 0;
                % if ~isfield(merged_configurations{j}, "skip") || merged_configurations{j}.skip == false
                %     previous_output_folder_tmp = previous_output_folder + string(filesep) + tomogram_names{j};
                %     previous_scratch_folder_tmp = previous_scratch_folder + string(filesep) + tomogram_names{j};
                %     success_file_path = previous_output_folder_tmp + string(filesep) + "SUCCESS";
                %     failure_file_path = previous_output_folder_tmp + string(filesep) + "FAILURE";
                
                %     if fileExists(success_file_path) && merged_configurations{j}.ignore_success_files == false
                %         disp("INFO: Skipping pipeline step for tomogram " + tomogram_names{j} + " due to availability of a SUCCESS file!")
                %         dynamic_configurations{j} = finishPipelineStep(...
                %             dynamic_configurations{j}, pipeline_definition, ...
                %             configuration_histories{j}, i);
                %         status_tmp{j} = 1;
                %         continue;
                %     elseif fileExists(failure_file_path) && merged_configurations{j}.ignore_success_files == false
                %         disp("INFO: Skipping pipeline step for tomogram " + tomogram_names{j} + " due to availability of a FAILURE file!")
                %         dynamic_configurations{j} = finishPipelineStep(...
                %             dynamic_configurations{j}, pipeline_definition, ...
                %             configuration_histories{j}, i);
                %         status_tmp{j} = 0;
                %         continue;
                %     end
                
                %     if ~isempty(previous_tomogram_status) && previous_tomogram_status(j) == 0
                %         status_tmp{j} = 0;
                %         fid = fopen(failure_file_path, 'wt');
                %         fclose(fid);
                %         continue;
                %     end
                
                %     createOutputAndScratchFoldersForPipelineStep(merged_configuration, output_folder, scratch_folder);
                
                %     function_handle = str2func(pipeline_definition);
                %     disp("INFO: Executing processing step " + num2str(i - 1) + ...
                %         ": " + pipeline_definition + "...");
                %     merged_configurations{j} = generateSetUpStruct(merged_configurations{j}, previous_tomogram_status, i, j);
                
                %     instantiated_class = function_handle(merged_configurations{j});
                
                %     saveJSON(instantiated_class.output_path + string(filesep) + "input.json", merged_configurations{j});
                
                %     instantiated_class = instantiated_class.setUp();
                %     instantiated_class = instantiated_class.process();
                %     instantiated_class = instantiated_class.cleanUp();
                %     status_tmp{j} = instantiated_class.status;
                %     dynamic_configuration_tmp = instantiated_class.dynamic_configuration;
                %     %                     dynamic_configuration_tmp.duration(j) = instantiated_class.duration;
                %     dynamic_configurations{j} = mergeConfigurations(dynamic_configurations{j}, dynamic_configuration_tmp, 0, "dynamic");
                
                %     configuration_histories{j}.(pipeline_definition) = dynamic_configurations{j};
                %     %                     configuration_histories{j}.(pipeline_definition).duration(j) = instantiated_class.duration;
                
                %     % TODO: if execution was reversed to aprevious step the
                %     % afterwards coming processed pipeline steps should be set to zero
                %     % configuration_histories{j}.(pipeline_definition).tomograms.(tomogram_names{j}).processed_pipeline_steps = merged_configurations{j}.tomograms.(tomogram_names{j}).processed_pipeline_steps;
                %     % configuration_histories{j}.(pipeline_definition).tomograms.(tomogram_names{j}).processed_pipeline_steps(i-1) = 1;
                
                %     parforSave(semaphore_key, getMetaDataFilePath(merged_configuration), configuration_histories{j});
                
                %     if status_tmp{j} == 1
                %         fid = fopen(success_file_path, 'wt');
                %         obj.saveJSON(instaniated_class.output_path + string(filesep) + "output.json", dynamic_configurations{j});
                %     elseif status_tmp{tj} == 0
                %         fid = fopen(failure_file_path, 'wt');
                %     end
                
                %     fclose(fid);
                
                %     disp("INFO: Execution for processing step " + num2str(i - 1) + ...
                %         " (" + pipeline_definition + ") has finished!");
                % else
                %     status_tmp{j} = 1;
                %     dynamic_configurations{j} = finishPipelineStep(...
                %         dynamic_configurations{j}, pipeline_definition, ...
                %         configuration_histories{j}, i);
                % end
            end
            if ~any(previous_tomogram_status)
                dynamic_configuration_out = struct;
            else
                dynamic_configuration_out = obj.combineConfigurations(dynamic_configurations_out);
            end
            
            %             [dynamic_configuration_out, configuration_history] = obj.combineConfigurations(configuration_histories, dynamic_configurations);
            
            %             if length(tomogram_names) > 1
            %
            %                 for j = 1:length(tomogram_names) - 1
            %
            %                     if j == 1
            %                         %                         merged_configuration = obj.mergeConfigurations(merged_configurations{j}, merged_configurations{j+1}, 0, "dynamic");
            %                         configuration_history = obj.mergeConfigurations(configuration_histories{j}, configuration_histories{j + 1}, 0, "dynamic");
            %                         dynamic_configuration_out = obj.mergeConfigurations(dynamic_configurations{j}, dynamic_configurations{j + 1}, 0, "dynamic");
            %                     else
            %                         %                         merged_configuration = obj.mergeConfigurations(merged_configuration, merged_configurations{j+1}, 0, "dynamic");
            %                         configuration_history = obj.mergeConfigurations(configuration_history, configuration_histories{j + 1}, 0, "dynamic");
            %                         dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, dynamic_configurations{j + 1}, 0, "dynamic");
            %                     end
            %
            %                 end
            %
            %             else
            %                 %                 merged_configuration = merged_configurations{1};
            %                 configuration_history = configuration_histories{1};
            %                 dynamic_configuration_out = dynamic_configurations{1};
            %             end
            
            
            %             if fileExists(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times.mat")
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times",...
            %                     "-append");
            %             else
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times");
            %             end
            
            %             configuration_history.(pipeline_definition) = obj.mergeConfigurations(configuration_history.(pipeline_definition), dynamic_configuration_out, 0, "dynamic");
            
            %             processing_step_end_time = toc(processing_step_start_time);
            % TODO: does this condition make really sense
            %             if (~isfield(processing_step_times, pipeline_definition))...
            %                     ||...
            %                     (isfield(processing_step_times, pipeline_definition) &&  ~fileExists(success_file_path))
            %             if ~isfield(processing_step_times, pipeline_definition)
            %                 dynamic_configuration.processing_step_times.(pipeline_definition) = processing_step_end_time;
            %             end
            for k = 1:length(indices)
                status{indices(k)} = status_tmp{k};
            end
            status = [status{:}];
            
            % NOTE:TODO be carefull not to use merged_configuration variable because it accumulates output_folder field in a wrong way
            %             obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history);
            %             save(meta_data_folder_path + string(filesep)...
            %                 + obj.configuration.general.project_name...
            %                 + "_history", "configuration_history",...
            %                 "-append");
        end
        
        function [dynamic_configuration_out, status] = execution_in_order(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            %
            %             tomogram_names = fieldnames(merged_configuration.tomograms);
            %
            %
            %             if isfield(merged_configuration, "tomogram_interval") &&~isempty(merged_configuration.tomogram_interval)
            %                 %                tomogram_names = {tomogram_names{merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)}};
            %                 tomogram_names = {tomogram_names{1:length(previous_tomogram_status)}};
            %
            %             elseif isfield(merged_configuration, "tomogram_start") && isfield(merged_configuration, "tomogram_end") && merged_configuration.tomogram_start ~= -1 && merged_configuration.tomogram_end ~= -1
            %                 tomogram_names = {tomogram_names{merged_configuration.tomogram_start:merged_configuration.tomogram_step:merged_configuration.tomogram_end}};
            %             end
            %
            
            %             status = zeros(1, length(previous_tomogram_status));
            %             status_tmp_tmp = {};
            
            %             parfor j = 1:length(tomogram_names)
            %                 status{j} = 0;
            %             end
            tomogram_names = fieldnames(merged_configuration.tomograms);
            %tomogram_names = obj.setUpInterval(merged_configuration, previous_tomogram_status);
            
            
            %tomogram_indices = find(previous_tomogram_status);
            %tomogram_names = {tomogram_names{tomogram_indices}};
            
            %             processing_step_start_time = tic;
            
            %             merged_configurations = {};
            %             configuration_histories = {};
            %             dynamic_configurations_in = {};
            %
            %             for j = 1:length(tomogram_names)
            %
            % %                 configuration_histories{j} = configuration_history;
            % %                 dynamic_configurations_in{j} = dynamic_configuration_in;
            %             end
            
            counter = 0;
            
            % TODO: revise for better parametrization
            if isfield(obj.configuration, "gpu_worker_multiplier")...
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
            % if merged_configuration.execution_method == "parallel"
            %     generatePool(merged_configuration.cpu_fraction, false, pool_folder);
            % elseif merged_configuration.execution_method == "in_order"
            generatePool(merged_configuration.environment_properties.gpu_count, false, pool_folder);
            
            cumulative_sum_previous_tomogram_status = cumsum(previous_tomogram_status);
            indices = find(previous_tomogram_status);
            for j = 1:max(cumulative_sum_previous_tomogram_status) %1:length(tomogram_names) %
                
                %                 if ~isempty(previous_tomogram_status) && previous_tomogram_status(j + 1) == 0
                %                     continue;
                %                 end
                if mod(j - 1, workers) == 0 && j > 1
                    wait(f);
                    [dynamic_configuration_tmp, status_tmp] = fetchOutputs(f, 'UniformOutput', false);
                    
                    for k = 1:workers
                        dynamic_configurations_out{counter + 1} = dynamic_configuration_tmp{k};
                        %                         configuration_histories{counter + 1} = configuration_history_tmp{k};
                        status{indices(counter + 1)} = status_tmp{k};
                        counter = counter + 1;
                    end
                    
                    %                     if workers == 1 &&
                    %
                    %                         dynamic_configuration_save_tmp = dynamic_configurations_out{1};
                    %                     elseif workers > 1
                    %                         for k = 1:workers
                    %
                    %                             if k == 1
                    %                                 %                             configuration_history_save_tmp = obj.mergeConfigurations(configuration_histories{counter - k}, configuration_histories{counter - k + 1}, 0, "dynamic");
                    %                                 dynamic_configuration_save_tmp = obj.mergeConfigurations(dynamic_configurations_out{counter - k}, dynamic_configurations_out{counter - k + 1}, 0, "dynamic");
                    %                             else
                    %                                 %                             configuration_history_save_tmp = obj.mergeConfigurations(configuration_history_save_tmp, configuration_histories{counter - k + 1}, 0, "dynamic");
                    %                                 dynamic_configuration_save_tmp = obj.mergeConfigurations(dynamic_configuration_save_tmp, dynamic_configurations_out{counter - k + 1}, 0, "dynamic");
                    %                             end
                    %
                    %                         end
                    %                     else
                    %                         error("ERROR: workers can not be less than 1!");
                    %                     end
                    %                     obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history_save_tmp);
                    %                     save(meta_data_folder_path + string(filesep)...
                    %                         + obj.configuration.general.project_name...
                    %                         + "_history", "configuration_history",...
                    %                         "-append");
                    
                    clear f;
                end
                merged_configurations{j} = merged_configuration;
                merged_configurations{j} = obj.fillSetUpStructIteration(merged_configurations{j}, indices(j), previous_tomogram_status);
                % TODO intermediate configurations need to be saved to be
                % consistent
                f(mod(j - 1, workers) + 1) = ...
                    parfeval(@iteration, 2, merged_configurations{j}, pipeline_definition, tomogram_names{indices(j)}, previous_tomogram_status(indices(j)));
            end
            
            %            if mod(j, workers) ~= 0 && j > 1
            if exist("f", "var") && ~isempty(f)
                %if mod(j, merged_configurations{j + 1}.environmentProperties.gpu_count) == 0 && j ~= 0
                wait(f);
                [dynamic_configuration_tmp, status_tmp] = fetchOutputs(f, 'UniformOutput', false);
                % TODO: needs to be dajusted for arbitrary number of
                % gpus
                for j = 1:length(dynamic_configuration_tmp)
                    dynamic_configurations_out{counter + 1} = dynamic_configuration_tmp{j};
                    %                     configuration_histories{counter + 1} = configuration_history_tmp{j};
                    status{indices(counter + 1)} = status_tmp{j};
                    counter = counter + 1;
                end
                
            end
            
            %end
            if ~any(previous_tomogram_status)
                dynamic_configuration_out = struct;
            else
                dynamic_configuration_out = obj.combineConfigurations(dynamic_configurations_out);
            end
            
            %             [dynamic_configuration_out, configuration_history] = obj.combineConfigurations(configuration_histories, dynamic_configurations_in);
            %             if length(tomogram_names) > 1
            %
            %                 for j = 1:length(tomogram_names) - 1
            %
            %                     if j == 1
            %                         %                         merged_configuration = obj.mergeConfigurations(merged_configurations{j}, merged_configurations{j+1}, 0, "dynamic");
            %                         configuration_history = obj.mergeConfigurations(configuration_histories{j}, configuration_histories{j + 1}, 0, "dynamic");
            %                         dynamic_configuration_out = obj.mergeConfigurations(dynamic_configurations{j}, dynamic_configurations{j + 1}, 0, "dynamic");
            %                     else
            %                         %                         merged_configuration = obj.mergeConfigurations(merged_configuration, merged_configurations{j+1}, 0, "dynamic");
            %                         configuration_history = obj.mergeConfigurations(configuration_history, configuration_histories{j + 1}, 0, "dynamic");
            %                         dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, dynamic_configurations{j + 1}, 0, "dynamic");
            %                     end
            %
            %                 end
            %
            %             else
            %                 %                 merged_configuration = merged_configurations{1};
            %                 configuration_history = configuration_histories{1};
            %                 dynamic_configuration_out = dynamic_configurations{1};
            %             end
            
            %             if fileExists(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times.mat")
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times",...
            %                     "-append");
            %             else
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times");
            %             end
            
            %             processing_step_end_time = toc(processing_step_start_time);
            %             % TODO: does this condition make really sense
            %             if (~isfield(processing_step_times, pipeline_definition))...
            %                     ||...
            %                     (isfield(processing_step_times, pipeline_definition) &&  ~fileExists(success_file_path))
            %                 dynamic_configuration.processing_step_times.(pipeline_definition) = processing_step_end_time;
            %             end
            
            % TODO: really needed seems that values are get overwritten
            % again
            %             dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, configuration_history.(pipeline_definition), 0, "dynamic");
            %             configuration_history.(pipeline_definition) = struct();
            %             configuration_history.(pipeline_definition) = obj.mergeConfigurations(configuration_history.(pipeline_definition), dynamic_configuration_out, 0, "dynamic");
            %             configuration_history.(pipeline_definition) = dynamic_configuration_out;
            %             status(find(previous_tomogram_status)) = [status_tmp_tmp{:}];
            status = [status{:}];
            %             obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history);
            
            %             save(meta_data_folder_path + string(filesep)...
            %                 + obj.configuration.general.project_name...
            %                 + "_history", "configuration_history",...
            %                 "-append");
        end
        
        function [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, tomogram_name, previous_tomogram_status)
            %         function [configuration_history, status] = iteration(obj, merged_configuration, pipeline_definition, ...
            %                 output_folder, scratch_folder, i, ...
            %                 configuration_history, dynamic_configuration_in, ...
            %                 tomogram_name, j, previous_tomogram_status, sempahore_key)
            
            
            [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, tomogram_name, previous_tomogram_status);
            
            %             [configuration_history, status] = iteration(merged_configuration, pipeline_definition, ...
            %                 output_folder, scratch_folder, i, ...
            %                 configuration_history, dynamic_configuration_in, ...
            %                 tomogram_name, j, previous_tomogram_status, sempahore_key);
            
            % % processing_path = merged_configuration.processing_path;
            
            % configuration_history.(pipeline_definition) = struct;
            % %             output_folder = "";
            % %             scratch_folder = "";
            % %             status = 0;
            % if ~isfield(merged_configuration, "skip") || merged_configuration.skip == false
            %     previous_output_folder_tmp = previous_output_folder + string(filesep) + tomogram_name;
            %     previous_scratch_folder_tmp = previous_scratch_folder + string(filesep) + tomogram_name;
            %     success_file_path = previous_output_folder_tmp + string(filesep) + "SUCCESS";
            %     failure_file_path = previous_output_folder_tmp + string(filesep) + "FAILURE";
            %     %                 status = 0;
            %     if fileExists(success_file_path) && merged_configuration.ignore_success_files == false
            %         disp("INFO: Skipping pipeline step for tomogram " + tomogram_name + " due to availability of a SUCCESS file!")
            %         dynamic_configuration_out = obj.finishPipelineStep(...
            %             dynamic_configuration_in, pipeline_definition, ...
            %             configuration_history, i);
            %         status = 1;
            %         return;
            %     elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
            %         disp("INFO: Skipping pipeline step for tomogram " + tomogram_name + " due to availability of a FAILURE file!")
            %         dynamic_configuration_out = obj.finishPipelineStep(...
            %             dynamic_configuration_in, pipeline_definition, ...
            %             configuration_history, i);
            %         status = 0;
            %         return;
            %     else
            
            %         if exist(previous_output_folder_tmp, "dir")
            %             rmdir(previous_output_folder_tmp, "s");
            %         end
            
            %         output_folder = previous_output_folder_tmp;
            %         previous_output_folder_splitted = strsplit(previous_output_folder_tmp, "/");
            %         merged_configuration.pipeline_step_output_folder = strjoin(previous_output_folder_splitted(end - 2:end), "/");
            
            %         if exist(previous_scratch_folder_tmp, "dir")
            %             rmdir(previous_scratch_folder_tmp, "s");
            %         end
            
            %         scratch_folder = previous_scratch_folder_tmp;
            %         previous_scratch_folder_splitted = strsplit(previous_scratch_folder_tmp, "/");
            %         merged_configuration.pipeline_step_scratch_folder = strjoin(previous_scratch_folder_splitted(end - 2:end), "/");
            %     end
            
            %     if ~exist(output_folder, "dir")
            %         [status_mkdir, message, message_id] = mkdir(output_folder);
            %     end
            
            %     if ~exist(scratch_folder, "dir")
            %         [status_mkdir, message, message_id] = mkdir(scratch_folder);
            %     end
            
            %     if ~isempty(previous_tomogram_status) && previous_tomogram_status(j) == 0
            %         status = 0;
            %         dynamic_configuration_out = obj.finishPipelineStep(...
            %             dynamic_configuration_in, pipeline_definition, ...
            %             configuration_history, i);
            %         fid = fopen(failure_file_path, 'wt');
            %         fclose(fid);
            %         return;
            %     end
            
            %     %                 merged_configuration = obj.generateSetUpStruct(merged_configuration, previous_tomogram_status, i ,j);
            %     function_handle = str2func(pipeline_definition);
            %     disp("INFO: Executing processing step " + num2str(i - 1) + ...
            %         ": " + pipeline_definition + "...");
            %     instantiated_class = function_handle(merged_configuration);
            %     saveJSON(instantiated_class.output_path + string(filesep) + "input.json", merged_configuration);
            
            %     instantiated_class = instantiated_class.setUp();
            %     instantiated_class = instantiated_class.process();
            %     instantiated_class = instantiated_class.cleanUp();
            %     dynamic_configuration_tmp = instantiated_class.dynamic_configuration;
            %     %                 dynamic_configuration_tmp.duration(j) = instantiated_class.duration;
            %     dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_in, dynamic_configuration_tmp, 0, "dynamic");
            %     status = instantiated_class.status;
            %     configuration_history.(pipeline_definition) = obj.mergeConfigurations(configuration_history.(pipeline_definition), dynamic_configuration_out, 0, "dynamic");
            %     % configuration_history.(pipeline_definition).tomograms.(tomogram_name).processed_pipeline_steps = merged_configuration.tomograms.(tomogram_name).processed_pipeline_steps;
            %     % configuration_history.(pipeline_definition).tomograms.(tomogram_name).processed_pipeline_steps(i-1) = 1;
            %     obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history);
            
            %     if status == 1
            %         fid = fopen(success_file_path, 'wt');
            %         saveJSON(instantiated_class.output_path + string(filesep) + "output.json", dynamic_configuration_out);
            %     elseif status == 0
            %         fid = fopen(failure_file_path, 'wt');
            %     end
            
            %     fclose(fid);
            
            %     disp("INFO: Execution for processing step " + num2str(i - 1) + ...
            %         " (" + pipeline_definition + ") has finished!");
            % else
            %     status = 1;
            %     dynamic_configuration_out = obj.finishPipelineStep(...
            %         dynamic_configuration_in, pipeline_definition, ...
            %         configuration_history, i);
            % end
            
        end
        
        function tomogram_names = setUpInterval(obj, merged_configuration, previous_tomogram_status)
            tomogram_names = fieldnames(merged_configuration.tomograms);
            if isfield(merged_configuration, "tomogram_interval") && ~isempty(merged_configuration.tomogram_interval)
                %                 tomogram_names = {tomogram_names{merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)}};
                tomogram_names = {tomogram_names{1:length(previous_tomogram_status)}};
            elseif isfield(merged_configuration, "tomogram_start") && isfield(merged_configuration, "tomogram_end") && merged_configuration.tomogram_start ~= -1 && merged_configuration.tomogram_end ~= -1
                tomogram_names = {tomogram_names{merged_configuration.tomogram_start:merged_configuration.tomogram_step:merged_configuration.tomogram_end}};
            end
        end
        
        function [dynamic_configuration_out, status] = execution_sequential(obj, merged_configuration, pipeline_definition, previous_tomogram_status)
            %dynamic_configuration_out = struct;
            tomogram_names = obj.setUpInterval(merged_configuration, previous_tomogram_status);
            
            %merged_configurations = {};
            %
            %             parfor j = 1:length(tomogram_names)
            %                 merged_configurations{j} = merged_configuration;
            %                 configuration_histories{j} = configuration_history;
            %                 dynamic_configurations{j} = dynamic_configuration
            %             end
            
            
            
            %             dynamic_configuration_out = dynamic_configuration_in;
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
                %                 [dynamic_configurations{j}, status{j}] = obj.iteration(merged_configuration, pipeline_definition, output_folder, scratch_folder, i, configuration_history, dynamic_configuration_in, tomogram_names{j}, j, previous_tomogram_status(j), obj.semaphore_key);
                %                 output_folder = "";
                %                 scratch_folder = "";
                %
                %                 if ~isfield(merged_configuration, "skip") || merged_configuration.skip == false
                %                     previous_output_folder_tmp = previous_output_folder + string(filesep) + tomogram_names{j};
                %                     previous_scratch_folder_tmp = previous_scratch_folder + string(filesep) + tomogram_names{j};
                %                     success_file_path = previous_output_folder_tmp + string(filesep) + "SUCCESS";
                %                     failure_file_path = previous_output_folder_tmp + string(filesep) + "FAILURE";
                %
                %                     if fileExists(success_file_path) && merged_configuration.ignore_success_files == false
                %                         disp("INFO: Skipping pipeline step for tomogram " + tomogram_names{j} + " due to availability of a SUCCESS file!")
                %                         dynamic_configuration_out = obj.finishPipelineStep(...
                %                             dynamic_configuration_out, pipeline_definition, ...
                %                             configuration_history, i);
                %                         status(j) = 1;
                %                         continue;
                %                     elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
                %                         disp("INFO: Skipping pipeline step for tomogram " + tomogram_names{j} + " due to availability of a FAILURE file!")
                %                         dynamic_configuration_out = obj.finishPipelineStep(...
                %                             dynamic_configuration_out, pipeline_definition, ...
                %                             configuration_history, i);
                %                         status(j) = 0;
                %                         continue;
                %                     end
                %
                %                     if ~isempty(previous_tomogram_status) && previous_tomogram_status(j) == 0
                %                         status(j) = 0;
                %                         fid = fopen(failure_file_path, 'wt');
                %                         fclose(fid);
                %                         continue;
                %                     end
                %
                %                     obj.createOutputAndScratchFoldersForPipelineStep(merged_configuration, output_folder, scratch_folder);
                %
                %                     function_handle = str2func(pipeline_definition);
                %                     disp("INFO: Executing processing step " + num2str(i - 1) + ...
                %                         ": " + pipeline_definition + "...");
                %
                %                     merged_configuration = obj.generateSetUpStruct(merged_configuration, previous_tomogram_status, i, j);
                %
                %                     instantiated_class = function_handle(merged_configuration);
                %                     saveJSON(instantiated_class.output_path + string(filesep) + "input.json", merged_configuration);
                %
                %                     instantiated_class = instantiated_class.setUp();
                %                     instantiated_class = instantiated_class.process();
                %                     instantiated_class = instantiated_class.cleanUp();
                %                     status(j) = instantiated_class.status;
                %                     dynamic_configuration_tmp = instantiated_class.dynamic_configuration;
                %                     %                     dynamic_configuration_tmp.duration(j) = instantiated_class.duration;
                %                     %dynamic_configuration_tmp = obj.mergeConfigurations(dynamic_configuration_in, dynamic_configuration_tmp, 0, "dynamic");
                %                     dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, dynamic_configuration_tmp, 0, "dynamic");
                %                     configuration_history.(pipeline_definition) = obj.mergeConfigurations(configuration_history.(pipeline_definition), dynamic_configuration_out, 0, "dynamic");
                %                     %                     configuration_history.(pipeline_definition).tomograms.(tomogram_names{j}).processed_pipeline_steps = merged_configuration.tomograms.(tomogram_names{j}).processed_pipeline_steps;
                %                     %                     configuration_history.(pipeline_definition).tomograms.(tomogram_names{j}).processed_pipeline_steps(i-1) = 1;
                %
                %                     obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history);
                %
                %                     %                     save(meta_data_folder_path + string(filesep)...
                %                     %                         + obj.configuration.general.project_name...
                %                     %                         + "_history", "configuration_history",...
                %                     %                         "-append");
                %
                %                     if status(j) == 1
                %                         fid = fopen(success_file_path, 'wt');
                %                         saveJSON(instantiated_class.output_path + string(filesep) + "output.json", dynamic_configuration_out);
                %                     elseif status(j) == 0
                %                         fid = fopen(failure_file_path, 'wt');
                %                     end
                %
                %                     fclose(fid);
                %
                %                     disp("INFO: Execution for processing step " + num2str(i - 1) + ...
                %                         " (" + pipeline_definition + ") has finished!");
                %                 else
                %                     status(j) = 1;
                %                     dynamic_configuration_out = obj.finishPipelineStep(...
                %                         dynamic_configuration_out, pipeline_definition, ...
                %                         configuration_history, i);
                %                 end
                disp("INFO: Execution of pipeline step " + num2str(merged_configuration.set_up.i - 1) + ...
                    " (" + pipeline_definition + ") for tomogram " + j + " has finished!");
            end
            dynamic_configuration_out = obj.combineConfigurations(dynamic_configurations);
            
            %                         [dynamic_configuration_out, configuration_history] = obj.combineConfigurations(configuration_histories, dynamic_configurations);
            %             if length(tomogram_names) > 1
            %
            %                 for j = 1:length(tomogram_names) - 1
            %
            %                     if j == 1
            %                         %                         merged_configuration = obj.mergeConfigurations(merged_configurations{j}, merged_configurations{j+1}, 0, "dynamic");
            %                         configuration_history = obj.mergeConfigurations(configuration_histories{j}, configuration_histories{j + 1}, 0, "dynamic");
            %                         dynamic_configuration_out = obj.mergeConfigurations(dynamic_configurations{j}, dynamic_configurations{j + 1}, 0, "dynamic");
            %                     else
            %                         %                         merged_configuration = obj.mergeConfigurations(merged_configuration, merged_configurations{j+1}, 0, "dynamic");
            %                         configuration_history = obj.mergeConfigurations(configuration_history, configuration_histories{j + 1}, 0, "dynamic");
            %                         dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, dynamic_configurations{j + 1}, 0, "dynamic");
            %                     end
            %
            %                 end
            %
            %             else
            %                 %                 merged_configuration = merged_configurations{1};
            %                 configuration_history = configuration_histories{1};
            %                 dynamic_configuration_out = dynamic_configurations{1};
            %             end
            
            %             if fileExists(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times.mat")
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times",...
            %                     "-append");
            %             else
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times");
            %             end
            
            %             processing_step_end_time = toc(processing_step_start_time);
            %             % TODO: does this condition make really sense
            %             if (~isfield(processing_step_times, pipeline_definition))...
            %                     ||...
            %                     (isfield(processing_step_times, pipeline_definition) &&  ~fileExists(success_file_path))
            %                 dynamic_configuration.processing_step_times.(pipeline_definition) = processing_step_end_time;
            %             end
            
            % TODO: really needed seems that values are get overwritten
            % again
            %             dynamic_configuration_out = obj.mergeConfigurations(dynamic_configuration_out, configuration_history.(pipeline_definition), 0, "dynamic");
            %             configuration_history.(pipeline_definition) = struct();
            
            %             configuration_history.(pipeline_definition) = obj.mergeConfigurations(configuration_history.(pipeline_definition), dynamic_configuration_out, 0, "dynamic");
            
            %             configuration_history.(pipeline_definition) = dynamic_configuration_out;
            %             status(find(previous_tomogram_status)) = [status_tmp_tmp{:}];
            status = [status{:}];
            %             obj.parforSave(getMetaDataFilePath(merged_configuration), configuration_history);
            %             for j = 1:length(tomogram_names) - 1
            %                 if j == 1
            %                     merged_configuration = obj.mergeConfigurations(merged_configurations{j}, merged_configurations{j+1}, 0, "dynamic");
            %                     configuration_history = obj.mergeConfigurations(configuration_histories{j}, configuration_histories{j+1}, 0, "dynamic");
            %                     dynamic_configuration = obj.mergeConfigurations(dynamic_configurations{j}, dynamic_configurations{j+1}, 0, "dynamic");
            %                 else
            %                     merged_configuration = obj.mergeConfigurations(merged_configuration, merged_configurations{j+1}, 0, "dynamic");
            %                     configuration_history = obj.mergeConfigurations(configuration_history, configuration_histories{j+1}, 0, "dynamic");
            %                     dynamic_configuration = obj.mergeConfigurations(dynamic_configuration, dynamic_configurations{j+1}, 0, "dynamic");
            %                 end
            %             end
            
            %             if fileExists(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times.mat")
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times",...
            %                     "-append");
            %             else
            %                 save(meta_data_folder_path + string(filesep)...
            %                     + obj.configuration.general.project_name...
            %                     + "_times", "processing_step_times");
            %             end
            
            %             dynamic_configuration_out_tmp = obj.mergeConfigurations(dynamic_configuration_out, configuration_history.(pipeline_definition), 0, "dynamic");
            %             dynamic_configuration_out = dynamic_configuration_out_tmp;
            
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
        
        % function parforSave(obj, path, variable)
        %     parforSave(obj.semaphore_key, path, variable)
        % end
        
        function saveJSON(obj, path, variable)
            saveJSON(path, variable);
        end
        
        function configuration = fillSetUpStructPipelineStep(obj, configuration, i)
            configuration = fillSetUpStructPipelineStep(configuration, i);
        end
        
        function configuration = fillSetUpStructIteration(obj, configuration, j, previous_tomogram_status)
            configuration = fillSetUpStructIteration(configuration, j, previous_tomogram_status);
        end
        %
        %         function combineConfigurationsAndSaveHistory(obj, pipeline_ending_step)
        %             disp("INFO: Executing pipeline...");
        %
        %             if ~isempty(obj.default_configuration)
        %                 configuration = obj.initializeDefaults();
        %             else
        %                 configuration = obj.configuration;
        %             end
        %
        %             if nargin < 2 && nargin > 2
        %                 error("ERROR: not enough or too many arguments!");
        %             end
        %
        %             %             if nargin == 1
        %             %                 pipeline_ending_step = -1;
        %             %             elseif nargin == 2
        %             %                 tomogram_end = -1;
        %             %                 pipeline_ending_step = -1;
        %             %             elseif nargin == 3
        %             %                 pipeline_ending_step = -1;
        %             %             end
        %
        %             %             configuration.general.tomogram_begin = tomogram_begin;
        %             %             configuration.general.tomogram_end = tomogram_end;
        %
        %             pipeline_definition = fieldnames(configuration);
        %
        %             if configuration.general.random_number_generator_seed > -1
        %                 if configuration.general.random_number_generator_seed == 0
        %                     rng("default")
        %                 else
        %                     rng(configuration.general.random_number_generator_seed);
        %                 end
        %             end
        %
        %             %             obj.semaphore_key = randi(999999);
        %
        %             %             try
        %             %                 semaphore('destroy', obj.semaphore_key, 1);
        %             %             catch
        %             %             end
        %             %
        %             %             semaphore('create', obj.semaphore_key, 1);
        %
        %
        %
        %             if configuration.general.cuda_forward_compatibility == true && ~verLessThan("matlab", "9.9")
        %                 parallel.gpu.enableCUDAForwardCompatibility(true)
        %             end
        %
        %             % NOTE: not really useful, because toolkit needs to be run from
        %             % project folder or needs to be added to path
        %             if configuration.general.data_path == ""
        %                 configuration.general.data_path = string(pwd);
        %                 configuration.general.processing_path = configuration.general.data_path;
        %             end
        %
        %             if configuration.general.processing_path ~= ""
        %                 processing_path = configuration.general.processing_path;
        %             else
        %                 configuration.general.processing_path = configuration.general.data_path;
        %                 processing_path = configuration.general.processing_path;
        %             end
        %
        %             disp("INFO:PROCESSING_PATH: " + configuration.general.processing_path);
        %             disp("INFO:DATA_PATH: " + configuration.general.data_path);
        %             %             dynamic_configuration = struct();
        %
        %             if configuration.general.debug == true
        %                 % TODO: check return value
        %                 if exist(processing_path + string(filesep) + configuration.general.output_folder, "dir")
        %                     rmdir(processing_path + string(filesep) + configuration.general.output_folder, "s");
        %                 end
        %
        %                 if exist(processing_path + string(filesep) + configuration.general.scratch_folder, "dir")
        %                     rmdir(processing_path + string(filesep) + configuration.general.scratch_folder, "s");
        %                 end
        %
        %             end
        %
        %             output_path = processing_path + string(filesep) + configuration.general.output_folder;
        %
        %             if ~exist(output_path, "dir")
        %                 [status_mkdir, message, message_id] = mkdir(output_path);
        %             end
        %
        %             pipeline_log_file_path = output_path + string(filesep) + "pipeline.log";
        %
        %             if fileExists(pipeline_log_file_path)
        %                 log_file_id = fopen(pipeline_log_file_path, "a");
        %             else
        %                 log_file_id = fopen(pipeline_log_file_path, "w");
        %             end
        %
        %             meta_data_folder_path = getMetaDataFolderPath(configuration.general);
        %
        %             if ~exist(meta_data_folder_path, "dir")
        %                 [status_mkdir, message, message_id] = mkdir(meta_data_folder_path);
        %             end
        %
        %             meta_data_file_path = getMetaDataFilePath(configuration.general);
        %             [folder, name, extension] = fileparts(meta_data_file_path);
        %
        %             if fileExists(folder + string(filesep) + name + ".json") %exist(meta_data_file_path, "file") == 2 ||
        %                 configuration_history = obj.loadJSON(folder + string(filesep) + name + ".json");
        %                 %                 try
        %                 %                     load(meta_data_file_path, "configuration_history");
        %                 %
        %                 %                 catch
        %                 %
        %                 %                     try
        %                 %                         load(folder + string(filesep) + name + "_backup" + extension, "configuration_history");
        %                 %                     catch
        %                 %                         load(folder + string(filesep) + name + "_backup_backup" + extension, "configuration_history");
        %                 %                     end
        %                 %
        %                 %                 end
        %
        %                 configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
        %             else
        %                 configuration_history = struct();
        %                 configuration_history.processing_step_times = struct;
        %             end
        %
        %             % TODO:NOTE: not needed
        %             % if configuration.general.wipe_cache == true
        %             % 	 if exist(meta_data_path, "file")
        %             %        % TODO: Check status and message and message_id
        %             %        [status, message, message_id] = rmdir(meta_data_path, "s");
        %             %    end
        %             % end
        %
        %
        %
        %             if obj.configuration_path ~= ""
        %                 [success, message, message_id] = copyfile(obj.configuration_path, folder + string(filesep) + "project.json");
        %             end
        %
        %             if obj.default_configuration_path ~= ""
        %                 [success, message, message_id] = copyfile(obj.default_configuration_path, folder + string(filesep) + "defaults.json");
        %             end
        %
        %             % TODO:NOTE: last processed tomogram number needs to be loaded
        %             % TODO: look if this is needed
        %
        %             file_count_changed = true;
        %
        %             while file_count_changed == true
        %
        %                 if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
        %                     dynamic_configuration = struct;
        %                     dynamic_configuration.file_count = configuration.general.file_count;
        %                     dynamic_configuration.starting_tomogram = configuration.general.starting_tomogram;
        %                     dynamic_configuration.tomograms_count = configuration.general.tomograms_count;
        %                     file_count_changed = false;
        %                 else
        %                     [dynamic_configuration, file_count_changed] = getUnprocessedTomograms(configuration.general, log_file_id);
        %                 end
        %
        %                 %                 obj.saveJSON(folder + string(filesep) + "tomogram_meta_data.json", dynamic_configuration);
        %                 sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
        %
        %                 if file_count_changed == true
        %                     sucess_files_to_be_deleted = dir(output_path + string(filesep) + "*" + string(filesep) + "SUCCESS");
        %
        %                     for i = 1:length(sucess_files_to_be_deleted)
        %                         delete(sucess_files_to_be_deleted(i).folder + string(filesep) + sucess_files_to_be_deleted(i).name);
        %                     end
        %
        %                 elseif file_count_changed == false && length(sucess_files_to_be_deleted) < length(pipeline_definition)
        %                 else
        %                     disp("INFO: File count has not changed therefor further execution of the pipeline is abandoned!")
        %                     break;
        %                 end
        %
        %                 if isfield(configuration_history, "general")
        %                     configuration_history.general = obj.mergeConfigurations(configuration_history.general, dynamic_configuration, 0, "dynamic");
        %                 else
        %                     configuration_history.general = dynamic_configuration;
        %                 end
        %
        %                 configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
        %
        %                 %                 tomogram_names = fieldnames(configuration.general.tomograms);
        %
        %                 % NOTE: possibly overwrites the currently loaded file
        %                 %save(meta_data_file_path, "configuration_history", "-v7.3");
        %                 %                 obj.parforSave(meta_data_file_path, configuration_history);
        %
        %                 % for j = 1:length(tomogram_names)
        %                 %     tomogram_number  = j;
        %                 %     % TODO:NOTE: what if new pipeline steps were added?
        %                 %     if ~isfield(configuration.general.tomograms.(tomogram_names{tomogram_number}), "processed_pipeline_steps")
        %                 %         configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps = zeros(length(pipeline_definition)-1, 1);
        %                 %     else
        %                 %         if length(pipeline_definition) > length(configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps)
        %                 %             % TODO: needs to be tested if count pipeline steps
        %                 %             % is changed and processed pipelinesteps are kept
        %                 %             processed_pipeline_steps_tmp = configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps;
        %                 %             configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps = zeros(length(pipeline_definition), 1);
        %                 %             configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps(1:length(processed_pipeline_steps_tmp)) = processed_pipeline_steps_tmp;
        %                 %         elseif length(pipeline_definition) < configuration.general.tomograms.(tomogram_names{tomogram_number}).processed_pipeline_steps
        %                 %             error("ERROR: reducing pipeline steps is not implemented!");
        %                 %         else
        %                 %             disp("NOTE: pipeline stayed unchanged, nothing to be done here!");
        %                 %         end
        %                 %     end
        %                 % end
        %                 tomogram_status = {};
        %
        %                 previous_tomogram_status = zeros([1 dynamic_configuration.tomograms_count]);
        %                 if isfield(configuration.general, "tomogram_indices") && ~isempty(configuration.general.tomogram_indices)
        %                     previous_tomogram_status(configuration.general.tomogram_indices) = 1;
        %                 elseif isfield(configuration.general, "tomogram_begin")...
        %                         && isfield(configuration.general, "tomogram_end")...
        %                         && 0 < configuration.general.tomogram_begin...
        %                         && 0 < configuration.general.tomogram_end...
        %                         && configuration.general.tomogram_end >= configuration.general.tomogram_begin...
        %                         && configuration.general.tomogram_step ~= 0
        %                     tomogram_indices = configuration.general.tomogram_begin:configuration.general.tomogram_step:configuration.general.tomogram_end;
        %                     previous_tomogram_status(tomogram_indices) = 1;
        %                 else
        %                     previous_tomogram_status = ones([1 dynamic_configuration.tomograms_count]);
        %                 end
        %
        %
        %                 %                 meta_data_file_path = getMetaDataFilePath(configuration.general);
        %
        %                 for i = 1:length(pipeline_definition)
        %                     % TODO: Make it independent of position, rather not,
        %                     % delete comment
        %                     if (i == 1 && obj.pipeline_definition{i} == "general")
        %                         continue;
        %                     elseif (i == 1 && obj.pipeline_definition{i} ~= "general")
        %                         error("ERROR: General section in configuration missing or" ...
        %                             + " it is not in the first position!");
        %                     end
        %
        %                     configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}) = struct;
        %
        %                     if ~isfield(configuration_history, pipeline_definition{i})
        %                         configuration_history.(pipeline_definition{i}) = struct;
        %                     end
        %
        %                     if ~isempty(fieldnames(dynamic_configuration))
        %                         configuration.(pipeline_definition{i}) = obj.mergeConfigurations(configuration.(pipeline_definition{i}), dynamic_configuration, 0, "dynamic");
        %                     end
        %
        %                     % NOTE: Everything is merged into general
        %                     % configuration, this means that fields defined in the
        %                     % pipeline processing step are overwriting fields from
        %                     % general configuration
        %                     merged_configuration = obj.mergeConfigurations(...
        %                         configuration.general, ...
        %                         configuration.(pipeline_definition{i}), i - 1, obj.pipeline_definition{i});
        %
        %                     merged_configuration = obj.fillSetUpStructPipelineStep(merged_configuration, i);
        %                     % TODO: perhaps should also look for corresponding
        %                     % scratch folder
        %
        %                     merged_configuration.output_path = processing_path + string(filesep) + merged_configuration.pipeline_step_output_folder;
        %                     merged_configuration.scratch_path = processing_path + string(filesep) + merged_configuration.pipeline_step_scratch_folder;
        %                     ignore_success_files = merged_configuration.ignore_success_files;
        %
        %                     time_file_path = merged_configuration.output_path + string(filesep) + "TIME";
        %                     success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
        %                     failure_file_path = merged_configuration.output_path + string(filesep) + "FAILURE";
        %
        %                     if fileExists(success_file_path)
        %                         success_file_id = fopen(success_file_path);
        %                         status_flags = textscan(success_file_id, "%s");
        %                         status_flags = status_flags{1};
        %                         status_flags = [str2double(status_flags)]';
        %                         if length(status_flags) < length(previous_tomogram_status)
        %                             status_flags_tmp = zeros([1 lenth(previous_tomogram_status)]);
        %                             status_flags_tmp(1:length(status_flags)) =  status_flags;
        %                             status_flags = status_flags_tmp;
        %                         end
        %                         if any(~status_flags & previous_tomogram_status)
        %                             status_flags = double(status_flags | previous_tomogram_status);
        %                             previous_tomogram_status = status_flags;
        %                             ignore_success_files = true;
        %                         end
        %                         tomogram_status{i - 1} = status_flags;
        %                     end
        %
        %
        %
        %                     if ignore_success_files == false && fileExists(success_file_path)
        %                         %                         success_file_id = fopen(success_file_path);
        %                         %                         status_flags = textscan(success_file_id, "%s");
        %                         %                         status_flags = status_flags{1};
        %                         %                         status_flags = [str2double(status_flags)]';
        %                         %                         tomogram_status{i - 1} = status_flags;
        %                         if obj.pipeline_definition{i} ~= "StopPipeline"
        %                             dynamic_configuration_in = dynamic_configuration;
        %                             dynamic_configuration_out = obj.finishPipelineStep(...
        %                                 dynamic_configuration, pipeline_definition{i}, ...
        %                                 configuration_history, i);
        %                             dynamic_configuration = dynamic_configuration_out;
        %                         end
        %                         disp("INFO: Skipping pipeline step (" + obj.pipeline_definition{i} + ") due to availability of a SUCCESS file!")
        %                         continue;
        %                     elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
        %                         disp("INFO: Aborting execution of the pipeline step (" + obj.pipeline_definition{i} + ") due to availability of a FAILURE file!");
        %                         return;
        %                     else
        %                         %configuration_history.(pipelineDefinition{i}) = struct;
        %                         %                         if i == 2
        %                         %                             previous_tomogram_status = {ones([1 dynamic_configuration.tomograms_count])};
        %                         %                         else
        %                         if i > 2
        %                             previous_tomogram_status = tomogram_status{i - 2};
        %                         end
        %
        %                         processing_step_start_time = tic;
        %
        %                         % TODO: pack module execution path description somewhere else
        %                         if isfield(merged_configuration, "execution_method")...
        %                                 && (merged_configuration.execution_method == "once"...
        %                                 || merged_configuration.execution_method == "in_order"...
        %                                 || merged_configuration.execution_method == "sequential"...
        %                                 || merged_configuration.execution_method == "parallel")
        %                             [dynamic_configuration_out, tomogram_status{i - 1}] = obj.("execution_" + merged_configuration.execution_method)(merged_configuration, obj.pipeline_definition{i}, previous_tomogram_status);
        %                         elseif isfield(merged_configuration, "execution_method") && merged_configuration.execution_method == "control"
        %                             if fileExists(success_file_path)
        %                                 continue;
        %                             else
        %                                 tomogram_status{i - 1} = tomogram_status{i - 2};
        %                                 obj.createOutputAndScratchFoldersForPipelineStep(merged_configuration);
        %                                 fid = fopen(success_file_path, 'wt');
        %                                 fprintf(fid, "%s", string(num2str(tomogram_status{i - 1})));
        %                                 fclose(fid);
        %                                 disp("INFO: reached control block (" + obj.pipeline_definition{i} + ") pipeline is stopping! ")
        %                                 return;
        %                             end
        %                         else
        %                             error("ERROR: no execution method defined for this module in json file.");
        %                         end
        %
        %                         processing_step_end_time = toc(processing_step_start_time);
        %
        %                         dynamic_configuration = obj.mergeConfigurations(dynamic_configuration, dynamic_configuration_out, 0, "dynamic");
        %
        %                         if ~isfield(configuration_history, pipeline_definition{i})
        %                             configuration_history.(pipeline_definition{i}) = struct;
        %                         end
        %
        %                         configuration_history.(pipeline_definition{i}) = obj.mergeConfigurations(configuration_history.(pipeline_definition{i}), dynamic_configuration_out, 0, "dynamic");
        %
        %
        %                         % TODO: does this condition make really sense
        %                         %if (~isfield(configuration_history.processing_step_times, "Step_" + (i - 1) + "_" + pipeline_definition{i}))...
        %                         %       ||...
        %                         %      (isfield(configuration_history.processing_step_times, pipeline_definition{i}) &&  ~fileExists(success_file_path))
        %                         if ~isfield(configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}), "overall_time")
        %                             configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}).overall_time = processing_step_end_time;
        %                         else
        %                             configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}).overall_time = ...
        %                                 configuration_history.processing_step_times.("Step_" + (i - 1) + "_" + pipeline_definition{i}) + processing_step_end_time;
        %                         end
        %
        %                         %end
        %
        %                         if fileExists(time_file_path) && merged_configuration.execution_method ~= "once"
        %                             fid = fopen(time_file_path, 'r');
        %                             previous_time = textscan(fid, "%s");
        %                             previous_time = previous_time{1};
        %                             previous_time = str2double(previous_time);
        %                             processing_step_end_time = processing_step_end_time + previous_time;
        %                         end
        %
        %                         fid = fopen(time_file_path, 'wt');
        %                         fprintf(fid, "%s", string(num2str(processing_step_end_time)));
        %                         fclose(fid);
        %
        %                         %                         TODO: needs revision if only one both variables is set
        %                         %                         if (isfield(merged_configuration, "tomogram_interval") && isempty(merged_configuration.tomogram_interval) ...
        %                         %                                 && (isfield(merged_configuration, "tomogram_begin") && isfield(merged_configuration, "tomogram_end") && merged_configuration.tomogram_begin == -1 && merged_configuration.tomogram_end == -1)) ...
        %                         %                                 || (isfield(merged_configuration, "tomogram_interval") && length(merged_configuration.tomogram_interval(1):merged_configuration.tomogram_interval(2):merged_configuration.tomogram_interval(3)) == length(tomogram_names) ...
        %                         %                                 || (isfield(merged_configuration, "tomogram_begin") && isfield(merged_configuration, "tomogram_end") && isfield(merged_configuration, "tomogram_step") && length(merged_configuration.tomogram_begin:merged_configuration.tomogram_step:merged_configuration.tomogram_end) == length(tomogram_names)))
        %                         %                             fid = fopen(success_file_path, 'wt');
        %                         %                             fprintf(fid, "%s", string(num2str(tomogram_status{i - 1})));
        %                         %                             fclose(fid);
        %                         %                         else
        %                         fid = fopen(success_file_path, 'wt');
        %                         fprintf(fid, "%s", string(num2str(tomogram_status{i - 1})));
        %                         fclose(fid);
        %                         %                         end
        %
        %                     end
        %
        %                     if nargin < 4 && pipeline_ending_step + 1 <= i
        %                         %                         obj.parforSave(meta_data_file_path, configuration_history);
        %                         combined_configuration = obj.readAndCombineConfigurationsFromFolder(merged_configuration.output_path);
        %                         obj.saveJSON(merged_configuration.output_path + string(filesep) + "partial_output.json", combined_configuration);
        %                         obj.saveJSON(merged_configuration.output_path + string(filesep) + "combined_output.json", dynamic_configuration);
        %                         obj.saveJSON(folder + string(filesep) + name + ".json", configuration_history);
        %                         % TODO: implement case for skipping whole pipeline steps,
        %                         % but what to do if new tomograms were added? add automatic an ignore
        %                         % flag?
        %                         if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
        %                             file_count_changed = false;
        %                         else
        %                             file_count_changed = getFileCountChanged(configuration.general);
        %                         end
        %
        %                         if file_count_changed == true
        %                             break;
        %                         end
        %
        %                         if pipeline_ending_step + 1 == i
        %                             disp("INFO: processing reached given pipeline step " + pipeline_ending_step);
        %                             %exit(0);
        %                             return;
        %                         end
        %                     end
        %                 end
        %             end
        %             disp("INFO: Execution finished!");
        %         end
        %
        
        %         function configuration = generateSetUpStruct(obj, configuration, previous_tomogram_status, i, j)
        %             configuration.set_up = struct;
        %             configuration.set_up.i = i;
        %             configuration.set_up.j = j;
        %             configuration.set_up.cumulative_tomogram_status = cumsum(previous_tomogram_status);
        %             if isScalar(obj.configuration.gpu) && obj.configuration.gpu == -1
        %                 configuration.set_up.gpu_sequence = mod(configuration.set_up.cumulative_tomogram_status - 1, configuration.environment_properties.gpu_count) + 1;
        %             elseif isScalar(obj.configuration.gpu) && obj.configuration.gpu >= 0
        %                 configuration.set_up.gpu_sequence = repmat(obj.configuration.gpu, [1 length(previous_tomogram_status)]);
        %             elseif ~isScalar(obj.configuration.gpu)
        %                 configuration.set_up.gpu_sequence = mod(configuration.set_up.cumulative_tomogram_status - 1, configuration.environment_properties.gpu_count) + 1;
        %                 configuration.set_up.gpu_sequence = obj.configuration.gpu(configuration.set_up.gpu_sequence);
        %             end
        %             configuration.set_up.gpu = configuration.set_up.gpu_sequence(j);
        %             configuration.set_up.adjusted_j = configuration.set_up.cumulative_tomogram_status(j);
        %         end
        
        function cleanIntermediates(obj)
            instantiated_class = function_handle(merged_configuration);
            %             instantiated_class = instantiated_class.setUp();
            %             instantiated_class = instantiated_class.process();
            %             instantiated_class = instantiated_class.cleanUp();
            instantiated_class.cleanUp();
        end
        %
        %         function delete(obj)
        %             semaphore('destroy', obj.semaphore_key, 1);
        %         end
    end
end
