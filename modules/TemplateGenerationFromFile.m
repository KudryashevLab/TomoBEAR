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


classdef TemplateGenerationFromFile < Module
    methods
        function obj = TemplateGenerationFromFile(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "templates_folder");
        end

        function obj = process(obj)
            map_path_char = char(obj.configuration.template_path);
            [folder, name, extension] = fileparts(obj.configuration.template_path);
           
            template_destination = obj.output_path + string(filesep) + name + extension;

            if obj.configuration.invert_density == true
                template = -dread(map_path_char);
            else
                template = dread(map_path_char);
            end
            
            if isfield(obj.configuration, "template_apix")
                template_pixel_size = obj.configuration.template_apix;
            else
                template_pixel_size = getPixelSizeFromHeader(obj.configuration.template_path, obj.log_file_id);
            end
            
            
            %for i = 1:length(obj.configuration.binning)
            binning = obj.configuration.template_matching_binning;% * obj.configuration.aligned_stack_binning;
            % TODO: what about homogenized data
            %                 rescaled_pixelsize = obj.configuration.apix * binning;
            if isfield(obj.configuration, "apix")
                apix = obj.configuration.apix * obj.configuration.ft_bin;
            else
                apix = obj.configuration.greatest_apix * obj.configuration.ft_bin;
            end

            rescaled_pixelsize = apix * binning / obj.configuration.ft_bin;
            scaling_ratio = str2double(template_pixel_size)/(rescaled_pixelsize);
            
            
            %             tilt_geometry = obj.configuration.tilt_geometry;
            %             projections = abs(tilt_geometry(1)-tilt_geometry(2)) / tilt_geometry(3);
            %             m = projections;
            template_scaled_to_actual_data = length(template) * (1/ apix);
            %             if obj.configuration.use_half_template_size == true
            %                 template_scaled_to_actual_data = template_scaled_to_actual_data / 2;
            %             end
            
            
            %             D = template_scaled_to_actual_data * obj.configuration.smallest_apix; %str2num(template_pixel_size)
            %             dx = (pi*D)/m;
            
            %             max_tilt_angle = (max(tilt_geometry));
            %
            %             exz = sqrt((max_tilt_angle+sin(max_tilt_angle)*cos(max_tilt_angle))/(max_tilt_angle-sin(max_tilt_angle)*cos(max_tilt_angle)));
            %
            %             dz = dx*exz;
            dz = obj.configuration.template_bandpass_cut_off_resolution_in_angstrom;
            fsc = 1:template_scaled_to_actual_data;
            
            obj.dynamic_configuration.fp = ceil((2*apix)*length(fsc)/dz);
            
            obj.dynamic_configuration.angstrom_template = (2*apix)*length(fsc)/obj.dynamic_configuration.fp;
            
            
            if obj.configuration.use_bandpassed_template == true
                band_passed_template = dbandpass(template, [obj.configuration.template_bandpass_cut_on_fourier_pixel obj.dynamic_configuration.fp obj.configuration.template_bandpass_smoothing_pixels]);
            else
                band_passed_template = template;
            end

              rescaled_template = dynamo_rescale(template, template_pixel_size, rescaled_pixelsize);
                rescaled_band_passed_template = dynamo_rescale(band_passed_template, template_pixel_size, rescaled_pixelsize);
                rescaled_template_tmp = rescaled_template;
                rescaled_template = makeEvenVolumeDimensions(rescaled_template_tmp);
                rescaled_band_passed_template_tmp = rescaled_band_passed_template;
                rescaled_band_passed_template = makeEvenVolumeDimensions(rescaled_band_passed_template_tmp);
            
            
            if obj.configuration.mask_path ~= ""
                mask = dread(char(obj.configuration.mask_path));
                mask_binarized = imbinarize(dynamo_rescale(double(mask), template_pixel_size, rescaled_pixelsize));
                
                mask_binarized_smoothed_cleaned = dbandpass(mask, obj.configuration.mask_bandpass);
                mask_binarized_smoothed_cleaned = dynamo_rescale(mask_binarized_smoothed_cleaned, template_pixel_size, rescaled_pixelsize);
            else
                if obj.configuration.use_ellipsoid == true
                    smoothing_pixels = (size(rescaled_template) .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio;

                    %smoothing_pixels = (length(rescaled_template)/2)/obj.configuration.ellipsoid_smoothing_ratio;
                    
                    
                    mask_binarized_smoothed_cleaned = dynamo_ellipsoid(((size(rescaled_template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(rescaled_template), length(rescaled_template)/2, smoothing_pixels);
                    
                    %mask_binarized_smoothed_cleaned = dynamo_ellipsoid((length(rescaled_template)-smoothing_pixels)/2, length(rescaled_template), length(rescaled_template)/2, smoothing_pixels);
                    
                    %mask_binarized = dynamo_ellipsoid((length(rescaled_template)-smoothing_pixels)/2, length(rescaled_template), 0);
                    mask_binarized = dynamo_ellipsoid(((size(rescaled_template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(rescaled_template), 0);
                else
                    mask = dbandpass(-template, obj.configuration.mask_bandpass);
                    mask_binarized = gather(imbinarize(mask));

                %                 mask_binarized_smoothed = gather(real(ifftn(fftn(mask_binarized) .* template_band_pass_filter)));
                %                 mask_binarized_smoothed_cleaned = mask_binarized_smoothed .* mask_binarized;
                    mask_binarized_smoothed_cleaned = mask.*mask_binarized;
                    mask_binarized = dynamo_rescale(double(mask_binarized), template_pixel_size, rescaled_pixelsize);
                    mask_binarized_smoothed_cleaned = dynamo_rescale(mask_binarized_smoothed_cleaned, template_pixel_size, rescaled_pixelsize);
                end
            end
            
            
            % TODO: need better criterion or check values
            %
            %             mask_frequency_cut_off = scaling_ratio .* obj.configuration.mask_cut_off;
            %             % NOTE: formerly 0.15
            %             template_frequency_cut_off = scaling_ratio .* obj.configuration.template_cut_off;
            %             template_band_pass_filter = obj.BH_bandpass3d(size(template), 0, 0, 1/template_frequency_cut_off, "GPU", 1);
            %             band_passed_template = gather(real(ifftn(fftn(template) .* template_band_pass_filter)));
            
           

                %                 template_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/template_frequency_cut_off, "GPU", 1);
                %                 mask_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/mask_frequency_cut_off, "GPU", 1);
                %                 mask = real(ifftn(fftn(rescaled_template) .* mask_band_pass_filter));
               
            
            
            
            
                %rescaled_mask_binarized = dynamo_rescale(mask_binarized, template_pixel_size, configuration.apix * configuration.binning(i));
                %rescaled_mask_binarized_smoothed_cleaned = dynamo_rescale(mask_binarized_smoothed_cleaned, template_pixel_size, configuration.apix * configuration.binning(i));
                        
            
            template_destination = char(obj.output_path + string(filesep) + "template_bin_" + num2str(binning) + ".mrc");
            template_destination_band_passed = char(obj.output_path + string(filesep) + "template_band_passed_bin_" + num2str(binning) + ".mrc");
            
            
            dwrite(rescaled_template, template_destination);
            dwrite(rescaled_band_passed_template, template_destination_band_passed);
            
            mask_link_destination = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder...
                + string(filesep) + obj.configuration.templates_folder + string(filesep) + "mask_bin_" + num2str(binning) + ".mrc";
            template_link_destination = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder...
                + string(filesep) + obj.configuration.templates_folder + string(filesep) + "template_bin_" + num2str(binning) + ".mrc";
            
            %mask_destination = char(obj.output_path + string(filesep) + "mask_bin_" + num2str(configuration.binning(i)) + ".mrc");
            mask_binarized_destination = char(obj.output_path + string(filesep) + "mask_binarized_bin_" + num2str(binning) + ".mrc");
            mask_smoothed_destination = char(obj.output_path + string(filesep) + "mask_smoothed_bin_" + num2str(binning) + ".mrc");
            if obj.configuration.use_bandpassed_template == true
                createSymbolicLink(template_destination_band_passed, template_link_destination, obj.log_file_id);
            else
                createSymbolicLink(template_destination, template_link_destination, obj.log_file_id);
            end
            
            
                
                dwrite(mask_binarized, mask_binarized_destination);
                dwrite(mask_binarized_smoothed_cleaned, mask_smoothed_destination);
                if obj.configuration.use_smoothed_mask == true
                    createSymbolicLink(mask_smoothed_destination, mask_link_destination, obj.log_file_id);
                else
                    createSymbolicLink(mask_binarized_destination, mask_link_destination, obj.log_file_id);
                end
            
        end
    end
end