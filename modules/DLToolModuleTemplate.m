%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUT A LICENSE NOTE HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef DLToolModuleTemplate < Module
    methods
         %% Module instance constructor
        function obj = DLToolModuleTemplate(configuration)
            obj@Module(configuration);
        end
        
         %% Pre-execution module setup
        function obj = setUp(obj)
            obj = setUp@Module(obj);
        end
        
        %% Module execution (main method)
        function obj = process(obj)
            
            return_path = cd(obj.output_path);
            
            % Get sub-steps of the module to execute
            % (e.g. preproc, train, predict, postproc)
            steps_to_execute_fields = fieldnames(obj.configuration.steps_to_execute);
            
            if isempty(steps_to_execute_fields)
                error("ERROR: No steps_to_execute were found in the JSON file!");
            end
            
            % Execute substeps using the corresponding methods
            % (methods should be named the same way, as the corresponding
            % subsections of the module in config file)
            for subjob_idx=1:length(steps_to_execute_fields)
                disp("INFO: substep " + string(subjob_idx) + ":" + string(steps_to_execute_fields{subjob_idx}));
                step_params = mergeConfigurations(obj.configuration.steps_to_execute_defaults.(steps_to_execute_fields{subjob_idx}),...
                    obj.configuration.steps_to_execute.(steps_to_execute_fields{subjob_idx}), ...
                    "DLToolModuleTemplate", "dynamic");
                obj.(steps_to_execute_fields{subjob_idx})(steps_to_execute_fields{subjob_idx}, step_params);
                disp("INFO: Execution for substep " + string(subjob_idx) +" (" + string(steps_to_execute_fields{subjob_idx}) + ") has finished!");
            end
            
            cd(return_path);
        end
        
        %% Method for substeps functionality
        
        % Method for step_name1 
        function obj = step_name1(obj, step_name, step_params)
            
            % Example of retrieving data: get ctf-corrected tomograms
            tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true);
            if isempty(tomograms)
                error("ERROR: no ctf corrected tomograms were found!");
            end
            
            % Example of tomograms filtering by binning level
            % take into account binnings parameter from "general" section
            % or use specified in config tomograms_binning if requested
            if step_params.tomograms_binning == -1
                binnings = sort(obj.configuration.binnings, "descend");
                tomograms_all = tomograms;
                for bin_idx=1:length(binnings)
                    tomograms = tomograms_all(contains({tomograms_all.name}, "bin_" + num2str(binnings(bin_idx))));
                    if ~isempty(tomograms)
                        binning = binnings(bin_idx);
                        break
                    end
                end
                tomograms = tomograms_all(contains({tomograms.name}, "bin_" + binning));
            elseif step_params.tomograms_binning > 1
                binning = step_params.tomograms_binning;
                tomograms = tomograms(contains({tomograms.name}, "bin_" + binning));
            end
            
            if isempty(tomograms)
                error("ERROR: no tomograms with the specified binning of were found!");
            end
            
            % Example of tomograms filtering by selected indeces
            % use all tomograms if tomograms_to_use list is empty
            % otherwise use only the specified tomograms
            if ~isempty(obj.configuration.tomograms_to_use)
                tomograms_to_star_str = string(arrayfun(@(a)num2str(a, '%03.f'),obj.configuration.tomograms_to_use,'uni',0));
                tomograms = tomograms(contains(string({tomograms(:).name}), "tomogram_"+tomograms_to_star_str));
                
                if isempty(tomograms)
                    error("ERROR: no tomograms with the specified indices were found!");
                end
            end
            
            % Example of parameters extraction from step_params structure
            use_params_cell = {'param1','param2', 'param3'};
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            
            % Example of retrieving a list 
            % of the requested CPUs number among available ones
            if step_params.ncpu == -1
                use_params.ncpu = getCpuPoolSize(1);
            else
                use_params.ncpu = getCpuPoolSize(1, step_params.ncpu);
            end
            
            % Example of retrieving a list 
            % of the requested GPUs indeces among available ones
            if obj.configuration.gpu > 0
                step_params.gpuID = obj.configuration.gpu - 1;
            else
                error("ERROR: Gpus are needed for step_name1 step!");
            end
            
            % Example of initializing absolute path to the requested
            % directory to be created in the module/step folder
            use_params.output_dir = obj.output_path + string(filesep) + use_params.output_dir;
            
            % Example of preparing requested parameters string
            % and passing it to the DL tool-executing method
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + step_params.star_file + params_string;
            % for the case #1 (below) of executeDLToolCommand():
            command_output = obj.executeDLToolCommand(params_string);
            % or, if you need to run specific script from the DL tool
            % to perform functionality of this particular substep,
            % i.e. for the case #2 (below) of executeDLToolCommand():
            command_output = obj.executeDLToolCommand(params_string, tool_script);
        end
        
        %% Auxilary methods to prepare and run external Python DL tool
        
        % Method to extract initialized parameters of the substep
        function parameters_req = getRequestedOnlyParametersStructure(obj, parameters_all, parameters_req_names)
            parameters_req = struct();
            for idx=1:length(parameters_req_names)
                param_value = parameters_all.(parameters_req_names{idx});
                if (isstring(param_value) && param_value ~= "")...
                        || (isnumeric(param_value) && isscalar(param_value) && param_value ~= -1)
                    parameters_req.(parameters_req_names{idx}) = param_value;
                elseif isnumeric(param_value) && ~isscalar(param_value) && ~isempty(param_value)
                    parameters_req.(parameters_req_names{idx}) = strjoin(string(param_value), ",");
                end
            end
        end
        
        % Method to convert parameters values to the parameters string
        function params_string = getParamsString(obj, params, param_prefix)
            if nargin < 3
                param_prefix="--";
            end
            params_fields = fieldnames(params);
            params_string = "";
            for idx=1:length(params_fields)
                params_string = params_string + " " + param_prefix + params_fields{idx} + " " + params.(params_fields{idx});
            end
        end
        
        % Methods to execute external Python DL tool
        
        % Case #1: DL tool is cloned from GitHub repository
        % (with dependencies being installed by user in the separate conda env)
        % Example tool: IsoNet
         function command_output = executeDLToolCommand(obj, params_string)
            python_run_script_snippet = "PYTHONPATH=" + fullfile(obj.configuration.repository_path, '..');

            % Add to command string non-interactive conda environment call
            if obj.configuration.use_conda == true
                python_run_script_snippet = python_run_script_snippet + " LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.dltool_env; 
            end
            
            python_run_script_snippet = python_run_script_snippet + " python " + obj.configuration.repository_path + filesep + "/path/to/main_file.py";
            
            % Merge params string with command string and execute target
            command_output = executeCommand(python_run_script_snippet + " " + params_string, false, obj.log_file_id);
        end
        
        % Case #2: DL tool is installed via conda as a package
        % (with dependencies coming along with the tool in the same conda env)
        % Example tool: crYOLO
        function command_output = executeDLToolCommand(obj, params_string, tool_script)
            
            % Add to command string non-interactive conda environment call
            if obj.configuration.use_conda == true
                python_run_script_snippet = python_run_script_snippet + " LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.dltool_env; 
            end
            command_snippet = obj.configuration.conda_path + string(filesep) + "envs"...
                + string(filesep) + obj.configuration.dltool_env + string(filesep) + "bin"...
                + string(filesep) + tool_script; 
            python_run_script_snippet = python_run_script_snippet + " python " + command_snippet;
            
            % Merge params string with command string and execute target
            command_output = executeCommand(python_run_script_snippet + " " + params_string, false, obj.log_file_id);
        end
    end
end

