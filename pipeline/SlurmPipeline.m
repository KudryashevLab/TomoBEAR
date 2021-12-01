classdef SlurmPipeline < Pipeline
    methods
        function obj = SlurmPipeline(configuration_path, default_configuration_path)
            if nargin == 0
                configuration_path = "";
                default_configuration_path = "";
            elseif nargin == 1
                default_configuration_path = "";
            end
            obj@Pipeline(configuration_path, default_configuration_path);
            
            configuration_path_dir_ouptut = dir(obj.configuration_path);
            default_configuration_path_dir_ouptut = dir(obj.default_configuration_path);
            obj.configuration_path = string(configuration_path_dir_ouptut.folder) + filesep + configuration_path_dir_ouptut.name;
            obj.default_configuration_path = string(default_configuration_path_dir_ouptut.folder) + filesep + default_configuration_path_dir_ouptut.name;
        end
        
        function execute(obj, tomogram_begin, tomogram_end, pipeline_ending_step)
            disp("INFO: Executing pipeline on slurm...");
            
            if ~isempty(obj.default_configuration)
                configuration = obj.initializeDefaults();
            else
                configuration = obj.configuration;
            end
            
            if nargin == 1
                tomogram_begin = -1;
                tomogram_end = -1;
                pipeline_ending_step = -1;
            elseif nargin == 2
                tomogram_end = -1;
                pipeline_ending_step = -1;
            elseif nargin == 3
                pipeline_ending_step = -1;
            end
            
            configuration.general.tomogram_begin = tomogram_begin;
            configuration.general.tomogram_end = tomogram_end;
            
            pipeline_definition = fieldnames(configuration);
            
            if configuration.general.processing_path ~= ""
                processing_path = configuration.general.processing_path;
            else
                configuration.general.processing_path = configuration.general.data_path;
                processing_path = configuration.general.processing_path;
            end
            
            disp("INFO:PROCESSING_PATH: " + configuration.general.processing_path);
            disp("INFO:DATA_PATH: " + configuration.general.data_path);
            
            output_path = processing_path + string(filesep) + configuration.general.output_folder;
            
            pipeline_log_file_path = output_path + string(filesep) + "slurm_pipeline.log";
            
            if fileExists(pipeline_log_file_path)
                log_file_id = fopen(pipeline_log_file_path, "a");
            else
                log_file_id = fopen(pipeline_log_file_path, "w");
            end
            
            file_count_changed = true;
            configuration.general.starting_tomogram = 1;
            configuration_history.general = struct;
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
                
                if isfield(configuration_history, "general")
                    configuration_history.general = obj.mergeConfigurations(configuration_history.general, dynamic_configuration, 0, "dynamic");
                else
                    configuration_history.general = dynamic_configuration;
                end
                
                configuration.general = obj.mergeConfigurations(configuration.general, configuration_history.general, 0, "Pipeline");
                previous_job_ids = [];
                
                first_step_to_execute = true;
                nodes_length = length(configuration.general.nodes);
                current_node = 0;
                
                if (pipeline_ending_step ~= -1 && pipeline_ending_step < length(pipeline_definition))...
                        || (pipeline_ending_step ~= -1 && pipeline_ending_step == length(pipeline_definition))
                    pipeline_steps = pipeline_ending_step;
                elseif pipeline_ending_step > length(pipeline_definition) || pipeline_ending_step == -1
                    if pipeline_ending_step ~= -1 && pipeline_ending_step > length(pipeline_definition)
                        disp("WARNING: pipeline ending step is bigger then configured pipeline steps")
                    end
                    pipeline_steps = length(pipeline_definition);
                end
                    
                    
                for i = 1:pipeline_steps
                    if (i == 1 && obj.pipeline_definition{i} == "general")
                        continue;
                    elseif (i == 1 && obj.pipeline_definition{i} ~= "general")
                        error("ERROR: General section in configuration missing or" ...
                            + " it is not on the first position!");
                    end
                    
                    if ~isempty(configuration.general.nodes)
                        node = configuration.general.nodes(mod(current_node, nodes_length)+1);
                    else
                        node = "";
                    end

                    job_ids = [];
                    
                    gpu_counter = 0;
                    
                    merged_configuration = obj.mergeConfigurations(...
                        configuration.general, ...
                        configuration.(pipeline_definition{i}), i - 1, obj.pipeline_definition{i});
                    
                    merged_configuration.output_path = processing_path + string(filesep) + merged_configuration.pipeline_step_output_folder;
                    
                    success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
                    failure_file_path = merged_configuration.output_path + string(filesep) + "FAILURE";
                    
                    if fileExists(success_file_path) && merged_configuration.ignore_success_files == false
                        disp("INFO: Skipping queing the pipeline step (" + obj.pipeline_definition{i} + ") due to availability of a SUCCESS file!");
                        continue;
                    elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
                        disp("INFO: Aborting queing of the pipeline step (" + obj.pipeline_definition{i} + ") due to availability of a FAILURE file!");
                        return;
                    else
                        if isfield(merged_configuration, "execution_method")...
                                && merged_configuration.execution_method == "once"
                            if configuration.general.jobs_per_node == 1 && configuration.general.gpus_per_node > 1
                            	gpu = mod(gpu_counter, configuration.general.gpus_per_node) + 1;
                                gpu_counter = gpu_counter + 1;
                            else
                            	gpu = -1;
                            end
                            [job_ids, first_step_to_execute] = obj.queueJobs(configuration, previous_job_ids, first_step_to_execute, 1, dynamic_configuration.tomograms_count, i - 1, obj.pipeline_definition{i}, node, gpu);
                        elseif isfield(merged_configuration, "execution_method")...
                                && (merged_configuration.execution_method == "in_order"...
                                || merged_configuration.execution_method == "sequential"...
                                || merged_configuration.execution_method == "parallel")
                            for j = 0:ceil(dynamic_configuration.tomograms_count/configuration.general.jobs_per_node) - 1
                                if configuration.general.jobs_per_node == 1 && configuration.general.gpus_per_node > 1
                                    gpu = mod(gpu_counter, configuration.general.gpus_per_node) + 1;
                                    gpu_counter = gpu_counter + 1;
                                else
                                    gpu = -1;
                                end
                                [job_ids(end + 1: end + configuration.general.jobs_per_node), first_step_to_execute] = obj.queueJobs(configuration, previous_job_ids, first_step_to_execute, (j * configuration.general.jobs_per_node) + 1, min(dynamic_configuration.tomograms_count,(j * configuration.general.jobs_per_node) + configuration.general.jobs_per_node), i - 1, obj.pipeline_definition{i}, node, gpu);
                                current_node = current_node + 1;
                                if ~isempty(configuration.general.nodes)
                                    node = configuration.general.nodes(mod(current_node, nodes_length)+1);
                                else
                                    node = "";
                                end
                            end
                            if configuration.general.jobs_per_node == 1 && configuration.general.gpus_per_node > 1
                            	gpu = mod(gpu_counter, configuration.general.gpus_per_node) + 1;
                                gpu_counter = gpu_counter + 1;
                            else
                                gpu = -1;
                            end
                            [job_ids(end + 1), first_step_to_execute] = obj.queueJobs(configuration, job_ids, first_step_to_execute, 1, dynamic_configuration.tomograms_count, i - 1, obj.pipeline_definition{i}, node, gpu);
                        elseif isfield(merged_configuration, "execution_method") && merged_configuration.execution_method == "control"
                            if configuration.general.jobs_per_node == 1 && configuration.general.gpus_per_node > 1
                            	gpu = mod(gpu_counter, configuration.general.gpus_per_node) + 1;
                                gpu_counter = gpu_counter + 1;
                            else
                                gpu = -1;
                            end
                            
                            [job_ids, first_step_to_execute] = obj.queueJobs(configuration, previous_job_ids, first_step_to_execute, 1, dynamic_configuration.tomograms_count, i - 1, obj.pipeline_definition{i}, node, gpu);
                            disp("INFO: Stopping execution of further pipeline steps due to reaching control point.");
                            return;
                        else
                            error("ERROR: No execution method defined for this module in json file.");
                        end
                    end
                    
                    previous_job_ids = job_ids;
                    
                    if isfield(configuration.general, "skip_data_check") && configuration.general.skip_data_check == true
                        file_count_changed = false;
                    else
                        file_count_changed = getFileCountChanged(configuration.general);
                    end
                    
                    current_node = current_node + 1;
                    
                    if pipeline_ending_step + 1 == i
                        disp("INFO: processing reached given pipeline step " + pipeline_ending_step);
                        %exit(0);
                        return;
                    end
                end
            end
            disp("INFO: Queing finished!");
        end
        
        function [job_ids, first_step_to_execute] = queueJobs(obj, configuration, previous_job_ids, first_step_to_execute, starting_tomogram, ending_tomogram, ending_step, step_name, node, gpu)
            execute = configuration.general.slurm_execute;
            job_ids = [];
            if nargin == 2
                first_step_to_execute = true;
            end
            
            if configuration.general.pipeline_location ~= ""
                sbatch_wrapper = configuration.general.pipeline_location + string(filesep) + configuration.general.sbatch_wrapper;
                pipeline_executable = configuration.general.pipeline_location + string(filesep) + configuration.general.pipeline_executable;
            else
                current_dir = string(pwd) + string(filesep);
                sbatch_wrapper = current_dir + configuration.general.sbatch_wrapper;
                pipeline_executable = current_dir + configuration.general.pipeline_executable;
            end
            
            command = sbatch_wrapper;
            
            command = command + " --job-name=" + step_name + " ";
            
            if configuration.general.slurm_partition ~= ""
                command = command + " --partition=" + configuration.general.slurm_partition + " ";
            else
                command = command + " ";
            end
            
            if configuration.general.slurm_constraint ~= ""
                command = command + " --constraint=" + configuration.general.slurm_constraint + " ";
            else
                command = command + " ";
            end

            if configuration.general.slurm_qos ~= ""
                command = command + " --qos=" + configuration.general.slurm_qos + " ";
            else
                command = command + " ";
            end

            if configuration.general.slurm_gres ~= ""
                command = command + " --gres=" + configuration.general.slurm_gres + " ";
            else
                command = command + " ";
            end
            
            if configuration.general.slurm_gpus > 0
                command = command + " --gpus=" + configuration.general.slurm_gpus + " ";
            else
                command = command + " ";
            end
            
            % TODO: rename slurm_time
            if configuration.general.slurm_time ~= ""
                command = command + " --time=" + configuration.general.time + " ";
            else
                command = command + " ";
            end
            
            if configuration.general.slurm_nodes > 0
                command = command + " --nodes=" + configuration.general.slurm_nodes + " ";
            else
                command = command + " ";
            end
            
            if configuration.general.slurm_node_list ~= ""
                command = command + " --nodelist=" + configuration.general.slurm_node_list + " ";
            else
                command = command + " ";
            end
            
            if node ~= ""
                command = command + " --nodelist=" + node + " ";
            else
                command = command + " ";
            end
            
            if configuration.general.slurm_exclusive == true
            	command = command + " --exclusive ";
            else
            	command = command + " ";
            end
            
            if configuration.general.slurm_nice > 0
            	command = command + " --nice=" + configuration.general.slurm_nice + " ";
            else
            	command = command + " ";
            end
            
            if configuration.general.slurm_mem_per_gpu_in_gb > 0
            	command = command + " --mem-per-gpu=" + configuration.general.slurm_mem_per_gpu_in_gb + "GB ";
            else
            	command = command + " ";
            end
            if configuration.general.slurm_gpus_per_task > 0
            	command = command + " --gpus-per-task=" + configuration.general.slurm_gpus_per_task + " ";
            else
            	command = command + " ";
            end
            
            if configuration.general.slurm_flags ~= ""
            	command = command + " " + configuration.general.slurm_flags + " ";
            else
            	command = command + " ";
            end
            pipeline_executable_string = pipeline_executable + " local " + obj.configuration_path + " " + obj.default_configuration_path + " " + starting_tomogram + " " + ending_tomogram + " " + ending_step;
            
            pipeline_executable_string = pipeline_executable_string + " " + gpu + " " + configuration.general.pipeline_location + " " + configuration.general.mcr_location;
            
            if first_step_to_execute == true
                command = command + pipeline_executable_string;
                if execute == true
                    [status, output] = system(command);
                    %                     job_ids(end + 1) = str2num(strtrim(output));
                else
                    disp(command);
                    output = "-1";
                end
                first_step_to_execute = false;
            else
                if length(previous_job_ids) > 1
                    command = command + " --dependency=afterok:" + strjoin(strsplit(num2str(previous_job_ids)), ":") + " ";
                    command = command + pipeline_executable_string;
                    if execute == true
                        [status, output] = system(command);
                    else
                        disp(command);
                        output = "-1";
                    end
                elseif length(previous_job_ids) == 1
                    command = command + " --dependency=afterok:" + num2str(previous_job_ids) + " ";
                    command = command + pipeline_executable_string;
                    if execute == true
                        [status, output] = system(command);
                    else
                        disp(command);
                        output = "-1";
                    end
                elseif length(previous_job_ids) == 0
                    command = command + pipeline_executable_string;
                    if execute == true
                        [status, output] = system(command);
                    else
                        disp(command);
                        output = "-1";
                    end
                end 
            end
%             if execute == true
                try
                    job_ids(end + 1) = str2num(output);
                catch exception
                    disp(output);
                    error(exception.message);
                end
%             end
        end
        
        function configuration = loadJSON(obj, file_path)
            configuration = loadJSON(file_path);
        end
    end
end
