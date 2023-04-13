%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


classdef MetaData < Module
    methods
        function obj = MetaData(configuration)
            obj@Module(configuration);
        end
       
        function obj = process(obj)
            folder_contents = obj.configuration.original_files; %getMRCs(obj.configuration, true);
           
            if obj.configuration.do_statistics == true
                micrograph_mean = zeros(length(folder_contents), 1);
                micrograph_min = zeros(length(folder_contents), 1);
                micrograph_max = zeros(length(folder_contents), 1);
                micrograph_std = zeros(length(folder_contents), 1);
               
                %TODO: get statistics
               
                obj.dynamic_configuration.micrograph_mean = micrograph_mean;
                obj.dynamic_configuration.micrograph_min = micrograph_min;
                obj.dynamic_configuration.micrograph_max = micrograph_max;
                obj.dynamic_configuration.micrograph_std = micrograph_std;
            end
           
            % NOTE:  may crash if lesser projections available
            %             splitted_mrc_name = strsplit(string(folder_contents(obj.configuration.skip_n_first_projections).name), "_");
            %             if isfield(obj.configuration, "tomogram_input_prefix") && isempty(obj.configuration.tomogram_input_prefix) %( || configuration.tomogram_input_prefix == "")
            %                 tomogram_input_prefix = string(splitted_mrc_name(1:obj.configuration.angle_position - 2));
            %                 obj.dynamic_configuration.tomogram_input_prefix = tomogram_input_prefix;
            %                 variable_string = printVariableToString(tomogram_input_prefix);
            %                 printToFile(obj.log_file_id, variable_string);
            %             end
           
           
           
            %             variable_string = printVariableToString(apix);
            %             printToFile(obj.log_file_id, variable_string);
           
            obj.dynamic_configuration.tomograms = struct();
            obj.dynamic_configuration.greatest_apix = NaN;
            obj.dynamic_configuration.smallest_apix = NaN;
            if obj.configuration.parallel_execution == true
                field_names = obj.field_names;
                configuration = obj.configuration;
                tomograms = cell(1, length(obj.field_names));
                apix_list = zeros(1, length(obj.field_names));
               parfor i = 1:length(field_names)%(,0) 
                    tomograms{i} = struct();
                    field_name = field_names{i};
                    num_images_2 = [];
                    num_images_1 = [];
                    size_output_1 = [];
                    size_output_2 = [];
                    if isfield(configuration, "tilt_stacks") && configuration.tilt_stacks == true
                        tomograms{i}.apix = configuration.apix;
                        apix_list(i) = tomograms{i}.apix;
                        tomograms{i}.high_dose = false;
                        tomograms{i}.low_dose_frames = 1;
                        tomograms{i}.high_dose_frames = 1;
                    else
                        if configuration.tomograms.(field_name).tif ~= true
                            [status_header, output_1] = system("header -s " + configuration.tomograms.(field_name).file_paths(1));
                            [status_header, output_1] = system("header -s " + configuration.tomograms.(field_name).file_paths(1));
                            size_output_1 = str2num(output_1);
                        else
                            info = imfinfo(char(configuration.tomograms.(field_name).file_paths(1)));
                            num_images_1 = numel(info);
                            %tmp_image_size_1 = [info(1).Width info(1).Height];
                        end
                        if length(configuration.tomograms.(field_name).file_paths) >= 2
                            if configuration.tomograms.(field_name).mrc == true
                                [status_header, output_2] = system("header -s " + configuration.tomograms.(field_name).file_paths(2));
                                size_output_2 = str2num(output_2);
                                tomograms{i}.high_dose = size_output_1(3) > size_output_2(3);
                            elseif configuration.tomograms.(field_name).tif == true
                                info = imfinfo(char(configuration.tomograms.(field_name).file_paths(2)));
                                num_images_2 = numel(info);
                                %tmp_image_size_2 = [info(1).Width info(1).Height];
                                tomograms{i}.high_dose = num_images_1 > num_images_2;
                            elseif configuration.tomograms.(field_name).eer == true
                                tomograms{i}.high_dose = false;
                            end
                        else
                            tomograms{i}.high_dose = false;
                        end
                        if isfield(tomograms{i}, "high_dose") && tomograms{i}.high_dose == true
                            if configuration.tomograms.(field_name).tif ~= true
                                tomograms{i}.high_dose_frames = size_output_1(3);
                                if length(configuration.tomograms.(field_name).file_paths) >= 2
                                    tomograms{i}.low_dose_frames = size_output_2(3);
                                else
                                    tomograms{i}.low_dose_frames = [];
                                end
                            else
                                tomograms{i}.high_dose_frames = num_images_1;
                                if length(configuration.tomograms.(field_name).file_paths) >= 2
                                    tomograms{i}.low_dose_frames = num_images_2;
                                else
                                    tomograms{i}.low_dose_frames = [];
                                end
                            end
                        else
                            if configuration.tomograms.(field_name).mrc == true
                                tomograms{i}.high_dose_frames = size_output_1(3);
                                tomograms{i}.low_dose_frames =  size_output_1(3);
                            elseif configuration.tomograms.(field_name).tif == true
                                tomograms{i}.high_dose_frames = num_images_1;
                                tomograms{i}.low_dose_frames = num_images_1;
                            elseif configuration.tomograms.(field_name).eer == true
                                tomograms{i}.high_dose_frames = 1;
                                tomograms{i}.low_dose_frames = 1;
                            end
                        end
                        % TODO: check for eer if header doesn?t support it
                        % and inform user to input apix
                        if isfield(configuration, "apix")
                            tomograms{i}.apix = configuration.apix;
                            apix_list(i) = tomograms{i}.apix;
                        else
                            tomograms{i}.apix = str2double(getPixelSizeFromHeader(configuration.tomograms.(field_name).file_paths(1)));
                            apix_list(i) = str2double(getPixelSizeFromHeader(configuration.tomograms.(field_name).file_paths(1)));
                        end
                    end
                end
                for i = 1:length(field_names)
                    obj.dynamic_configuration.tomograms.(field_names{i}) = tomograms{i};
                    obj.dynamic_configuration.apix_list = apix_list;
                    obj.dynamic_configuration.greatest_apix = max(apix_list);
                    obj.dynamic_configuration.smallest_apix = min(apix_list);
                end
               
            else
                for i = 1:length(obj.field_names)
                    obj.dynamic_configuration.tomograms.(obj.field_names{i}) = struct();
                   
                    if obj.configuration.tomograms.(obj.field_names{i}).tif ~= true
                        [status_header, output_1] = system("header -s " + obj.configuration.tomograms.(obj.field_names{i}).file_paths(1));
                        size_output_1 = str2num(output_1);
                    else
                        info = imfinfo(char(obj.configuration.tomograms.(obj.field_names{i}).file_paths(1)));
                        num_images_1 = numel(info);
                        %tmp_image_size_1 = [info(1).Width info(1).Height];
                    end
                   
                    if length(obj.configuration.tomograms.(obj.field_names{i}).file_paths) >= 2
                        if obj.configuration.tomograms.(obj.field_names{i}).tif ~= true
                            [status_header, output_2] = system("header -s " + obj.configuration.tomograms.(obj.field_names{i}).file_paths(2));
                            size_output_2 = str2num(output_2);
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose = size_output_1(3) > size_output_2(3);
                        else
                            info = imfinfo(char(obj.configuration.tomograms.(obj.field_names{i}).file_paths(2)));
                            num_images_2 = numel(info);
                            %tmp_image_size_2 = [info(1).Width info(1).Height];
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose = num_images_1 > num_images_2;
                        end
                       
                    else
                        obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose = false;
                    end
                   
                   
                    if isfield(obj.dynamic_configuration.tomograms.(obj.field_names{i}), "high_dose") && obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose == true
                       
                        if obj.configuration.tomograms.(obj.field_names{i}).tif ~= true
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose_frames = size_output_1(3);
                            if length(obj.configuration.tomograms.(obj.field_names{i}).file_paths) >= 2
                                obj.dynamic_configuration.tomograms.(obj.field_names{i}).low_dose_frames = size_output_2(3);
                            else
                                obj.dynamic_configuration.tomograms.(obj.field_names{i}).low_dose_frames = [];
                            end
                        else
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose_frames = num_images_1;
                            if length(obj.configuration.tomograms.(obj.field_names{i}).file_paths) >= 2
                                obj.dynamic_configuration.tomograms.(obj.field_names{i}).low_dose_frames = num_images_2;
                            else
                                obj.dynamic_configuration.tomograms.(obj.field_names{i}).low_dose_frames = [];
                            end
                        end
                    else
                        if obj.configuration.tomograms.(obj.field_names{i}).tif ~= true
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose_frames = size_output_1(3);
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).low_dose_frames =  size_output_1(3);
                        else
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).high_dose_frames = num_images_1;
                            obj.dynamic_configuration.tomograms.(obj.field_names{i}).low_dose_frames = num_images_1;
                        end
                    end
                   
                    if isfield(obj.configuration, "apix")
                        obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix = obj.configuration.apix;
                    obj.dynamic_configuration.apix_list(i) = obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix;
                    else
                        obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix = str2double(getPixelSizeFromHeader(obj.configuration.tomograms.(obj.field_names{i}).file_paths(1)));
                        obj.dynamic_configuration.apix_list(i) = str2double(getPixelSizeFromHeader(obj.configuration.tomograms.(obj.field_names{i}).file_paths(1)));
                    end
                                           
                    if isnan(obj.dynamic_configuration.greatest_apix) || obj.dynamic_configuration.greatest_apix < obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix
                        obj.dynamic_configuration.greatest_apix = obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix;
                    end
                   
                    if isnan(obj.dynamic_configuration.smallest_apix) || obj.dynamic_configuration.smallest_apix > obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix
                        obj.dynamic_configuration.smallest_apix = obj.dynamic_configuration.tomograms.(obj.field_names{i}).apix;
                    end
                end
            end
           
           
            % NOTE: not really needed because it is down streamed anyway
            %meta_data_destination = obj.output_path + string(filesep) + obj.configuration.project_name + "_meta_data.mat";
            %dynamic_configuration = obj.dynamic_configuration;
            %save(meta_data_destination, "dynamic_configuration");
           
            %createSymbolicLinkInStandardFolder(obj.configuration, meta_data_destination, "meta_data_folder", obj.log_file_id);
           
            % TODO: remove if it works
            % if isfield(configuration, "meta_data_folder")
            %     meta_data_link_destination = configuration.processing_path + string(filesep)...
            %         + configuration.output_folder + string(filesep)...
            %         + configuration.meta_data_folder + string(filesep)...
            %         + configuration.project_name + "_meta_data.mat";
            %
            %     createSymbolicLink(meta_data_destination,...
            %         meta_data_link_destination, obj.log_file_id);
            % end
        end
    end
end