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
            if iscell(files)
                files_dir_struct = [];
                for idx = 1:length(files)
                    temp_struct = dir(files{idx});
                    if ~isempty(temp_struct)
                        files_dir_struct = [files_dir_struct, temp_struct];
                    end
                end
            else
                files_dir_struct = files;
            end
            
            if ~isempty(files_dir_struct)
                files_dir_struct_names = {files_dir_struct.name};
                files_dir_struct = files_dir_struct(~ismember(files_dir_struct_names,{'.','..'}));
            
                for idx = 1:length(files_dir_struct)
                    filename = files_dir_struct(idx).folder + string(filesep) + files_dir_struct(idx).name;
                    if files_dir_struct(idx).isdir == true && exist(filename, 'dir')
                        [~, ~, ~] = rmdir(filename, "s");
                    elseif isfile(filename)
                        delete(filename);
                    end
                end
            end
        end
        
        function obj = deleteFolderIfEmpty(obj, folder)
            contents = dir(folder);
            contentNames = {contents.name};
            contentNames = contentNames(~ismember(contentNames ,{'.','..'}));
            if isempty(contentNames)
                [success, message, message_id] = rmdir(folder, "s");
            end
        end
        
        function obj = setUp(obj)
            obj.start_time = tic;
        end
        
        function obj = cleanUp(obj)
            % NOTE: disabled the functionality below because decoupled
            % cleanup and execution modes. Temporary files to be deleted
            % during execution are currently deleted in the .cleanUp()
            % insances of the corresponding Module classes.            
%             if ~isempty(obj.temporary_files) && (obj.configuration.execute == false && obj.configuration.keep_intermediates == false)
%                 for i = 1:length(obj.temporary_files)
%                     [success, message, message_id] = rmdir(obj.temporary_files{i},"s");
%                     if success == 0 && isfile(obj.temporary_files{i})
%                         delete(obj.temporary_files{i});
%                     end
%                 end
%             end
            % TODO: review temporary files to be deleted per each module,
            % collect them in obj.temporary_files and use centralized
            % deletion implemented here
            
            % TODO: think what to do with log file if in cleanup mode
            fclose(obj.log_file_id);
            
            if obj.configuration.execute == true
                obj.duration = toc(obj.start_time);
                fid = fopen(obj.output_path + string(filesep) + "TIME", "w");
                fprintf(fid, "%s", string(num2str(obj.duration)));
                fclose(fid);
            end
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