function [tab_tomo, temporary_files] = template_matching_post_processing_iteration(configuration, binned_tomograms_paths_filtered, output_path, mask_erase)
[folder, name, extension] = fileparts(binned_tomograms_paths_filtered.folder);
name_splitted = strsplit(name, "_");
number = str2num(name_splitted{2});
cc_folder = char(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep)...
    + configuration.dynamo_folder + string(filesep)...
    + name + string(filesep) + name + ".TM");

if configuration.keep_intermediates == true
    temporary_files = "";
else
    temporary_files = string(cc_folder);
end

if ~fileExists(output_path + string(filesep) + "SUCCESS_" + number)
    if ~isfield(configuration, "tilt_index_angle_mapping") || ~isfield(configuration.tilt_index_angle_mapping, name) || isempty(configuration.tilt_index_angle_mapping.(name))
        tlt = configuration.tomograms.(name).tilt_index_angle_mapping;
        tlt(2,:) = sort(tlt(2,:));
    else
        tlt = configuration.tilt_index_angle_mapping.(name);
        tlt(2,:) = sort(tlt(2,:));
    end
    if ~fileExists(cc_folder + string(filesep) + 'cc.mrc')
        tab_tomo = [];
        temporary_files = "";
        return;
    end
    cc = dread(char(cc_folder + string(filesep) + 'cc.mrc'));
    tab_tomo = dynamo_table_blank(1);
    half_mask_size = round(size(mask_erase,1)/2 + (size(mask_erase,1)/4));
    cc(1:half_mask_size,:,:) = 0;
    cc(:,1:half_mask_size,:) = 0;
    cc(:,:,1:half_mask_size) = 0;
    cc(end-half_mask_size:end,:,:) = 0;
    cc(:,end-half_mask_size:end,:) = 0;
    cc(:,:,end-half_mask_size:end) = 0;

    % TODO:NOTE: probably not necessary
    if std(cc(:)) == 0
        return;
    end
    
    mean_val = mean(cc(:));
    std_val = std(cc(:));
    
    if configuration.cross_correlation_mask == true
        result = imhmin(cc, mean_val + (configuration.cc_std * std_val));
        result_binarized = imbinarize(result);
        result_binarized_morphed = bwmorph3(result_binarized, "clean");
        result_binarized_morphed = bwmorph3(result_binarized_morphed, "fill");
        result_binarized_morphed = bwmorph3(result_binarized_morphed, "majority");
        connected_components = bwconncomp(result_binarized_morphed);
        region_props = regionprops(connected_components, 'Area', 'PixelIdxList', 'PixelList','Centroid');
        
        % TODO: add option based on mask voxels greater than some
        % ratio 1.5 e.g.
        if configuration.remove_large_correlation_clusters == true
            if configuration.use_mask_for_cluster_removal == true
                mask_path = getMask(configuration, true);
                mask_vol = dread(char(mask_path));
                cluster_size_threshold = size(find(mask_vol(mask_vol >= configuration.non_zero_voxels_threshold)), 1) * configuration.mask_non_zero_voxels_ratio;
            else
                cluster_size_threshold = mean([region_props.Area]) + configuration.cluster_std * std([region_props.Area]);
            end
            
            cluster_size_threshold_indices = find([region_props.Area] > cluster_size_threshold);
            
            result_binarized_morphed_cleaned = result_binarized_morphed;
            for j = 1:length(cluster_size_threshold_indices)
                for k = 1:length(region_props(cluster_size_threshold_indices(j)).PixelList)
                    result_binarized_morphed_cleaned(region_props(cluster_size_threshold_indices(j)).PixelList(k,2),...
                        region_props(cluster_size_threshold_indices(j)).PixelList(k,1),...
                        region_props(cluster_size_threshold_indices(j)).PixelList(k,3)) = 0;
                end
            end
            cc = cc .* result_binarized_morphed_cleaned;
        else
            cc = cc .* result_binarized_morphed;
        end
    end

    if configuration.bandpass_cc_volume == true
        if bandpass_cc_low_pass == 0
            cc = tom_bandpass(cc, configuration.bandpass_cc_high_pass, size(cc),bandpass_cc_smoothing);
        else
            cc = tom_bandpass(cc, configuration.bandpass_cc_high_pass, configuration.bandpass_cc_low_pass, bandpass_cc_smoothing);
        end
    end
    
    L = round((size(mask_erase,1)*configuration.exclusion_radius_box_size_ratio));

    tilt_max = dread(char(cc_folder + string(filesep) + "tilt.mrc"));
    tdrot_max = dread(char(cc_folder + string(filesep) + "tdrot.mrc"));
    narot_max = dread(char(cc_folder + string(filesep) + "narot.mrc"));
    
    disp('extracting peaks');

    precision = configuration.precision;

    counter = 0;
    while true
        [a, b] = dynamo_peak_subpixel(cc);
       
        if configuration.particle_count == counter && configuration.particle_count > 0
            break;
        end
        
        
        if configuration.particle_count == 0 && ((b < mean_val + (configuration.cc_std * std_val)) || ~any(cc(:)))
            break;
        end
        if counter == 0 
        	point_file_name = char(output_path + string(filesep)...
                + "tab_" + num2str(number) + "_ini_bin_"...
                + configuration.template_matching_binning + ".points");
            fid = fopen(point_file_name, "w+");
        end
        counter = counter + 1;
        
        tab_tomo(counter,24:26) = [0.5,0.5,0.5] + a;
        
        tab_tomo(counter,10) = b;

        ar = round([0.5,0.5,0.5]+a);
        cc(ar(1)-L+1:ar(1)+L, ar(2)-L+1:ar(2)+L, ar(3)-L+1:ar(3)+L) =...
            cc(ar(1)-L+1:ar(1)+L, ar(2)-L+1:ar(2)+L, ar(3)-L+1:ar(3)+L) .* (1-mask_erase);

        % TODO: perhaps interpolate
        tab_tomo(counter,7) = tdrot_max(round(a(1)),round(a(2)), round(a(3)));
        tab_tomo(counter,8) = tilt_max(round(a(1)),round(a(2)), round(a(3)));
        tab_tomo(counter,9) = narot_max(round(a(1)),round(a(2)), round(a(3)));
        tab_tomo(counter,13) = 1;
        tab_tomo(counter,14) = tlt(2,find(tlt(3,:),1,"first"));
        tab_tomo(counter,15) = tlt(2,find(tlt(3,:),1,"last"));
        tab_tomo(counter,16) = tlt(2,find(tlt(3,:),1,"first"));
        tab_tomo(counter,17) = tlt(2,find(tlt(3,:),1,"last"));
        tab_tomo(counter,20) = number;
        tab_tomo(counter,32) = 1;

        tab_tomo(counter,1) = counter;
        tab_tomo(counter,2) = 1;
        tab_tomo(counter,3) = 1;
        
        fprintf(fid, "%d %." + configuration.precision + "f %." + configuration.precision...
            + "f %." + configuration.precision...
            + "f \n", 1, round(tab_tomo(counter,24),precision),...
            round(tab_tomo(counter,25),precision),...
            round(tab_tomo(counter,26),precision));
    end
    if counter ~= 0 
        model_file_name = char(output_path + string(filesep)...
            + "tab_" + num2str(number) + "_ini_bin_"...
            + configuration.template_matching_binning + "_" + num2str(counter) + ".model");
        system("point2model " + point_file_name + " " + model_file_name);
        fclose(fid);
    end
    if configuration.cross_correlation_mask == true
        dwrite(result_binarized_morphed, output_path + string(filesep)...
            + "tab_" + num2str(number) + "_ini_bin_"...
            + configuration.template_matching_binning + "_" + num2str(counter) + "_mask.mrc");
        if configuration.remove_large_correlation_clusters == true
            dwrite(result_binarized_morphed_cleaned, output_path...
                + string(filesep) + "tab_" + num2str(number) + "_ini_bin_"...
                + configuration.template_matching_binning + "_"...
                + num2str(counter) + "_mask_cleaned.mrc");
        end
    end
    if tab_tomo(1,20) ~= 0
        dwrite(tab_tomo, char(output_path + string(filesep)...
            + "tab_" + num2str(number) + "_ini_bin_"...
            + configuration.template_matching_binning + "_"...
            + num2str(counter) + ".tbl"));
        fid = fopen(output_path + string(filesep)...
            + "SUCCESS_" + num2str(number), "w");
        fclose(fid);
    else
        fid = fopen(output_path + string(filesep)...
            + "FAILURE_" + num2str(number), "w");
        fclose(fid);
    end
else
    table_file_path = dir(output_path + string(filesep)...
        + "tab_" + num2str(number) + "_ini_bin_"...
        + configuration.template_matching_binning + "_*.tbl");
    tab_tomo = dread(char(table_file_path(1).folder + string(filesep)...
        + table_file_path(1).name));
end
end

