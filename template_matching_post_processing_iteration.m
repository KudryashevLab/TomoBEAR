function [tab_tomo, temporary_files] = template_matching_post_processing_iteration(configuration, binned_tomograms_paths_filtered, output_path, mask_erase)
[folder, name, extension] = fileparts(binned_tomograms_paths_filtered.folder);
name_splitted = strsplit(name, "_");
number = str2num(name_splitted{2});
% result_binarized_morphed = [];
% result_binarized_morphed_cleaned = [];
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
    %try
    
    
    if ~isfield(configuration, "tilt_index_angle_mapping") || ~isfield(configuration.tilt_index_angle_mapping, name) || isempty(configuration.tilt_index_angle_mapping.(name))
        tlt = configuration.tomograms.(name).tilt_index_angle_mapping;
        tlt(2,:) = sort(tlt(2,:));
    else
        tlt = configuration.tilt_index_angle_mapping.(name);
        tlt(2,:) = sort(tlt(2,:));
    end
    %tlt = configuration.tomograms.(name).tilt_index_angle_mapping;
    
    if ~fileExists(cc_folder + string(filesep) + 'cc.mrc')
        tab_tomo = [];
        temporary_files = "";
        return;
    end
    
    cc = dread(char(cc_folder + string(filesep) + 'cc.mrc'));
    
    
    tab_tomo = dynamo_table_blank(1);
    
    
    %try
    
    %end
    %cc = dread(['TM/tomo_' num2strtotal(i,3) '_maxcc.mrc']);
    %cc([1:20 end-21:end],:,:) = median(cc(:));
    %cc(:,[1:20 end-21:end],:) = median(cc(:));
    %cc(:,:,[1:20 end-21:end]) = median(cc(:));
    %cc = tom_bandpass(cc-mean(cc(:)),50, 100,25);
    
    % tilt_max = dread(['TM/tomo_' num2strtotal(i,3) '_tilt_max.mrc']);
    % tdrot_max = dread(['TM/tomo_' num2strtotal(i,3) '_tdrot_max.mrc']);
    % narot_max = dread(['TM/tomo_' num2strtotal(i,3) '_narot_max.mrc']);
    
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
    
    %                 L = round((size(mask_erase,1)/2)); %  + (size(mask_erase,1)/4)) distance to zero-in from the edges
    %sel = find(abs(cc) < 0.0001);
    %cc(abs(cc) < 0.0001) = median(cc(:));
    %                 cc1 = tom_bandpass(cc-mean(cc(:)),20, 60,15);
    
    
    
    
    mean_val = mean(cc(:));
    std_val = std(cc(:));
    
    if configuration.cross_correlation_mask == true
        %               mask_vol = dread('binnedMask.mrc');
        result = imhmin(cc, mean_val + (configuration.cc_std * std_val));
        result_binarized = imbinarize(result);
        result_binarized_morphed = bwmorph3(result_binarized, "clean");
        % result_binarized_morphed = bwmorph3(result_binarized_morphed, "clean");
        % result_binarized_morphed = bwmorph3(result_binarized_morphed, "clean");
        
        result_binarized_morphed = bwmorph3(result_binarized_morphed, "fill");
        
        result_binarized_morphed = bwmorph3(result_binarized_morphed, "majority");
        
        
        connected_components = bwconncomp(result_binarized_morphed);
        region_props = regionprops(connected_components, 'Area', 'PixelIdxList', 'PixelList','Centroid');
        
        % TODO: add option based on mask voxels greater than some
        % ration 1.5 e.g.
        if configuration.remove_large_correlation_clusters == true
            if configuration.use_mask_for_cluster_removal == true
                mask_path = getMask(configuration, true);
                mask_vol = dread(char(mask_path));
                cluster_size_threshold = size(find(mask_vol(mask_vol >= configuration.non_zero_voxels_threshold)), 1) * configuration.mask_non_zero_voxels_ratio;
            else
                cluster_size_threshold = mean([region_props.Area]) + configuration.cluster_std * std([region_props.Area]);
            end
            % prod(size(template_vol)) * 2l
            %cluster_size_threshold = size(find(mask_vol(mask_vol >= 0.1)), 1) * 1.5;
            
            cluster_size_threshold_indices = find([region_props.Area] > cluster_size_threshold);
            
            result_binarized_morphed_cleaned = result_binarized_morphed;
            for j = 1:length(cluster_size_threshold_indices)
                for k = 1:length(region_props(cluster_size_threshold_indices(j)).PixelList)
                    result_binarized_morphed_cleaned(region_props(cluster_size_threshold_indices(j)).PixelList(k,2),...
                        region_props(cluster_size_threshold_indices(j)).PixelList(k,1),...
                        region_props(cluster_size_threshold_indices(j)).PixelList(k,3)) = 0;
                    %         disp("" + region_props(cluster_size_threshold_indices(i)).PixelList(j,1) + " "...
                    %             + region_props(cluster_size_threshold_indices(i)).PixelList(j,2) + " "...
                    %             + region_props(cluster_size_threshold_indices(i)).PixelList(j,3));
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
        %                 else
        %                     cc1 = cc;
    end
    %cc = cc.*(1-gold_mask_all_b1);
    %                 cc1([1:L end-L-1:end],:,:) = 0;
    %                 cc1(:,[1:L end-L-1:end],:) = 0;
    %                 cc1(:,:,[1:L end-L-1:end]) = 0;
    %
    L = round((size(mask_erase,1)*configuration.exclusion_radius_box_size_ratio)); % %TODO: minimize box of mask (/2)
    %cc = tom_bandplass(cc-mean(cc(:)),50, 100,25);
    
    
    tilt_max = dread(char(cc_folder + string(filesep) + "tilt.mrc"));
    tdrot_max = dread(char(cc_folder + string(filesep) + "tdrot.mrc"));
    narot_max = dread(char(cc_folder + string(filesep) + "narot.mrc"));
    
    %cc1 = dbin(cc.0);
    disp('extracting peaks');
    
    %                 cc = gpuArray(single(cc));
    %                 mask_erase = gpuArray(single(mask_erase));
    precision = configuration.precision;
    point_file_name = char(output_path + string(filesep)...
        + "tab_" + num2str(number) + "_ini_bin_"...
        + configuration.template_matching_binning + ".points");
    fid = fopen(point_file_name, "w+");
    % this part is under construction
    %L = round(size(mask_erase,1)/2); % distance to zero-in from the edges
    counter = 0;
    while true
        [a, b] = dynamo_peak_subpixel(cc);
        % [b, a] = gpuPeak2(cc);
        
        if configuration.particle_count == counter && configuration.particle_count > 0
            break;
        end
        
        
        if configuration.particle_count == 0 && ((b < mean_val + (configuration.cc_std * std_val)) || ~any(cc(:)))
            break;
        end
        counter = counter + 1;
        %if (p < 5) disp([p a b]);end
        
        tab_tomo(counter,24:26) = [0.5,0.5,0.5] + a;%-[17 0 231];
        %                     tab_tomo{i}(p,24) = tab_tomo{i}(p,24);%-[17 0 231];
        
        tab_tomo(counter,10) = b;
        %nmask = dnan(tom_shift(mask_peak,double(a-size(mask_peak)/2)));
        %                     ar = gpuArray(round([0.5,0.5,0.5]+a));
        ar = round([0.5,0.5,0.5]+a);
        cc(ar(1)-L+1:ar(1)+L, ar(2)-L+1:ar(2)+L, ar(3)-L+1:ar(3)+L) =...
            cc(ar(1)-L+1:ar(1)+L, ar(2)-L+1:ar(2)+L, ar(3)-L+1:ar(3)+L) .* (1-mask_erase);
        %cc1 = cc1.*(1-nmask);
        %a = a*2+1;
        % TODO: perhaps interpolate
        tab_tomo(counter,7) = tdrot_max(round(a(1)),round(a(2)), round(a(3)));
        tab_tomo(counter,8) = tilt_max(round(a(1)),round(a(2)), round(a(3)));
        tab_tomo(counter,9) = narot_max(round(a(1)),round(a(2)), round(a(3)));
        %                      tab_tomo{i}(counter,7) = tdrot_max(a(1), a(2), a(3));
        %                      tab_tomo{i}(counter,8) = tilt_max(a(1), a(2), a(3));
        %                      tab_tomo{i}(counter,9) = narot_max(a(1), a(2), a(3));
        %
        tab_tomo(counter,13) = 1;
        tab_tomo(counter,14) = tlt(2,find(tlt(3,:),1,"first"));%maxangles(i,1);
        tab_tomo(counter,15) = tlt(2,find(tlt(3,:),1,"last"));%maxangles(i,2);
        tab_tomo(counter,16) = tlt(2,find(tlt(3,:),1,"first"));%maxangles(i,1);
        tab_tomo(counter,17) = tlt(2,find(tlt(3,:),1,"last"));%maxangles(i,2);
        tab_tomo(counter,20) = number;
        tab_tomo(counter,32) = 1;
        
        %global_counter = global_counter + 1;
        tab_tomo(counter,1) = counter; %global_counter;
        tab_tomo(counter,2) = 1;
        tab_tomo(counter,3) = 1;
        
        fprintf(fid, "%d %." + configuration.precision + "f %." + configuration.precision...
            + "f %." + configuration.precision...
            + "f \n", 1, round(tab_tomo(counter,24),precision),...
            round(tab_tomo(counter,25),precision),...
            round(tab_tomo(counter,26),precision));
    end
    
    model_file_name = char(output_path + string(filesep)...
        + "tab_" + num2str(number) + "_ini_bin_"...
        + configuration.template_matching_binning + "_" + num2str(counter) + ".model");
    system("point2model " + point_file_name + " " + model_file_name);
    fclose(fid);
    
    if configuration.cross_correlation_mask == true
        dwrite(result_binarized_morphed, output_path + string(filesep)...
            + "tab_" + num2str(number) + "_ini_bin_"...
            + configuration.template_matching_binning + "_" + num2str(counter) + "_mask.mrc");
        if configuration.remove_large_correlation_clusters == true
            dwrite(result_binarized_morphed_cleaned, output_path + string(filesep)...
                + "tab_" + num2str(number) + "_ini_bin_"...
                + configuration.template_matching_binning + "_" + num2str(counter) + "_mask_cleaned.mrc");
        end
    end
    
    % merge tables here
    %tomo_name = ['/sbdata/EM/projects/wechen/motor/WT_100/tomos/tomo' num2strtotal(i,3) '_bin4.mrc'];
    %tomo_name = ['tomos_all2/tomo' num2strtotal(i,3) '_bin8.rec'];
    %tomo = dread(tomo_name['tomos/tomo'  num2strtotal(i,3) '_bin4.mrc']);
    %tomo =  dynamo_normalize_roi(tomo);
    %     if configuration.crop_particles == true
    %         if configuration.all_in_one_folder == false
    %             particles_folder = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.particles_folder + string(filesep) + name + "_bin_" + configuration.template_matching_binning;
    %             dtcrop(char(binned_tomograms_paths_filtered.folder + string(filesep) + binned_tomograms_paths_filtered.name), tab_tomo, char(particles_folder), size(mask_erase, 1), 'allow_padding', 1, 'inmemory',1 , 'maxMb', 50000);
    %         else
    %             particles_folder = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.particles_folder + string(filesep) + "particles_bin_" + configuration.template_matching_binning;
    %             dtcrop(char(binned_tomograms_paths_filtered.folder + string(filesep) + binned_tomograms_paths_filtered.name), tab_tomo, char(particles_folder), size(mask_erase, 1), 'allow_padding', 1, 'inmemory',1 , 'maxMb', 50000, 'append_tags', true);
    %         end
    %     end
    %tab = dread(char(particles_folder + string(filesep) + "crop.tbl"));
    %tab_all(end+1:end+N,:) = tab;
    %                     if system(['mv particles_bin8_tmp/*em particles_bin8/'])
    %                         system(['mkdir particles_bin8']);
    %                     end
    %catch
    %disp(lasterr);
    %end
    dwrite(tab_tomo, char(output_path + string(filesep) + "tab_" + num2str(number) + "_ini_bin_" + configuration.template_matching_binning + "_" + num2str(counter) + ".tbl"));
    fid = fopen(output_path + string(filesep) + "SUCCESS_" + num2str(number), "w");
    fclose(fid);
else
    table_file_path = dir(output_path + string(filesep) + "tab_" + num2str(number) + "_ini_bin_" + configuration.template_matching_binning + "_*.tbl");
    tab_tomo = dread(char(table_file_path(1).folder + string(filesep) + table_file_path(1).name));
end
end

