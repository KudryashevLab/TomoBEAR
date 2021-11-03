classdef (Abstract) Module
    properties
        configuration struct;
        dynamic_configuration struct;
        input_path string;
        output_path string;
        log_file_id double;
        status double;
        start_time uint64;
        duration double;
        temporary_files string;
        original_field_names string;
        field_names string;
        name string;
        i string;
        j string;
        gpu string;
    end
    
    methods
        function obj = Module(configuration)
            if nargin == 0
                error("ERROR: no configuration passed to constructor!");
            end
            if configuration.random_number_generator_seed > -1
                if configuration.random_number_generator_seed == 0
                    rng("default")
                else
                    rng(configuration.random_number_generator_seed);
                end
            end
            obj.configuration = configuration;
            obj.temporary_files = string([]);
            obj = obj.setUpModule();
        end
        
        function obj = deleteFilesOrFolders(obj, files)
            for i = 1:length(files)
                if files(i).isdir == true
                    [~, ~, ~] = rmdir(files(i).folder + string(filesep) + files(i).name, "s");
                else
                    delete(files(i).folder + string(filesep) + files(i).name)
                end
            end
        end
        
        function obj = setUp(obj)
            obj.start_time = tic;
        end
        
        function obj = cleanUp(obj)
            if ~isempty(obj.temporary_files) && obj.configuration.keep_intermediates == false
                for i = 1:length(obj.temporary_files)
                    [success, message, message_id] = rmdir(obj.temporary_files{i},"s");
                    if success == 0
                        delete(obj.temporary_files{i});
                    end
                end
            end
            fclose(obj.log_file_id);
            obj.duration = toc(obj.start_time);
            fid = fopen(obj.output_path + string(filesep) + "TIME", "w");
            fprintf(fid, "%s", string(num2str(obj.duration)));
            fclose(fid);
        end
        
        function obj = setUpModule(obj)
            db_stack = dbstack();
            script_name = string(db_stack(3).file);
            script_name = strsplit(script_name, ".");
            script_name = script_name(1);
            
            % disp("INFO:PIPELINE...")
            %
            % disp("INFO:FUNCTION_NAME: " + script_name);
            
            % NOTE: Alternative, also showing file extension
            %call_stack = dbstack();
            %disp("Name: " + string(call_stack(1).file));
            
            % disp("INFO:FILE_NAME: " + string(db_stack(2).file));
            % disp("INFO:FILE_LOCATION: " + string(which(db_stack(2).file)));
            % disp("INFO:CONFIGURATION...");
            % disp(configuration);
            
            obj.dynamic_configuration = struct();
            
            field_names = fieldnames(obj.configuration);
            if any(contains(field_names, "previous_step_output_folder"))
                obj.input_path = obj.configuration.previous_step_output_folder;
            else
                obj.input_path = "";
            end
            % disp("INFO:INPUT_PATH " + input_path);
            % TODO: needs to be tested
            % TODO: use own function for that already available
            if obj.configuration.processing_path(end) == "/"
                obj.output_path = obj.configuration.processing_path + obj.configuration.pipeline_step_output_folder;
            else
                obj.output_path = obj.configuration.processing_path + string(filesep) + obj.configuration.pipeline_step_output_folder;
            end
            % disp("INFO:OUTPUT_PATH " + output_path);
            obj.dynamic_configuration.previous_step = string(script_name);
            obj.dynamic_configuration.previous_step_output_folder = obj.output_path;
            
            [obj.log_file_id, message] = fopen(obj.output_path + string(filesep) + script_name + ".log", "a");
            obj.status = 1;
            
            % TODO revise if module needs to know more tomogram names
            % TODO needs to handle more cases (begin, end, step) or remove
            obj.original_field_names = fieldnames(obj.configuration.tomograms);
            
            if isfield(obj.configuration, "tomogram_indices") && ~isempty(obj.configuration.tomogram_indices)
                obj.field_names = {obj.original_field_names{obj.configuration.tomogram_indices}};
            elseif isfield(obj.configuration, "tomogram_begin")...
                    && isfield(obj.configuration, "tomogram_end")...
                    && 0 < obj.configuration.tomogram_begin...
                    && 0 < obj.configuration.tomogram_end...
                    && obj.configuration.tomogram_end >= obj.configuration.tomogram_begin...
                    && obj.configuration.tomogram_step ~= 0
                tomogram_indices = obj.configuration.tomogram_begin:obj.configuration.tomogram_step:obj.configuration.tomogram_end;
                obj.field_names = {obj.original_field_names{tomogram_indices}};
            else
                obj.field_names = obj.original_field_names;
            end

            obj.i = obj.configuration.set_up.i;
            
            if obj.configuration.execution_method ~= "once"
                obj.gpu = obj.configuration.set_up.gpu;
                obj.j = obj.configuration.set_up.j;
                obj.name = obj.original_field_names{obj.configuration.set_up.j};
            elseif obj.configuration.execution_method == "once"
                if isfield(obj.configuration, "parallel_execution") && obj.configuration.parallel_execution == true
                     pool_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + "jobs" + string(filesep) + "pool_" + obj.configuration.tomogram_end;
                     if ~exist(pool_folder, "dir")
                     	[status_mkdir, message, message_id] = mkdir(pool_folder);
                     end
                    generatePool(obj.configuration.cpu_fraction, false, pool_folder);
                end
            end
        end
    end
    
    methods (Abstract)
        obj = process(obj);
    end
end