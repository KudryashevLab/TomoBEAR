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

% NOTE:TODO: relion_estimate_gain

classdef GainCorrection < Module
    methods
        function obj = GainCorrection(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "gain_correction_folder", true);
        end
        
        function obj = process(obj)
            for i = 1:length(obj.field_names)
                if i == 1
                    data_dir(1:length(obj.configuration.tomograms.(obj.field_names{i}).original_file_paths)) = obj.configuration.tomograms.(obj.field_names{i}).original_file_paths;
                else
                    data_dir(end+1:end+length(obj.configuration.tomograms.(obj.field_names{i}).original_file_paths)) = obj.configuration.tomograms.(obj.field_names{i}).original_file_paths;
                end
            end
            [folder, name, extension] = fileparts(data_dir(1));
            if extension ~= ".tif"
                tmp_image_size = size(dread(char(data_dir(1))));
                tif_flag = false;
            else
                info = imfinfo(char(data_dir(1)));
                num_images = numel(info);
                tmp_image_size = [info(1).Width info(1).Height];
                tif_flag = true;
            end
            summed_image = zeros(tmp_image_size(1), tmp_image_size(2));
            clear tmp_image;
            frames = 1;
            if obj.configuration.parallel_execution == true
                parfor i = 1:length(data_dir)
                    image = [];
                    file_name = data_dir(i);
                    disp("INFO:VARIABLE:file_name -> " + file_name);
                    if tif_flag == false
                        image = double(dread(char(file_name)));
                        % TODO extract to function and add mean value to
                        % boarder
                        if size(image,1) ~= tmp_image_size(1) || size(image,2) ~= tmp_image_size(2)
                            difference = abs(tmp_image_size(1) - size(image,1));
                            disp("INFO:VARIABLE:difference -> " + difference);
                            tmp_image = zeros(tmp_image_size(1), tmp_image_size(2), size(image,3));
                            tmp_image(1:size(image,1), 1:size(image,2), :) = image;
                            image = tmp_image;
                        end
                        frames = frames + size(image, 3);
                        summed_image = summed_image + sum(image, 3);
                        disp("image number: " + num2str(i) + " of " + num2str(length(data_dir)));
                    else
                        info = imfinfo(char(data_dir(i)));
                        num_images = numel(info);
                        counter = 1;
                        for k = 1:num_images
                            image(:,:,counter) = double(imread(char(data_dir(i)), k))';
                            % TODO extract to function and add mean value to
                            % boarder
                            if size(image,1) ~= tmp_image_size(1) || size(image,2) ~= tmp_image_size(2)
                                difference = abs(tmp_image_size(1) - size(image,1));
                                disp("INFO:VARIABLE:difference -> " + difference);
                                tmp_image = zeros(tmp_image_size(1), tmp_image_size(2), size(image,3));
                                tmp_image(1:size(image,1), 1:size(image,2), :) = image;
                                image = tmp_image;
                            end
                            if mod(sum(image, 3), 10) == 0
                                summed_image = summed_image + sum(image, 3);
                                counter = 1;
                                image = [];
                            end
                        end
                        summed_image = summed_image + sum(image, 3);
                        frames = frames + num_images;
                        disp("image number: " + num2str(i) + " of " + num2str(length(data_dir)));
                    end
                end
            else
                for i = 1:length(data_dir)
                    image = [];
                    file_name = data_dir(i);
                    disp("INFO:VARIABLE:file_name -> " + file_name);
                    if tif_flag == false
                        image = double(dread(char(file_name)));
                        % TODO extract to function and add mean value to
                        % boarder
                        if size(image,1) ~= tmp_image_size(1) || size(image,2) ~= tmp_image_size(2)
                            difference = abs(tmp_image_size(1) - size(image,1));
                            disp("INFO:VARIABLE:difference -> " + difference);
                            tmp_image = zeros(tmp_image_size(1), tmp_image_size(2), size(image,3));
                            tmp_image(1:size(image,1), 1:size(image,2), :) = image;
                            image = tmp_image;
                        end
                        frames = frames + size(image, 3);
                        summed_image = summed_image + sum(image, 3);
                        disp("image number: " + num2str(i) + " of " + num2str(length(data_dir)));
                    else
                        info = imfinfo(char(data_dir(i)));
                        num_images = numel(info);
                        counter = 1;
                        for k = 1:num_images
                            image(:,:,counter) = double(imread(char(data_dir(i)), k))';
                            % TODO extract to function and add mean value to
                            % boarder
                            if size(image,1) ~= tmp_image_size(1) || size(image,2) ~= tmp_image_size(2)
                                difference = abs(tmp_image_size(1) - size(image,1));
                                disp("INFO:VARIABLE:difference -> " + difference);
                                tmp_image = zeros(tmp_image_size(1), tmp_image_size(2), size(image,3));
                                tmp_image(1:size(image,1), 1:size(image,2), :) = image;
                                image = tmp_image;
                            end
                            if mod(sum(image, 3), 10) == 0
                                summed_image = summed_image + sum(image, 3);
                                counter = 1;
                                image = [];
                            end
                        end
                        summed_image = summed_image + sum(image, 3);
                        frames = frames + num_images;
                        disp("image number: " + num2str(i) + " of " + num2str(length(data_dir)));
                    end
                end
            end
            mean_value = mean2(summed_image);
            gain_correction_image = summed_image / mean_value;
            % TODO: clean script if the method works
            summed_image_normalized = summed_image / frames;
            method = obj.configuration.method;
            siz = size(gain_correction_image);
            pad_gain_correction_image = false;
            cut_on_frequency = siz(1) / 4;
            filter_string = "hann";
            smoothing = siz(2) / 8;
            sigma = 2;
            filter_size = 2 * ceil( 2 * sigma)+1;
            filter_domain = "spatial";
            median_filter = obj.configuration.median_filter;
            if pad_gain_correction_image
                gain_correction_image = padarray(gain_correction_image,[round(size(gain_correction_image, 1) / padding_factor) round(size(gain_correction_image, 2) / padding_factor)],'both');
            end
            if method == "gaussfilt"
                background_image = imgaussfilt(gain_correction_image, sigma,...
                    "FilterSize", filter_size, "FilterDomain", filter_domain,...
                    "Padding", "replicate");
                bandpassed_image = gain_correction_image - background_image;
                bandpassed_image = bandpassed_image + min(bandpassed_image(:));
            elseif method == "gaussian"
                cut_on_frequency_tmp = cut_on_frequency / siz(1);
                mean_value = mean(gain_correction_image(:));
                gain_correction_image_indices = gain_correction_image > mean_value * 3;
                gain_correction_image_values = gain_correction_image(gain_correction_image_indices);
                gain_correction_image_tmp = gain_correction_image;
                gain_correction_image_tmp(gain_correction_image_indices) = mean_value;
                [f1, f2] = freqspace([siz(1) siz(2)],'meshgrid');
                r = sqrt(f1.^2 + f2.^2);
                Hd = ones(size(gain_correction_image));
                Hd((r<cut_on_frequency_tmp)|(r>1.0)) = 0;
                win = fspecial('gaussian',size(gain_correction_image),2);
                win = win ./ max(win(:));
                h = fwind2(Hd,win);
                bandpassed_image = imfilter(h,gain_correction_image_tmp,"conv");
                bandpassed_image(gain_correction_image_indices) = gain_correction_image_values;
            elseif method == "butterworth"
                bandpassed_image = butterworthbpf(gain_correction_image_padded,siz(2)/8,siz(2),8);
                close all;
            elseif method == "tom"
                bandpassed_image = tom_bandpass(gain_correction_image, round(cut_on_frequency), size(gain_correction_image, 2), size(gain_correction_image, 2)/20);
            elseif method == "dynamo"
                bandpassed_image = dynamo_bandpass(gain_correction_image_padded,...
                    [round(cut_on_frequency)...
                    size(gain_correction_image, 2)...
                    round(smoothing)],0);
            elseif method == "window2"
                filter_func = str2func(filter_string);
                win = window2(siz(1),siz(2),filter_func);
                fft_gain_correction_image = fft2(gain_correction_image.*win);
                fft_gain_correction_image_filt = fft_gain_correction_image.*Hd;
                bandpassed_image = real(ifft2(gain_correction_image));
            elseif method == "median"
                median_filtered_gain_correction_image = medfilt2(gain_correction_image, median_filter);
                
                bandpassed_image = gain_correction_image - median_filtered_gain_correction_image;
                if min(bandpassed_image(:)) < 0
                    bandpassed_image = bandpassed_image - min(bandpassed_image(:));
                end
            end
            gain_correction_image_normalized = uint16(round(reshape(normalize(gain_correction_image(:), "range"), size(gain_correction_image)) * 2^16));
            bandpassed_image_normalized = uint16(round(reshape(normalize(bandpassed_image(:), "range"), size(gain_correction_image)) * 2^16));
            output_image = histogramEqualization(bandpassed_image_normalized, gain_correction_image_normalized);
            output_image_normalized = single(output_image) / 2^16;
            output_image_normalized = reshape(normalize(output_image_normalized(:), "range"), size(output_image_normalized));
            output_image_normalized_zeros_replaced = output_image_normalized * max(bandpassed_image(:));
            output_image_normalized_zeros_replaced = output_image_normalized_zeros_replaced / mean(bandpassed_image(:));
            output_image_normalized_zeros_replaced(output_image_normalized_zeros_replaced == 0) = 0.01;
            gain_correction_output_path = obj.output_path + string(filesep) + "gain_correction.mrc";
            % NOTE: inverted gain reference is saved because it seams that motioncor is
            % multiplying instead of dividing
            dwrite(ones(size(output_image_normalized_zeros_replaced))./output_image_normalized_zeros_replaced, char(gain_correction_output_path));
            createSymbolicLinkInStandardFolder(obj.configuration, gain_correction_output_path, "gain_correction_folder", obj.log_file_id);
        end
    end
end

