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

classdef CreateStacks < Module
    methods
        function obj = CreateStacks(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "tilt_stacks_folder", false);
            createStandardFolder(obj.configuration, "even_tilt_stacks_folder", false);
            createStandardFolder(obj.configuration, "odd_tilt_stacks_folder", false);
            createStandardFolder(obj.configuration, "dose_weighted_tilt_stacks_folder", false);
            createStandardFolder(obj.configuration, "dose_weighted_sum_tilt_stacks_folder", false);
        end
        
        function obj = process(obj)
            if obj.configuration.set_up.gpu >  0
                gpuDevice(obj.configuration.set_up.gpu);
                %             else
                %                 gpu_number = obj.configuration.gpu;
                %                 gpuDevice(gpu_number);
            end
            field_names = fieldnames(obj.configuration.tomograms);
            
            % NOTE: raw data is needed to be able to determine the frame number for
            % high dose and low dose movies
            if ~isfield(obj.configuration, "tilt_stacks") || obj.configuration.tilt_stacks ~= true
                motion_corrected_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files;
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                    motion_corrected_dose_weighted_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_dose_weighted_files;
                end
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                    motion_corrected_dose_weighted_sum_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_dose_weighted_sum_files;
                end
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                    motion_corrected_even_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_even_files;
                end
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                    motion_corrected_odd_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_odd_files;
                end
            else
                source = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).file_paths;
                tilt_stack_name = field_names{obj.configuration.set_up.j};
                slice_folder = "slices";
                destination_folder = obj.output_path;
                destination = destination_folder + string(filesep) + tilt_stack_name + "_link.st";
                
                output = createSymbolicLink(source, destination, obj.log_file_id);
                slice_destination_folder = obj.output_path + string(filesep) + slice_folder;
                [success, message, message_id] = mkdir(slice_destination_folder);
                output = executeCommand("newstack -split 1 -append mrc "...
                    + destination + " "...
                    + slice_destination_folder + string(filesep) + field_names{obj.configuration.set_up.j}...
                    + "_" + obj.configuration.slice_suffix + "_", false, obj.log_file_id);
                motion_corrected_files = dir(slice_destination_folder + string(filesep) + field_names{obj.configuration.set_up.j}...
                    + "_" + obj.configuration.slice_suffix + "_*");
                for i = 1:length(motion_corrected_files)
                    motion_corrected_files_tmp{i} = string(motion_corrected_files(1).folder) + string(filesep) + motion_corrected_files(i).name;
                end
                motion_corrected_files = motion_corrected_files_tmp;
            end
            %             raw_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files;
            %             tilt_minus_3 = [];
            %             for i = 1:length(raw_files)
            %                 if ~isempty(regexp(raw_files{i}, "_-[0]*3\.0", "match"))
            %                     tilt_minus_3 = raw_files{i};
            %                     break;
            %                 end
            %             end
            %
            %             tilt_zero = [];
            %             for i = 1:length(raw_files)
            %                 if ~isempty(regexp(raw_files{i},"_[+-]*0{2}\.0", "match"))
            %                     tilt_zero = raw_files{i};
            %                     break;
            %                 end
            %             end
            %
            %             tilt_plus_3 = [];
            %             for i = 1:length(raw_files)
            %                 if ~isempty(regexp(raw_files{i},"_[+]*[0]*3\.0", "match"))
            %                     tilt_plus_3 = raw_files{i};
            %                     break;
            %                 end
            %             end
            %
            %             % NOTE: n is the column where the frame count resides
            %             n = 3;
            %             tilt_m3_frames = executeCommand("header"...
            %                 + " -s " + tilt_minus_3...% NOTE: already appended: + ".mrc"...
            %                 + " | awk -v N=" + n + " '{print $N}'", false, obj.log_file_id);
            %
            %             tilt_z0_frames = executeCommand("header"...
            %                 + " -s " + tilt_zero...% NOTE: already appended: + ".mrc"...
            %                 + " | awk -v N=" + n + " '{print $N}'", false, obj.log_file_id);
            %
            %             tilt_p3_frames = executeCommand("header"...
            %                 + " -s " + tilt_plus_3...% NOTE: already appended: + ".mrc"...
            %                 + " | awk -v N=" + n + " '{print $N}'", false, obj.log_file_id);
            %
            
            %             [~, tok_tilt_z0_frames, ~] = regexp(tilt_z0_frames, "INFO:VARIABLE:command_output:\s*(\d*)", 'match', ...
            %                 'tokens', 'tokenExtents');
            %             tok_tilt_z0_frames = str2num(tok_tilt_z0_frames{1});
            %             [~, tok_tilt_m3_frames, ~] = regexp(tilt_m3_frames, "INFO:VARIABLE:command_output:\s*(\d*)", 'match', ...
            %                 'tokens', 'tokenExtents');
            %             tok_tilt_m3_frames = str2num(tok_tilt_m3_frames{1});
            %             [~, tok_tilt_p3_frames, ~] = regexp(tilt_p3_frames, "INFO:VARIABLE:command_output:\s*(\d*)", 'match', ...
            %                 'tokens', 'tokenExtents');
            %             tok_tilt_p3_frames = str2num(tok_tilt_p3_frames{1});
            
            
            if obj.configuration.normalization_method == "mean_std"
                
                % TODO: rephrase in matlab style also for windows support else rely on
                % cygwin, but this is worst case
                
                
                % TODO: remove because it should be output now in executeCommand
                %printVariable(tilt_m3_frames);
                %printVariable(tilt_z0_frames);
                %printVariable(tilt_p3_frames);
                
                
                
                % NOTE: seem to be equal
                % TODO: check if next two statements are equal
                % lowdose_std = executeCommand("awk"...
                %     + " -v num0=" + tilt_m3_frames(1)...
                %     + " -v num1=" + tilt_p3_frames(1)...
                %     + " -v den=" + tilt_z0_frames(1)...
                %     + " -v std=" + configuration.pixel_intensity_standard_deviation...
                %     + " 'BEGIN {printf ""%.4f"", std*sqrt((2*den)/(num0+num1)); exit(0)}'");
                
                
                
                lowdose_std = obj.configuration.pixel_intensity_standard_deviation...
                    * sqrt((2 * obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).high_dose_frames)...
                    /(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).low_dose_frames...
                    + obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).low_dose_frames));
                
                obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).lowdose_std = lowdose_std;
                
                % TODO: test for function inputVariable
                pixel_intensity_standard_deviation = obj.configuration.pixel_intensity_standard_deviation;
                printVariable(pixel_intensity_standard_deviation);
                printVariable(lowdose_std);
                %
                %             input_mrc_list = getMRCs(obj.configuration, true);
                %
                %             unique_input_tomogram_folders = unique({input_mrc_list.folder});
                %unique_input_tomogram_folders = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_mrcs;
                
                
                
                %tilt_index_angle_mapping = struct();
                %for i = 1:length(unique_input_tomogram_folders)
                %                 partial_input_mrc_list = struct([]);
                %                 partial_input_mrc_counter = 1;
                %                 for j = 1:length(input_mrc_list)
                %                     if input_mrc_list(j).folder == unique_input_tomogram_folders{i}
                %                         partial_input_mrc_list(partial_input_mrc_counter).name = input_mrc_list(j).name;
                %                         partial_input_mrc_list(partial_input_mrc_counter).folder = input_mrc_list(j).folder;
                %                         partial_input_mrc_counter = partial_input_mrc_counter + 1;
                %                     end
                %                 end
                %splitted_name = strsplit(partial_input_mrc_list(1).name, "_");
                output_stack_list = string([]);
                %tilt_index_angle_mapping.(strjoin(splitted_name(1:configuration.angle_position-2), "_")) = zeros(4,length(partial_input_mrc_list));
                for i = 1:length(motion_corrected_files)
                    [path, name, extension] = fileparts(motion_corrected_files{i});
                    
                    path_parts = strsplit(path, string(filesep));
                    
                    % TODO: delete if unneeded
                    %previous_step_output_folder_parts = strsplit(configuration.previous_step_output_folder, string(filesep));
                    
                    % TODO: if convention is to keep everything in folders, then the
                    % next statement can be simplified to only the first condition
                    % TODO: extract in function since needed twice
                    %         if path_parts(end) ~= previous_step_output_folder_parts(end)
                    [status_mkdir, message] = mkdir(obj.output_path);
                    if status_mkdir ~= 1
                        error("ERROR: Can't create stack folder for script output!");
                    end
                    projection_output_path = obj.output_path + string(filesep) + name + "_" + obj.configuration.normalized_postfix + ".mrc";
                    projection_input_path = motion_corrected_files{i};
                    stack_output_path = obj.output_path + string(filesep) + path_parts(end) + ".st";
                    %         else
                    %             projection_output_path = obj.input_path + string(filesep) + name + "_" + configuration.normalized_postfix + ".mrc";
                    %             projection_input_path = obj.input_path + string(filesep) + name + extension;
                    %             % TODO: is configuration.stack_name or better use the configuration.tomogram_input_prefix
                    %             stack_output_path = obj.output_path + string(filesep) + configuration.stack_name;
                    %         end
                    
                    splitted_name = strsplit(name, "_");
                    
                    % TODO: check if it is ok to add everywhere + 1 after the script
                    % sort mrcs ran, else you need to remove this extra underscore
                    % between name and tomogram number
                    %angle = str2double(splitted_name(obj.configuration.angle_position));
                    %angle = str2double(splitted_name(obj.configuration.angle_position + 1));
                    % TODO: fix angles
                    angle = str2double(splitted_name(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).adjusted_angle_position));
                    
                    
                    tilt_index_angle_mapping(1,i) = i;
                    tilt_index_angle_mapping(2,i) = angle;
                    tilt_index_angle_mapping(3,i) = true;
                    
                    if i == length(motion_corrected_files)
                        tilt_index_angle_mapping(4,:) = cumsum(tilt_index_angle_mapping(3,:));
                    end
                    
                    % TODO: determine if stack has high dose image automatically, then
                    % flag can be ommited
                    if ~isempty(regexp(motion_corrected_files{i}, "_[+-]*0{2}\.0", "match")) && obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).high_dose == true
                        tilt_index_angle_mapping(5,i) = 1;
                        executeCommand("newstack"...
                            + " -in " + projection_input_path...
                            + " -ou " + projection_output_path...
                            + " -mea " + obj.configuration.pixel_intensity_average + "," + obj.configuration.pixel_intensity_standard_deviation, false, obj.log_file_id);
                    else
                        tilt_index_angle_mapping(5,i) = 0;
                        executeCommand("newstack"...
                            + " -in " + projection_input_path...
                            + " -ou " + projection_output_path...
                            + " -mea " + obj.configuration.pixel_intensity_average + "," + lowdose_std, false, obj.log_file_id)
                    end
                    output_stack_list(i) = projection_output_path;
                end
            elseif obj.configuration.normalization_method == "frames"
                [width, height, ~] = getHeightAndWidthFromHeader(motion_corrected_files{1});
                if obj.configuration.border_pixels > 0
                    if obj.configuration.set_up.gpu >  0
                        border_image = zeros([width, height], "single", "gpuArray");
                        mean_image = zeros([width, height], "single", "gpuArray");
                    else
                        mean_image = zeros([width, height], "single");
                        border_image = zeros([width, height], "single");
                    end
                    %                     mean_value = mean(normalized_micrograph(:));
                    %                     for j = 1:obj.configuration.border_pixels
                    %                         percentage = ((obj.configuration.border_pixels-(j-1))/obj.configuration.border_pixels);
                    %                         border_image([j end-j+1],:) = (percentage * mean_value) + ((1-percentage) * normalized_micrograph([j end-j+1],:));
                    %                         border_image(:,[j end-j+1]) = (percentage * mean_value) + ((1-percentage) * normalized_micrograph(:,[j end-j+1]));
                    %                     end
                    %                     border_image([obj.configuration.border_pixels+1:end-obj.configuration.border_pixels-1],[obj.configuration.border_pixels+1:end-obj.configuration.border_pixels-1]) =...
                    %                         normalized_micrograph([obj.configuration.border_pixels+1:end-obj.configuration.border_pixels-1],[obj.configuration.border_pixels+1:end-obj.configuration.border_pixels-1]);
                    %                     normalized_micrograph = border_image;
                                        
                    border_image([1:obj.configuration.border_pixels end-obj.configuration.border_pixels:end],:) = 1.0;
                    border_image(:,[1:obj.configuration.border_pixels end-obj.configuration.border_pixels:end]) = 1.0;
                    medfilt_border_image = imgaussfilt(border_image, 50);
                    %                         windowSize = 51;
                    %                         kernel = ones(windowSize) / windowSize ^ 2;
                    %                         medfilt_border_image = conv2(double(border_image), kernel, 'same');
                    %                         medfilt_border_image(medfilt_border_image < 0.0000000001) = 0;
                end
                path_parts = strsplit(obj.output_path, string(filesep));
                % TODO: refactor to outside of loop
                stack_output_path = obj.output_path + string(filesep) + path_parts(end) + ".st";
                
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                    stack_output_path_even = obj.output_path + string(filesep) + path_parts(end) + "_even.st";
                end
                
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                    stack_output_path_odd = obj.output_path + string(filesep) + path_parts(end) + "_odd.st";
                end
                
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                    stack_output_path_dose_weighted = obj.output_path + string(filesep) + path_parts(end) + "_dw.st";
                end
                
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                    stack_output_path_dose_weighted_sum = obj.output_path + string(filesep) + path_parts(end) + "_dws.st";
                end
                
                for i = 1:length(motion_corrected_files)
                    [path, name, extension] = fileparts(motion_corrected_files{i});
                    
                    
                    % TODO: check if needed here
                    [status_mkdir, message] = mkdir(obj.output_path);
                    if status_mkdir ~= 1
                        error("ERROR: Can't create stack folder for script output!");
                    end
                    %                     projection_output_path = obj.output_path + string(filesep) + name + "_" + obj.configuration.normalized_postfix + ".mrc";
                    projection_input_path = motion_corrected_files{i};
                    
                    if ~isfield(obj.configuration, "tilt_stacks") || obj.configuration.tilt_stacks ~= true
                        splitted_name = strsplit(name, "_");
                        
                        % TODO: check if it is ok to add everywhere + 1 after the script
                        % sort mrcs ran, else you need to remove this extra underscore
                        % between name and tomogram number
                        %angle = str2double(splitted_name(obj.configuration.angle_position));
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "adjusted_angle_position")
                            angle = str2double(splitted_name(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).adjusted_angle_position));
                        else
                            %angle = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).original_angles(i);
                            angle = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).sorted_angles(i);
                        end
                        tilt_index_angle_mapping(1,i) = i;
                        tilt_index_angle_mapping(2,i) = angle;
                        tilt_index_angle_mapping(3,i) = true;
                        
                        angle_count = length(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).original_angles(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).original_angles == angle));
                        
                        if i == length(motion_corrected_files)
                            tilt_index_angle_mapping(4,:) = cumsum(tilt_index_angle_mapping(3,:));
                        end
                    else
                        tilt_index_angle_mapping(1,i) = i;
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "sorted_angles")
                            tilt_index_angle_mapping(2,i) = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).sorted_angles(i);
                        else
                            tilt_angles = sort(obj.configuration.tilt_angles);
                            tilt_index_angle_mapping(2,i) = tilt_angles(i);
                        end
                        tilt_index_angle_mapping(3,i) = true;
                        if i == length(motion_corrected_files)
                            tilt_index_angle_mapping(4,:) = cumsum(tilt_index_angle_mapping(3,:));
                        end
                        obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).original_angles(i) = obj.configuration.tilt_angles(i);
                    end
                    
                    micrograph = single(dread(char(projection_input_path)));
                    if obj.configuration.set_up.gpu > 0
                        micrograph = gpuArray(micrograph);
                    end
                    
                    if ~isfield(obj.configuration, "tilt_stacks") || obj.configuration.tilt_stacks ~= true
                        if ~isempty(regexp(motion_corrected_files{i}, "_[+-]*0{2}\.0", "match")) && isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "high_dose") && obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).high_dose == true
                            tilt_index_angle_mapping(5,i) = 1;
                            normalized_micrograph = micrograph ./ obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).high_dose_frames;
                            tilt_index_angle_mapping(6,i) = 1;
                        else
                            if ~isempty(regexp(motion_corrected_files{i}, "_[+-]*0{2}\.0", "match"))
                                tilt_index_angle_mapping(5,i) = 1;
                            else
                                tilt_index_angle_mapping(5,i) = 0;
                            end
                            % TODO: rename variables tok_tilt_p3_frames without
                            % angle, say better lowdose, highdose
                            normalized_micrograph = micrograph ./ obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).low_dose_frames;
                        end
                        
                        if angle_count > 1 && obj.configuration.duplicated_tilts == "keep"
                            normalized_micrograph = normalized_micrograph ./ angle_count;
                            tilt_index_angle_mapping(6,i) = angle_count;
                        else
                            tilt_index_angle_mapping(6,i) = 1;
                        end
                    else
                        tilt_index_angle_mapping(5,i) = tilt_index_angle_mapping(2,i) == 0; %obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).zero_tilt(i);
                        if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "dose")
                            normalized_micrograph = micrograph ./ obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).dose(i);
                        else
                            normalized_micrograph = micrograph;
                        end
                        % TODO: need to check if duplicated tilts go into
                        % stack
                        tilt_index_angle_mapping(6,i) = 1;
                        
                    end
                    projection_output_path = obj.output_path + string(filesep) + name + "_" + obj.configuration.normalized_postfix + ".mrc";
                    
                    if obj.configuration.border_pixels > 0
                        mean_image(:,:) = mean(normalized_micrograph(:));
                        normalized_micrograph = ((medfilt_border_image) .* mean_image) + ((1.0-medfilt_border_image) .* normalized_micrograph);
                    end
                    dwrite(gather(normalized_micrograph), char(projection_output_path));
                    output_stack_list(i) = projection_output_path;
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        output_stack_list_even(i) = string(motion_corrected_even_files{i});
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        output_stack_list_odd(i) = string(motion_corrected_odd_files{i});
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                        output_stack_list_dose_weighted(i) = string(motion_corrected_dose_weighted_files{i});
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")    
                        output_stack_list_dose_weighted_sum(i) = string(motion_corrected_dose_weighted_sum_files{i});
                    end
                end
            else
                error("ERROR: unknown normalization method!");
            end
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_files_normalized = output_stack_list;
            
            % NOTE: tilt_stack_files_normalized should not be deleted 
            % here because might be used on the DynamoCleanStacks step!
            %obj.temporary_files = output_stack_list;
            
            if (~isfield(obj.configuration, "live_data_mode") || ~obj.configuration.live_data_mode) && (length(output_stack_list) < obj.configuration.minimum_files)
                disp("INFO: Not enough MRC files to create stack!");
                obj.status = 0;
                return;
            end
            
            disp("INFO: Creating Stack!");
            % TODO: add "-tilt" parameter to include angles in meta data
            executeCommand("newstack " + strjoin(output_stack_list, " ") + " " + stack_output_path, false, obj.log_file_id);

            if isfield(obj.configuration, "apix")
                apix = obj.configuration.apix * obj.configuration.ft_bin;
            else
                apix = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix * obj.configuration.ft_bin;
            end

            executeCommand("alterheader -del " + apix + "," + apix + "," + apix + " " + stack_output_path, false, obj.log_file_id);
            
            [tilt_stack_symbolic_link_output, tilt_stack_symbolic_link] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path, "tilt_stacks_folder", obj.log_file_id);
            
            if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                executeCommand("newstack " + strjoin(output_stack_list_even, " ") + " " + stack_output_path_even, false, obj.log_file_id);
                executeCommand("alterheader -del " + apix + "," + apix + "," + apix + " " + stack_output_path_even, false, obj.log_file_id);
                [tilt_stack_symbolic_link_output, tilt_stack_symbolic_link] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path_even, "even_tilt_stacks_folder", obj.log_file_id);
            end
            
            if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                executeCommand("newstack " + strjoin(output_stack_list_odd, " ") + " " + stack_output_path_odd, false, obj.log_file_id);
                executeCommand("alterheader -del " + apix + "," + apix + "," + apix + " " + stack_output_path_odd, false, obj.log_file_id);
                [tilt_stack_symbolic_link_output, tilt_stack_symbolic_link] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path_odd, "odd_tilt_stacks_folder", obj.log_file_id);
            end
            
            if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                executeCommand("newstack " + strjoin(output_stack_list_dose_weighted, " ") + " " + stack_output_path_dose_weighted, false, obj.log_file_id);
                executeCommand("alterheader -del " + apix + "," + apix + "," + apix + " " + stack_output_path_dose_weighted, false, obj.log_file_id);
                [tilt_stack_symbolic_link_output, tilt_stack_symbolic_link] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path_dose_weighted, "dose_weighted_tilt_stacks_folder", obj.log_file_id);
            end
            
            if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                executeCommand("newstack " + strjoin(output_stack_list_dose_weighted_sum, " ") + " " + stack_output_path_dose_weighted_sum, false, obj.log_file_id);
                executeCommand("alterheader -del " + apix + "," + apix + "," + apix + " " + stack_output_path_dose_weighted_sum, false, obj.log_file_id);
                [tilt_stack_symbolic_link_output, tilt_stack_symbolic_link] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path_dose_weighted_sum, "dose_weighted_sum_tilt_stacks_folder", obj.log_file_id);
            end
            
            
            
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping = tilt_index_angle_mapping;
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping(2,:) = sort(obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping(2,:));
            
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_path = stack_output_path;
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_symbolic_link = tilt_stack_symbolic_link;

            %     if isfield(configuration, "tilt_stacks_folder")
            %         % TODO: check for errors
            %         mkdir(tilt_stacks_folder + string(filesep)...
            %             + path_parts(end));
            %         destination = tilt_stacks_folder + string(filesep)...
            %             + path_parts(end) + string(filesep) + path_parts(end) + ".st";
            %         createSymbolicLink(stack_output_path, destination, obj.log_file_id);
            %     end
            %end
            %meta_data_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.meta_data_folder;
            % TODO: check if tilt index mapping is merged in configuration
            %             save(meta_data_path + string(filesep)...
            %                 + obj.configuration.project_name...
            %                 + "_tilt_index_angle_mapping", "tilt_index_angle_mapping",...
            %                 "-v7.3");
            
            %obj.dynamic_configuration.tilt_index_angle_mapping = tilt_index_angle_mapping;
            if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "high_dose") && obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).high_dose == true
                disp("INFO: Create high dose stack done!");
            else
                disp("INFO: Create stack done!");
            end
        end
        
        function obj = cleanUp(obj)
            
            field_names = fieldnames(obj.configuration.tomograms);
            
            % Delete slices files created if input data were stacks
            % TODO: parametrize slice_folder to match created foldername
            slice_folder = "slices";
            folder = obj.output_path + string(filesep) + slice_folder;
            if exist(folder, 'dir')
                files = dir(folder + string(filesep) + field_names{obj.configuration.set_up.j} + "_" + obj.configuration.slice_suffix + "_*.mrc");
                obj.deleteFilesOrFolders(files);
                obj.deleteFolderIfEmpty(folder);
            end
            
            if obj.configuration.execute == false && obj.configuration.keep_intermediates == false
                
                if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_files")
                    files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files;
                    obj.deleteFilesOrFolders(files);
                
                    files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files_symbolic_links;
                    [folder, ~, ~] = fileparts(files{1});
                    obj.deleteFilesOrFolders(files);
                    obj.deleteFolderIfEmpty(folder);
                    [parent_folder, ~, ~] = fileparts(folder);
                    obj.deleteFolderIfEmpty(parent_folder);
                end
            end
            obj = cleanUp@Module(obj);
        end
    end
end

