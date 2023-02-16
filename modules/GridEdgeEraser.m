classdef GridEdgeEraser < Module
    methods
        function obj = GridEdgeEraser(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
        end
        
        function obj = process(obj)
            
            % Get actual pixel size according to used binning
            [rescaled_pixelsize, ~] = getApix(obj.configuration);

            % Define window (i.e. kernel) size for local std filter
            % Heuristic used: window size = 2 * gold bead size (+ 1, because kernel should be odd-sized)  
            gold_bead_size_pix_binned = ceil((obj.configuration.gold_bead_size_in_nm * 10) / (rescaled_pixelsize * obj.configuration.detection_binning));
            obj.dynamic_configuration.local_std_window_size = gold_bead_size_pix_binned * 2 + 1;

            % Define output shift based on user queries
            output_shift_user_mask = obj.configuration.output_shift_user ~= 0;
            output_shift_kernel = obj.configuration.output_shift_kernel_factor * obj.dynamic_configuration.local_std_window_size * obj.configuration.detection_binning;
            output_shift = output_shift_user_mask .* obj.configuration.output_shift_user + (~output_shift_user_mask) .* output_shift_kernel;
            output_shift = output_shift';
            
            % Convert grid hole diameter in microns to radius in pixels
            grid_hole_radius_in_pixels = ((obj.configuration.grid_hole_diameter_in_um / 2) * 10000) / rescaled_pixelsize;
            grid_hole_radius_in_pixels_binned = grid_hole_radius_in_pixels / obj.configuration.detection_binning;

            % Convert tilt axis angle
            tilt_axis_angle_deg = (90 - obj.configuration.rotation_tilt_axis);
            obj.dynamic_configuration.tilt_axis_angle_rad = (tilt_axis_angle_deg / 360) * 2 * pi;
            
            field_names = fieldnames(obj.configuration.tomograms);
            
            % TODO: implement mcor stack input case
            % NOTE: currently works only on mcor files
            motion_corrected_files = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files;
            [motion_corrected_files_path, ~, ~] = fileparts(motion_corrected_files{1});
            disp("INFO: Getting ready to process...");
            disp("INFO: Processing micrographs in " + motion_corrected_files_path);
            
            if obj.configuration.relink_as_previous_output == true
                    folder_destination = obj.configuration.motion_corrected_files_folder;
                    slinks_path_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + folder_destination + filesep + obj.name;
                    if exist(slinks_path_destination, "dir")
                        rmdir(slinks_path_destination, "s");
                    end
                    mkdir(slinks_path_destination);
            end
            
            grid_edge_cleaned_files = {};
            for i = 1:length(motion_corrected_files)
                [~, name, ext] = fileparts(motion_corrected_files{i});
                tilt_angle_deg = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).sorted_angles(i);
                %tilt_angle_str = obj.getTiltAngleString(tilt_angle_deg);
                
                %path_parts = strsplit(path, string(filesep));
%                 [status_mkdir, ~] = mkdir(obj.output_path);
%                 if status_mkdir ~= 1
%                     error("ERROR: Can't create GridEdgeEraser folder for script output!");
%                 end
                
                % Read & preprocess raw frame
                raw_frame = dread(motion_corrected_files{i});

                % Bin frame to speed up further processing and to smooth peaks
                frame_binned = imresize(raw_frame, 1/obj.configuration.detection_binning);

                % Standartize frame intensity distribution
                frame = frame_binned - mean(frame_binned, 'all');
                frame = frame / std(frame, 1, 'all');

                % Get grid hole stretching factor due to projection under given tilt angle
                tilt_angle_rad = (tilt_angle_deg / 360) * 2 * pi;
                tilt_stretch_factor = cos(tilt_angle_rad);
                obj.dynamic_configuration.tilt_stretch_vector = [1 tilt_stretch_factor];

                % Get ellips ring mask parameters corresponding to 
                % the grid hole projected under given specimen tilt angle
                ellips_mask_semiaxes_binned = round(grid_hole_radius_in_pixels_binned .* obj.dynamic_configuration.tilt_stretch_vector);
                additive_extra_space_binned = size(frame) * 2;
                ellips_mask_box_size_binned = obj.calculateRotatedEllipsEmbeddingBoxSize(ellips_mask_semiaxes_binned, additive_extra_space_binned);

                % Use cross-correlation to find frame position relative to grid hole mask
                [frame_start_position_binned, frame_end_position_binned, grid_edge_detected] = obj.findFramePositionRelativeToGridHoleModelByCrossCorrelation(frame, ellips_mask_semiaxes_binned, ellips_mask_box_size_binned);

                if grid_edge_detected == false
                    disp("WARNING: Grid edge was not detected for view " + name + ". Try to change parameters values...");
                    % No edge was detected (or parameters should be tuned!)
                    frame_cleaned = raw_frame;
                    %frame_cleaned_binned = frame;
                else
                    disp("INFO: Grid edge was detected for view " + name + ". Writing cleaned view...");
                    % Cleaned frame for original version
                    frame_start_position = frame_start_position_binned * obj.configuration.detection_binning;
                    frame_start_position = frame_start_position + output_shift;
                    frame_end_position = frame_start_position + (size(raw_frame) - 1);

                    box_x_range = frame_start_position(1):frame_end_position(1);
                    box_y_range = frame_start_position(2):frame_end_position(2);

                    ellips_mask_semiaxes = ellips_mask_semiaxes_binned * obj.configuration.detection_binning;
                    additive_extra_space = additive_extra_space_binned * obj.configuration.detection_binning;
                    ellips_eraser_mask_box_size = obj.calculateRotatedEllipsEmbeddingBoxSize(ellips_mask_semiaxes, additive_extra_space);
                    
                    ellips_eraser_mask = obj.createEllipsMaskRotated(ellips_mask_semiaxes, ellips_eraser_mask_box_size, box_x_range, box_y_range, obj.configuration.smooth_mask_border);
                    
                    frame_cleaned = raw_frame .* ellips_eraser_mask;
                    
                    % NOTE: casting boolean smooth_mask_border to double
                    % NOTE: if true, masked region will be equal to mean
                    frame_cleaned = frame_cleaned + double(obj.configuration.smooth_to_mean) * mean(raw_frame(ellips_eraser_mask == 1), 'all') * (1-ellips_eraser_mask);
                    
                    % Cleaned frame for binned version
                    %{
                    output_shift_binned = output_shift / obj.configuration.detection_binning;
                    frame_start_position = frame_start_position_binned + output_shift_binned;
                    %frame_end_position = frame_end_position_binned;
                    frame_end_position = frame_start_position + (size(frame) - 1);

                    box_x_range = frame_start_position(1):frame_end_position(1);
                    box_y_range = frame_start_position(2):frame_end_position(2);

                    ellips_eraser_mask = obj.createEllipsMaskRotated(ellips_mask_semiaxes_binned, ellips_mask_box_size_binned, box_x_range, box_y_range);

                    frame_cleaned_binned = frame .* ellips_eraser_mask;
                    %}
                end
                frame_cleaned_path = obj.output_path + string(filesep) + name + "_" + obj.configuration.cleaned_postfix + ext;
                dwrite(frame_cleaned, frame_cleaned_path);
                grid_edge_cleaned_files{i} = char(frame_cleaned_path);
                
                %{
                frame_cleaned_binned_path = obj.output_path + string(filesep) + name + "_bin_" + num2str(obj.configuration.detection_binning) + "_" + obj.configuration.cleaned_postfix + ext;
                dwrite(frame_cleaned_binned, frame_cleaned_binned_path);
                %}
                
                if obj.configuration.relink_as_previous_output == true
                    % TODO: implement mcor stack input case
                    % NOTE: currently works only on mcor files 
                    filename_link_destination = string(name) + string(ext);
                    link_destination = slinks_path_destination + filesep + filename_link_destination;
                    createSymbolicLink(frame_cleaned_path, link_destination, obj.log_file_id);
                end
            end
            % TODO: create corresponding files and filelinks field for 
            % GridedgeEraser module and change dependent modules accord.
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files = grid_edge_cleaned_files;
            disp("INFO: Grid edge detection and masking is done!");
        end
        
        function tilt_angle_str = getTiltAngleString(obj, tilt_angle_deg)
            tilt_angle_deg_fract = abs(tilt_angle_deg) - floor(abs(tilt_angle_deg));
            tilt_angle_fract_str = num2str(tilt_angle_deg_fract, '%.1f');
            tilt_angle_fract_str = tilt_angle_fract_str(2:end);
            tilt_angle_int_str = num2str(tilt_angle_deg,'%+03.f');
            tilt_angle_str = [tilt_angle_int_str tilt_angle_fract_str];
        end

        function [is_valid_grid_edge_model, peak_position, peak_value] = isValidGridEdgeModel(obj, cc_full, is_inner_region, frame, frameStdMap_mean, frameStdMap_std, ellips_mask_semiaxes, ellips_mask_box_size)
            ellips_mask = obj.createEllipsMaskRotated(ellips_mask_semiaxes, ellips_mask_box_size);
            if is_inner_region
                cc = cc_full .* ellips_mask;
            else
                cc = cc_full .* (~ellips_mask);
            end

            % Get peak position - position of 'moving' image center 
            % relative to 'fixed' image coordinate system
            [peak_position, peak_value] = dynamo_peak_subpixel(cc);

            [frame_start_position, frame_end_position] = obj.getFrameStartEndPositions(peak_position, size(frame));

            mask_size = size(ellips_mask);
            frame_start_out_of_bonds = 0 < sum((frame_start_position < 1) | (frame_start_position > mask_size) | ~isreal(frame_start_position) | isnan(frame_start_position) | isinf(frame_start_position));
            frame_end_out_of_bonds = 0 < sum((frame_end_position < 1) | (frame_end_position > mask_size) | ~isreal(frame_end_position) | isnan(frame_end_position) | isinf(frame_end_position));

            if ~(frame_start_out_of_bonds || frame_end_out_of_bonds)
                box_x_range = frame_start_position(1):frame_end_position(1);
                box_y_range = frame_start_position(2):frame_end_position(2);    

                ellips_check_mask = ellips_mask(box_x_range, box_y_range);

                ellips_check_mask_semiaxes_plus = ellips_mask_semiaxes + 2 * obj.dynamic_configuration.local_std_window_size;
                ellips_check_mask_semiaxes_minus = ellips_mask_semiaxes - 2 * obj.dynamic_configuration.local_std_window_size;
                ellips_check_mask_plus = obj.createEllipsMaskRotated(ellips_check_mask_semiaxes_plus, ellips_mask_box_size, box_x_range, box_y_range);
                ellips_check_mask_minus = obj.createEllipsMaskRotated(ellips_check_mask_semiaxes_minus, ellips_mask_box_size, box_x_range, box_y_range);
                ellips_check_mask_plus = logical(ellips_check_mask_plus - ellips_check_mask);
                ellips_check_mask_minus = logical(ellips_check_mask - ellips_check_mask_minus);

                % FOR FUTURE: this criterion can be updated to more reliable
                % Make sure that the difference between means is consistent with
                % the binarizing local std map threshold
                frame_global_mean_inner = mean(frame(ellips_check_mask), 'all');
                frame_global_mean_outer = mean(frame(~ellips_check_mask), 'all');
                frame_global_means_diff = abs(frame_global_mean_outer - frame_global_mean_inner);
                num_of_stdevs_global = (frame_global_means_diff - frameStdMap_mean) / frameStdMap_std;

                frame_local_mean_inner = mean(frame(ellips_check_mask_minus), 'all');
                frame_local_mean_outer = mean(frame(ellips_check_mask_plus), 'all');
                frame_local_means_diff = abs(frame_local_mean_outer - frame_local_mean_inner);
                num_of_stdevs_local = (frame_local_means_diff - frameStdMap_mean) / frameStdMap_std;

                % Check whether found border line position corresponds to grid edge 
                % dividing dense grid region and transparent hole region
                is_dense_enough = (num_of_stdevs_global >= obj.configuration.grid_detection_threshold_in_std) && (num_of_stdevs_local >= obj.configuration.grid_detection_threshold_in_std);

                % If curvature is low, wrong curvature erasing model may be 
                % detected. Check whether erasing model curvature has right sign
                is_correct_curvature = frame_global_mean_outer < frame_global_mean_inner;

                % Heuristuc to check minimal erased area which should be larger
                % than square of half kernel size to avoid misdetection of gold
                % beads near frame border as a grid edge due to their high density
                threshold_min_area = (obj.dynamic_configuration.local_std_window_size ^ 2)/2;
                min_area = min(sum(~ellips_check_mask, 'all'), sum(ellips_check_mask, 'all'));
                is_big_enough = min_area > threshold_min_area;

                % Combine all criteria to get final decision
                is_valid_grid_edge_model = is_dense_enough & is_correct_curvature & is_big_enough;
            else
                is_valid_grid_edge_model = false;
            end
        end

        function [frame_start_position, frame_end_position, grid_edge_detected] = findFramePositionRelativeToGridHoleModelByCrossCorrelation(obj, frame, ellips_mask_semiaxes, ellips_mask_box_size)
            % Set initial function output values
            grid_edge_detected = false;
            frame_start_position = -1;
            frame_end_position = -1;

            % Get local std map of frame
            kernel = ones(obj.dynamic_configuration.local_std_window_size);
            frameStdMap = stdfilt(frame, kernel);
            frameStdMap_mean = mean(frameStdMap, 'all');
            frameStdMap_std = std(frameStdMap, 1, 'all');
            frameStdMap_threshold = frameStdMap_mean + frameStdMap_std * obj.configuration.binarize_threshold_in_std;

            % Embed frame with min-intensity line
            % These lines are made in order to make continuous 
            % border which divides hole and grid edge regions
            %{
            extra_size = floor(obj.dynamic_configuration.local_std_window_size/2);
            frame_preembedded = ones(size(frame) + 2 * extra_size) * min(frame, [], 'all');
            x_preembedding_range = (extra_size + 1):(extra_size+size(frame,1));
            y_preembedding_range = (extra_size + 1):(extra_size+size(frame,2));
            frame_preembedded(x_preembedding_range, y_preembedding_range) = frame;
            frameStdMap_preembedded = stdfilt(frame_preembedded, kernel);
            frameStdMap_preembedded = obj.frameStdMap_preembedded(x_preembedding_range, y_preembedding_range);
            %}

            % Binarize local std map of frame
            frameStdMap_bw = frameStdMap > frameStdMap_threshold;
            frameStdMap_bw_inv = ~frameStdMap_bw;
            frameStdMap_bw_final = frameStdMap_bw - frameStdMap_bw_inv;

            % Prepare ellipsoidal ring mask as a grid model
            ellips_mask_semiaxes_upper = ellips_mask_semiaxes + (floor(obj.dynamic_configuration.local_std_window_size/2) .* obj.dynamic_configuration.tilt_stretch_vector);
            ellips_mask_semiaxes_lower = ellips_mask_semiaxes - (floor(obj.dynamic_configuration.local_std_window_size/2) .* obj.dynamic_configuration.tilt_stretch_vector);

            ellips_mask_upper = obj.createEllipsMaskRotated(ellips_mask_semiaxes_upper, ellips_mask_box_size);
            ellips_mask_lower = obj.createEllipsMaskRotated(ellips_mask_semiaxes_lower, ellips_mask_box_size);

            ellips_ring_mask_plus = ellips_mask_upper - ellips_mask_lower;
            ellips_ring_mask_minus = ~ellips_ring_mask_plus;
            ellips_ring_mask = ellips_ring_mask_plus - ellips_ring_mask_minus;

            % Create frame embedded in box of grid edge mask size
            frame_embedded = zeros(size(ellips_ring_mask));
            frame_embedded_center = size(frame_embedded) / 2;
            frame_embedding_start = round(frame_embedded_center - size(frameStdMap_bw_final)/2);
            frame_embedding_end = frame_embedding_start + (size(frameStdMap_bw_final) - 1);
            x_embedding_range = frame_embedding_start(1):frame_embedding_end(1);
            y_embedding_range = frame_embedding_start(2):frame_embedding_end(2);
            frame_embedded(x_embedding_range, y_embedding_range) = frameStdMap_bw_final;

            % Find frame position relative to grid edge mask by cross-correlation
            % Order: fixed image, moving image
            cc = dynamo_cc(ellips_ring_mask, frame_embedded);

            [is_valid_grid_edge_model_inner, peak_position_inner, peak_value_inner] = obj.isValidGridEdgeModel(cc, 1, frame, frameStdMap_mean, frameStdMap_std, ellips_mask_semiaxes, ellips_mask_box_size);
            [is_valid_grid_edge_model_outer, peak_position_outer, peak_value_outer] = obj.isValidGridEdgeModel(cc, 0, frame, frameStdMap_mean, frameStdMap_std, ellips_mask_semiaxes, ellips_mask_box_size);

            if is_valid_grid_edge_model_inner || is_valid_grid_edge_model_outer
                if is_valid_grid_edge_model_inner && is_valid_grid_edge_model_outer
                    if peak_value_inner > peak_value_outer
                        peak_position = peak_position_inner;
                    else
                        peak_position = peak_position_outer;
                    end
                elseif is_valid_grid_edge_model_inner
                    peak_position = peak_position_inner;
                elseif is_valid_grid_edge_model_outer
                    peak_position = peak_position_outer;
                end
                [frame_start_position, frame_end_position] = obj.getFrameStartEndPositions(peak_position, size(frame));
                grid_edge_detected = true;
            end
        end

        function [frame_start_position, frame_end_position] = getFrameStartEndPositions(obj, peak_position, frame_size)
            peak_position = round(peak_position(1:2) + [0.5 0.5]);
            frame_start_position = peak_position - round(frame_size/2);
            frame_end_position = frame_start_position + (frame_size - 1);
        end

        function ellips_box_size = calculateRotatedEllipsEmbeddingBoxSize(obj, ellips_semiaxes, additive_extra_space)
            ellips_extremum_min = sqrt((max(ellips_semiaxes) * sin(obj.dynamic_configuration.tilt_axis_angle_rad))^2 + (min(ellips_semiaxes) * cos(obj.dynamic_configuration.tilt_axis_angle_rad))^2);
            ellips_extremum_maj = sqrt((min(ellips_semiaxes) * sin(obj.dynamic_configuration.tilt_axis_angle_rad))^2 + (max(ellips_semiaxes) * cos(obj.dynamic_configuration.tilt_axis_angle_rad))^2);
            ellips_box_size = ceil([ellips_extremum_maj ellips_extremum_min] * 2) + additive_extra_space;
        end

        function ellips_mask = createEllipsMaskRotated(obj, varargin)
            
            ellips_semiaxes = varargin{1};
            ellips_box_size = varargin{2};
            if nargin > 3
                box_x_range = varargin{3};
                box_y_range = varargin{4};
                if nargin > 5
                    smooth_mask_border = varargin{5};
                else
                    smooth_mask_border = 0;
                end
            else
                box_x_range = 1:ellips_box_size(1);
                box_y_range = 1:ellips_box_size(2);
                smooth_mask_border = 0;
            end

            ellips_center = ellips_box_size / 2;

            [Y, X] = meshgrid(box_y_range, box_x_range);
            Xsq = (((X - ellips_center(1))*cos(obj.dynamic_configuration.tilt_axis_angle_rad) + (Y - ellips_center(2))*sin(obj.dynamic_configuration.tilt_axis_angle_rad)) / ellips_semiaxes(1)).^2;
            Ysq = (((X - ellips_center(1))*sin(obj.dynamic_configuration.tilt_axis_angle_rad) - (Y - ellips_center(2))*cos(obj.dynamic_configuration.tilt_axis_angle_rad)) / ellips_semiaxes(2)).^2;
            R = Xsq + Ysq;

            if smooth_mask_border ~= 0
                pow = ones(size(R));
                pow(R < 1) = 0;
                pow = pow .* (obj.configuration.smoothing_exp_decay * (R-1));
                ellips_mask = exp(pow);
            else
                ellips_mask = R < 1;
            end
        end
    end
end