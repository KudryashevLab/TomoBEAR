classdef DynamoTemplateMatching < Module
    methods
        function obj = DynamoTemplateMatching(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "dynamo_folder", false);
        end
        
        function obj = process(obj)
            if obj.configuration.set_up.gpu > 0
                gpuDevice(obj.configuration.set_up.gpu );
            else
                error("ERROR: Gpus are needed to run this module!")
            end
            dynamo_folder = obj.output_path;
            return_path = cd(dynamo_folder);
            %dynamo_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.dynamo_folder;
            
            if obj.configuration.use_ctf_corrected_tomograms == true
                if obj.configuration.use_denoised_tomograms == true
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getDenoisedCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getDenoisedCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                else
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end
            else
                if obj.configuration.use_denoised_tomograms == true
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getDenoisedBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getDenoisedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                else
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end
            end
            
            % TODO: if wrong template binning is set get the next lower available binning
            template_path = getTemplate(obj.configuration, true);
            
            mask_path = getMask(obj.configuration, true);
            %min_and_max_tilt_angles = getMinAndMaxTiltAnglesFromTiltFile(obj.configuration);
            field_names = fieldnames(obj.configuration.tomograms);
            %for i = 1:length(tomograms) / length(obj.configuration.binnings)
            
            min_and_max_tilt_angles = getTiltAngles(obj.configuration);

            %output = executeCommand("header -size " + template_path);
            [status_system, output] = system("header -size " + template_path);
            
            template_size = str2num(output);
            % NOTE: assumption is that pixel size is isotropic in all directions
            if obj.configuration.size_of_chunk(1) > template_size(1) * 2
                size_of_chunk = obj.configuration.size_of_chunk;
            else
                size_of_chunk = template_size * 3;
            end
            
            if isfield(obj.configuration, "template_transform") && obj.configuration.template_transform == "flip_handedness"
                template = dread(char(template_path));
                mask = dread(char(mask_path));
                template = flip(template, 1);
                mask = flip(mask, 1);
            elseif isfield(obj.configuration, "template_transform") && obj.configuration.template_transform == "symmetrize"
                template = dread(char(template_path));
                mask = dread(char(mask_path));
                template = dsym(template, obj.configuration.symmetry);
                mask = dsym(mask, obj.configuration.symmetry);
            elseif isfield(obj.configuration, "template_transform") && obj.configuration.template_transform == "none"
                template = dread(char(template_path));
                mask = dread(char(mask_path));
            else
                % TODO: this will not work with in plane rotations
                template = char(template_path);
                mask = char(mask_path);
            end
            
            % TODO: do something about the fact when a string and numric variable is
            % allowed
            if isfield(obj.configuration, "matlab_workers") && obj.configuration.matlab_workers == 0
                matlab_workers = 0;
            elseif isfield(obj.configuration, "matlab_workers") && obj.configuration.matlab_workers < 0
                matlab_workers = obj.environment_properties.cpu_count / 2;
            else
                matlab_workers = obj.configuration.matlab_workers;
            end
            
            
            %for i = 1:length(tomograms)
%             [path, name, extension] = fileparts(tomograms(obj.configuration.set_up.j).folder);
            [path, name, extension] = fileparts(dynamo_folder);
            dynamo_template_matching_path = dynamo_folder + string(filesep) + name;
            
            selected_tomogram = contains({tomograms(:).name}, field_names{obj.configuration.set_up.j});
            if any(selected_tomogram)
                tomogram_path = tomograms(selected_tomogram).folder + string(filesep) + tomograms(selected_tomogram).name;
            end
            
%            if obj.configuration.tomogram_begin ~= 0 && obj.configuration.tomogram_end ~= 0
%                tomogram_path = tomograms(obj.configuration.tomogram_begin + obj.configuration.set_up.adjusted_j - 1).folder + string(filesep) + tomograms(obj.configuration.tomogram_begin + obj.configuration.set_up.adjusted_j - 1).name;
%            else
%                tomogram_path = tomograms(obj.configuration.set_up.adjusted_j).folder + string(filesep) + tomograms(obj.configuration.set_up.adjusted_j).name;
%            end
            %loop_count = configuration.in_plane_range / configuration.in_plane_sampling;
            %loop_count = 0;
            %for j = 0:loop_count
            %rotation_matrix = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1];
            %in_plane_rotation_angle = obj.configuration.in_plane_sampling * j;
            %         if in_plane_rotation_angle ~= 0
            %             rotation_matrix = gpuEulerToMatrix([0 0 in_plane_rotation_angle], "matrixOperation", "interpolation", "volumeSize", length(template));
            %             rotated_template = gather(gpuRotate(template, rotation_matrix));
            %             rotated_mask = gather(gpuRotate(mask, rotation_matrix));
            %         else
            %                 rotated_template = template;
            %                 rotated_mask = mask;
            %         end
            
            if obj.configuration.matlab_workers ~= -1
                matlab_workers = obj.configuration.matlab_workers;
            else
                matlab_workers = obj.configuration.environment_properties.cpu_count_physical;
            end
           
            newStr = extractBetween(obj.configuration.expected_symmetrie,2,length(obj.configuration.expected_symmetrie{1}));
            symmetry_order = str2num(newStr);
            cone_range = obj.configuration.cone_range / symmetry_order;
            in_plane_range = obj.configuration.in_plane_range / symmetry_order;

            %                 obj.dynamic_configuration.inplane_range = inplane_range;
            %                 obj.dynamic_configuration.cone_range = cone_range;
            
            if obj.configuration.auto_detect_sampling == true
                in_plane_sampling = asind(obj.configuration.auto_detect_sampling_multiplication_factor/(length(template)/2));
                cone_sampling = asind(obj.configuration.auto_detect_sampling_multiplication_factor/(length(template)/2));
            else
                if (isfield(obj.configuration, "sampling") && obj.configuration.sampling <= 0) || ~isfield(obj.configuration, "sampling")
                    in_plane_sampling = obj.configuration.in_plane_sampling;
                    cone_sampling = obj.configuration.cone_sampling;
                    obj.dynamic_configuration.in_plane_sampling = in_plane_sampling;
                    obj.dynamic_configuration.cone_sampling = cone_sampling;
                elseif isfield(obj.configuration, "sampling") && obj.configuration.sampling > 0
                    in_plane_sampling = obj.configuration.sampling;
                    cone_sampling = obj.configuration.sampling;
                    %obj.dynamic_configuration.sampling = obj.configuration.sampling;
                    obj.dynamic_configuration.in_plane_sampling = in_plane_sampling;
                    obj.dynamic_configuration.cone_sampling = cone_sampling;
                else
                    error("ERROR: specification of sampling is not correct");
                end
            end
            
            variable_string = printVariableToString(tomogram_path);
            printToFile(obj.log_file_id, variable_string);
            variable_string = printVariableToString(dynamo_template_matching_path);
            printToFile(obj.log_file_id, variable_string);

            obj.dynamic_configuration.template_matching_cone_sampling = cone_sampling;
            obj.dynamic_configuration.template_matching_in_plane_sampling = in_plane_sampling;
            obj.dynamic_configuration.template_matching_cone_range = cone_range;
            obj.dynamic_configuration.template_matching_in_plane_range = in_plane_range;
            
            % NOTE: modified function "compute" and "dynamo_normalize_roi"
            pts = dynamo_match(char(tomogram_path),...
                template, 'mask', mask,...
                'outputFolder', char(dynamo_template_matching_path),...
                ...%TODO: fix structure
                'ytilt', [min_and_max_tilt_angles(1), min_and_max_tilt_angles(end)],...
                ...%'ytilt', [tilt_geometry(1), tilt_geometry(2)],...
                'sc', size_of_chunk,...
                'cr', cone_range,...
                'cs', cone_sampling,...
                'ir', in_plane_range,...
                'is', in_plane_sampling,...
                'mw', matlab_workers);
            
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
            %end
            cd(return_path);
            %             return_path = cd(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.dynamo_folder);
            %
            %             cd(return_path);
            createSymbolicLinkInStandardFolder(obj.configuration, dynamo_template_matching_path + ".TM", "dynamo_folder", obj.log_file_id);
            
        end
    end
end

