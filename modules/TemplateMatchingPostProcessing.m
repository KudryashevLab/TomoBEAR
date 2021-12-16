classdef TemplateMatchingPostProcessing < Module
    methods
        function obj = TemplateMatchingPostProcessing(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "particles_folder", true);
            createStandardFolder(obj.configuration, "particles_table_folder", true);
        end
        
        function obj = process(obj)
            rec_resampled = getMask(obj.configuration);
            % TODO: introduce fraction of volume to erase as parameter
            if obj.configuration.mask_gaussian_fall_off == true
                if mod(size(rec_resampled,1),2) ~= 0
                    mask_gaussian_fall_off = (size(rec_resampled) + 1)/4;
                else
                    mask_gaussian_fall_off = size(rec_resampled)/4;
                end
            else
                mask_gaussian_fall_off = 0;
            end
            
            if mod(size(rec_resampled,1),2) ~= 0
                mask_erase = dynamo_ellipsoid((size(rec_resampled) + 1)*obj.configuration.exclusion_radius_box_size_ratio, size(rec_resampled,1) + 1, (size(rec_resampled,1) + 1)/2, mask_gaussian_fall_off);
            else
                mask_erase = dynamo_ellipsoid(size(rec_resampled)*obj.configuration.exclusion_radius_box_size_ratio, size(rec_resampled,1), size(rec_resampled,1)/2, mask_gaussian_fall_off);
            end

            binned_tomograms_paths = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
            if isempty(binned_tomograms_paths) == true
                binned_tomograms_paths = getBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
            end
            binned_tomograms_paths_filtered = binned_tomograms_paths(contains({binned_tomograms_paths.name}, "bin_" + obj.configuration.template_matching_binning));
            temporary_files = string([]);
            output_path = obj.output_path;
            if obj.configuration.parallel_execution == true
                configuration = obj.configuration;
                parfor i = 1:length(binned_tomograms_paths_filtered)
                    [tab_tomo{i}, temporary_files(i)] = template_matching_post_processing_iteration(configuration, binned_tomograms_paths_filtered(i), output_path, mask_erase);
                end
            else
                for i = 1:length(binned_tomograms_paths_filtered)
                    [tab_tomo{i}, temporary_files(i)] = template_matching_post_processing_iteration(obj.configuration, binned_tomograms_paths_filtered(i), output_path, mask_erase);
                end
            end
            obj.temporary_files = temporary_files;
            if obj.configuration.box_size >= 1 && obj.configuration.box_size <= 10
                box_size = round(size(mask_erase, 1) * obj.configuration.box_size);
            else
                box_size = obj.configuration.box_size;
            end
            if mod(box_size, 2) == 1
                disp("INFO: resulting box size is odd, adding 1 to make it even!")
                box_size = box_size + 1;
            end
            tab_all = zeros([size(tab_tomo{1}, 1), 35]);
            sum_particles_previous_table = 0;
            particles_to_be_cropped = obj.configuration.particles_to_be_cropped;
            break_flag = false;
            for i = 1:length(tab_tomo)
                if tab_tomo{i}(1,20) == 0
                    continue;
                end
                if i == 1
                    tab_all(1:end, :) = tab_tomo{i};
                else
                    tab_tomo_tmp = tab_tomo{i};
                    tab_tomo_tmp(:,1) = tab_tomo{i}(:,1) + sum_particles_previous_table;
                    tab_all(end + 1:end + size(tab_tomo{i}, 1), :) = tab_tomo_tmp;
                end
                
                tomogram_paths{tab_tomo{i}(1,20)} = char(binned_tomograms_paths_filtered(i).folder + string(filesep) + binned_tomograms_paths_filtered(i).name);
                sum_particles_previous_table = sum_particles_previous_table + tab_tomo{i}(end, 1);
                if obj.configuration.particles_to_be_cropped > 0
                    if sum_particles_previous_table > obj.configuration.particles_to_be_cropped && obj.configuration.particles_to_be_cropped > 0
                        tab_all(obj.configuration.particles_to_be_cropped + 1:end, :) = [];
                        tab_tomo{i}(particles_to_be_cropped + 1:end, :) = [];
                        break_flag = true;
                    else
                        particles_to_be_cropped = particles_to_be_cropped - sum_particles_previous_table;
                        break_flag = false;
                    end
                else
                    break_flag = false;
                end
                
                % TODO: integrate SUSAN
                if obj.configuration.crop_particles == true
                    if obj.configuration.all_in_one_folder == true
                        particles_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + obj.configuration.template_matching_binning  + "_bs_" + box_size;
                        dtcrop(char(binned_tomograms_paths_filtered(i).folder + string(filesep) + binned_tomograms_paths_filtered(i).name), tab_tomo{i}, char(particles_folder), box_size, 'allow_padding', 1, 'inmemory',1 , 'maxMb', 50000, 'append_tags', true, 'asBoxes', 0);
                    else
                        [folder, name, extension] = fileparts(binned_tomograms_paths_filtered(i).folder);
                        particles_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + obj.configuration.template_matching_binning  + "_bs_" + box_size + string(name);
                        dtcrop(char(binned_tomograms_paths_filtered(i).folder + string(filesep) + binned_tomograms_paths_filtered(i).name), tab_tomo{i}, char(particles_folder), box_size, 'allow_padding', 1, 'inmemory',1 , 'maxMb', 50000, 'append_tags', true, 'asBoxes', 0);
                    end
                end
                if break_flag == true
                	break;
                end
            end
            
            % TODO: integrate SUSAN
            if obj.configuration.crop_particles == true && obj.configuration.as_boxes == 1
                if obj.configuration.all_in_one_folder == true
                    particles_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + obj.configuration.template_matching_binning + "_bs_" + box_size;
                    ownDbox(string(particles_folder),string([char(particles_folder) '.Boxes']));
                    % TODO: make flag for leaving original particles
                    % folder
                    [status, message, messageid] = rmdir(char(particles_folder), 's');
                end
            end
            
            tab_all_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder;
            
            dwrite(tab_all, char(tab_all_path + string(filesep) + "tab_ini_all_bin_" + obj.configuration.template_matching_binning + "_" + num2str(size(tab_all,1)) + ".tbl"));
        end
        
        function connected_components(obj)
            cc_vol = dread('cc.mrc');
            template_vol = dread('binnedTemplate.mrc');
            mask_vol = dread('binnedMask.mrc');
            
            dtmshow(cc_vol)
            result = imhmin(cc_vol, mean(cc_vol(:)) + 2 * std(cc_vol(:)));
            result_binarized = imbinarize(result);
            result_binarized_morphed = bwmorph3(result_binarized, "clean");
            result_binarized_morphed = bwmorph3(result_binarized_morphed, "fill");
            result_binarized_morphed = bwmorph3(result_binarized_morphed, "majority");
            connected_components = bwconncomp(result_binarized_morphed);
            region_props = regionprops(connected_components, 'Area', 'PixelIdxList', 'PixelList','Centroid');
            cluster_size_threshold = mean([region_props.Area]) + 2 * std([region_props.Area]);
            cluster_size_threshold_indices = find([region_props.Area] > cluster_size_threshold);
            result_binarized_morphed_cleaned = result_binarized_morphed;
            for i = 1:length(cluster_size_threshold_indices)
                for j = 1:length(region_props(cluster_size_threshold_indices(i)).PixelList)
                    result_binarized_morphed_cleaned(region_props(cluster_size_threshold_indices(i)).PixelList(j,2),...
                        region_props(cluster_size_threshold_indices(i)).PixelList(j,1),...
                        region_props(cluster_size_threshold_indices(i)).PixelList(j,3)) = 0;
                end
            end
            region_props(cluster_size_threshold_indices) = [];
            
            dtmshow(result_binarized_morphed_cleaned)
            
            precision = 2;
            file_name = "table.points";
            fid = fopen(file_name, "w+");
            for i = 1:length(region_props)
                fprintf(fid, "%d %." + precision + "f %." + precision + "f %." + precision + "f \n", i, round(region_props(i).Centroid(2),precision),...
                    round(region_props(i).Centroid(1),precision),...
                    round(region_props(i).Centroid(3),precision));
            end
            fclose(fid);
            dwrite(result_binarized_morphed_cleaned, "result.mrc");
            system("point2model " + file_name + " " + "table.model")
        end
        
        function [dynamic_configuration]= process2(obj, current_tomogram_index)
            dynamo_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.dynamo_folder;
            tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true);
            tiltIndexAngleMapping = getTiltIndexAngleMapping(obj.configuration);
            for i = 1:length(tomograms)
                [path, name, extension] = fileparts(tomograms(i).folder);
                tomogram_path = tomograms(i).folder + string(filesep) + tomograms(i).name;
                dynamo_template_matching_path = dynamo_folder + string(filesep) + name + string(filesep) + name;
                dynamo_template_matching_files = dir(dynamo_template_matching_path);
  
            end
        end
        
        function obj = cleanUp(obj)
            if obj.configuration.keep_intermediates == false
                field_names = fieldnames(obj.configuration.tomograms);
                for i = 1:length(field_names)
                    name = field_names{i};
                    % TODO: flag for keep cross correlation volume
                    [success, message, message_id] = rmdir(obj.configuration.processing_path + string(filesep)...
                        + obj.configuration.output_folder + string(filesep)...
                        + obj.configuration.dynamo_folder + string(filesep)...
                        + name + string(filesep) + name + ".TM", "s");
                    if (obj.configuration.reconstruct == "unbinned" ||...
                            obj.configuration.reconstruct == "full" ||...
                            obj.configuration.reconstruct == "both" ||...
                            obj.configuration.reconstruct == "all") && obj.configuration.keep_unbinned == false
                        [success, message, message_id] = rmdir(obj.configuration.processing_path + string(filesep)...
                            + obj.configuration.output_folder + string(filesep)...
                            + obj.configuration.tomograms_folder + string(filesep)...
                            + name, "s");
                    end
                    if (obj.configuration.reconstruct == "binned" ||...
                            obj.configuration.reconstruct == "both" ||...
                            obj.configuration.reconstruct == "all") && obj.configuration.keep_binned == false
                        [success, message, message_id] = rmdir(obj.configuration.processing_path + string(filesep)...
                            + obj.configuration.output_folder + string(filesep)...
                            + obj.configuration.binned_tomograms_folder + string(filesep)...
                            + name, "s");
                    end
                end
            end
            obj = cleanUp@Module(obj);
        end
    end
end
