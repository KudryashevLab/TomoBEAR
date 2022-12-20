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
            new_table_1 = dread(table_1_path);
            new_table_1(:,[24 25 26]) = new_table_1(:,[24 25 26]) + new_table_1(:,[4 5 6]);
            new_table_1(:,[4 5 6]) = 0;
            new_table_2 = dread(table_2_path);
            new_table_2(:,[24 25 26]) = new_table_2(:,[24 25 26]) + new_table_2(:,[4 5 6]);
            new_table_2(:,[4 5 6]) = 0;
            tomos_id = unique(new_table_1(:,20));
            
            N = length(tomos_id);
            for i = 1:N
                obj.configuration.set_up.j = tomos_id(i);
                tilt_angles = getTiltAngles(obj.configuration, true);
                if i == 1
                    P = length(tilt_angles);
                    tmp_tilt_angles = tilt_angles;
                elseif length(tilt_angles) > P
                    P = length(tilt_angles);
                    tmp_tilt_angles = tilt_angles;
                end
            end
            tilt_angles = tmp_tilt_angles;
            tilt_angle_step = abs(tilt_angles(1) - tilt_angles(2));
            dose_order = obj.configuration.dose_order;
            if any(dose_order == 0) == true
                dose_order = obj.configuration.dose_order + 1;
            end
            dose_order_sel = ismember(obj.configuration.tilt_angles, tilt_angles);
            dose_order = dose_order(dose_order_sel);
            dose = obj.configuration.dose;
            b_factor_per_projection = obj.configuration.b_factor_per_projection;
            if obj.configuration.binning > 0
                binning = obj.configuration.binning;
            else
                paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "last");
                alignment_folder = dir(paths{1} + filesep + "alignment_project*");
                alignment_folder_splitted = strsplit(alignment_folder.name, "_");
                binning = str2double(alignment_folder_splitted{end});
            end
            [scaled_apix, apix] = getApix(obj.configuration, binning);
            reconstruction_thickness = obj.configuration.reconstruction_thickness;
            per_particle_ctf_correction = obj.configuration.per_particle_ctf_correction;
            %             box_size = obj.configuration.box_size;
            if isempty(obj.configuration.ssnr)
                ssnr = [1, 0];
            else
                ssnr = obj.configuration.ssnr;
            end
            
            padding_policy = obj.configuration.padding_policy;
            normalization = obj.configuration.normalization;
            expected_symmetrie = obj.configuration.expected_symmetrie;
            
            if binning <= 1
                aligned_tilt_stacks = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                aligned_tilt_stacks = aligned_tilt_stacks(~contains({aligned_tilt_stacks.name}, "_bin_"));
            else
                aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true, binning);
            end
            
            % TODO: move folder creation to the module setup
            particles_path = obj.output_path + filesep + "particles";
            if exist(particles_path, "dir")
                rmdir(particles_path, "s");
            end
            
            mkdir(particles_path);
            
            [width, height, z] = getHeightAndWidthFromHeader(string(aligned_tilt_stacks(1).folder) + filesep + string(aligned_tilt_stacks(1).name), -1);
            %tlt_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "tlt", "last");
            tlt_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".tlt");
            
            %defocus_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "defocus", "last");
            defocus_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".defocus");
                        
            if obj.configuration.use_symmetry == true && obj.configuration.use_SUSAN_symmetry == false
                sym = char(obj.configuration.expected_symmetrie);
            else
                sym = 'c1';
            end
            
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
            combined_particles_tbl = char(particles_path + filesep + "particles_bin_" + binning + ".tbl");
            dwrite(combined_table, combined_particles_tbl);
            
            box_size = round((length(mask) * obj.configuration.box_size));
            if mod(box_size, 2) == 1
                box_size = box_size + 1;
            end
            
            if binning > 1
                box_size_binned = round(box_size / binning);
            else
                box_size_binned = box_size;
            end
            
            if obj.configuration.tilt_scheme == "dose_symmetric"
                indices = floor(P/2);
            elseif obj.configuration.tilt_scheme == "bi_directional"
                indices = P - 1;
            else
                error("ERROR: unknown tilt scheme");
            end
            dose_per_projection = dose / P;
            
            tomos = SUSAN.Data.TomosInfo(N,P);
            for i = 1:N
                tomos.tomo_id(i) = tomos_id(i);
                stack_path = string(aligned_tilt_stacks(i).folder) + filesep + string(aligned_tilt_stacks(i).name);
                tomos.set_stack(i, stack_path);
                tomos.set_angles(i, char(string(tlt_files{tomos_id(i)}.folder) + filesep + tlt_files{tomos_id(i)}.name));
                tomos.pix_size(i) = scaled_apix;
                tomos.tomo_size(i,:) = [width, height, reconstruction_thickness / binning];
            end
            
            % DEBUG: delete line below
            %indices = 10;
            
            fsc_cell = cell(indices,1);
            % 1 - resolution, 2 - area under FSC curve
            fsc_metrics = zeros(indices,2);
            
            for k = 1:indices  
                for i = 1:N
                    tomos.set_defocus(i, char(string(defocus_files{tomos_id(i)}.folder) + filesep + string(defocus_files{tomos_id(i)}.name)));
                    if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                        error('ERROR: Using dose_symmetric_parallel tilt scheme is not fully implemented yet, sorry!');
                        % TODO: review condition in this branch
%                         for j = 1:size(tomos.defocus, 1)
%                             if tilt_angles(dose_order == j) >= -((floor(P/2) - k + 1) * tilt_angle_step)  && tilt_angles(dose_order == j) <= ((floor(P/2) - k + 1) * tilt_angle_step)
%                                 if dose > 0
%                                     tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
%                                 end
%                                 tomos.proj_weight(dose_order == j,1,i) = 1;
%                             else
%                                 tomos.proj_weight(dose_order == j,1,i) = 0;
%                             end
%                         end
                    elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                        for j = 1:size(tomos.defocus, 1)
                            if  j == k %j <= k %j < max(dose_order) - k + 1 
                                if dose > 0
                                    tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
                                end
                                tomos.proj_weight(dose_order == j,1,i) = 1;
                            else
                                tomos.proj_weight(dose_order == j,1,i) = 0;
                            end
                        end
                    end
                end
                tomos_name = char(particles_path + filesep + "tomos_bin_" + binning + "_" + k + ".tomostxt");
                tomos.save(tomos_name);
               
                ptcls = SUSAN.Data.ParticlesInfo(combined_table, tomos);
                ptcls.half_id(1:particle_count) = 1;
                ptcls.half_id(particle_count+1:end) = 2;
                particles_raw = char(particles_path + filesep + "particles_bin_" + binning + "_" + k + ".ptclsraw");
                ptcls.save(particles_raw);
                
                if obj.configuration.use_SUSAN_averager == false
                    error('ERROR: Dynamo averager is not fully implemented yet, sorry!');
                    % TODO: review this part of code
%                     if dose > 0
%                         real_particles_path = char(particles_path + filesep + "particles_bin_" + binning + "_bs_" + box_size + "_dw");
%                     else
%                         real_particles_path = char(particles_path + filesep  + "particles_bin_" + binning + "_bs_" + box_size);
%                     end
%                     
%                     if exist(real_particles_path, "dir")
%                         rmdir(real_particles_path, "s");
%                     end
%                     
%                     mkdir(real_particles_path);
%                     if obj.configuration.use_SUSAN_particle_generator == true
%                         subtomos = SUSAN.Modules.SubtomoRec;
%                         subtomos.gpu_list = 0:gpuDeviceCount - 1;
%                         %subtomos.padding = round(box_size / binning);
%                         subtomos.set_ctf_correction(char(per_particle_ctf_correction)); % try also wiener if you like
%                         %subtomos.set_padding_policy(char(padding_policy));
%                         subtomos.set_normalization(char(normalization));
%                         subtomos.reconstruct(char(real_particles_path), tomos_name, particles_raw, box_size);
%                     else
%                         % TODO: dtcrop
%                     end
%                     
%                     vol1 = daverage(char(real_particles_path),'-t', new_table_1, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
%                     vol2 = daverage(char(real_particles_path),'-t', new_table_2, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
%                     
%                     vol1 = vol1.average;
%                     vol2 = vol2.average;
                else
                    avg = SUSAN.Modules.Averager;
                    
                    if obj.configuration.gpu == -1
                        avg.gpu_list = 0:gpuDeviceCount - 1;
                    else
                        avg.gpu_list = obj.configuration.gpu - 1;
                    end
                    
                    avg.bandpass.highpass = 0;
                    avg.bandpass.lowpass = (box_size_binned / 2) - 1;
                     
                    if obj.configuration.susan_padding > 1 || obj.configuration.susan_padding == 0
                        if binning > 1
                            avg.padding = round(obj.configuration.susan_padding / binning);
                        else
                            avg.padding = obj.configuration.susan_padding;
                        end
                    elseif obj.configuration.susan_padding > 0 && obj.configuration.susan_padding <= 1
                        avg.padding = round(obj.configuration.susan_padding * box_size_binned);
                    else
                        avg.padding = round(box_size_binned / 4);
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
                    
                    avg.reconstruct(char(string(particles_path) + filesep + "map_bin_" + binning + "_" + k), tomos_name, particles_raw, box_size_binned);
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
                
                %                 particles_raw_1 = char(particles_path + filesep + "particles_bin_" + binning + "_1.ptclsraw");
                %                 ptcls = SUSAN.Data.ParticlesInfo(new_table_1, tomos);
                %                 ptcls.save(particles_raw_1);
                %
                %                 particles_raw_2 = char(particles_path + filesep + "particles_bin_" + binning + "_2.ptclsraw");
                %                 ptcls = SUSAN.Data.ParticlesInfo(new_table_2, tomos);
                %                 ptcls.save(particles_raw_2);
                
                movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_previous.mrc");
                movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half1.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_1_previous.mrc");
                movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half2.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_2_previous.mrc");
                                
                %vol1 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_1_previous.mrc")));
                %vol2 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_2_previous.mrc")));
                
                vol1 = [];
                vol2 = [];
                for tlt_rec=1:k
                    vol1_tlt_rec = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + tlt_rec + "_half_1_previous.mrc")));
                    vol2_tlt_rec = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + tlt_rec + "_half_2_previous.mrc")));
                    if tlt_rec==1
                       vol1 = vol1_tlt_rec;
                       vol2 = vol2_tlt_rec;
                    else
                       vol1 = vol1 + vol1_tlt_rec;
                       vol2 = vol2 + vol2_tlt_rec;
                    end
                end
                
                fsc = dfsc(vol1, vol2, 'apix', scaled_apix, 'show', 'off', 'mask', mask, 'sym', sym);
                
                if isfield(fsc, "res_0143")
                    fsc_res = fsc.res_0143;
                else
                    fsc_res = fsc.res_013;
                end
                
                fid = fopen(particles_path + filesep + "ds_ini_bin_" + binning + "_" + k + "_resolution_" + fsc_res + ".txt", "w+");
                % TODO: write fsc into file
                fprintf(fid, "%s\n", fsc_res);
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
            
            % calculate max and value for FSC area metrics and find 
            % corresp. threshold as the number of tilts to be used
            [fsc_area_max, fsc_area_imax] = max(fsc_metrics(2,:));
            fsc_area_diff = fsc_area_max - fsc_metrics(2,:);
            % find minimal number of tilts required to get same FSC area
            % as defined max under defined threshold level
            fsc_area_threshold_passed = fsc_area_diff < obj.configuration.fsc_area_threshold;
            fsc_area_left_from_max = zeros(1, size(fsc_metrics, 2));
            fsc_area_left_from_max(1:max(fsc_area_imax,1)) = 1;
            [fsc_area_max_relaxed, fsc_area_imax_relaxed] = max(fsc_area_diff .* double(fsc_area_threshold_passed & fsc_area_left_from_max));
            if fsc_area_max_relaxed == 0
                fsc_area_imax_relaxed = fsc_area_imax;
            end
            disp("INFO: optimal number of tilts: " + fsc_area_imax_relaxed);
            
            % TODO: wrap saving figures into function in utilites/
            % plot all FSCs on one figure
            % NOTE: supress MATLAB warning regarding switching
            % to another rendering agent
            S = warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
            if obj.configuration.save_figures == true
                % plot FSCs
                f = figure(1);
                if obj.configuration.show_figures == false
                    f.Visible = 'off';
                end
                tracks_titles = [];
                
                % TODO: edit xticklabels for FSC plot!!!
                for k=1:obj.configuration.tilts_step_to_plot_fscs:length(fsc_cell)
                    plot(fsc_cell{k});
                    hold on;
                    tracks_titles = [tracks_titles; string(k)];
                end
                yline(0.143, 'r', 'FSC=0.143', 'LineWidth', 1);
                title('Fourier shell correlation curves');
                xlabel('Fourier pixel');
                ylabel('FSC value');
                leg = legend(tracks_titles);
                title(leg,'Tilts amount');
                hold off;
                saveas(f,particles_path + filesep + "map_bin_" + binning + "_1to" + string(length(fsc_cell)) + "_fsc", "fig");
                saveas(f,particles_path + filesep + "map_bin_" + binning + "_1to" + string(length(fsc_cell)) + "_fsc", "png");
                close(f);
                
                % plot resolutions
                f = figure(1);
                if obj.configuration.show_figures == false
                    f.Visible = 'off';
                end
                plot(1:size(fsc_metrics, 2), fsc_metrics(1,:));
                title('Resolution as function of tilts amount');
                xlabel('Tilts amount (exposure order)');
                ylabel('Resolution, Angstrom');
                saveas(f,particles_path + filesep + "map_bin_" + binning + "_1to" + string(length(fsc_cell)) + "_resolution", "fig");
                saveas(f,particles_path + filesep + "map_bin_" + binning + "_1to" + string(length(fsc_cell)) + "_resolution", "png");
                close(f);
                
                % plot area under FSCs
                f = figure(1);
                if obj.configuration.show_figures == false
                    f.Visible = 'off';
                end
                plot(1:size(fsc_metrics, 2), fsc_metrics(2,:));
                hold on;
                %xline(fsc_area_imax, '--b', 'Optimal tilts num', 'LineWidth', 1);
                %xline(fsc_area_imax_relaxed, '--r', 'Optimal relaxed tilts num', 'LineWidth', 1);
                title('Area under FSC curve as function of tilts amount');
                xlabel('Tilts amount (exposure order)');
                ylabel('Area under FSC, Angstrom');
                hold off;
                saveas(f,particles_path + filesep + "map_bin_" + binning + "_1to" + string(length(fsc_cell)) + "_area_under_fsc", "fig");
                saveas(f,particles_path + filesep + "map_bin_" + binning + "_1to" + string(length(fsc_cell)) + "_area_under_fsc", "png");
                close(f);
            end
            
            % TODO: rewrite part below during refactoring
            % (copy-paste from above functionality)
            % TODO: make here final map reconstruction using the optimal
            % number of tilt images according to FSC metrics!!!
            k_optimal = fsc_area_imax_relaxed;
            for i = 1:N
                tomos.set_defocus(i, char(string(defocus_files{tomos_id(i)}.folder) + filesep + string(defocus_files{tomos_id(i)}.name)));
                if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                    error('ERROR: Using dose_symmetric_parallel tilt scheme is not fully implemented yet, sorry!');
                    % TODO: review condition in this branch
%                         for j = 1:size(tomos.defocus, 1)
%                             if tilt_angles(dose_order == j) >= -((floor(P/2) - k + 1) * tilt_angle_step)  && tilt_angles(dose_order == j) <= ((floor(P/2) - k + 1) * tilt_angle_step)
%                                 if dose > 0
%                                     tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
%                                 end
%                                 tomos.proj_weight(dose_order == j,1,i) = 1;
%                             else
%                                 tomos.proj_weight(dose_order == j,1,i) = 0;
%                             end
%                         end
                elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                    for j = 1:size(tomos.defocus, 1)
                        if  j <= k_optimal
                            if dose > 0
                                tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
                            end
                            tomos.proj_weight(dose_order == j,1,i) = 1;
                        else
                            tomos.proj_weight(dose_order == j,1,i) = 0;
                        end
                    end
                end
            end
            tomos_name = char(particles_path + filesep + "tomos_bin_" + binning + "_1to" + k_optimal + ".tomostxt");
            tomos.save(tomos_name);

            ptcls = SUSAN.Data.ParticlesInfo(combined_table, tomos);
            ptcls.half_id(1:particle_count) = 1;
            ptcls.half_id(particle_count+1:end) = 2;
            particles_raw = char(particles_path + filesep + "particles_bin_" + binning + "_1to" + k_optimal + ".ptclsraw");
            ptcls.save(particles_raw);
            
            if obj.configuration.use_SUSAN_averager == false
                error('ERROR: Dynamo averager is not fully implemented yet, sorry!');
                % TODO: review this part of code
%                     if dose > 0
%                         real_particles_path = char(particles_path + filesep + "particles_bin_" + binning + "_bs_" + box_size + "_dw");
%                     else
%                         real_particles_path = char(particles_path + filesep  + "particles_bin_" + binning + "_bs_" + box_size);
%                     end
%                     
%                     if exist(real_particles_path, "dir")
%                         rmdir(real_particles_path, "s");
%                     end
%                     
%                     mkdir(real_particles_path);
%                     if obj.configuration.use_SUSAN_particle_generator == true
%                         subtomos = SUSAN.Modules.SubtomoRec;
%                         subtomos.gpu_list = 0:gpuDeviceCount - 1;
%                         %subtomos.padding = round(box_size / binning);
%                         subtomos.set_ctf_correction(char(per_particle_ctf_correction)); % try also wiener if you like
%                         %subtomos.set_padding_policy(char(padding_policy));
%                         subtomos.set_normalization(char(normalization));
%                         subtomos.reconstruct(char(real_particles_path), tomos_name, particles_raw, box_size);
%                     else
%                         % TODO: dtcrop
%                     end
%                     
%                     vol1 = daverage(char(real_particles_path),'-t', new_table_1, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
%                     vol2 = daverage(char(real_particles_path),'-t', new_table_2, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
%                     
%                     vol1 = vol1.average;
%                     vol2 = vol2.average;
            else
                avg = SUSAN.Modules.Averager;

                if obj.configuration.gpu == -1
                    avg.gpu_list = 0:gpuDeviceCount - 1;
                else
                    avg.gpu_list = obj.configuration.gpu - 1;
                end

                avg.bandpass.highpass = 0;
                avg.bandpass.lowpass = (box_size_binned / 2) - 1;

                if obj.configuration.susan_padding > 1 || obj.configuration.susan_padding == 0
                    if binning > 1
                        avg.padding = round(obj.configuration.susan_padding / binning);
                    else
                        avg.padding = obj.configuration.susan_padding;
                    end
                elseif obj.configuration.susan_padding > 0 && obj.configuration.susan_padding <= 1
                    avg.padding = round(obj.configuration.susan_padding * box_size_binned);
                else
                    avg.padding = round(box_size_binned / 4);
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

                avg.reconstruct(char(string(particles_path) + filesep + "map_bin_" + binning + "_1to" + k_optimal), tomos_name, particles_raw, box_size_binned);
            end

            movefile(particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_class001.mrc", particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_final.mrc");
            movefile(particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_class001_half1.mrc", particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_half_1_final.mrc");
            movefile(particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_class001_half2.mrc", particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_half_2_final.mrc");
            
            vol1 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_half_1_final.mrc")));
            vol2 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_1to" + k_optimal + "_half_2_final.mrc")));

            fsc = dfsc(vol1, vol2, 'apix', scaled_apix, 'show', 'off', 'mask', mask, 'sym', sym);

            if isfield(fsc, "res_0143")
                fsc_res = fsc.res_0143;
            else
                fsc_res = fsc.res_013;
            end

            fid = fopen(particles_path + filesep + "ds_ini_bin_" + binning + "_1to" + k_optimal + "_resolution_" + fsc_res + ".txt", "w+");
            % TODO: write fsc into file
            fprintf(fid, "%s\n", fsc_res);
            fclose(fid);
            fsc.area = sum(fsc.fsc);
            disp("INFO:FSC_RES (optimal tlts num.): " + fsc_res + " Angstrom");
            disp("INFO:FSC_AREA (optimal tlts num.): " + fsc.area + " Angstrom");
            
        end
    end
end

