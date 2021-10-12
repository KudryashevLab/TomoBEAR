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
            %             addpath /home/mikudrya/procedures/setpathme/tom_good_old/Filtrans/
            %             addpath /home/mikudrya/procedures/setpathme/tom_good_old/Geom/
            %             addpath /home/mikudrya/procedures/setpathme/bol_scripts
            %             addpath /sbdata/PTMP/nibalysc/helper/gpu/
            %             addpath /sbdata/PTMP/nibalysc/helper/
            
            %             mask_peak = dynamo_ellipsoid([20 20 25],720,[361 361 361], 3);
            %             mask_peak = dbin(mask_peak(:,:,211:510),0);
            %             mask_peak = mask_peak(105:104+512,:,:);
            %rec = dread('ref_ini_18A_320.mrc');
            %recn = dbin(rec,3);
            %rec_resampled = dbin(dynamo_rescale(recn, 1.7, 1.4),0);
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
                mask_erase = dynamo_ellipsoid((size(rec_resampled) + 1)/4, size(rec_resampled,1) + 1, (size(rec_resampled,1) + 1)/2, mask_gaussian_fall_off);
            else
                mask_erase = dynamo_ellipsoid(size(rec_resampled)/4, size(rec_resampled,1), size(rec_resampled,1)/2, mask_gaussian_fall_off);
            end
            
            %tab_all = dread('tab_ini_bin8_2_32500.tbl');
            binned_tomograms_paths = getBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
            if isempty(binned_tomograms_paths) == true
                binned_tomograms_paths = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
            end
            binned_tomograms_paths_filtered = binned_tomograms_paths(contains({binned_tomograms_paths.name}, "bin_" + obj.configuration.template_matching_binning));
            %mask_gold = dynamo_ellipsoid([14 14 18], 36);
            % TODO: check for particle counts in table name
            %             for i = 1:length(binned_tomograms_paths_filtered)
            temporary_files = string([]);
            %             for i = 1:length(binned_tomograms_paths_filtered)
            % TODO: parallel and non parallel mode
            %             global_counter = 0;
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
            
%             obj.dynamic_configuration.box_size = obj.configuration.box_size;
            
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
                if obj.configuration.crop_particles == true % && obj.configuration.as_boxes == 0
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
                %dBoxes('create', char([particles_folder '.Boxes']))
                if obj.configuration.all_in_one_folder == true
                    particles_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + obj.configuration.template_matching_binning + "_bs_" + box_size;
                    %dBoxes.convertSimpleData(char(particles_folder),char([char(particles_folder) '.Boxes']),'batch',obj.configuration.particle_batch,'dc',obj.configuration.direct_copy);
                    ownDbox(string(particles_folder),string([char(particles_folder) '.Boxes']));
                    % TODO: make flag for leaving original particles
                    % folder
                    [status, message, messageid] = rmdir(char(particles_folder), 's');
%                     movefile(char([char(particles_folder) '.Boxes']), char(particles_folder));
%                 	particles_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + obj.configuration.template_matching_binning;
%                     dtcrop(tomogram_paths, tab_all, char(particles_folder), box_size, 'allow_padding', 1, 'inmemory',1 , 'maxMb', 50000, 'append_tags', true, 'asBoxes', obj.configuration.as_boxes);
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
            %peaks = houghpeaks(double(cc_vol),1000);
            result = imhmin(cc_vol, mean(cc_vol(:)) + 2 * std(cc_vol(:)));
            result_binarized = imbinarize(result);
            result_binarized_morphed = bwmorph3(result_binarized, "clean");
            % result_binarized_morphed = bwmorph3(result_binarized_morphed, "clean");
            % result_binarized_morphed = bwmorph3(result_binarized_morphed, "clean");
            
            result_binarized_morphed = bwmorph3(result_binarized_morphed, "fill");
            
            result_binarized_morphed = bwmorph3(result_binarized_morphed, "majority");
            
            
            connected_components = bwconncomp(result_binarized_morphed);
            region_props = regionprops(connected_components, 'Area', 'PixelIdxList', 'PixelList','Centroid');
            cluster_size_threshold = mean([region_props.Area]) + 2 * std([region_props.Area]);
            
            % prod(size(template_vol)) * 2
            %cluster_size_threshold = size(find(mask_vol(mask_vol >= 0.1)), 1) * 1.5;
            
            cluster_size_threshold_indices = find([region_props.Area] > cluster_size_threshold);
            
            result_binarized_morphed_cleaned = result_binarized_morphed;
            for i = 1:length(cluster_size_threshold_indices)
                for j = 1:length(region_props(cluster_size_threshold_indices(i)).PixelList)
                    result_binarized_morphed_cleaned(region_props(cluster_size_threshold_indices(i)).PixelList(j,2),...
                        region_props(cluster_size_threshold_indices(i)).PixelList(j,1),...
                        region_props(cluster_size_threshold_indices(i)).PixelList(j,3)) = 0;
                    %         disp("" + region_props(cluster_size_threshold_indices(i)).PixelList(j,1) + " "...
                    %             + region_props(cluster_size_threshold_indices(i)).PixelList(j,2) + " "...
                    %             + region_props(cluster_size_threshold_indices(i)).PixelList(j,3));
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
                
                
                %templateMatchingTomogramMask(tomogram_path, tiltIndexAngleMapping(tomograms(i).name), )
                
                
                %processCCVolume(configuration, dynamo_template_matching_path);
                %
                %         pts{j+1}.showCC;
                %         pts{j+1}.peaks.plotCCPeaks('sidelength',32);
                %         particle_table{j+1} = pts{j+1}.peaks.computeTable('mcc',0.1);
                %
                %         % TODO: find a more genral name or split visualizations logically and
                %         % introduce new variables
                %         if configuration.show_cross_correlations == true
                %             dtplot(particle_table{j+1},'pf','oriented_positions');
                %             pts{j+1}.peaks.browse();
                %             ddbrowse('d',tomogram_path,'t',particle_table{j+1});
                %         end
                %
                %         if configuration.randomize_angles == false
                %             oap{j+1} = pts{j+1}.peaks.average(template_size(1));
                %         else
                %             oap{j+1} = pts{j+1}.peaks.average(template_size(1),'ra',1);
                %         end
                %
                %         if configuration.show_generated_template == true
                %             dview(oap{j+1});
                %         end
                %
                %         [tomo_path, tomo_name, tomo_extension] = fileparts(tomograms(i).name);
                %         tomo_name = strsplit(tomo_name, "_");
                %         binning_factor = strsplit(tomo_name{end}, ".");
                %         binning_factor = num2str(binning_factor{1});
                %         table_original_scale{j+1} = dynamo_table_rescale(particle_table{j+1}, 'factor', (configuration.apix * binning_factor) / configuration.apix);
                %         % NOTE: particles can also be cropped with help of "dtcrop(...)"
                %
                %         % NOTE: In the syntax of dynamo_table_rescale, the factor is expressed in terms of how many times is the apix in the original table bigger than in the target table to be computed
                %         if configuration.show_table == true
                %             dtinfo(table_original_scale{j+1});
                %         end
                
                % NOTE:
                %         table_original_scale_centered_crop_points{j+1} = dpktbl.centerCropPoints(table_original_scale{j+1});
                
                %         dwrite(table_original_scale_centered_crop_points{j+1}, char(name + "_" + in_plane_rotation_angle + "_initial_peaks.tbl"));
                % Entering result in catalogue
                %         dmimport('t', char(dynamo_folder + string(filesep) + name + "_" + in_plane_rotation_angle + "_initial_peaks.tbl"), 'c', char(name), 'i', i, 'mn', 'cc_peaks');
                %end
                
                %     [combined_volume, combined_tdrot, combined_tilt, combined_narot] = combineCCVolumes(dynamo_template_matching_path);
                %     dwrite(combined_volume, char(dynamo_folder + string(filesep) + name + string(filesep) + "combined_volume.mrc"));
                %     dwrite(combined_tdrot, char(dynamo_folder + string(filesep) + name + string(filesep) + "combined_tdrot.mrc"));
                %     dwrite(combined_tilt, char(dynamo_folder + string(filesep) + name + string(filesep) + "combined_tilt.mrc"));
                %     dwrite(combined_narot, char(dynamo_folder + string(filesep) + name + string(filesep) + "combined_narot.mrc"));
                
                % NOTE: lists models
                %dcm('c', char(name), 'i', i, 'l', 'm');
                
                % Keeping peaks inside the selected polygon
                %     dcmodels(name, 'nc', 'peaks', 'ws', 'output');
                %     p = dread(output.files{1});
                %     dcmodels(name, 'nc', 'bound', 'ws', 'output');
                %     b = dread(output.files{1});
                %
                %     pXZ = p.points(:,[1,3]);
                %     bXZ = b.points(:,[1,3]);
                %     indicesOfPInsideB = inpolygon(pXZ(:,1),pXZ(:,2),bXZ(:,1),bXZ(:,2));
                
                % Plotting the kept peaks
                %     f = figure();
                %     hs1 = subplot(2,1,1);
                %     h = dpkgeom.plotCloud(p.points); axis equal
                %     h.Marker = '.';
                %     view([0,1,0]);
                %     hs1.ZLim = [0,200];
                %     hs1.XLim = [0,1000];
                %     title('Original peaks');
                %
                %     hs2 = subplot(2,1,2);
                %     h = dpkgeom.plotCloud(p.points(indicesOfPInsideB,:));
                %     axis equal;
                %     h.Marker = '.';
                %     hold on;
                %     hB = dpkgeom.plotCloud(b.points);
                %     axis equal;
                %     hB.Marker = 'o';
                %     hB.LineStyle = '--';
                %     hB.MarkerFaceColor = 'b';
                %     hB.Color = 'k';
                %     title('Peaks inside boundary');
                %     view([0,1,0]);
                %     axis(hs2,axis(hs1));
            end
        end
        
        function obj = cleanUp(obj)
            if obj.configuration.keep_intermediates == false
                field_names = fieldnames(obj.configuration.tomograms);
                %parfor i = 1:length(field_names)
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
