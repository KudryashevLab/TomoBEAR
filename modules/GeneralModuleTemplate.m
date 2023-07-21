%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUT A LICENSE NOTE HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef GeneralModuleTemplate < Module
    methods
        %% Module instance constructor
        function obj = GeneralModuleTemplate(configuration)
            obj@Module(configuration);
        end
        
        %% Pre-execution module setup
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            
            % Create data_folder or metadata_folder in project folder
            createStandardFolder(obj.configuration, "data_folder", false);
            createStandardFolder(obj.configuration, "metadata_folder", false);
        end
        
        %% Module execution (main method)
        function obj = process(obj) 
            %% 1. Get input data 
            % > Get files/directories/parameters from global configuration
            % > Calculate and set necessary temporal configuration params
            
            % Get global configuration parameter PARAM (which must be present in configuration anyway)
            config_param = obj.configuration.PARAM;
            
            % Use global configuration parameter PARAM (which could not be present in configuration)
            if isfield(obj.configuration, "PARAM") && CHECK_IF_EMPTY
                % CHECK_IF_EMPTY depends on data type, alternatives are: 
                % if PARAM is a number: obj.configuration.PARAM ~= -1
                % if PARAM is a string: obj.configuration.PARAM ~= ""
                % if PARAM is a list: ~isempty(obj.configuration.PARAM)
                
                % put here code accessing obj.configuration.PARAM
            end
            
            % Set dynamic configuration parameter PARAM with VALUE
            obj.dynamic_configuration.PARAM = VALUE;
           
            % Get tomogram titles
            field_names = fieldnames(obj.configuration.tomograms);
            
             % Access tomogram parameter PARAM by its title index IDX
            data = obj.configuration.tomograms.(field_names{IDX}).PARAM;
            
            % Get files of the certain type from previous steps
            filepaths = getFilesFromLastModuleRun(obj.configuration, "GeneralModuleTemplate", "extension", "last");
            % or use other ways to get specific files, e.g. check folder
            % utilities/ for available functions or add necessary
            % functionality right as a new utilities/ function or
            % as an additional method of the current module (see below)
            
            %% 2. Execute target module code
            % > Use your original algorithm
            % by inserting it directly here or by using the custom method 
            % calling it with some INPUTS set and geting OUTPUTS set as
            [OUTPUTS] = obj.customMethod(INPUTS);
            
            % > Wrap external (CLI) software call
            
            % If you want to code module to be parallelized
            % on CPUs using "parallel" execution method, or
            % on GPUs using "in_order" execution method
            % the assigned index of a parallelized piece of data 
            % (currently only tilt serie/tomogram, but can be else)
            % to be processed on the assigned CPU or GPU worker is:
            % obj.configuration.set_up.adjusted_j
            % To access the PARAM parameter of the corresponding 
            % computing resource-assigned tomogram use
            data = obj.configuration.tomograms.(field_names{obj.configuration.set_up.adjusted_j}).PARAM;
            
            % Additionaly, for GPU-parallelized module execution
            % (execution_method == "in_order") to get assigned GPU use:
            if obj.configuration.set_up.gpu > 0
                gpu_number = obj.configuration.set_up.gpu - 1;
            else
                error("ERROR: Gpus are needed to run this module!");
            end
            
            % For a general external tool_command launch
            % for all the available (data processing) execution methods
            % (i.e. "once", "sequential", "parallel", "in_order")
            executeCommand(obj.configuration.tool_command...
                    + " -arg1 " + num2str(argument_value_number)...
                    + " -arg2 " + strjoin(num2str(argument_value_numbers_list), ",")...
                    ... % some other parameters
                    + " -argN " + argument_value_string, false, obj.log_file_id);
            % the last parameter is to write command output to the log file
            
            %% 3. Link output data and metadata to standard locations
            
            % Make symlink using source file and destination file paths
            createSymbolicLink(source_file_path, dest_file_path, obj.log_file_id);
            
            % Make symlink using source file and destination dir paths
            % where destination dir is a (meta)data_folder in project dir            
            createSymbolicLinkInStandardFolder(obj.configuration, source_file_path, "data_folder", obj.log_file_id);
            
            %% N.B. Inform user about execution status by INFO and ERROR
            
            % Display info-message for user during execution
            disp("INFO: Put some info message here...");
            
            % Display error message for user during execution
            error("ERROR: Put some error message here!");
            
        end
        
        %% Custom processing method
        function [outputs] = customMethod(obj, inputs)
            % Put your custom method code here 
        end
                
        %% Post-execution routines
        function obj = cleanUp(obj)
            % Automated data removal (execution modes except "cleanup")
            % > for files with folders
            obj.deleteFilesOrFolders(files);
            % > for folders only
            obj.deleteFolderIfEmpty(folder);
            
            % Automated data removal ("cleanup" execution mode only)
            if obj.configuration.execute == false && obj.configuration.keep_intermediates == false
                % put here your code for cleanup
            end
            
            % Post-execution routines (execution modes except "cleanup")
            % write TIME and step log files
            obj = cleanUp@Module(obj);
        end
    end
end