classdef PolishParticlesAndEstimateResolution < Module
    methods
        function obj = PolishParticlesAndEstimateResolution(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)
            paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "last");
            alignment_folder = dir(paths{1} + filesep + "alignment_project*");
            alignment_folder_splitted = strsplit(alignment_folder.name, "_");
            previous_binning = str2double(alignment_folder_splitted{end});
            iteration_path = dir(paths{1} + filesep + "*" + filesep + "*" + filesep + "results" + filesep + "ite_*");
            tab_all_path = dir(string(iteration_path(end-1).folder) + filesep + iteration_path(end-1).name + filesep + "averages" + filesep + "*.tbl");
            if contains(tab_all_path(1).folder, "bin_" + previous_binning + "_eo" + filesep)
                if obj.configuration.mask_path == ""
                    mask_path = dir(paths{1} + filesep + "*" + filesep + "*_eo" + filesep + "settings" + filesep + "mask.em");
                    mask = dread(char(string(mask_path.folder) + filesep + mask_path.name));
                else
                    mask = dread(char(obj.configuration.mask_path));
                end
                obj.polishParticlesAndEstimateResolution(string(tab_all_path(1).folder) + filesep + tab_all_path(1).name,...
                    string(tab_all_path(2).folder) + filesep + tab_all_path(2).name, mask);
            else
                error("ERROR: no alignment projects were executed up to now!")
            end
        end
        
        function polishParticlesAndEstimateResolution(obj, table_1_path, table_2_path, mask)
            
            % PART I: SETTING UP PARAMETERS AND STRUCTURES
            module_config = obj.setupParameters(table_1_path, table_2_path, mask);

            % PART II: POLISHING FINAL MAP BY FINDING OPTIMAL NUMBER OF
            % TILT IMAGES TO BE USED DURING MAP RECONSTRUCTION
            module_config = obj.polishAverageMapByExposureCoordinate(module_config, mask);
            
            % PART III: POLISHING FINAL MAP BY SELECTING OPTIMAL NUMBER OF 
            % THE BEST PARTICLES TO BE USED DURING MAP RECONSTRUCTION
            obj.polishAverageMapByParticlesAmount(module_config, mask);
            
        end
        
        function module_config = setupParameters(obj, table_1_path, table_2_path, mask)
            
            module_config = struct;
            
            if obj.configuration.binning > 0
                module_config.binning = obj.configuration.binning;
            else
                paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "last");
                alignment_folder = dir(paths{1} + filesep + "alignment_project*");
                alignment_folder_splitted = strsplit(alignment_folder.name, "_");
                module_config.binning = str2double(alignment_folder_splitted{end});
            end
            
            new_table_1 = dread(table_1_path);
            new_table_1(:,[24 25 26]) = new_table_1(:,[24 25 26]) + new_table_1(:,[4 5 6]);
            new_table_1(:,[4 5 6]) = 0;
            new_table_2 = dread(table_2_path);
            new_table_2(:,[24 25 26]) = new_table_2(:,[24 25 26]) + new_table_2(:,[4 5 6]);
            new_table_2(:,[4 5 6]) = 0;
            
            new_table_1 = sortrows(new_table_1, [-10]);
            new_table_2 = sortrows(new_table_2, [-10]);

            if obj.configuration.particle_count == 0
                if size(new_table_1 ,1) ~= size(new_table_2 ,1)
                    disp("INFO: tables are not equal in size chosing the smaller table for particle count calculation");
                    if size(new_table_1 ,1) < size(new_table_2 ,1)
                        particle_count = size(new_table_1 ,1);
                    else
                        particle_count = size(new_table_2 ,1);
                    end
                else
                    particle_count = size(new_table_1 ,1);
                end
                combined_table = [new_table_1(1:particle_count, :); new_table_2(1:particle_count, :)];
            elseif obj.configuration.particle_count < -1
                if abs(obj.configuration.particle_count) > size(new_table_1 ,1) || abs(obj.configuration.particle_count) > size(new_table_2 ,1)
                    disp("INFO: chosen particle count is larger than the amount of particles in one of the tables, clipping to the size of the smaller table");
                    if size(new_table_1 ,1) < size(new_table_2 ,1)
                        particle_count = size(new_table_1 ,1);
                    else
                        particle_count = size(new_table_2 ,1);
                    end
                end
                combined_table = [new_table_1(end+obj.configuration.particle_count:end, :); new_table_2(end+obj.configuration.particle_count:end, :)];
            elseif obj.configuration.particle_count > 1
                if obj.configuration.particle_count > size(new_table_1 ,1) || obj.configuration.particle_count > size(new_table_2 ,1)
                    disp("INFO: chosen particle count is larger than the amount of particles in one of the tables, clipping to the size of the smaller table");
                    if size(new_table_1 ,1) < size(new_table_2 ,1)
                        particle_count = size(new_table_1 ,1);
                    else
                        particle_count = size(new_table_2 ,1);
                    end
                end
                combined_table = [new_table_1(1:particle_count, :); new_table_2(1:particle_count, :)];
            elseif obj.configuration.particle_count <= 1 && obj.configuration.particle_count > 0
                if size(new_table_1 ,1) ~= size(new_table_2 ,1)
                    disp("INFO: tables are not equal in size chosing the smaller table for particle count calculation");
                    if size(new_table_1 ,1) < size(new_table_2 ,1)
                        particle_count = round(obj.configuration.particle_count * size(new_table_1, 1));
                    else
                        particle_count = round(obj.configuration.particle_count * size(new_table_2, 1));
                    end
                else
                    particle_count = round(obj.configuration.particle_count * size(new_table_1, 1));
                end
                combined_table = [new_table_1(1:particle_count, :); new_table_2(1:particle_count, :)];
            elseif obj.configuration.particle_count >= -1 && obj.configuration.particle_count < 0
                if size(new_table_1 ,1) ~= size(new_table_2 ,1)
                    disp("INFO: tables are not equal in size chosing the smaller table for particle count calculation");
                    if size(new_table_1 ,1) < size(new_table_2 ,1)
                        particle_count = round(obj.configuration.particle_count * size(new_table_1, 1));
                    else
                        particle_count = round(obj.configuration.particle_count * size(new_table_2, 1));
                    end
                else
                    particle_count = round(obj.configuration.particle_count * size(new_table_1, 1));
                end
                combined_table = [new_table_1(end+obj.configuration.particle_count:end, :); new_table_2(end+obj.configuration.particle_count:end, :)];
            end
            module_config.particle_count = particle_count;
            module_config.combined_particles_tbl_path = char(obj.output_path + filesep + "particles_bin_" + module_config.binning + ".tbl");
            dwrite(combined_table, module_config.combined_particles_tbl_path);
            
            module_config.tomos_id = unique(combined_table(:,20));
            module_config.N = length(module_config.tomos_id);
            for i = 1:module_config.N
                obj.configuration.set_up.j = module_config.tomos_id(i);
                tilt_angles = getTiltAngles(obj.configuration, true);
                if i == 1
                    module_config.P = length(tilt_angles);
                    tmp_tilt_angles = tilt_angles;
                elseif length(tilt_angles) > module_config.P
                    module_config.P = length(tilt_angles);
                    tmp_tilt_angles = tilt_angles;
                end
            end
            module_config.tilt_angles = tmp_tilt_angles;
            module_config.tilt_angle_step = abs(tilt_angles(1) - tilt_angles(2));
            
            module_config.dose_order = obj.configuration.dose_order;
            if any(module_config.dose_order == 0) == true
                module_config.dose_order = module_config.dose_order + 1;
            end
            dose_order_sel = ismember(obj.configuration.tilt_angles, module_config.tilt_angles);
            module_config.dose_order = module_config.dose_order(dose_order_sel);
            
            % TODO: parse case when dose input as a list
            dose = obj.configuration.dose;
%                 if isscalar(dose)
            module_config.dose_per_projection = dose / module_config.P;
%                 else
%                     % NOTE: if obj.configuration.dose is a list this meas user
%                     % had already specified dose per projection as dose list
%                     module_config.dose_per_projection = dose;
%                 end
            
            % TODO: parse case when dose input as a list
            module_config.b_factor_per_projection = obj.configuration.b_factor_per_projection;
            
            [module_config.scaled_apix, ~] = getApix(obj.configuration, module_config.binning);
                        
            if obj.configuration.use_symmetry == true && obj.configuration.use_SUSAN_symmetry == false
                module_config.sym = char(obj.configuration.expected_symmetrie);
            else
                module_config.sym = 'c1';
            end
            
            box_size = round((length(mask) * obj.configuration.box_size));
            if mod(box_size, 2) == 1
                box_size = box_size + 1;
            end
            
            if module_config.binning > 1
                module_config.box_size_binned = round(box_size / module_config.binning);
            else
                module_config.box_size_binned = box_size;
            end
            
            % SETUP SUSAN.DATA.TOMOSINFO OBJECT
            if module_config.binning <= 1
                aligned_tilt_stacks = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                aligned_tilt_stacks = aligned_tilt_stacks(~contains({aligned_tilt_stacks.name}, "_bin_"));
            else
                aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true, binning);
            end
            
            [width, height, ~] = getHeightAndWidthFromHeader(string(aligned_tilt_stacks(1).folder) + filesep + string(aligned_tilt_stacks(1).name), -1);
            reconstruction_thickness = obj.configuration.reconstruction_thickness;
            
            %tlt_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "tlt", "last");
            tlt_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".tlt");
            
            %defocus_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "defocus", "last");
            defocus_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".defocus");
            
            tomos = SUSAN.Data.TomosInfo(module_config.N, module_config.P);
            for i = 1:module_config.N
                tomos.tomo_id(i) = module_config.tomos_id(i);
                stack_path = string(aligned_tilt_stacks(i).folder) + filesep + string(aligned_tilt_stacks(i).name);
                tomos.set_stack(i, stack_path);
                tomos.set_angles(i, char(string(tlt_files{module_config.tomos_id(i)}.folder) + filesep + tlt_files{module_config.tomos_id(i)}.name));
                tomos.pix_size(i) = module_config.scaled_apix;
                tomos.tomo_size(i,:) = [width, height, reconstruction_thickness / module_config.binning]; 
                tomos.set_defocus(i, char(string(defocus_files{module_config.tomos_id(i)}.folder) + filesep + string(defocus_files{module_config.tomos_id(i)}.name)));
            end
             
            if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                error('ERROR: Using dose_symmetric_parallel tilt scheme is not fully implemented yet, sorry!');
%                 TODO: review condition in this branch
%                 for j = 1:size(tomos.defocus, 1)
%                     if tilt_angles(dose_order == j) >= -((floor(P/2) - k + 1) * tilt_angle_step)  && tilt_angles(dose_order == j) <= ((floor(P/2) - k + 1) * tilt_angle_step)
%                         if dose > 0
%                             tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
%                         end
%                         tomos.proj_weight(dose_order == j,1,i) = 1;
%                     else
%                         tomos.proj_weight(dose_order == j,1,i) = 0;
%                     end
%                 end
            elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                for i = 1:module_config.N
                    for j = 1:size(tomos.defocus, 1)
                        if dose > 0
                            % NOTE: known heuristics of 4 A^2 per 1 e-/A^2 of accumulated dose
                            tomos.defocus(module_config.dose_order == j,6,i) = (j - 1) * module_config.dose_per_projection * module_config.b_factor_per_projection;
                        end
                    end
                end
            else
                error("ERROR: unknown tilt scheme");
            end
            
            module_config.tomos_base_name = char(obj.output_path + filesep + "tomos_bin_" + module_config.binning + ".tomostxt");
            tomos.save(module_config.tomos_base_name);
            
            if obj.configuration.tilt_scheme == "dose_symmetric"
                module_config.indices = floor(module_config.P/2);
            elseif obj.configuration.tilt_scheme == "bi_directional"
                module_config.indices = module_config.P - 1;
            else
                error("ERROR: unknown tilt scheme");
            end
            
            module_config.set_cc_as_prtcls_weights = obj.configuration.set_cc_as_prtcls_weights;
            module_config.prtcls_weights_range = obj.configuration.prtcls_weights_range;
        end
        
        function module_config = polishAverageMapByExposureCoordinate(obj, module_config, mask)
            
            % TODO: move folder creation to the module setup
            exp_ave_path = obj.output_path + filesep + "averages_by_exposure";
            if exist(exp_ave_path, "dir")
                rmdir(exp_ave_path, "s");
            end
            mkdir(exp_ave_path);
            
            % TODO: move folder creation to the module setup
            exp_ave_susan_info_path = exp_ave_path + filesep + "susan_info";
            if exist(exp_ave_susan_info_path, "dir")
                rmdir(exp_ave_susan_info_path, "s");
            end
            mkdir(exp_ave_susan_info_path);
            
            % TODO: move folder creation to the module setup
            exp_ave_maps_path = exp_ave_path + filesep + "maps";
            if exist(exp_ave_maps_path, "dir")
                rmdir(exp_ave_maps_path, "s");
            end
            mkdir(exp_ave_maps_path);
            
            % DEBUG: delete line below
            %module_config.indices = 5;

            tomos = SUSAN.read(module_config.tomos_base_name);
            
            % cell of FSC objects (FSCs, resolution & area under FSC)  
            fsc_cell = cell(module_config.indices,1);
            fsc_metrics = zeros(module_config.indices,2);
            
            % TODO: parametrize tilt image step to be used during
            % optimization (e.g., constant value or custom list)
            for k = 1:module_config.indices
                if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                    error('ERROR: Using dose_symmetric_parallel tilt scheme is not fully implemented yet, sorry!');
                    % TODO: review condition in this branch
%                     for j = 1:size(tomos.defocus, 1)
%                         if tilt_angles(dose_order == j) >= -((floor(P/2) - k + 1) * tilt_angle_step)  && tilt_angles(dose_order == j) <= ((floor(P/2) - k + 1) * tilt_angle_step)
%                             if dose > 0
%                                 tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
%                             end
%                             tomos.proj_weight(dose_order == j,1,i) = 1;
%                         else
%                             tomos.proj_weight(dose_order == j,1,i) = 0;
%                         end
%                     end                    
                elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                    for i = 1:module_config.N
                        for j = 1:size(tomos.defocus, 1)
                            if  j == k %j <= k
                                tomos.proj_weight(module_config.dose_order == j,1,i) = 1;
                            else
                                tomos.proj_weight(module_config.dose_order == j,1,i) = 0;
                            end
                        end
                    end
                end
                tomos_name = char(exp_ave_susan_info_path + filesep + "tomos_bin_" + module_config.binning + "_view_" + k + ".tomostxt");
                tomos.save(tomos_name);
                
                combined_table = SUSAN.read(module_config.combined_particles_tbl_path);
                
                ptcls = SUSAN.Data.ParticlesInfo(combined_table, tomos);
                ptcls.half_id(1:module_config.particle_count) = 1;
                ptcls.half_id(module_config.particle_count+1:end) = 2;
                particles_raw = char(exp_ave_susan_info_path + filesep + "particles_bin_" + module_config.binning + "_view_" + k + ".ptclsraw");
                ptcls.save(particles_raw);

                % GENERATE AVERAGE
                exp_ave_map_path_with_prefix = exp_ave_maps_path + filesep + "map_bin_" + module_config.binning;
                exp_ave_map_k_path = exp_ave_map_path_with_prefix + "_view_" + k;
                obj.generateParticlesAverage(tomos_name, particles_raw, exp_ave_map_k_path, module_config);
                
                vol1 = [];
                vol2 = [];
                for tlt_rec=1:k
                    average_by_exposure_TLT_prefix = exp_ave_map_path_with_prefix + "_view_" + tlt_rec;
                    vol1_tlt_rec = dnan(dread(char(average_by_exposure_TLT_prefix + "_half_1.mrc")));
                    vol2_tlt_rec = dnan(dread(char(average_by_exposure_TLT_prefix + "_half_2.mrc")));
                    if tlt_rec==1
                       vol1 = vol1_tlt_rec;
                       vol2 = vol2_tlt_rec;
                    else
                       vol1 = vol1 + vol1_tlt_rec;
                       vol2 = vol2 + vol2_tlt_rec;
                    end
                end
                
                fsc = dfsc(vol1, vol2, 'apix', module_config.scaled_apix, 'show', 'off', 'mask', mask, 'sym', module_config.sym);

                if isfield(fsc, "res_0143")
                    fsc_res = fsc.res_0143;
                else
                    fsc_res = fsc.res_013;
                end
                
                fid = fopen(exp_ave_maps_path + filesep + "ds_ini_bin_" + module_config.binning + "_view_1to" + k + "_resolution_" + fsc_res + ".txt", "w+");
                for idx=1:length(fsc.fsc)
                   fprintf(fid, "%s ", fsc.fsc(idx)); 
                end
                fclose(fid);

                disp("INFO:NUMBER_OF_TILTS_USED: " + k);
                disp("INFO:CURRENT_FSC: " + fsc_res + " Angstrom");
                if k == 1 || fsc_res < fsc_res_best
                    fsc_res_best = fsc_res;
                end
                disp("INFO:BEST_FSC: " + fsc_res_best + " Angstrom");

                fsc.area = sum(fsc.fsc);
                disp("INFO:CURRENT_FSC_AREA: " + fsc.area + " Angstrom");
                if k == 1 || fsc.area > fsc_area_best
                    fsc_area_best = fsc.area;
                end
                disp("INFO:BEST_FSC_AREA: " + fsc_area_best + " Angstrom");
                
                fsc_metrics(1,k) = fsc_res;
                fsc_metrics(2,k) = fsc.area;
                fsc_cell{k} = fsc.fsc;
            end
            
            [~, fsc_area_imax_relaxed] = obj.getRelaxedMaximum(fsc_metrics(2,:), obj.configuration.fsc_area_threshold);
            disp("INFO: optimal number of tilts: " + fsc_area_imax_relaxed);

            if obj.configuration.save_figures == true
                figures_title_prefix = "map_bin_" + module_config.binning + "_optimize_by_exposure";
                obj.plotMapQualityMetrics(fsc_cell, fsc_metrics, exp_ave_path, figures_title_prefix, "exposure");
            end

            % TODO: make here final map reconstruction using the optimal
            % number of tilt images according to FSC metrics!!!
            module_config.k_optimal = fsc_area_imax_relaxed;
            
            tomos = SUSAN.read(module_config.tomos_base_name);
            if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                error('ERROR: Using dose_symmetric_parallel tilt scheme is not fully implemented yet, sorry!');
%                 TODO: review condition in this branch
%                 for j = 1:size(tomos.defocus, 1)
%                     if tilt_angles(dose_order == j) >= -((floor(P/2) - k + 1) * tilt_angle_step)  && tilt_angles(dose_order == j) <= ((floor(P/2) - k + 1) * tilt_angle_step)
%                         if dose > 0
%                             tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
%                         end
%                         tomos.proj_weight(dose_order == j,1,i) = 1;
%                     else
%                         tomos.proj_weight(dose_order == j,1,i) = 0;
%                     end
%                 end                    
            elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                for i = 1:module_config.N
                    for j = 1:size(tomos.defocus, 1)
                        if  j <= module_config.k_optimal
                            tomos.proj_weight(module_config.dose_order == j,1,i) = 1;
                        else
                            tomos.proj_weight(module_config.dose_order == j,1,i) = 0;
                        end
                    end
                end
            end
            module_config.tomos_optimal_exposure_name = char(exp_ave_path + filesep + "tomos_bin_" + module_config.binning + "_view_1to" + module_config.k_optimal + ".tomostxt");
            tomos.save(module_config.tomos_optimal_exposure_name);

            combined_table = SUSAN.read(module_config.combined_particles_tbl_path);

            ptcls = SUSAN.Data.ParticlesInfo(combined_table, tomos);
            ptcls.half_id(1:module_config.particle_count) = 1;
            ptcls.half_id(module_config.particle_count+1:end) = 2;
            particles_raw = char(exp_ave_path + filesep + "particles_bin_" + module_config.binning + "_view_1to" + module_config.k_optimal + ".ptclsraw");
            ptcls.save(particles_raw);

            % GENERATE AVERAGE
            exp_ave_map_optimal_k_path = exp_ave_path + filesep + "map_bin_" + module_config.binning + "_view_1to" + module_config.k_optimal; 
            obj.generateParticlesAverage(module_config.tomos_optimal_exposure_name, particles_raw, exp_ave_map_optimal_k_path, module_config, "final");
                
            vol1 = dnan(dread(char(exp_ave_map_optimal_k_path + "_half_1_final.mrc")));
            vol2 = dnan(dread(char(exp_ave_map_optimal_k_path + "_half_2_final.mrc")));

            fsc = dfsc(vol1, vol2, 'apix', module_config.scaled_apix, 'show', 'off', 'mask', mask, 'sym', module_config.sym);

            if isfield(fsc, "res_0143")
                fsc_res = fsc.res_0143;
            else
                fsc_res = fsc.res_013;
            end

            fid = fopen(exp_ave_path + filesep + "ds_ini_bin_" + module_config.binning + "_view_1to" + module_config.k_optimal + "_resolution_" + fsc_res + ".txt", "w+");
            for idx=1:length(fsc.fsc)
               fprintf(fid, "%s ", fsc.fsc(idx)); 
            end
            fclose(fid);
            fsc.area = sum(fsc.fsc);
            disp("INFO:FSC_RES (optimal tlts num.): " + fsc_res + " Angstrom");
            disp("INFO:FSC_AREA (optimal tlts num.): " + fsc.area + " Angstrom"); 
        end
        
        function module_config = polishAverageMapByParticlesAmount(obj, module_config, mask)
            
            % TODO: move folder creation to the module setup
            prtcls_ave_path = obj.output_path + filesep + "averages_by_particles";
            if module_config.set_cc_as_prtcls_weights == true
                prtcls_ave_path = prtcls_ave_path + "_weighted";
            end
            
            if exist(prtcls_ave_path, "dir")
                rmdir(prtcls_ave_path, "s");
            end
            mkdir(prtcls_ave_path);
            
            % TODO: move folder creation to the module setup
            prtcls_ave_susan_info_path = prtcls_ave_path + filesep + "susan_info";
            if exist(prtcls_ave_susan_info_path, "dir")
                rmdir(prtcls_ave_susan_info_path, "s");
            end
            mkdir(prtcls_ave_susan_info_path);
            
            % TODO: move folder creation to the module setup
            prtcls_ave_maps_path = prtcls_ave_path + filesep + "maps";
            if exist(prtcls_ave_maps_path , "dir")
                rmdir(prtcls_ave_maps_path , "s");
            end
            mkdir(prtcls_ave_maps_path);
            
            combined_table = SUSAN.read(module_config.combined_particles_tbl_path);
            
            cc_angle_table = [combined_table(:, 1), combined_table(:, 34), combined_table(:, 8), combined_table(:, 10)];
            cc_angle_table(1:module_config.particle_count,2) = 1;
            cc_angle_table(module_config.particle_count+1:end,2) = 2;
            cc_angle_table(:,5) = 90 - abs(cc_angle_table(:,3) - 90);

            angles_step = obj.configuration.cc_floating_average_angular_step_deg;
            angles_range = 0:90;
            points_number = length(angles_range) - angles_step + 1;

            order = obj.configuration.cc_floating_average_interp_order;
            
            % TODO: parametrize (const value or custom list)
            cc_percentile_step = obj.configuration.prtcls_cc_order_percentile_step;
            cc_percentile_high = 100 - cc_percentile_step;
            cc_percentile_range = cc_percentile_high:(-cc_percentile_step):0;
            cc_thresh_border_list = cell(2,1);

            % get floating mean CC values over setted angular step
            cc_angle_smoothed = zeros(3, points_number);
            for i=1:points_number
                cc_angle_table_sel = (cc_angle_table(:,5) >= angles_range(i)) & (cc_angle_table(:,5) < angles_range(i)+angles_step);
                cc_angle_smoothed(1,i) = angles_range(i) + (angles_step/2);
                cc_angle_smoothed(2,i) = length(cc_angle_table(cc_angle_table_sel,4));
                cc_angle_smoothed(3,i) = mean(cc_angle_table(cc_angle_table_sel,4));
            end
            cc_angle_smoothed = cc_angle_smoothed(:,cc_angle_smoothed(2,:)~=0);

            % fit floating mean CC values with curve of chosed order
            x = cc_angle_smoothed(1,:);
            y = cc_angle_smoothed(3,:);

            p = polyfit(x,y,order);
            y_fit = polyval(p,x);

            % get correction coefficients as function of angles
            coeff_correct = y_fit - min(y_fit);
            coeff_correct = max(coeff_correct) - coeff_correct;
            cc_angle_smoothed(4,:) = coeff_correct;

            % calculate corrected CC values
            cc_angle_table(:,6) = zeros(size(cc_angle_table,1),1);
            for i=1:points_number
                cc_angle_table_sel = (cc_angle_table(:,5) >= angles_range(i)) & (cc_angle_table(:,5) < angles_range(i)+angles_step);
                cc_angle_table(cc_angle_table_sel,6) = cc_angle_smoothed(4,i);
            end 
            cc_angle_table(:,7) = cc_angle_table(:,4) + cc_angle_table(:,6);
            
            % define CC values diving particles on fractions for both halves
            for half=1:2
                half_sel = cc_angle_table(:,2)==half;

                [cc_counts, cc_edges] = histcounts(cc_angle_table(half_sel,7),100);
                cc_cdf = rescale(cumsum(cc_counts), 0, 100);

                cc_thresh_border_list{half} = zeros(length(cc_percentile_range),1);
                for idx=1:length(cc_percentile_range)
                    percentile=cc_percentile_range(idx);
                    cc_thresh_border_list{half}(idx) = min(cc_edges(cc_cdf >= percentile));
                end
            end
            
            if obj.configuration.save_figures == true
                figures_title_prefix = "map_bin_" + module_config.binning + "_optimize_by_particles_set";
                obj.plotCorrectedCCAndParticlesPercentilesByHalfSubsets(cc_angle_smoothed, cc_angle_table, cc_percentile_range, cc_thresh_border_list, prtcls_ave_path, figures_title_prefix);
            end
            
            tomos = SUSAN.read(module_config.tomos_optimal_exposure_name);
            
            fsc_cell = cell(length(cc_percentile_range),1);
            fsc_metrics = zeros(length(cc_percentile_range),2); % 1 - resolution, 2 - area under FSC curve
            
            cc_top_percentile_range = 100 - cc_percentile_range;
            cc_angle_table_sel = zeros(length(cc_percentile_range), size(cc_angle_table,1),2);
            
            cc = cc_angle_table(:,7);
            
            if module_config.set_cc_as_prtcls_weights == true
                cc_angle_table_corr_norm = (cc - min(cc)) / (max(cc) - min(cc));
                
                new_min = module_config.prtcls_weights_range(1);
                new_max = module_config.prtcls_weights_range(2);
                cc_angle_table_corr_norm = cc_angle_table_corr_norm * (new_max - new_min) + new_min;
            end
            
            % select particles from halves and perform reconstructions
            for idx=1:length(cc_percentile_range)
                for half=1:2
                    half_sel = cc_angle_table(:,2)==half;
                    cc_angle_table_sel(idx,half_sel,half) = cc_angle_table(half_sel,7) >= cc_thresh_border_list{half}(idx);
                end
                half1_size = sum(cc_angle_table_sel(idx,:,1));
                half2_size = sum(cc_angle_table_sel(idx,:,2));
                disp('INFO: Halves sizes for top-' + string(cc_top_percentile_range(idx)) + '% : (half1=' + string(half1_size) + ',half2=' + string(half2_size) + ')');

                combined_table_filtered = [combined_table(logical(cc_angle_table_sel(idx,:,1)), :); combined_table(logical(cc_angle_table_sel(idx,:,2)), :)];

                ptcls = SUSAN.Data.ParticlesInfo(combined_table_filtered, tomos);

                ptcls.half_id(1:half1_size) = 1;
                ptcls.half_id(half1_size+1:end) = 2;
                particles_raw = char(prtcls_ave_susan_info_path + filesep + "particles_bin_" + module_config.binning + "_perc_" + string(cc_top_percentile_range(idx)) + ".ptclsraw");
                
                % TODO: save corrected CC values?
                % (re-write corresp. row in combined_table_filtered?)
                if module_config.set_cc_as_prtcls_weights == true
                    combined_corrected_cc_values_table = [cc_angle_table_corr_norm(logical(cc_angle_table_sel(idx,:,1))); cc_angle_table_corr_norm(logical(cc_angle_table_sel(idx,:,2)))];
                    ptcls.set_weights(combined_corrected_cc_values_table);
                end
                ptcls.save(particles_raw);

                % GENERATE AVERAGE
                prtcls_ave_map_path = prtcls_ave_maps_path + filesep + "map_bin_" + module_config.binning + "_perc_" + string(cc_top_percentile_range(idx)); 
                obj.generateParticlesAverage(module_config.tomos_optimal_exposure_name, particles_raw, prtcls_ave_map_path, module_config);
                
                vol1 = dnan(dread(char(prtcls_ave_map_path + "_half_1.mrc")));
                vol2 = dnan(dread(char(prtcls_ave_map_path + "_half_2.mrc")));

                fsc = dfsc(vol1, vol2, 'apix', module_config.scaled_apix, 'show', 'off', 'mask', mask, 'sym', module_config.sym);

                if isfield(fsc, "res_0143")
                    fsc_res = fsc.res_0143;
                else
                    fsc_res = fsc.res_013;
                end
                
                fid = fopen(prtcls_ave_maps_path + filesep + "ds_ini_bin_" + module_config.binning + "_perc_" + string(cc_top_percentile_range(idx)) + "_resolution_" + fsc_res + ".txt", "w+");
                for fsc_idx=1:length(fsc.fsc)
                   fprintf(fid, "%s ", fsc.fsc(fsc_idx)); 
                end
                fclose(fid);

                disp("INFO:PARTICLES_DATASET_PERCENTILE_USED: " + cc_top_percentile_range(idx));
                disp("INFO:NUMBER_OF_PARTICLES_USED_HALF1: " + half1_size);
                disp("INFO:NUMBER_OF_PARTICLES_USED_HALF2: " + half2_size);
                disp("INFO:NUMBER_OF_PARTICLES_USED_TOTAL: " + (half1_size+half2_size));

                disp("INFO:CURRENT_FSC: " + fsc_res + " Angstrom");
                if idx == 1 || fsc_res < fsc_res_best
                    fsc_res_best = fsc_res;
                end
                disp("INFO:BEST_FSC: " + fsc_res_best + " Angstrom");

                fsc.area = sum(fsc.fsc);
                disp("INFO:CURRENT_FSC_AREA: " + fsc.area + " Angstrom");
                if idx == 1 || fsc.area > fsc_area_best
                    fsc_area_best = fsc.area;
                end
                disp("INFO:BEST_FSC_AREA: " + fsc_area_best + " Angstrom");

                fsc_metrics(1,idx) = fsc_res;
                fsc_metrics(2,idx) = fsc.area;
                fsc_cell{idx} = fsc.fsc;
            end
            
            [~, fsc_area_imax_relaxed] = obj.getRelaxedMaximum(fsc_metrics(2,:), obj.configuration.fsc_area_threshold);
            half1_optimal_size = sum(cc_angle_table_sel(fsc_area_imax_relaxed,:,1));
            half2_optimal_size = sum(cc_angle_table_sel(fsc_area_imax_relaxed,:,2));
            total_optimal_size = half1_optimal_size + half2_optimal_size;
            disp("INFO: optimal fraction of top-CC particles: " + cc_top_percentile_range(fsc_area_imax_relaxed));
            disp("INFO: optimal number of particles from half1: " + half1_optimal_size);
            disp("INFO: optimal number of particles from half2: " + half2_optimal_size);
            disp("INFO: optimal number of particles in total: " + total_optimal_size);
            
            if obj.configuration.save_figures == true
                figures_title_prefix = "map_bin_" + module_config.binning + "_optimize_by_particles_set";
                obj.plotMapQualityMetrics(fsc_cell, fsc_metrics, prtcls_ave_path, figures_title_prefix, "particles_set");
            end
            
            combined_table_optimal_particles = [combined_table(logical(cc_angle_table_sel(fsc_area_imax_relaxed,:,1)), :); combined_table(logical(cc_angle_table_sel(fsc_area_imax_relaxed,:,2)), :)];
            module_config.combined_optimal_particles_tbl_path = char(obj.output_path + filesep + "particles_optimal_bin_" + module_config.binning + ".tbl");
            module_config.particle_count_optimal = half1_optimal_size;
            dwrite(combined_table_optimal_particles, module_config.combined_optimal_particles_tbl_path);
            
            prtcls_ave_map_path = prtcls_ave_maps_path + filesep + "map_bin_" + module_config.binning + "_perc_" + string(cc_top_percentile_range(fsc_area_imax_relaxed)); 
            prtcls_ave_map_final_path = prtcls_ave_path + filesep + "map_bin_" + module_config.binning + "_perc_" + string(cc_top_percentile_range(fsc_area_imax_relaxed));
            copyfile(prtcls_ave_map_path + ".mrc", prtcls_ave_map_final_path + "_final.mrc");
            copyfile(prtcls_ave_map_path + "_half_1.mrc", prtcls_ave_map_final_path + "_half1_final.mrc");
            copyfile(prtcls_ave_map_path + "_half_2.mrc", prtcls_ave_map_final_path + "_half2_final.mrc");
            
            disp("INFO:FSC_RES (optimal prtcls num.): " + fsc_metrics(2,fsc_area_imax_relaxed) + " Angstrom");
            disp("INFO:FSC_AREA (optimal prtcls num.): " + fsc_metrics(1,fsc_area_imax_relaxed) + " Angstrom");
        end
        
        function generateParticlesAverage(obj, tomos_name, particles_raw, average_path, module_config, new_average_postfix)
            
            if nargin < 6
                new_average_postfix="";
            end
                
            if isempty(obj.configuration.ssnr)
                ssnr = [1, 0];
            else
                ssnr = obj.configuration.ssnr;
            end
            
            per_particle_ctf_correction = obj.configuration.per_particle_ctf_correction;
            padding_policy = obj.configuration.padding_policy;
            normalization = obj.configuration.normalization;
            expected_symmetrie = obj.configuration.expected_symmetrie;
            
            if obj.configuration.use_SUSAN_averager == false
                error('ERROR: Dynamo averager is not fully implemented yet, sorry!');
                % TODO: review this part of code
%                 if dose > 0
%                     real_particles_path = char(averages_by_exposure_path + filesep + "particles_bin_" + binning + "_bs_" + box_size + "_dw");
%                 else
%                     real_particles_path = char(averages_by_exposure_path + filesep  + "particles_bin_" + binning + "_bs_" + box_size);
%                 end
% 
%                 if exist(real_particles_path, "dir")
%                     rmdir(real_particles_path, "s");
%                 end
% 
%                 mkdir(real_particles_path);
%                 if obj.configuration.use_SUSAN_particle_generator == true
%                     subtomos = SUSAN.Modules.SubtomoRec;
%                     subtomos.gpu_list = 0:gpuDeviceCount - 1;
%                     %subtomos.padding = round(box_size / binning);
%                     subtomos.set_ctf_correction(char(per_particle_ctf_correction)); % try also wiener if you like
%                     %subtomos.set_padding_policy(char(padding_policy));
%                     subtomos.set_normalization(char(normalization));
%                     subtomos.reconstruct(char(real_particles_path), tomos_name, particles_raw, box_size);
%                 else
%                     % TODO: dtcrop
%                 end
% 
%                 vol1 = daverage(char(real_particles_path),'-t', new_table_1, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
%                 vol2 = daverage(char(real_particles_path),'-t', new_table_2, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
% 
%                 vol1 = vol1.average;
%                 vol2 = vol2.average;
            else
                avg = SUSAN.Modules.Averager;

                if obj.configuration.gpu == -1
                    avg.gpu_list = 0:gpuDeviceCount - 1;
                else
                    avg.gpu_list = obj.configuration.gpu - 1;
                end

                avg.bandpass.highpass = 0;
                avg.bandpass.lowpass = (module_config.box_size_binned / 2) - 1;

                if obj.configuration.susan_padding > 1 || obj.configuration.susan_padding == 0
                    if module_config.binning > 1
                        avg.padding = round(obj.configuration.susan_padding / module_config.binning);
                    else
                        avg.padding = obj.configuration.susan_padding;
                    end
                elseif obj.configuration.susan_padding > 0 && obj.configuration.susan_padding <= 1
                    avg.padding = round(obj.configuration.susan_padding * module_config.box_size_binned);
                else
                    avg.padding = round(module_config.box_size_binned / 4);
                end

                avg.rec_halves = true;
                avg.inversion.iter = obj.configuration.sampling_iterations;
                avg.inversion.gstd = obj.configuration.gaussian_filter_std;
                if (string(per_particle_ctf_correction) == "wiener_ssnr")
                    avg.set_ctf_correction(char("wiener_ssnr"), ssnr(1), ssnr(2)); % what about SSNR....: set_ctf_correction('wiener_ssnr',1,0.8);
                else
                    avg.set_ctf_correction(char(per_particle_ctf_correction)); % what about SSNR....: set_ctf_correction('wiener_ssnr',1,0.8);
                end

                avg.set_padding_policy(char(padding_policy));
                avg.set_normalization(char(normalization));
                if obj.configuration.use_symmetry == true
                    avg.set_symmetry(char(expected_symmetrie));
                else
                    avg.set_symmetry(char("C1"));
                end
                
                % string(averages_by_exposure_path) + filesep + "map_bin_" + binning + "_" + k
                avg.reconstruct(char(average_path), tomos_name, particles_raw, module_config.box_size_binned);
                % if i == 1
                %     avg.reconstruct(char("test/ds_ini_bin_" + binning + "_" + i), tomos_name, particles_raw_1, box_size);
                % else
                %     avg.reconstruct(char("test/ds_ini_bin_" + binning + "_" + i), tomos_name, particles_raw_2, box_size);
                % end
                %%

                % particle_files = dir([particles_path filesep 'particle*.em']);
                % ptags = zeros([length(particle_files) 1]);
                % for l = 1:length(particle_files)
                %     particle_name = strsplit(particle_files(l).name, ".");
                %     particle_number = strsplit(particle_name{1}, "_");
                %     ptag = str2double(particle_number{2});
                %     ptags(l) = ptag;
                % end
                % if ~isempty(setdiff(new_table(:,1), ptags(:)))
                %
                %     set_diff = setdiff(new_table(:,1), ptags(:));
                %     for i = 1:length(set_diff)
                %         new_table(new_table(:, 1) == set_diff(i),:) = [];
                %     end
                % end
                % if obj.configuration.as_boxes == 1
                %     % dBoxes.convertSimpleData(char("../../particles/particles_bin_" + binning  + "_bs_" + box_size),...
                %     %     [char("../../particles/particles_bin_" + binning  + "_bs_" + box_size) '.Boxes'],...
                %     %     'batch', obj.configuration.particle_batch, 'dc', obj.configuration.direct_copy);
                %     ownDbox(string(particles_path),...
                %         string([char(particles_path) '.Boxes']));
                %
                %     [status, message, messageid] = rmdir(char(particles_path), 's');
                %     particles_path = [char(particles_path) '.Boxes'];
                %     %                             new_table(:,1) = 1:length(new_table);
                %     %movefile(char([char("../../particles/particles_bin_" + binning) '.Boxes']), char("../../particles/particles_bin_" + binning));
                % end
                %
                % avge = daverage(char(particles_path), '-t', new_table, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                % template_em_files{1} = char(alignment_project_folder_path + string(filesep) + "average_" + 1 + ".em");
                % dwrite(avge.average, template_em_files{1});
                %vol1 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half1.mrc")));
                %vol2 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half2.mrc")));
            end
            
            if new_average_postfix == ""
                movefile(average_path + "_class001.mrc", average_path + ".mrc");
                movefile(average_path + "_class001_half1.mrc", average_path + "_half_1" + ".mrc");
                movefile(average_path + "_class001_half2.mrc", average_path + "_half_2" + ".mrc");
            else
                movefile(average_path + "_class001.mrc", average_path + "_" + new_average_postfix + ".mrc");
                movefile(average_path + "_class001_half1.mrc", average_path + "_half_1_" + new_average_postfix + ".mrc");
                movefile(average_path + "_class001_half2.mrc", average_path + "_half_2_" + new_average_postfix + ".mrc");
            end
        end
        
        function [relaxed_max_value, relaxed_max_index] = getRelaxedMaximum(~, empirical_function, relaxation_threshold)
            [max_value, max_index] = max(empirical_function);
            function_max_diff = max_value - empirical_function;
            function_threshold_passed = function_max_diff < relaxation_threshold;
            function_left_from_max = zeros(1, length(empirical_function));
            function_left_from_max(1:max(max_index,1)) = 1;
            [relaxed_max_value, relaxed_max_index] = max(function_max_diff .* double(function_threshold_passed & function_left_from_max));
            if relaxed_max_value == 0
                relaxed_max_index = max_index;
            end
        end
        
        function plotMapQualityMetrics(obj, fsc_cell, fsc_metrics, figures_path, figures_title_prefix, optimized_parameter)
            
            if optimized_parameter == "exposure"
                fsc_legend_title = "Tilts amount";
                parameter_title = "Tilts amount (exposure order)";
                fsc_step = obj.configuration.tilts_step_to_plot_fscs;
            else
                fsc_legend_title = "Particles percentile";
                parameter_title = "Particles percentile (CC order)";
                fsc_step = 1;
                cc_percentile_step = obj.configuration.prtcls_cc_order_percentile_step;
            end
            
            % NOTE: supress MATLAB warning regarding switching
            % to another rendering agent
            S = warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
            
            % plot FSCs
            f = figure(1);
            if obj.configuration.show_figures == false
                f.Visible = 'off';
            end
            
            % TODO: edit xticklabels for FSC plot!!!
            for k=1:fsc_step:length(fsc_cell)
                plot(fsc_cell{k});
                hold on;
            end
            yline(0.143, 'r', 'FSC=0.143', 'LineWidth', 1);
            xlabel('Fourier pixel');
            ylabel('FSC value');
            
            tracks_titles = [];
            if optimized_parameter == "exposure"
                for k=1:fsc_step:length(fsc_cell)
                    tracks_titles = [tracks_titles; string(k)];
                end
            else
                for k=1:fsc_step:length(fsc_cell)
                    tracks_titles = [tracks_titles; string(k*cc_percentile_step)];
                end 
            end
            leg = legend(tracks_titles);
            title(leg, fsc_legend_title);
            
            hold off;
            saveas(f, figures_path + filesep + figures_title_prefix + "_fsc", "fig");
            saveas(f, figures_path + filesep + figures_title_prefix + "_fsc", "png");
            close(f);

            % plot resolutions
            f = figure(1);
            if obj.configuration.show_figures == false
                f.Visible = 'off';
            end
            x = 1:size(fsc_metrics, 2);
            if optimized_parameter == "particles_set"
                x = x * cc_percentile_step;
            end
            plot(x, fsc_metrics(1,:));
            xlabel(parameter_title);
            ylabel('Resolution, Angstrom');
            saveas(f, figures_path + filesep + figures_title_prefix + "_resolution", "fig");
            saveas(f, figures_path + filesep + figures_title_prefix + "_resolution", "png");
            close(f);

            % plot area under FSCs
            f = figure(1);
            if obj.configuration.show_figures == false
                f.Visible = 'off';
            end
            x = 1:size(fsc_metrics, 2);
            if optimized_parameter == "particles_set"
                x = x * cc_percentile_step;
            end
            plot(x, fsc_metrics(2,:));
            hold on;
            %xline(fsc_area_imax, '--b', 'Optimal tilts num', 'LineWidth', 1);
            %xline(fsc_area_imax_relaxed, '--r', 'Optimal relaxed tilts num', 'LineWidth', 1);
            xlabel(parameter_title);
            ylabel('Area under FSC, Angstrom');
            hold off;
            saveas(f, figures_path + filesep + figures_title_prefix + "_area_under_fsc", "fig");
            saveas(f, figures_path + filesep + figures_title_prefix + "_area_under_fsc", "png");
            close(f);
        end
        
        function plotCorrectedCCAndParticlesPercentilesByHalfSubsets(obj, cc_angle_smoothed, cc_angle_table, cc_percentile_range, cc_thresh_border_list, figures_path, figures_title_prefix)
            
            % NOTE: supress MATLAB warning regarding switching
            % to another rendering agent
            S = warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
            
            f = figure(1);
            if obj.configuration.show_figures == false
                f.Visible = 'off';
            end
            
            x = cc_angle_smoothed(1,:);
            y = cc_angle_smoothed(3,:);
            scatter(x,y, 10, 'filled');
            hold on;

            order = obj.configuration.cc_floating_average_interp_order;
            p = polyfit(x,y,order);
            plot(x,polyval(p,x), 'LineWidth', 1);
            
            cc_angle_smoothed(5,:) = cc_angle_smoothed(3,:) + cc_angle_smoothed(4,:);
            x = cc_angle_smoothed(1,:);
            y = cc_angle_smoothed(5,:);
            scatter(x,y, 10, 'filled');

            p = polyfit(x,y,order);
            plot(x,polyval(p,x), 'LineWidth', 1);

            legend('original', 'original fitted', 'corrected', 'corrected fitted');
            xlabel('Angle from beam (eu(2), ZXZ conv.), deg');
            ylabel('CC value (floating average)');
            hold off;
            saveas(f, figures_path + filesep + figures_title_prefix + "_cc_float_ave", "fig");
            saveas(f, figures_path + filesep + figures_title_prefix + "_cc_float_ave", "png");
            close(f);

            f = figure(1);
            if obj.configuration.show_figures == false
                f.Visible = 'off';
            end
            scatter(cc_angle_table(:,5), cc_angle_table(:,4), 6, 'filled'); hold on;
            scatter(cc_angle_table(:,5), cc_angle_table(:,7), 6, 'filled'); 
            legend('original', 'corrected');
            xlabel('Angle from beam (eu(2), ZXZ conv.), deg');
            ylabel('CC value');
            hold off;
            saveas(f, figures_path + filesep + figures_title_prefix + "_cc_correction", "fig");
            saveas(f, figures_path + filesep + figures_title_prefix + "_cc_correction", "png");
            close(f);
            
            cc_top_percentile_range = 100 - cc_percentile_range;
            for half=1:2
                f = figure(half);
                if obj.configuration.show_figures == false
                    f.Visible = 'off';
                end
                half_sel = cc_angle_table(:,2)==half;
                scatter(cc_angle_table(half_sel,5), cc_angle_table(half_sel,7), 6, 'filled');
                for idx=1:length(cc_top_percentile_range)
                    percentile=cc_top_percentile_range(idx);
                    yline(cc_thresh_border_list{half}(idx), '--r', 'top '+string(percentile)+'%', 'LineWidth',1);
                end
                title('Half ' + string(half));
                saveas(f, figures_path + filesep + figures_title_prefix + "_cc_perc_half" + string(half), "fig");
                saveas(f, figures_path + filesep + figures_title_prefix + "_cc_perc_half" + string(half), "png");
                close(f);
            end
        end
    end
end

