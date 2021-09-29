classdef Pipeline < handle
    
    properties
        pipeline_definition cell;
        configuration struct;
        configuration_path string;
        default_configuration struct;
        default_configuration_path string;
        environment_properties struct;
    end
    
    methods
        function obj = Pipeline(configuration_path, default_configuration_path)
            
            if gpuDeviceCount > 0
                gpuDevice([]);
            end
            
            poolobj = gcp('nocreate');
            
            if ~isempty(poolobj)
                delete(poolobj);
            end
            
            
            
            if isdeployed()
                obj.environment_properties = getEnvironmentProperties(default_configuration_path);
            else
                obj.environment_properties = getEnvironmentProperties();
            end
            
            %             meta_data_file_path = getMetaDataFilePath(configuration.general);
            %             [meta_data_folder, name, extension] = fileparts(meta_data_file_path);
            
            configuration_parser = ConfigurationParser();
            
            if configuration_path == "" && default_configuration_path == ""
                configuration_path = "meta_data" + string(filesep) + "project.json";
                default_configuration_path = "meta_data" + string(filesep) + "defaults.json";
            elseif default_configuration_path == ""
                default_configuration_path_tmp = "meta_data" + string(filesep) + "defaults.json";
                if ~fileExists(default_configuration_path_tmp)
                    default_configuration_path_tmp = obj.environment_properties.project_path + string(filesep) + "configurations/defaults.json";
                end
                default_configuration_path = default_configuration_path_tmp;
            end
            
            %             % TODO introduce checks for configurations
            %             if nargin == 0
            %                 disp("INFO: Created empty pipeline object!")
            %             end
            
            %             if nargin == 1 || nargin == 2
            [obj.configuration, obj.pipeline_definition] = configuration_parser.parse(configuration_path);
            
            
            if ~isfield(obj.configuration, "general")
                error("ERROR: No general section in configuration available!")
            end
            
            
            obj.configuration.general.environment_properties = obj.environment_properties;
            %             end
            
            %             if nargin >= 0 && nargin <= 2
            
            
            [obj.default_configuration, ~] = configuration_parser.parse(default_configuration_path);
            %             end
            obj.configuration_path = configuration_path;
            obj.default_configuration_path = default_configuration_path;
            
            %             % TODO: extract from default configuration only fields
            %             % available in configuration, so that configuration defines the
            %             % pipeline steps
            %             if nargin == 4
            %                 % TODO: should be wrong to use merge configurations
            %                 % function, please check
            %                 merged_configuration = obj.mergeConfigurations(default_configuration, configuration);
            %                 obj.executePipeline(pipelineDefinition, merged_configuration);
            %             elseif nargin == 3
            %                 obj.executePipeline(pipelineDefinition, configuration);
            %             elseif nargin == 2
            %                 error("ERROR: Only 1, 3 or 4 arguments are accepted!");
            %             elseif nargin == 1
            %                 if ~isempty(obj.default_configuration)
            %                     configuration = obj.initializeDefaults();
            %                 else
            %                     configuration = obj.configuration;
            %                 end
            %                 obj.executePipeline(obj.pipeline_definition, configuration);
            %             end
        end
        
        function print(obj)
            % TODO: move general to the first position if needed, better to let it the user do
            if ~isfield(obj.configuration, "general")
                error("ERROR: No general section in configuration available!")
            elseif isfield(obj.configuration, "general") && obj.pipeline_definition{1} ~= "general"
                error("ERROR: General section is not in the first position!")
            end
            
            for i = 1:length(obj.pipeline_definition)
                % TODO: make it independent of position
                if (i == 1 && obj.pipeline_definition{i} == "general")
                    continue;
                elseif (i == 1 && obj.pipeline_definition{i} ~= "general")
                    error("ERROR:General section in configuration missing or" ...
                        + " it is not on the first position!");
                end
                disp("INFO: PROCESSING STEP " + num2str(i - 1) + ":" ...
                    + obj.pipeline_definition{i});
            end
            
        end
        
        function initialized_configuration = initializeDefaults(obj)
            %             printVariable(obj.default_configuration);
            %             printVariable(obj.configuration);
            default_pipeline_names = fieldnames(obj.default_configuration);
            pipeline_names = fieldnames(obj.configuration);
            initialized_configuration = obj.configuration;
            
            for i = 1:length(default_pipeline_names)
                default_pipeline_name = default_pipeline_names(i);
                processing_steps = contains(pipeline_names, default_pipeline_name{1});
                pipeline_steps_to_initialize = pipeline_names(processing_steps);
                for j = 1:length(pipeline_steps_to_initialize)
                    pipeline_step_to_initialize = pipeline_steps_to_initialize(j);
                    default_field_names = fieldnames(obj.default_configuration.(default_pipeline_name{1}));
                    for k = 1:length(default_field_names)
                        if isfield(initialized_configuration.(pipeline_step_to_initialize{1}), default_field_names{k})
                            if isstruct(obj.default_configuration.(default_pipeline_name{1}).(default_field_names{k}))
                                %initialized_configuration.(pipeline_step_to_initialize{1}).(default_field_names{k}) = struct;
                                initialized_configuration.(pipeline_step_to_initialize{1}).(default_field_names{k}) =...
                                    obj.mergeConfigurations(...
                                    ...
                                    obj.default_configuration.(default_pipeline_name{1}).(default_field_names{k}),...
                                    initialized_configuration.(pipeline_step_to_initialize{1}).(default_field_names{k}),0, "dynamic");
                            end
                            continue;
                        else
                            initialized_configuration.(pipeline_step_to_initialize{1}).(default_field_names{k}) = obj.default_configuration.(default_pipeline_name{1}).(default_field_names{k});
                        end
                    end
                end
            end
            %             printVariable(initialized_configuration);
        end
        
        function merged_configurations = mergeConfigurations(obj, ...
                first_configuration, second_configuration, pipeline_step, script_name)
            %printVariable(first_configuration);
            %printVariable(second_configuration);
            field_names = fieldnames(second_configuration);
            merged_configurations = first_configuration;
            
            for i = 1:length(field_names)
                
                if field_names{i} ~= "output_folder" && field_names{i} ~= "scratch_folder"
                    
                    if isstruct(second_configuration.(field_names{i})) && (field_names{i}) ~= "environmentProperties"
                        
                        if isscalar(second_configuration.(field_names{i}))
                            
                            if ~isfield(first_configuration, (field_names{i}))
                                first_configuration.(field_names{i}) = struct;
                            end
                            
                            merged_configurations.(field_names{i}) = ...
                                obj.mergeConfigurations(first_configuration.(field_names{i}), ...
                                second_configuration.(field_names{i}), pipeline_step, "dynamic");
                        else
                            
                            for j = 1:length(second_configuration.(field_names{i}))
                                first_configuration.(field_names{i})(j) = struct(second_configuration.(field_names{i})(j));
                            end
                            
                            for j = 1:length(second_configuration.(field_names{i}))
                                merged_configurations.(field_names{i})(j) = ...
                                    obj.mergeConfigurations(first_configuration.(field_names{i})(j), ...
                                    second_configuration.(field_names{i})(j), pipeline_step, "dynamic");
                            end
                            
                        end
                        %                     elseif field_names{i} == "duration"
                        %                         if ~isfield(first_configuration, (field_names{i}))
                        %                             first_configuration.(field_names{i})(1:length(second_configuration.(field_names{i}))) = 0;
                        %                         elseif isfield(first_configuration, (field_names{i})) && length(first_configuration.(field_names{i})) < length(second_configuration.(field_names{i}))
                        %                             tmp = first_configuration.(field_names{i});
                        %                             first_configuration.(field_names{i})(1:length(second_configuration.(field_names{i}))) = 0;
                        %                             first_configuration.(field_names{i})(1:length(tmp)) = tmp;
                        %                         end
                        %                         merged_configurations.(field_names{i}) = first_configuration.(field_names{i})(1:length(second_configuration.(field_names{i}))) + second_configuration.(field_names{i});
                    else
                        merged_configurations.(field_names{i}) = ...
                            second_configuration.(field_names{i});
                    end
                elseif (field_names{i} == "output_folder" || field_names{i} == "scratch_folder")
                    merged_configurations.(field_names{i}) = ...
                        merged_configurations.(field_names{i}) ...
                        + string(filesep) ...
                        + pipeline_step + "_" + second_configuration.(field_names{i});
                end
            end
            
            % NOTE: be careful if a script outputs output_folder field as
            % dynamic variable
            if ~any(ismember(field_names, "output_folder")) && script_name ~= "dynamic"
                merged_configurations.pipeline_step_output_folder = first_configuration.output_folder + string(filesep) + pipeline_step + "_" + script_name;
                merged_configurations.pipeline_step_output_folder = increaseFolderNumber(merged_configurations, merged_configurations.pipeline_step_output_folder);
            end
            
            if ~any(ismember(field_names, "scratch_folder")) && script_name ~= "dynamic"
                merged_configurations.pipeline_step_scratch_folder = first_configuration.scratch_folder + string(filesep) + pipeline_step + "_" + script_name;
                merged_configurations.pipeline_step_scratch_folder = increaseFolderNumber(merged_configurations, merged_configurations.pipeline_step_scratch_folder);
            end
            
            %printVariable(merged_configurations);
        end
    end
    
    methods(Abstract)
        execute(obj, tomogram_begin, tomogram_end, pipeline_ending_step);
    end
end
