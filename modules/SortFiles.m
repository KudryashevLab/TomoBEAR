classdef SortFiles < Module
    methods
        function obj = SortFiles(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = process(obj)
            obj = obj.populate_folder_tomo();
            disp("INFO: Done " + string(mfilename()));
        end
        
        function obj = populate_folder_tomo(obj)
            field_names = fieldnames(obj.configuration.tomograms);
            angles = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles;
            [angles_sorted, angles_old_indices] = sort(angles);
            % TODO: perhaps pack tomogram_output_prefix in dynamic configuration
            if isfield(obj.configuration, "tomogram_output_prefix") && obj.configuration.tomogram_output_prefix ~= "" % TODO: probably remove: && ~isempty(configuration.tomogram_output_prefix)
                tomogram_output_prefix = obj.configuration.tomogram_output_prefix;
            else
                tomogram_output_prefix = obj.configuration.tomogram_input_prefix;
            end
            obj.dynamic_configuration.tomogram_output_prefix = tomogram_output_prefix;
            if isfield(obj.configuration, "raw_files_folder")
                raw_files_folder = sprintf("%s" + string(filesep) + tomogram_output_prefix...
                    + "_%03d", obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.raw_files_folder,...
                    obj.configuration.set_up.j);
                if exist(raw_files_folder, "dir")
                    % TODO: add checks
                     [success, message, message_id] = rmdir(raw_files_folder, "s");
                end
                [status_mkdir, message] = mkdir(raw_files_folder);
            end
            % TODO: make varying amount of zeros based on tomograms
            output_path = obj.configuration.processing_path + string(filesep) + obj.configuration.pipeline_step_output_folder;
            [status_mkdir, message] = mkdir(output_path);
            if status_mkdir ~= 1
                error("ERROR: Can't create tomogram folder!");
            end
            % TODO: Decide if mrclist.txt is needed
            %fp = fopen(tomogram_obj.output_path + string(filesep) + "mrclist.txt", "w");
            configuration = obj.configuration;
            log_file_id = -1;
            %TODO: make it also sequential
            for i = 1:length(angles_sorted)%(,0) par
                % TODO: is configuration.tomogram_output_prefix or better use the configuration.tomogram_input_prefix
                file_name_out = sprintf(tomogram_output_prefix + "_%03d_%03d_%+05.1f", configuration.set_up.j,...
                    i, angles_sorted(i));
                source = configuration.tomograms.(field_names{configuration.set_up.j}).file_paths(angles_old_indices(i));
                [~, ~, extension] = fileparts(source);
                destination = output_path + string(filesep) + file_name_out + extension;
                
                
                if configuration.use_link == true
                    disp("INFO: Linking from " + source + newline + " to "...
                        + destination + "!");
                    % TODO: Check status and / or output
                    [~, ~] = createSymbolicLink(source, destination, log_file_id);
                else
                    disp("INFO: Copying from " + source + newline + " to "...
                        + destination + "!");
                    % TODO: Check status and/or message, message_id
                    [status_copyfile, message, message_id] = copyfile(source, destination);
                end
                % TODO: decide if statement is needed because it will be mandatory to
                % have standardized linked folders
                [output_symbolic_links_standard_folder, symbolic_links_standard_folder{i}] = createSymbolicLinkInStandardFolder(configuration, destination, "raw_files_folder", log_file_id);
                raw_files{i} = destination;
            end
            obj.dynamic_configuration.tomograms = struct;
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files = raw_files;
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files_symbolic_links = symbolic_links_standard_folder;
        end
    end
end

