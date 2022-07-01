classdef DynamoAlignmentProject < Module
    
    methods
        
        function obj = DynamoAlignmentProject(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = process(obj)
            
            if isfield(obj.configuration, "apix")
                apix = obj.configuration.apix * obj.configuration.ft_bin;
            else
                
                if isfield(obj.configuration, "greatest_apix")
                    apix = obj.configuration.greatest_apix * obj.configuration.ft_bin;
                else
                    apix = obj.configuration.tomograms.tomogram_001.apix * obj.configuration.ft_bin;
                end
                
            end
            
            if isfield(obj.configuration, "binning")
                binning = obj.configuration.binning;
            else
                binning = obj.configuration.template_matching_binning;
            end
            
            project_name = char(obj.configuration.project_name + "_bin_" + binning);
            alignment_project_folder_path = obj.output_path + string(filesep) + "alignment_project_1_bin_" + binning;
            
            if ~exist(alignment_project_folder_path + filesep + project_name, "dir")
                [status_mkdir, message, message_id] = mkdir(alignment_project_folder_path);
                
                %                 if ~exist(alignment_project_folder_path, "dir")
                %                 else
                %
                %                     rmdir(alignment_project_folder_path, "s");
                %                     [status_mkdir, message, message_id] = mkdir(alignment_project_folder_path);
                %                 end
                
                return_path = cd(alignment_project_folder_path);
                
                paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "prelast");
                
                particle_counter = 0;
                
                % Calculate available size of CPU pool to be opened 
                % for averaging (and for CPU-based classification)
                cpu_poolsize = getCpuPoolSize(obj.configuration.cpu_fraction, obj.configuration.environment_properties.cpu_count_physical);
                
                if isempty(paths) || obj.configuration.reference == "template"
                    previous_binning = 0;
                    template = getTemplate(obj.configuration);
                    template_em_files = {char(alignment_project_folder_path + string(filesep) + "template.em")};
                    mask = getMask(obj.configuration);
                    
                    mask_em_files = {char(alignment_project_folder_path + string(filesep) + "mask.em")};
                    tab_all_path = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder + string(filesep) + "*.tbl");
                    tables = {char(string(tab_all_path.folder) + string(filesep) + tab_all_path.name)};
                    new_table = dread(tables{1});
                    dwrite(new_table, 'tables.tbl');
                    if obj.configuration.as_boxes == 1
                        
                        if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "*_dw.Boxes" + filesep + "batch_*" + filesep + "*.em";
                        else
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "*.Boxes" + filesep + "batch_*" + filesep + "*.em";
                        end
                        
                    else
                        
                        if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "*_dw" + filesep + "*.em";
                        else
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "*" + filesep + "*.em";
                        end
                        
                    end
                    
                    particles = dir(particles_path);
                    particle = dread([particles(1).folder filesep particles(1).name]);
                    
                    box_size = (size(template, 1) / size(particle, 1));
                    
                    if mod(box_size, 2) == 1
                        disp("INFO: resulting box size is odd, adding 1 to make it even!")
                        box_size = box_size + 1;
                    end
                    
                    if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                        mask = dread(obj.configuration.mask_path);
                        mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                    else
                        % TODO:NOTE: introduce flag for doing iteration before
                        % or after
                        if obj.configuration.use_elliptic_mask == true && obj.configuration.classes > 1
                            smoothing_pixels = ((size(mask)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                            mask = dynamo_ellipsoid(((size(mask) .* obj.configuration.radii_ratio) - smoothing_pixels), length(mask), length(mask) / 2, smoothing_pixels);
                        else
                            smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                            mask_sphere = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                            mask = generateMaskFromTemplate(obj.configuration, template) .* mask_sphere;
                        end
                        
                    end
                    
                    if box_size > 1
                        template = dynamo_crop(template, size(particle, 1));
                        mask = dynamo_crop(mask, size(particle, 1));
                    elseif box_size < 1
                        template = dynamo_embed(template, size(particle, 1));
                        mask = dynamo_embed(mask, size(particle, 1));
                    end
                    
                    dwrite(template, template_em_files{1});
                    dwrite(mask, mask_em_files{1});
                    
                    if obj.configuration.use_noise_classes == true
                        
                        for i = 2:obj.configuration.classes
                            noise_template{i} = rand([size(particle, 1) size(particle, 1) size(particle, 1)]) * obj.configuration.noise_scaling_factor;
                            template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "template_" + i + ".em");
                            dwrite(noise_template{i}, template_em_files{i});
                            mask_em_files{i} = char(alignment_project_folder_path + string(filesep) + "mask_" + i + ".em");
                            dwrite(mask, mask_em_files{i});
                        end
                        
                    end
                    
                elseif ~isempty(paths) || obj.configuration.reference == "average"
                    paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "prelast");
                    
                    if ~isempty(paths)
                        alignment_folder = dir(paths{1} + filesep + "alignment_project*");
                        alignment_folder_splitted = strsplit(alignment_folder.name, "_");
                        previous_binning = str2double(alignment_folder_splitted{end});
                        iteration_path = dir(paths{1} + filesep + "*" + filesep + "*" + filesep + "results" + filesep + "ite_*");
                        tab_all_path = dir(string(iteration_path(end - 1).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "*.tbl");
                    else
                        tab_all_path = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder + string(filesep) + "*.tbl");
                        tab_all_path_name = strsplit(tab_all_path.name, "_");
                        previous_binning = str2double(tab_all_path_name{5});
                    end
                    
                    if obj.configuration.classes == 1 && obj.configuration.swap_particles == false && (contains(tab_all_path(1).folder, "bin_" + previous_binning + "_eo" + filesep) || contains(tab_all_path(1).folder, "particles"))
                        counter = 0;
                        for i = 1:length(tab_all_path)
                            table = dread(string(tab_all_path(i).folder) + filesep + tab_all_path(i).name);
                            sub_table = table(:, :);
                            sub_tables{counter + 1} = sub_table;
                            counter = counter + 1;
                            particle_counter = particle_counter + length(sub_table);
                            %                             if isempty(new_table)
                            %                                 new_table = sub_table;
                            %                             else
                            %                                 new_table(end+1:length(sub_table),:) = sub_table;
                            %                             end
                        end
                        
                        if contains(tab_all_path(1).folder, "particles")
                            tab_all_path = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder + string(filesep) + "*.tbl");
                            
                            for i = 1:length(tab_all_path)
                                tables{i} = char(string(tab_all_path(end).folder) + string(filesep) + tab_all_path(i).name);
                            end
                            
                            %                             avge = daverage(char(particles_path), '-t', sub_table, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                            %                             template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                            %                             dwrite(avge.average, template_em_files{i});
                            %                             template = avge.average;
                            
                            new_table = dread(tables{1});
 
                            if binning > 1
                                aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true, binning);
                            else
                                aligned_tilt_stacks = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                            end
                            
                            [width, height, z] = getHeightAndWidthFromHeader(string(aligned_tilt_stacks(1).folder) + filesep + string(aligned_tilt_stacks(1).name), -1);
                            %tlt_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "tlt", "last");
                            tlt_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".tlt");
                            %defocus_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "defocus", "last");
                            defocus_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".defocus");
                            tomos_id = unique(new_table(:, 20));
                            
                            N = length(tomos_id);
                            
                            if isfield(obj.configuration, "tilt_angles")
                                P = length(obj.configuration.tilt_angles);
                            else
                                P = length(obj.configuration.tomograms.tomogram_001.original_angles);
                            end
                            
                            tomos = SUSAN.Data.TomosInfo(N, P);
                            dose_per_projection = obj.configuration.dose / P;
                            
                            for i = 1:N
                                tomos.tomo_id(i) = tomos_id(i);
                                stack_path = string(aligned_tilt_stacks(i).folder) + filesep + string(aligned_tilt_stacks(i).name);
                                tomos.set_stack (i, stack_path);
                                tomos.set_angles (i, char(string(tlt_files{tomos_id(i)}(1).folder) + filesep + tlt_files{tomos_id(i)}(1).name));
                                % TODO: exclude line if ctf_correction_method
                                % is not "defocus_file"
                                tomos.set_defocus(i, char(string(defocus_files{tomos_id(i)}(1).folder) + filesep + string(defocus_files{tomos_id(i)}(1).name)));
                                
                                if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                                    field_names = fieldnames(obj.configuration.tomograms);
                                    if configuration.tilt_stacks == false
                                        projections_in_high_dose_image = configuration.tomograms.(field_names{tomos_id(i)}).high_dose_frames / configuration.tomograms.(field_names{tomos_id(i)}).low_dose_frames;
                                    else
                                        projections_in_high_dose_image = 0;
                                    end
                                    for j = 1:size(tomos.defocus, 1)
                                        
                                        if obj.configuration.dose_weight_first_image == true
                                            
                                            if obj.configuration.high_dose == true
                                                tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j) - 1 + projections_in_high_dose_image) * dose_per_projection);
                                            else
                                                tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j)) * dose_per_projection);
                                            end
                                            
                                        else
                                            
                                            if obj.configuration.high_dose == true
                                                
                                                if j > 1
                                                    tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j) - 1 + projections_in_high_dose_image) * dose_per_projection);
                                                end
                                                
                                            else
                                                tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j) - 1) * dose_per_projection);
                                            end
                                            
                                        end
                                        
                                    end
                                    
                                end
                                
                                if obj.configuration.exclude_projections == true && obj.configuration.use_SUSAN == true
                                    
                                    if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                                        
                                        for j = 1:size(tomos.defocus, 1)
                                            
                                            if tilt_angles(dose_order == j) >= -((floor(P / 2) - k + 1) * tilt_angle_step) && tilt_angles(dose_order == j) <= ((floor(P / 2) - k + 1) * tilt_angle_step)
                                                tomos.proj_weight(dose_order == j, 1, i) = 1;
                                            else
                                                tomos.proj_weight(dose_order == j, 1, i) = 0;
                                            end
                                            
                                        end
                                        
                                    elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                                        
                                        for j = 1:size(tomos.defocus, 1)
                                            
                                            if j < max(dose_order) - exclude_projections
                                                tomos.proj_weight(dose_order == j, 1, i) = 1;
                                            else
                                                tomos.proj_weight(dose_order == j, 1, i) = 0;
                                            end
                                            
                                        end
                                        
                                    end
                                    
                                end
                                
                                if isfield(obj.configuration, "apix") && obj.configuration.apix ~= 0
                                    tomos.pix_size(i) = obj.configuration.apix * obj.configuration.ft_bin * binning;
                                else
                                    tomos.pix_size(i) = obj.configuration.greatest_apix * obj.configuration.ft_bin * binning;
                                end
                                
                                tomos.tomo_size(i, :) = [width, height, obj.configuration.reconstruction_thickness / binning];
                                
                            end
                            
                            tomos_name = char("tomos_bin_" + binning + ".tomostxt");
                            tomos.save(tomos_name);
                            
                            %%
                            %                         new_table(:,[24 25 26]) = new_table(:,[24 25 26]) + new_table(:,[4 5 6]);
                            %                         new_table(:,[4 5 6]) = 0;
                            %                         new_table(:,[24 25 26]) = previous_binning/binning*new_table(:,[24 25 26])+1;
                            %                         table_name = char("table_bin_" + binning + ".tbl");
                            %                         dwrite(new_table,table_name);
                            particles_raw = char("particles_bin_" + binning + ".ptclsraw");
                            ptcls = SUSAN.Data.ParticlesInfo(new_table, tomos);
                            
                            if obj.configuration.ctf_correction_method == "IMOD"
                                tmp_positions = ptcls.position(:, 3);
                                ptcls.position(:, 3) = 0;
                                ptcls.update_defocus(tomos);
                                ptcls.position(:, 3) = tmp_positions;
                            elseif obj.configuration.ctf_correction_method == "defocus_file"
                            elseif obj.configuration.ctf_correction_method == "SUSAN"
                                sampling = size(template, 1); % spacing between particles, in pixels
                                grid_ctf = SUSAN.Data.ParticlesInfo.grid2D(sampling, tomos);
                                grid_ctf.save('grid_ctf.ptclsraw');
                                %% Create CtfEstimator
                                ctf_est = SUSAN.Modules.CtfEstimator(obj.configuration.SUSAN_ctf_box_size);
                                ctf_est.binning = obj.configuration.SUSAN_binning; % No binning (2^0).
                                
                                if obj.configuration.gpu == -1
                                    ctf_est.gpu_list = 0:gpuDeviceCount - 1;
                                else
                                    ctf_est.gpu_list = obj.configuration.gpu - 1;
                                end
                                
                                %ctf_est.gpu_list = [0 1 2 3]; % 4 GPUs available.
                                
                                ctf_est.resolution.min = obj.configuration.template_matching_binning * apix; % angstroms
                                ctf_est.resolution.max = binning * apix;
                                
                                if isfield(obj.configuration, "global_lower_defocus_average_in_angstrom")
                                    ctf_est.defocus.min = configuration.global_lower_defocus_average_in_angstrom;
                                    ctf_est.defocus.max = configuration.global_upper_defocus_average_in_angstrom;
                                elseif isfield(obj.configuration, "nominal_defocus_in_nm") && obj.configuration.nominal_defocus_in_nm ~= 0
                                    % TODO: could be also 2 numbers for lower and upper
                                    % limit or factors in different variable names
                                    ctf_est.defocus.min = round(obj.configuration.nominal_defocus_in_nm / obj.configuration.defocus_limit_factor) * 10^4;
                                    ctf_est.defocus.max = round(obj.configuration.nominal_defocus_in_nm * obj.configuration.defocus_limit_factor) * 10^4;
                                else
                                    ctf_est.defocus.min = obj.configuration.SUSAN_defocus_min; % angstroms
                                    ctf_est.defocus.max = obj.configuration.SUSAN_defocus_max; % angstroms
                                end
                                
                                tomos_ctf = ctf_est.estimate('ctf_grid', 'grid_ctf.ptclsraw', ...
                                    tomos_name);
                                tomos_ctf.save(tomos_name);
                            end
                            
                            ptcls.save(particles_raw);
                            
                            %%
                            avg = SUSAN.Modules.Averager;
                            
                            if obj.configuration.gpu == -1
                                avg.gpu_list = 0:gpuDeviceCount - 1;
                            else
                                avg.gpu_list = obj.configuration.gpu - 1;
                            end
                            
                            box_size = round((size(template, 1) * obj.configuration.box_size) * (previous_binning / binning));
                            
                            if mod(box_size, 2) == 1
                                box_size = box_size + 1;
                            end
                            
                            avg.bandpass.lowpass = min(obj.configuration.susan_lowpass, (box_size / 2) / 2);
                            avg.padding = obj.configuration.susan_padding / binning;
                            avg.rec_halves = true;
                            
                            if (obj.configuration.per_particle_ctf_correction == "wiener_ssnr")
                                avg.set_ctf_correction(char("wiener_ssnr"), obj.configuration.ssnr(1), obj.configuration.ssnr(2)); % what about SSNR....: set_ctf_correction('wiener_ssnr', 1, 0.8);
                            else
                                avg.set_ctf_correction(char(obj.configuration.per_particle_ctf_correction)); % what about SSNR....: set_ctf_correction('wiener_ssnr', 1, 0.8);
                            end
                            
                            avg.set_padding_policy(char(obj.configuration.padding_policy));
                            avg.set_normalization(char(obj.configuration.normalization));
                            
                            if obj.configuration.use_symmetrie == true
                                avg.set_symmetry(char(obj.configuration.expected_symmetrie));
                            end
                            
                            %                         if obj.configuration.susan_box_size > 0
                            %                             box_size = round((size(template,1) * obj.configuration.susan_box_size) * (previous_binning / binning)); %obj.configuration.susan_box_size;
                            %                             obj.dynamic_configuration.susan_box_size = 1;
                            %                         else
                            
                            %                         end
                            if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                                particles_path = char("../../particles/particles_bin_" + binning + "_bs_" + box_size + "_dw");
                            else
                                particles_path = char("../../particles/particles_bin_" + binning + "_bs_" + box_size);
                            end
                            
                            avg.reconstruct(char("ds_ini_bin_" + binning), tomos_name, particles_raw, box_size);
                            %%
                            
                            subtomos = SUSAN.Modules.SubtomoRec;
                            
                            if obj.configuration.gpu == -1
                                subtomos.gpu_list = 0:gpuDeviceCount - 1;
                            else
                                subtomos.gpu_list = obj.configuration.gpu - 1;
                            end
                            
                            subtomos.padding = round(obj.configuration.susan_padding / binning);
                            
                            subtomos.set_ctf_correction(char(obj.configuration.per_particle_ctf_correction)); % try also wiener if you like
                            subtomos.set_padding_policy(char(obj.configuration.padding_policy));
                            subtomos.set_normalization(char(obj.configuration.normalization));
                            subtomos.reconstruct(char(particles_path), tomos_name, particles_raw, box_size);
                            
                            new_table = cleanCroppedParticlesTable(new_table, char(particles_path));
                            
                            if obj.configuration.as_boxes == 1
                                % dBoxes.convertSimpleData(char("../../particles/particles_bin_" + binning  + "_bs_" + box_size),...
                                %     [char("../../particles/particles_bin_" + binning  + "_bs_" + box_size) '.Boxes'],...
                                %     'batch', obj.configuration.particle_batch, 'dc', obj.configuration.direct_copy);
                                ownDbox(string(particles_path), ...
                                    string([char(particles_path) '.Boxes']));
                                
                                [status, message, messageid] = rmdir(char(particles_path), 's');
                                particles_path = [char(particles_path) '.Boxes'];
                                %                             new_table(:,1) = 1:length(new_table);
                                %movefile(char([char("../../particles/particles_bin_" + binning) '.Boxes']), char("../../particles/particles_bin_" + binning));
                            end
                            
                            %
                            %                         if obj.configuration.classes == 1
                            %                             for i = 1:2
                            %                                 if length(sub_tables) == 1
                            %                                     average = daverage(char(particles_path), '-t', new_table, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                            %                                 else
                            %                                     average = daverage(char(particles_path), '-t', sub_tables{i}, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                            %                                 end
                            %                                 template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                            %                                 dwrite(average.average, template_em_files{i});
                            %                             end
                            %                             obj.configuration.classes = 2;
                            %                         else
                            avge = daverage(char(particles_path), '-t', new_table, 'mw', cpu_poolsize);
                            template_em_files{1} = char(alignment_project_folder_path + string(filesep) + "average_" + 1 + ".em");
                            dwrite(avge.average, template_em_files{1});
                            
                        else
                            tab_all_path = dir(string(iteration_path(end).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "*.tbl");
                            
                            for i = 1:length(tab_all_path)
                                tables{i} = char(string(tab_all_path(end).folder) + string(filesep) + tab_all_path(i).name);
                            end
                            
                            if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                                mask = dread(obj.configuration.mask_path);
                                mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                                dwrite(mask, char(alignment_project_folder_path + string(filesep) + "mask.em"))
                                mask_em_path = dir(char(alignment_project_folder_path + string(filesep) + "mask.em"));
                            else
                                mask_em_path = dir(string(paths{1}) + filesep + "*/*_eo/settings/mask.em");
                                
                                if isempty(mask_em_path)
                                    mask_em_path = dir(string(paths{1}) + filesep + "*/*/settings/mask.em");
                                end
                                
                            end
                            
                            template_em_path = dir(string(iteration_path(end).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "average_ref_*.em");
                            
                            for i = 1:length(template_em_path)
                                mask_em_files{i} = char(string(mask_em_path(1).folder) + string(filesep) + mask_em_path(1).name);
                            end
                            
                            for i = 1:length(template_em_path)
                                template_em_files{i} = char(string(template_em_path(i).folder) + string(filesep) + template_em_path(i).name);
                            end
                            
                            template = dread(template_em_files{1});
                        end
                        
                    elseif length(tab_all_path) == length(obj.configuration.selected_classes) && isscalar(obj.configuration.selected_classes(1))
                        %                     new_table = [];
                        counter = 0;
                        
                        for i = 1:length(tab_all_path)
                            
                            if any(i == obj.configuration.selected_classes)
                                table = dread(string(tab_all_path(i).folder) + filesep + tab_all_path(i).name);
                                sub_table = table(table(:, 34) == i, :);
                                sub_tables{counter + 1} = sub_table;
                                counter = counter + 1;
                                particle_counter = particle_counter + length(sub_table);
                                %                             if isempty(new_table)
                                %                                 new_table = sub_table;
                                %                             else
                                %                                 new_table(end+1:length(sub_table),:) = sub_table;
                                %                             end
                            end
                            
                        end
                        
                        tab_all_path = dir(string(iteration_path(end).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "*.tbl");
                        
                        for i = 1:length(tab_all_path)
                            tables{i} = char(string(tab_all_path(end).folder) + string(filesep) + tab_all_path(end).name);
                        end
                        
                        if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                            mask = dread(obj.configuration.mask_path);
                            mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                            dwrite(mask, char(alignment_project_folder_path + string(filesep) + "mask.em"))
                            mask_em_path = dir(char(alignment_project_folder_path + string(filesep) + "mask.em"));
                        else
                            mask_em_path = dir(string(paths{1}) + filesep + "*/*_eo/settings/mask.em");
                            
                            if isempty(mask_em_path)
                                mask_em_path = dir(string(paths{1}) + filesep + "*/*/settings/mask.em");
                            end
                            
                        end
                        
                        template_em_path = dir(string(iteration_path(end).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "average_ref_*.em");
                        
                        for i = 1:length(template_em_path)
                            mask_em_files{i} = char(string(mask_em_path(1).folder) + string(filesep) + mask_em_path(1).name);
                        end
                        
                        for i = 1:length(template_em_path)
                            template_em_files{i} = char(string(template_em_path(i).folder) + string(filesep) + template_em_path(i).name);
                        end
                        
                        template = dread(template_em_files{1});
                    else
                        
                        if ~iscell(obj.configuration.selected_classes)
                            
                            if any(length(tab_all_path) < obj.configuration.selected_classes)
                                error("ERROR: some or all of the selected class(es) are not available in previous run!")
                            end
                            
                        else
                            table = dread(string(tab_all_path(1).folder) + filesep + tab_all_path(1).name);
                            tomogram_indices = unique(table(:, 20));
                            
                            for i = 1:length(obj.configuration.selected_classes)
                                
                                if any(length(tab_all_path) < obj.configuration.selected_classes{i})
                                    error("ERROR: some or all of the selected class(es) are not available in previous run for tomogram class entry " + i + " with tomogram index " + tomogram_indices(i) + "!")
                                end
                                
                            end
                            
                        end
                        
                        tab_all_path = dir(string(iteration_path(end).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "*.tbl");
                        %                     new_table = [];
                        counter = 0;
                        
                        if ~iscell(obj.configuration.selected_classes)
                            
                            for i = 1:length(tab_all_path)
                                
                                if any(i == obj.configuration.selected_classes)
                                    table = dread(string(tab_all_path(i).folder) + filesep + tab_all_path(i).name);
                                    sub_table = table(table(:, 34) == i, :);
                                    sub_tables{counter + 1} = sub_table;
                                    counter = counter + 1;
                                    particle_counter = particle_counter + length(sub_table);
                                    %                             if isempty(new_table)
                                    %                                 new_table = sub_table;
                                    %                             else
                                    %                                 new_table(end+1:length(sub_table),:) = sub_table;
                                    %                             end
                                    tables{i} = char(alignment_project_folder_path + string(filesep) + "table_" + i + ".tbl");
                                    dwrite(sub_table, tables{i})
                                end
                                
                            end
                            
                        else
                            table_counter = 0;
                            
                            for i = 1:length(unique(tomogram_indices))
                                
                                for j = 1:length(tab_all_path)
                                    
                                    if any(j == obj.configuration.selected_classes{i})
                                        table_counter = table_counter + 1;
                                        table = dread(string(tab_all_path(j).folder) + filesep + tab_all_path(j).name);
                                        sub_table = table(table(:, 34) == j & table(:, 20) == tomogram_indices(i), :);
                                        sub_tables{counter + 1} = sub_table;
                                        counter = counter + 1;
                                        particle_counter = particle_counter + length(sub_table);
                                        %                             if isempty(new_table)
                                        %                                 new_table = sub_table;
                                        %                             else
                                        %                                 new_table(end+1:length(sub_table),:) = sub_table;
                                        %                             end
                                        tables{i} = char(alignment_project_folder_path + string(filesep) + "table_" + table_counter + "_tomogram_" + tomogram_indices(i) + "_class_" + j + ".tbl");
                                        dwrite(sub_table, tables{i})
                                    end
                                    
                                end
                                
                            end
                            
                        end
                        
                        mask_em_path = dir(string(paths{1}) + filesep + "*/*_eo/settings/mask.em");
                        
                        if isempty(mask_em_path)
                            mask_em_path = dir(string(paths{1}) + filesep + "*/*/settings/mask.em");
                        end
                        
                        template_em_path = dir(string(iteration_path(end - 1).folder) + filesep + iteration_path(end - 1).name + filesep + "averages" + filesep + "average_ref_*.em");
                        
                        if iscell(obj.configuration.selected_classes)
                            selected_classes = [];
                            
                            for i = 1:length(obj.configuration.selected_classes)
                                selected_classes = unique([selected_classes obj.configuration.selected_classes{i}']);
                            end
                            
                        else
                            selected_classes = obj.configuration.selected_classes;
                        end
                        
                        counter = 0;
                        
                        for i = 1:length(template_em_path)
                            
                            if any(i == selected_classes)
                                mask_em_files{counter + 1} = char(string(mask_em_path(1).folder) + string(filesep) + mask_em_path(1).name);
                                counter = counter + 1;
                            end
                            
                        end
                        
                        counter = 0;
                        template = [];
                        
                        for i = 1:length(template_em_path)
                            
                            if any(i == selected_classes)
                                template_em_files{counter + 1} = char(template_em_path(i).folder + string(filesep) + template_em_path(i).name);
                                counter = counter + 1;
                                
                                if isempty(template)
                                    template = dread(template_em_files{1});
                                else
                                    template = (template + dread(template_em_files{1})) / 2;
                                end
                                
                            end
                            
                        end
                        
                    end
                    
                end
                
                if previous_binning / binning == 0
                    box_size = round(size(template, 1) * obj.configuration.box_size);
                else
                    box_size = round(size(template, 1) * obj.configuration.box_size * (previous_binning / binning));
                end
                
                if mod(box_size, 2) == 1
                    box_size = box_size + 1;
                end
                
                if obj.configuration.as_boxes == true
                    
                    if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw.Boxes" + filesep + "batch_*" + filesep + "*.em";
                    else
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + ".Boxes" + filesep + "batch_*" + filesep + "*.em";
                    end
                    
                else
                    
                    if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw" + filesep + "*.em";
                    else
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + filesep + "*.em";
                    end
                    
                end
                
                if binning > 0 && (isempty(dir(particles_path))) % || length(dir(particles_path)) ~= particle_counter)
                    %                     if obj.configuration.as_boxes == true
                    %                         particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + ".Boxes";
                    %                     else
                    %                         particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size;
                    %                     end
                    %particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning;
                    disp("INFO: generating particles for binning " + binning);
                    %                     tmp_folder = getFilesFromLastModuleRun(obj.configuration, "TemplateMatchingPostProcessing", "");
                    %                     particle_boundaries_files = dir(tmp_folder{1} + filesep + "*.tbl");
                    %                     particle_boundaries = [];
                    %                     for i = 1:length(particle_boundaries_files)
                    %                         particle_boundaries_splitted = strsplit(particle_boundaries_files(i).name);
                    %                         particle_boundaries(end + 1) = num2str(particle_boundaries_splitted{end});
                    %                     end
                    template_em_files = {};
                    
                    if (~isfield(obj.configuration, "use_SUSAN") || obj.configuration.use_SUSAN ~= true) % binning >= obj.configuration.aligned_stack_binning &&
                        
                        if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw";
                        else
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size;
                        end
                        
                        if binning == 1
                            binned_tomograms_paths = getCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                            
                            if isempty(binned_tomograms_paths) == true
                                binned_tomograms_paths = getTomogramsFromStandardFolder(obj.configuration, true);
                            end
                            
                            binned_tomograms_paths_filtered = binned_tomograms_paths;
                            
                            if isempty(binned_tomograms_paths_filtered)
                                error("ERROR: no tomograms to crop particles are available for the selected binning level(" + binning + ")!");
                            end
                            
                        else
                            binned_tomograms_paths = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, binning);
                            
                            if isempty(binned_tomograms_paths) == true
                                binned_tomograms_paths = getBinnedTomogramsFromStandardFolder(obj.configuration, true, binning);
                            end
                            
                            binned_tomograms_paths_filtered = binned_tomograms_paths(contains({binned_tomograms_paths.name}, "bin_" + binning));
                            
                            if isempty(binned_tomograms_paths_filtered)
                                error("ERROR: no tomograms to crop particles are available for the selected binning level(" + binning + ")!");
                            end
                            
                        end
                        
                        new_table = [];
                        
                        if obj.configuration.classes == 1 && obj.configuration.swap_particles == false && exist("tab_all_path", "var") && contains(tab_all_path(1).folder, "bin_" + previous_binning + "_eo" + filesep)
                            
                            for i = 1:length(sub_tables)
                                sub_table = sub_tables{i};
                                
                                if previous_binning / binning > 1
                                    sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                    sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                    sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                    sub_table(:, 4) = 0;
                                    sub_table(:, 5) = 0;
                                    sub_table(:, 6) = 0;
                                    
                                    if previous_binning > binning
                                        sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                    else
                                        sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                    end
                                    
                                end
                                
                                indices = unique(sub_table(:, 20));
                                
                                for j = 1:length(indices)
                                    index = find(contains({binned_tomograms_paths_filtered.name}, sprintf("%03d", indices(j))));
                                    binned_tomogram_path = char(string(binned_tomograms_paths_filtered(index).folder) + string(filesep) + binned_tomograms_paths_filtered(index).name);
                                    dtcrop(binned_tomogram_path, sub_table(sub_table(:, 20) == indices(j), :), char(particles_path), box_size, 'allow_padding', obj.configuration.dynamo_allow_padding, 'inmemory', obj.configuration.dt_crop_in_memory, 'maxMb', obj.configuration.dt_crop_max_mb, 'asBoxes', obj.configuration.as_boxes);
 
                                end
                                
                                %                             if previous_binning == binning
                                %
                                %                             else
                                avge = daverage(char(particles_path), '-t', sub_table, 'mw', cpu_poolsize);
                                template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                                dwrite(avge.average, template_em_files{i});
                                %                             end
                                
                                if isempty(new_table)
                                    new_table = sub_table;
                                else
                                    new_table(end + 1:end + size(sub_table, 1), :) = sub_table;
                                end
                                
                            end
                            if ~obj.configuration.dynamo_allow_padding
                                new_table = cleanCroppedParticlesTable(new_table, char(particles_path));
                            end
                        else
                            
                            for i = 1:length(obj.configuration.selected_classes)
                                sub_table = sub_tables{i}(sub_tables{i}(:, 34) == obj.configuration.selected_classes(i), :);
                                
                                if previous_binning / binning > 1
                                    
                                    sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                    sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                    sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                    sub_table(:, 4) = 0;
                                    sub_table(:, 5) = 0;
                                    sub_table(:, 6) = 0;
                                    
                                    if previous_binning > binning
                                        sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                    else
                                        sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                    end
                                    
                                end
                                
                                indices = unique(sub_table(:, 20));
                                
                                for j = 1:length(indices)
                                    index = find(contains({binned_tomograms_paths_filtered.name}, sprintf("%03d", indices(j))));
                                    binned_tomogram_path = char(string(binned_tomograms_paths_filtered(index).folder) + string(filesep) + binned_tomograms_paths_filtered(index).name);
                                    dtcrop(binned_tomogram_path, sub_table(sub_table(:, 20) == indices(j), :), char(particles_path), box_size, 'allow_padding', obj.configuration.dynamo_allow_padding, 'inmemory', obj.configuration.dt_crop_in_memory, 'maxMb', obj.configuration.dt_crop_max_mb, 'asBoxes', obj.configuration.as_boxes);

                                    
                                end
                                
                                %                                	if obj.configuration.as_boxes == true
                                %                                     particles_path = particles_path + ".Boxes";
                                %                                 end
                                %                             if previous_binning == binning
                                %
                                %                             else
                                avge = daverage(char(particles_path), '-t', sub_table, 'mw', cpu_poolsize);
                                template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                                dwrite(avge.average, template_em_files{i});
                                %                             end
                                
                                if isempty(new_table)
                                    new_table = sub_table;
                                else
                                    new_table(end + 1:end + size(sub_table, 1), :) = sub_table;
                                end
                                
                            end
                            if ~obj.configuration.dynamo_allow_padding
                                new_table = cleanCroppedParticlesTable(new_table, char(particles_path));
                            end
                        end
                        
                        %TODO: needs to be tested if that is faster or make
                        %option for decision
                        if obj.configuration.as_boxes == 1
                            % dBoxes.convertSimpleData(char(particles_path),...
                            %     [char(particles_path) '.Boxes'],...
                            %     'batch', obj.configuration.particle_batch, 'dc', obj.configuration.direct_copy);
                            ownDbox(string(particles_path), string([char(particles_path) '.Boxes']));
                            
                            [status, message, messageid] = rmdir(char(particles_path), 's');
                            %                             new_table(:,1) = 1:length(new_table);
                            %                             movefile(char([char(particles_path) '.Boxes']), char(particles_path));
                        end
                        
                        %
                        if obj.configuration.use_noise_classes == true
                            
                            for i = length(obj.configuration.selected_classes) + 1:obj.configuration.classes
                                noise_template{i} = rand(size(template) * (previous_binning / binning)) * obj.configuration.noise_scaling_factor;
                                template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "template_" + i + ".em");
                                dwrite(noise_template{i}, template_em_files{i});
                                %                                 template_em_files{i} = noise_template{i};
                                %                                 mask_em_files{i} = char(alignment_project_folder_path + string(filesep) + "mask_" + i + ".em");
                                %                                 dwrite(mask, mask_em_files{i});
                            end
                            
                        end
                        if exist("avge", "var")
                            template = avge.average;
                        end
                    else
                        new_table = [];
                        
                        if obj.configuration.classes == 1 && obj.configuration.swap_particles == false && exist("tab_all_path", "var") && contains(tab_all_path(1).folder, "bin_" + previous_binning + "_eo" + filesep)
                            
                            for i = 1:length(sub_tables)
                                sub_table = sub_tables{i};
                                
                                if previous_binning / binning > 1
                                    
                                    sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                    sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                    sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                    sub_table(:, 4) = 0;
                                    sub_table(:, 5) = 0;
                                    sub_table(:, 6) = 0;
                                    
                                    if previous_binning > binning
                                        sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                    else
                                        sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                    end
                                    
                                end
                                
                                %sub_table(:,20) = i;
                                if isempty(new_table)
                                    new_table = sub_table;
                                else
                                    new_table(end + 1:end + size(sub_table, 1), :) = sub_table;
                                end
                                
                            end
                            
                        else
                            
                            if ~iscell(obj.configuration.selected_classes)
                                
                                for i = 1:length(obj.configuration.selected_classes)
                                    sub_table = sub_tables{i}(sub_tables{i}(:, 34) == obj.configuration.selected_classes(i), :);
                                    
                                    if previous_binning / binning > 1
                                        
                                        sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                        sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                        sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                        sub_table(:, 4) = 0;
                                        sub_table(:, 5) = 0;
                                        sub_table(:, 6) = 0;
                                        
                                        if previous_binning > binning
                                            sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                            sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                            sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                        else
                                            sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                            sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                            sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                        end
                                        
                                    end
                                    
                                    %sub_table(:,20) = i;
                                    if isempty(new_table)
                                        new_table = sub_table;
                                    else
                                        new_table(end + 1:end + size(sub_table, 1), :) = sub_table;
                                    end
                                    
                                end
                                
                            else
                                
                                for i = 1:length(selected_classes)
                                    
                                    if i == 1
                                        new_table = [];
                                    end
                                    
                                    sub_table = [];
                                    
                                    for j = 1:length(sub_tables)
                                        
                                        if isempty(sub_table)
                                            sub_table = sub_tables{j}(sub_tables{j}(:, 34) == selected_classes(i), :);
                                        else
                                            sub_table(end + 1:end + length(sub_tables{j}(sub_tables{j}(:, 34) == selected_classes(i), :)), :) = sub_tables{j}(sub_tables{j}(:, 34) == selected_classes(i), :);
                                        end
                                        
                                    end
                                    
                                    if previous_binning / binning > 1
                                        
                                        sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                        sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                        sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                        sub_table(:, 4) = 0;
                                        sub_table(:, 5) = 0;
                                        sub_table(:, 6) = 0;
                                        
                                        if previous_binning >= binning
                                            sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                            sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                            sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                        else
                                            sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                            sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                            sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                        end
                                        
                                    end
                                    
                                    if isempty(new_table)
                                        new_table = sub_table;
                                    else
                                        new_table(end + 1:end + size(sub_table, 1), :) = sub_table;
                                    end
                                    
                                end
                                
                            end
                            
                        end
                        
                        if binning > 1
                            aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true, binning);
                        else
                            aligned_tilt_stacks = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                        end
                        
                        [width, height, z] = getHeightAndWidthFromHeader(string(aligned_tilt_stacks(1).folder) + filesep + string(aligned_tilt_stacks(1).name), -1);
                        %tlt_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "tlt", "last");
                        tlt_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".tlt");
                        %defocus_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "defocus", "last");
                        defocus_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, ".defocus");
                        tomos_id = unique(new_table(:, 20));
                        
                        N = length(tomos_id);
                        
                        if isfield(obj.configuration, "tilt_angles")
                            P = length(obj.configuration.tilt_angles);
                        else
                            P = length(obj.configuration.tomograms.tomogram_001.original_angles);
                        end
                        
                        tomos = SUSAN.Data.TomosInfo(N, P);
                        dose_per_projection = obj.configuration.dose / P;
                        
                        for i = 1:N
                            tomos.tomo_id(i) = tomos_id(i);
                            stack_path = string(aligned_tilt_stacks(find(contains({aligned_tilt_stacks(:).name}, sprintf("%03d", tomos_id(i))))).folder) + filesep + string(aligned_tilt_stacks(find(contains({aligned_tilt_stacks(:).name}, sprintf("%03d", tomos_id(i))))).name);
                            tomos.set_stack (i, stack_path);
                            tomos.set_angles (i, char(string(tlt_files{tomos_id(i)}(1).folder) + filesep + tlt_files{tomos_id(i)}(1).name));
                            % TODO: exclude line if ctf_correction_method
                            % is not "defocus_file"
                            tomos.set_defocus(i, char(string(defocus_files{tomos_id(i)}(1).folder) + filesep + string(defocus_files{tomos_id(i)}(1).name)));
                            
                            if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                                field_names = fieldnames(obj.configuration.tomograms);
                                if obj.configuration.tilt_stacks == false
                                    projections_in_high_dose_image = obj.configuration.tomograms.(field_names{tomos_id(i)}).high_dose_frames / obj.configuration.tomograms.(field_names{tomos_id(i)}).low_dose_frames;
                                else
                                    projections_in_high_dose_image = 0;
                                end
                                for j = 1:size(tomos.defocus, 1)
                                    
                                    if obj.configuration.dose_weight_first_image == true
                                        
                                        if obj.configuration.tomograms.(field_names{tomos_id(i)}).high_dose == true
                                            tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j) - 1 + projections_in_high_dose_image) * dose_per_projection);
                                        else
                                            tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j)) * dose_per_projection);
                                        end
                                        
                                    else
                                        
                                        if obj.configuration.tomograms.(field_names{tomos_id(i)}).high_dose == true
                                            
                                            if j > 1
                                                tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j) - 1 + projections_in_high_dose_image) * dose_per_projection);
                                            end
                                            
                                        else
                                            tomos.defocus(j, 6, i) = obj.configuration.b_factor_per_projection * ((obj.configuration.dose_order(j) - 1) * dose_per_projection);
                                        end
                                        
                                    end
                                    
                                end
                                
                            end
                            
                            if obj.configuration.exclude_projections == true && obj.configuration.use_SUSAN == true
                                
                                if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                                    
                                    for j = 1:size(tomos.defocus, 1)
                                        
                                        if tilt_angles(dose_order == j) >= -((floor(P / 2) - exclude_projections + 1) * tilt_angle_step) && tilt_angles(dose_order == j) <= ((floor(P / 2) - exclude_projections + 1) * tilt_angle_step)
                                            tomos.proj_weight(dose_order == j, 1, i) = 1;
                                        else
                                            tomos.proj_weight(dose_order == j, 1, i) = 0;
                                        end
                                        
                                    end
                                    
                                elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                                    
                                    for j = 1:size(tomos.defocus, 1)
                                        
                                        if j < max(dose_order) - k
                                            tomos.proj_weight(dose_order == j, 1, i) = 1;
                                        else
                                            tomos.proj_weight(dose_order == j, 1, i) = 0;
                                        end
                                        
                                    end
                                    
                                end
                                
                            end
                            
                            if isfield(obj.configuration, "apix") && obj.configuration.apix ~= 0
                                tomos.pix_size(i) = obj.configuration.apix * obj.configuration.ft_bin * binning;
                            else
                                tomos.pix_size(i) = obj.configuration.greatest_apix * obj.configuration.ft_bin * binning;
                            end
                            
                            tomos.tomo_size(i, :) = [width, height, obj.configuration.reconstruction_thickness / binning];
                            
                        end
                        
                        tomos_name = char("tomos_bin_" + binning + ".tomostxt");
                        tomos.save(tomos_name);
                        
                        %%
                        %                         new_table(:,[24 25 26]) = new_table(:,[24 25 26]) + new_table(:,[4 5 6]);
                        %                         new_table(:,[4 5 6]) = 0;
                        %                         new_table(:,[24 25 26]) = previous_binning/binning*new_table(:,[24 25 26])+1;
                        %                         table_name = char("table_bin_" + binning + ".tbl");
                        %                         dwrite(new_table,table_name);
                        particles_raw = char("particles_bin_" + binning + ".ptclsraw");
                        ptcls = SUSAN.Data.ParticlesInfo(new_table, tomos);
                        
                        if obj.configuration.ctf_correction_method == "IMOD"
                            tmp_positions = ptcls.position(:, 3);
                            ptcls.position(:, 3) = 0;
                            ptcls.update_defocus(tomos);
                            ptcls.position(:, 3) = tmp_positions;
                        elseif obj.configuration.ctf_correction_method == "defocus_file"
                        elseif obj.configuration.ctf_correction_method == "SUSAN"
                            sampling = size(template, 1); % spacing between particles, in pixels
                            grid_ctf = SUSAN.Data.ParticlesInfo.grid2D(sampling, tomos);
                            grid_ctf.save('grid_ctf.ptclsraw');
                            %% Create CtfEstimator
                            ctf_est = SUSAN.Modules.CtfEstimator(obj.configuration.SUSAN_ctf_box_size);
                            ctf_est.binning = obj.configuration.SUSAN_binning; % No binning (2^0).
                            
                            if obj.configuration.gpu == -1
                                ctf_est.gpu_list = 0:gpuDeviceCount - 1;
                            else
                                ctf_est.gpu_list = obj.configuration.gpu - 1;
                            end
                            
                            %ctf_est.gpu_list = [0 1 2 3]; % 4 GPUs available.
                            
                            ctf_est.resolution.min = obj.configuration.template_matching_binning * apix; % angstroms
                            ctf_est.resolution.max = binning * apix;
                            
                            if isfield(obj.configuration, "global_lower_defocus_average_in_angstrom")
                                ctf_est.defocus.min = configuration.global_lower_defocus_average_in_angstrom;
                                ctf_est.defocus.max = configuration.global_upper_defocus_average_in_angstrom;
                            elseif isfield(obj.configuration, "nominal_defocus_in_nm") && obj.configuration.nominal_defocus_in_nm ~= 0
                                % TODO: could be also 2 numbers for lower and upper
                                % limit or factors in different variable names
                                ctf_est.defocus.min = round(obj.configuration.nominal_defocus_in_nm / obj.configuration.defocus_limit_factor) * 10^4;
                                ctf_est.defocus.max = round(obj.configuration.nominal_defocus_in_nm * obj.configuration.defocus_limit_factor) * 10^4;
                            else
                                ctf_est.defocus.min = obj.configuration.SUSAN_defocus_min; % angstroms
                                ctf_est.defocus.max = obj.configuration.SUSAN_defocus_max; % angstroms
                            end
                            
                            tomos_ctf = ctf_est.estimate('ctf_grid', 'grid_ctf.ptclsraw', ...
                                tomos_name);
                            tomos_ctf.save(tomos_name);
                        end
                        
                        ptcls.save(particles_raw);
                        
                        %%
                        avg = SUSAN.Modules.Averager;
                        
                        if obj.configuration.gpu == -1
                            avg.gpu_list = 0:gpuDeviceCount - 1;
                        else
                            avg.gpu_list = obj.configuration.gpu - 1;
                        end
                        
                        box_size = round((size(template, 1) * obj.configuration.box_size) * (previous_binning / binning));
                        
                        if mod(box_size, 2) == 1
                            box_size = box_size + 1;
                        end
                        
                        avg.bandpass.lowpass = min(obj.configuration.susan_lowpass, (box_size / 2) / 2);
                        avg.padding = obj.configuration.susan_padding / binning;
                        avg.rec_halves = true;
                        
                        if (obj.configuration.per_particle_ctf_correction == "wiener_ssnr")
                            avg.set_ctf_correction(char("wiener_ssnr"), obj.configuration.ssnr(1), obj.configuration.ssnr(2)); % what about SSNR....: set_ctf_correction('wiener_ssnr', 1, 0.8);
                        else
                            avg.set_ctf_correction(char(obj.configuration.per_particle_ctf_correction)); % what about SSNR....: set_ctf_correction('wiener_ssnr', 1, 0.8);
                        end
                        
                        avg.set_padding_policy(char(obj.configuration.padding_policy));
                        avg.set_normalization(char(obj.configuration.normalization));
                        
                        if obj.configuration.use_symmetrie == true
                            avg.set_symmetry(char(obj.configuration.expected_symmetrie));
                        end
                        
                        %                         if obj.configuration.susan_box_size > 0
                        %                             box_size = round((size(template,1) * obj.configuration.susan_box_size) * (previous_binning / binning)); %obj.configuration.susan_box_size;
                        %                             obj.dynamic_configuration.susan_box_size = 1;
                        %                         else
                        
                        %                         end
                        if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                            particles_path = char("../../particles/particles_bin_" + binning + "_bs_" + box_size + "_dw");
                        else
                            particles_path = char("../../particles/particles_bin_" + binning + "_bs_" + box_size);
                        end
                        
                        avg.reconstruct(char("ds_ini_bin_" + binning), tomos_name, particles_raw, box_size);
                        %%
                        
                        subtomos = SUSAN.Modules.SubtomoRec;
                        
                        if obj.configuration.gpu == -1
                            subtomos.gpu_list = 0:gpuDeviceCount - 1;
                        else
                            subtomos.gpu_list = obj.configuration.gpu - 1;
                        end
                        
                        subtomos.padding = round(obj.configuration.susan_padding / binning);
                        
                        subtomos.set_ctf_correction(char(obj.configuration.per_particle_ctf_correction)); % try also wiener if you like
                        subtomos.set_padding_policy(char(obj.configuration.padding_policy));
                        subtomos.set_normalization(char(obj.configuration.normalization));
                        subtomos.reconstruct(char(particles_path), tomos_name, particles_raw, box_size);
                        
                        new_table = cleanCroppedParticlesTable(new_table, char(particles_path));
                        
                        if obj.configuration.as_boxes == 1
                            % dBoxes.convertSimpleData(char("../../particles/particles_bin_" + binning  + "_bs_" + box_size),...
                            %     [char("../../particles/particles_bin_" + binning  + "_bs_" + box_size) '.Boxes'],...
                            %     'batch', obj.configuration.particle_batch, 'dc', obj.configuration.direct_copy);
                            ownDbox(string(particles_path), ...
                                string([char(particles_path) '.Boxes']));
                            
                            [status, message, messageid] = rmdir(char(particles_path), 's');
                            particles_path = [char(particles_path) '.Boxes'];
                            %                             new_table(:,1) = 1:length(new_table);
                            %movefile(char([char("../../particles/particles_bin_" + binning) '.Boxes']), char("../../particles/particles_bin_" + binning));
                        end
                        
                        %
                        %                         if obj.configuration.classes == 1
                        %                             for i = 1:2
                        %                                 if length(sub_tables) == 1
                        %                                     average = daverage(char(particles_path), '-t', new_table, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                        %                                 else
                        %                                     average = daverage(char(particles_path), '-t', sub_tables{i}, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                        %                                 end
                        %                                 template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                        %                                 dwrite(average.average, template_em_files{i});
                        %                             end
                        %                             obj.configuration.classes = 2;
                        %                         else
                        avge = daverage(char(particles_path), '-t', new_table, 'mw', cpu_poolsize);
                        template_em_files{1} = char(alignment_project_folder_path + string(filesep) + "average_" + 1 + ".em");
                        dwrite(avge.average, template_em_files{1});
                        %                         end
                    end
                    
                    tables = {char(alignment_project_folder_path + string(filesep) + "table.tbl")};
                    dwrite(new_table, tables{1});
                    template = avge.average;
                    
                    if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                        mask = dread(obj.configuration.mask_path);
                        mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                    else
                        % TODO:NOTE: introduce flag for doing iteration before
                        % or after
                        if obj.configuration.use_elliptic_mask == true && obj.configuration.classes > 1
                            smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                            mask = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                        else
                            smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                            mask_sphere = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                            mask = generateMaskFromTemplate(obj.configuration, template) .* mask_sphere;
                        end
                        
                    end
                    
                    mask_em_files = {char(alignment_project_folder_path + string(filesep) + "mask.em")};
                    dwrite(mask, mask_em_files{1});
                elseif previous_binning > 0
                    
                    if obj.configuration.as_boxes == true
                        
                        if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw.Boxes";
                        else
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + ".Boxes";
                        end
                        
                    else
                        
                        if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw";
                        else
                            particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size;
                        end
                        
                    end
                    
                    %                     particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning;
                    if obj.configuration.classes == 1 && obj.configuration.swap_particles == false && exist("tab_all_path", "var") && contains(tab_all_path(1).folder, "bin_" + binning + "_eo" + filesep)
                        new_table = [];
                        
                        for i = 1:length(sub_tables)
                            sub_table = sub_tables{i};
                            
                            if previous_binning / binning > 1
                                
                                sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                sub_table(:, 4) = 0;
                                sub_table(:, 5) = 0;
                                sub_table(:, 6) = 0;
                                
                                if previous_binning > binning
                                    sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                    sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                    sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                else
                                    sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                    sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                    sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                end
                                
                            end
                            
                            %sub_table(:,20) = i;
                            if isempty(new_table)
                                new_table = sub_table;
                            else
                                new_table(end + 1:end + size(sub_table, 1), :) = sub_table;
                            end
                            
                        end
                        
                    else
                        
                        if ~iscell(obj.configuration.selected_classes)
                            
                            for i = 1:length(obj.configuration.selected_classes)
                                
                                if i == 1
                                    new_table = [];
                                end
                                
                                sub_table = sub_tables{i}(sub_tables{i}(:, 34) == obj.configuration.selected_classes(i), :);
                                
                                if previous_binning / binning > 1
                                    
                                    sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                    sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                    sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                    sub_table(:, 4) = 0;
                                    sub_table(:, 5) = 0;
                                    sub_table(:, 6) = 0;
                                    
                                    if previous_binning >= binning
                                        sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                    else
                                        sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                    end
                                    
                                end
                                
                                %                         if previous_binning == binning
                                %
                                %                         else
                                if previous_binning == binning
                                    template = dread(template_em_files{i});
                                else
                                    
                                    if ~fileExists(char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em"))
                                        avge = daverage(char(particles_path), '-t', sub_table, 'mw', cpu_poolsize);
                                        template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                                        dwrite(avge.average, template_em_files{i});
                                        template = avge.average;
                                    else
                                        template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                                        template = dread(template_em_files{i});
                                    end
                                    
                                end
                                
                                %                         end
                                
                                if isempty(new_table)
                                    new_table = sub_table;
                                else
                                    new_table(end + 1:end + length(sub_table), :) = sub_table;
                                end
                                
                                if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                                    mask = dread(obj.configuration.mask_path);
                                    mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                                else
                                    % TODO:NOTE: introduce flag for doing iteration before
                                    % or after
                                    if obj.configuration.use_elliptic_mask == true && obj.configuration.classes > 1
                                        smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                                        mask = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                                    else
                                        smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                                        mask_sphere = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                                        mask = generateMaskFromTemplate(obj.configuration, template) .* mask_sphere;
                                    end
                                    
                                end
                                
                                mask_em_files = {char(alignment_project_folder_path + string(filesep) + "mask.em")};
                                dwrite(mask, mask_em_files{1});
                                
                            end
                            
                        else
                            
                            for i = 1:length(selected_classes)
                                
                                if i == 1
                                    new_table = [];
                                end
                                
                                sub_table = [];
                                
                                for j = 1:length(sub_tables)
                                    
                                    if isempty(sub_table)
                                        sub_table = sub_tables{j}(sub_tables{j}(:, 34) == selected_classes(i), :);
                                    else
                                        sub_table(end + 1:end + length(sub_tables{j}(sub_tables{j}(:, 34) == selected_classes(i), :)), :) = sub_tables{j}(sub_tables{j}(:, 34) == selected_classes(i), :);
                                    end
                                    
                                end
                                
                                if previous_binning / binning > 1
                                    
                                    sub_table(:, 24) = sub_table(:, 24) + sub_table(:, 4);
                                    sub_table(:, 25) = sub_table(:, 25) + sub_table(:, 5);
                                    sub_table(:, 26) = sub_table(:, 26) + sub_table(:, 6);
                                    sub_table(:, 4) = 0;
                                    sub_table(:, 5) = 0;
                                    sub_table(:, 6) = 0;
                                    
                                    if previous_binning >= binning
                                        sub_table(:, 24) = (sub_table(:, 24) * previous_binning / binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * previous_binning / binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * previous_binning / binning) + 1;
                                    else
                                        sub_table(:, 24) = (sub_table(:, 24) * binning / previous_binning) + 1;
                                        sub_table(:, 25) = (sub_table(:, 25) * binning / previous_binning) + 1;
                                        sub_table(:, 26) = (sub_table(:, 26) * binning / previous_binning) + 1;
                                    end
                                    
                                end
                                
                                %                         if previous_binning == binning
                                %
                                %                         else
                                if previous_binning == binning
                                    template = dread(template_em_files{i});
                                else
                                    
                                    if ~fileExists(char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em"))
                                        avge = daverage(char(particles_path), '-t', sub_table, 'mw', cpu_poolsize);
                                        template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                                        dwrite(avge.average, template_em_files{i});
                                        template = avge.average;
                                    else
                                        template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                                        template = dread(template_em_files{i});
                                    end
                                    
                                end
                                
                                %                         end
                                
                                if isempty(new_table)
                                    new_table = sub_table;
                                else
                                    new_table(end + 1:end + length(sub_table), :) = sub_table;
                                end
                                
                                if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                                    mask = dread(obj.configuration.mask_path);
                                    mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                                else
                                    % TODO:NOTE: introduce flag for doing iteration before
                                    % or after
                                    if obj.configuration.use_elliptic_mask == true && obj.configuration.classes > 1
                                        smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                                        mask = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                                    else
                                        smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                                        mask_sphere = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                                        mask = generateMaskFromTemplate(obj.configuration, template) .* mask_sphere;
                                    end
                                    
                                end
                                
                                mask_em_files = {char(alignment_project_folder_path + string(filesep) + "mask.em")};
                                dwrite(mask, mask_em_files{1});
                            end
                            
                        end
                        
                        if obj.configuration.use_noise_classes == true
                            
                            for i = length(obj.configuration.selected_classes) + 1:obj.configuration.classes
                                noise_template{i} = rand(size(template) * (previous_binning / binning)) * obj.configuration.noise_scaling_factor;
                                template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "template_" + i + ".em");
                                dwrite(noise_template{i}, template_em_files{i});
                                %                                 template_em_files{i} = noise_template{i};
                                %                                 mask_em_files{i} = char(alignment_project_folder_path + string(filesep) + "mask_" + i + ".em");
                                %                                 dwrite(mask, mask_em_files{i});
                            end
                            
                        end
                        
                    end
                    
                    %                     template = daverage(char(particles_path), '-t', new_table);
                    %                     template_em_files{i} = char(alignment_project_folder_path + string(filesep) + "average_" + i + ".em");
                    %                     dwrite(average.average, template_em_files{i});
                    tables = {char(alignment_project_folder_path + string(filesep) + "table.tbl")};
                    dwrite(new_table, tables{1});
                end
                
                if ((obj.configuration.classes < length(obj.configuration.selected_classes) || obj.configuration.classes > length(obj.configuration.selected_classes)) && previous_binning ~= 0) && obj.configuration.classes ~= 1
                    
                    if obj.configuration.use_noise_classes == false
                        
                        for i = 1:length(template_em_files)
                            
                            if i == 1
                                vol = dread(template_em_files{i});
                            else
                                vol = (vol + dread(template_em_files{i})) ./ 2;
                            end
                            
                        end
                        
                        template_em_files = {vol};
                        dwrite(template_em_files{1}, char(alignment_project_folder_path + string(filesep) + "average.em"));
                        mask_em_files = {mask_em_files{1}};
                    else
                        
                        if isfield(obj.configuration, "mask_path") && obj.configuration.mask_path ~= ""
                            mask = dread(obj.configuration.mask_path);
                            mask = dynamo_rescale(mask, obj.configuration.mask_apix, obj.configuration.greatest_apix * binning);
                        else
                            % TODO:NOTE: introduce flag for doing iteration before
                            % or after
                            if obj.configuration.use_elliptic_mask == true && obj.configuration.classes > 1
                                smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                                mask = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                            else
                                smoothing_pixels = ((size(template)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                                mask_sphere = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template) / 2, smoothing_pixels);
                                mask = generateMaskFromTemplate(obj.configuration, template) .* mask_sphere;
                            end
                            
                        end
                        
                        mask_em_files = {char(alignment_project_folder_path + string(filesep) + "mask.em")};
                        dwrite(mask, mask_em_files{1});
                    end
                    
                    new_table = [];
                    
                    for i = 1:length(tables)
                        table = dread(tables{i});
                        
                        if i == 1
                            new_table = table;
                            %                         new_table(:,25) = table(:,25);
                            %                         new_table(:,26) = table(:,26);
                            %                         new_table(:,4) = table(:,4);
                            %                         new_table(:,5) = table(:,5);
                            %                         new_table(:,6) = table(:,6);
                        else
                            
                            if length(tab_all_path) == length(obj.configuration.selected_classes)
                                new_table(:, 24) = (table(:, 24) + new_table(:, 24)) / 2;
                                new_table(:, 25) = (table(:, 25) + new_table(:, 25)) / 2;
                                new_table(:, 26) = (table(:, 26) + new_table(:, 26)) / 2;
                                new_table(:, 4) = (table(:, 4) + new_table(:, 4)) / 2;
                                new_table(:, 5) = (table(:, 5) + new_table(:, 5)) / 2;
                                new_table(:, 6) = (table(:, 6) + new_table(:, 6)) / 2;
                            else
                                new_table(end + 1:end + length(table), :) = table;
                            end
                            
                        end
                        
                    end
                    
                    tables = {char(alignment_project_folder_path + string(filesep) + "table.tbl")};
                    dwrite(new_table, tables{1});
                end
                
                %                 if obj.configuration.use_elliptic_mask == true
                %                     smoothing_pixels = ((size(mask)' .* obj.configuration.radii_ratio) .* obj.configuration.ellipsoid_smoothing_ratio)';
                %                     mask = dynamo_ellipsoid(((size(template) .* obj.configuration.radii_ratio) - smoothing_pixels), length(template), length(template)/2, smoothing_pixels);
                %                     mask_em_files = {char(alignment_project_folder_path + string(filesep) + "mask.em")};
                %                     dwrite(mask, mask_em_files{1});
                %                 end
                
                if obj.configuration.as_boxes == 1
                    
                    if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw.Boxes/batch_0";
                    else
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + ".Boxes/batch_0";
                    end
                    
                else
                    
                    if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw";
                    else
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size;
                    end
                    
                end
                
                if ~exist("mask", "var")
                    mask = dread(mask_em_files{1});
                end
                
                if previous_binning == binning && (box_size ~= size(template, 1) || box_size ~= size(mask, 1))
                    
                    if box_size > size(template, 1)
                        template = dynamo_embed(template, box_size);
                    elseif box_size < size(template, 1)
                        template = dynamo_crop(template, box_size);
                    end
                    
                    if box_size > size(mask, 1)
                        mask = dynamo_embed(mask, box_size);
                    elseif box_size < size(mask, 1)
                        mask = dynamo_crop(mask, box_size);
                    end
                    
                    template_em_files{1} = char(alignment_project_folder_path + string(filesep) + "average_" + 1 + ".em");
                    dwrite(template, template_em_files{1});
                    mask_em_files{1} = char(alignment_project_folder_path + string(filesep) + "mask_" + 1 + ".em");
                    dwrite(mask, mask_em_files{1});
                end
                
                if length(tables) == 1
                    %                     p = dcp.new(project_name, 't', tables{1}, 'show', 0);
                    p = dcp.new(project_name, 'd', char(particles_path), 't', tables{1}, 'show', 0);
                else
                    p = dcp.new(project_name, 'd', char(particles_path), 'show', 0);
                end
                
                if obj.configuration.as_boxes == 1
                    
                    if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw.Boxes";
                    else
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + ".Boxes";
                    end
                    
                else
                    
                    if obj.configuration.use_dose_weighted_particles == true && obj.configuration.use_SUSAN == true
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw";
                    else
                        particles_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size;
                    end
                    
                end
                
                dvput(project_name, 'data', char(particles_path));
                
                if obj.configuration.classes > 1 % && length(obj.configuration.selected_classes) > 1
                    dwrite_multireference(template_em_files, 'template', char(project_name), 'refs', 1:obj.configuration.classes, 'n', 1, 'p', char(project_name), 'noise', obj.configuration.noise);
                    %                     if obj.configuration.use_elliptic_mask == true
                    %                         dwrite_multireference([char(alignment_project_folder_path) '/' char(project_name) '/settings/mask.em'], 'fmask', [char(alignment_project_folder_path) '/' char(project_name) '/settings'], 'refs', 1:obj.configuration.classes, 'p', char(project_name));
                    %                     else
                    dwrite_multireference(ones(box_size, box_size, box_size), 'fmask', char(project_name), 'refs', 1:obj.configuration.classes, 'p', char(project_name));
                    dwrite_multireference(mask_em_files, 'mask', char(project_name), 'refs', 1:obj.configuration.classes, 'p', char(project_name));
                    %                         dwrite_multireference(mask_em_files, 'cmask',char(project_name), 'refs', 1:obj.configuration.classes, 'p', char(project_name));
                    %
                    %                     end
                    dwrite_multireference(tables, 'table', char(project_name), 'refs', 1:obj.configuration.classes);
                else
                    
                    if length(template_em_files) == 1
                    elseif length(template_em_files) > 1
                        vol = (dread(template_em_files{1}) + dread(template_em_files{2})) / 2;
                        template_em_files = {};
                        template_em_files{1} = 'template.em';
                        dwrite(vol, template_em_files{1});
                    else
                        error("ERROR: should never happen");
                    end
                    
                    dwrite_multireference(template_em_files, 'template', char(project_name), 'refs', 1, 'n', 1, 'noise', obj.configuration.noise);
                    %                     if obj.configuration.use_elliptic_mask == true
                    %                         dwrite_multireference([char(alignment_project_folder_path) '/' char(project_name) '/settings/mask.em'], 'fmask', [char(alignment_project_folder_path) '/' char(project_name) '/settings'], 'refs', 1, 'p', char(project_name));
                    %                     else
                    if length(mask_em_files) == 1
                    elseif length(mask_em_files) > 1
                        vol = (dread(mask_em_files{1}) + dread(mask_em_files{2})) / 2;
                        mask_em_files = {};
                        mask_em_files{1} = 'mask.em';
                        dwrite(vol, mask_em_files{1});
                    else
                        error("ERROR: should never happen");
                    end
                    
                    dwrite_multireference(mask_em_files, 'mask', char(project_name), 'refs', 1);
                    %                     end
                    dwrite_multireference(tables, 'table', char(project_name), 'refs', 1);
                end
                
                if ~exist("template", "var")
                    templates_files = dir("template*.em");
                    
                    if ~isempty(templates_files)
                        template = dread(char(string(templates_files(1).folder) + filesep + templates_files(1).name));
                    else
                        templates_files = dir("average*.em");
                        template = dread(char(string(templates_files(1).folder) + filesep + templates_files(1).name));
                    end
                    
                end
                
                if obj.configuration.classes > 1 && obj.configuration.swap_particles == true
                    %                 newStr = extractBetween(obj.configuration.expected_symmetrie,2,length(obj.configuration.expected_symmetrie{1}));
                    %                 symmetry_order = str2double(newStr);
                    iterations = 0;
                    %                 %             if isfield(obj.configuration, "iterations") && (obj.configuration.iterations > 0 || obj.configuration.iterations > -1)
                    %                 if obj.configuration.sampling == 0
                    %                     obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                 else
                    %                     obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.sampling / obj.configuration.refine_factor;
                    %                     obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.sampling / obj.configuration.refine_factor;
                    %                 end
                    %                 obj.configuration.("ite_r" + (iterations + 1)) = obj.configuration.iterations;
                    %                 obj.configuration.("rf_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("rff_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("dim_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("lim_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("limm_r" + (iterations + 1)) = 1;
                    %                 obj.configuration.("sym_r" + (iterations + 1)) = char(obj.configuration.expected_symmetrie);
                    %                 obj.configuration.("threshold_r" + (iterations + 1)) = obj.configuration.threshold;
                    %                 obj.configuration.("threshold_modus_r" + (iterations + 1)) = obj.configuration.threshold_mode;
                    %                 obj.configuration.("area_search_modus_r" + (iterations + 1)) = 1;
                    %                 %                 inplane_sampling = obj.configuration.("is_r" + (iterations + 1));
                    %
                    %                 %             else
                    %                 %                 obj.configuration.("ir_r" + (iterations + 1)) = 360 / symmetry_order;
                    %                 %                 obj.configuration.("is_r" + (iterations + 1)) = 360;
                    %                 inplane_sampling = obj.configuration.("is_r" + (iterations + 1));
                    %                 %                 obj.configuration.("cr_r" + (iterations + 1)) = 360;
                    %                 %                 obj.configuration.("cs_r" + (iterations + 1))  = 360;
                    %                 iterations = iterations + 1;
                    %                 if obj.configuration.sampling == 0
                    %                 if obj.configuration.in_plane_sampling / 2 < atand(1/(size(template,1)/2))
                    if obj.configuration.sampling == 0
                        %                 if obj.configuration.in_plane_sampling / 2 < atand(1/(size(template,1)/2))
                        inplane_range = obj.configuration.template_matching_in_plane_sampling;
                        inplane_sampling = inplane_range / obj.configuration.refine_factor;
                        cone_range = obj.configuration.template_matching_cone_sampling;
                        cone_sampling = cone_range / obj.configuration.refine_factor;
                    else
                        inplane_range = obj.configuration.sampling;
                        inplane_sampling = inplane_range / obj.configuration.refine_factor;
                        cone_range = obj.configuration.sampling;
                        cone_sampling = cone_range / obj.configuration.refine_factor;
                    end
                    %                     skipped_iterations = 0;
                    %                     iterations_to_skip = (obj.configuration.template_matching_binning / binning) - 1;
                    %                 else
                    %                     inplane_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    %                     inplane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                     skipped_iterations = (obj.configuration.template_matching_binning / binning) - 1;
                    %                     iterations_to_skip = (obj.configuration.template_matching_binning / binning) - 1;
                    %                 end
                    %                 else
                    %                     if obj.configuration.in_plane_sampling < atand(1/(size(template,1)/2))/2
                    %                         inplane_sampling = obj.configuration.template_matching_in_plane_sampling / obj.configuration.refine_factor;
                    %                         cone_sampling = obj.configuration.template_matching_cone_sampling / obj.configuration.refine_factor;
                    %                         skipped_iterations = 0;
                    %                         iterations_to_skip = (template_matching_binning / binning) - 1;
                    %                     else
                    %                         inplane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                         cone_sampling = obj.dynamic_configuration.cone_sampling / obj.configuration.refine_factor;
                    %                         skipped_iterations = (template_matching_binning / binning) - 1;
                    %                         iterations_to_skip = (template_matching_binning / binning) - 1;
                    %                     end
                    %                 end
                    
                    while (inplane_sampling > atand(1 / (size(template, 1) / 2)) / obj.configuration.atand_factor) || iterations == 0
                        %                     if skipped_iterations < iterations_to_skip
                        %                         %                         if obj.configuration.sampling == 0
                        %                         %                             if obj.configuration.in_plane_sampling < atand(1/(size(template,1)/2))/2 % asind(1/size(template,1))
                        %                         %                                 inplane_sampling = inplane_sampling / obj.configuration.refine_factor;
                        %                         %                             else
                        %                         %                                 inplane_sampling = inplane_sampling / obj.configuration.refine_factor;
                        %                         %                             end
                        %                         %                         else
                        %                         inplane_sampling = inplane_sampling / obj.configuration.refine_factor;
                        %                         cone_sampling = cone_sampling / obj.configuration.refine_factor;
                        %
                        %                         %                         end
                        %                         skipped_iterations = skipped_iterations + 1;
                        %                         continue;
                        %                     end
                        if iterations == 0
                            %                         if obj.configuration.sampling == 0
                            %                             if obj.configuration.in_plane_sampling < atand(1/(size(template,1)/2))/2 % asind(1/size(template,1))
                            %                                 obj.configuration.("ir_r" + (iterations + 1)) = inplane_sampling + obj.configuration.discretization_bias;
                            %                                 obj.configuration.("is_r" + (iterations + 1)) = inplane_sampling / obj.configuration.refine_factor;
                            %                                 obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                            %                                 obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                            %                             else
                            
                            obj.configuration.("ir_r" + (iterations + 1)) = inplane_range + (obj.configuration.discretization_bias / (iterations + 1));
                            obj.configuration.("is_r" + (iterations + 1)) = inplane_sampling;% / obj.configuration.refine_factor;
                            obj.configuration.("cr_r" + (iterations + 1)) = cone_range + (obj.configuration.discretization_bias / (iterations + 1));
                            obj.configuration.("cs_r" + (iterations + 1)) = cone_sampling;% / obj.configuration.refine_factor;
                            %                             end
                            %                         else
                            %                             obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.("is_r" + iterations) + obj.configuration.discretization_bias;
                            %                             obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.("is_r" + iterations) / obj.configuration.refine_factor;
                            %                             obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.("cs_r" + iterations) + obj.configuration.discretization_bias;
                            %                             obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.("cs_r" + iterations) / obj.configuration.refine_factor;
                            %                         end
                        else
                            %	inplane_range [level i+1] = refine_factor * inplane_sampling [level i];
                            %	cone_range    [level i+1] = refine_factor * cone_sampling [level i];
                            obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.("is_r" + iterations) + (obj.configuration.discretization_bias / (iterations + 1)); % * obj.configuration.refine_factor; % + (obj.configuration.discretization_bias / (obj.configuration.refine_factor * j))
                            obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.("is_r" + iterations) / obj.configuration.refine_factor;
                            obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.("cs_r" + iterations) + (obj.configuration.discretization_bias / (iterations + 1)); % * obj.configuration.refine_factor; % + (obj.configuration.discretization_bias / (obj.configuration.refine_factor * j))
                            obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.("cs_r" + iterations) / obj.configuration.refine_factor;
                            %sampling = sampling / obj.configuration.refine_factor;
                        end
                        
                        obj.configuration.("ite_r" + (iterations + 1)) = obj.configuration.iterations;
                        obj.configuration.("rf_r" + (iterations + 1)) = 0;
                        obj.configuration.("rff_r" + (iterations + 1)) = 0;
                        obj.configuration.("dim_r" + (iterations + 1)) = 0;
                        obj.configuration.("lim_r" + (iterations + 1)) = 0;
                        obj.configuration.("limm_r" + (iterations + 1)) = obj.configuration.area_search_mode;
                        obj.configuration.("sym_r" + (iterations + 1)) = char(obj.configuration.expected_symmetrie);
                        obj.configuration.("threshold_r" + (iterations + 1)) = obj.configuration.threshold;
                        obj.configuration.("threshold_modus_r" + (iterations + 1)) = obj.configuration.threshold_mode;
                        obj.configuration.("area_search_modus_r" + (iterations + 1)) = obj.configuration.area_search_mode;
                        obj.configuration.("cone_flip_r" + (iterations + 1)) = obj.configuration.cone_flip;
                        
                        if obj.configuration.bandpass_method == "angles"
                            obj.configuration.("high_r" + (iterations + 1)) = 2;
                            obj.configuration.("low_r" + (iterations + 1)) = 1 / tand(obj.configuration.("is_r" + (iterations + 1)));
                        end
                        
                        inplane_sampling = obj.configuration.("is_r" + (iterations + 1));
                        iterations = iterations + 1;
                    end
                    
                    obj.dynamic_configuration.in_plane_range = obj.configuration.("ir_r" + (iterations));
                    obj.dynamic_configuration.in_plane_sampling = obj.configuration.("is_r" + (iterations));
                    obj.dynamic_configuration.cone_range = obj.configuration.("cr_r" + (iterations));
                    obj.dynamic_configuration.cone_sampling = obj.configuration.("cs_r" + (iterations));
                    
                    if obj.configuration.bandpass_method == "iterations"
                        bandpass_step = (((size(template, 1) / 2) / 2) - 3) / iterations;
                        
                        for i = 1:iterations
                            obj.configuration.("high_r" + i) = 2;
                            obj.configuration.("low_r" + i) = 3 + floor(bandpass_step * i);
                        end
                        
                    end
                    
                    %     dvput project d -sym c1
                    %     % is equivalent to
                    %     dvput project d -sym_r1 c1
                    %             end
                    
                    %
                    %             if obj.configuration.sampling == 0
                    %                 if obj.configuration.in_plane_sampling < asind(1/size(template,1))
                    %                     in_plane_range = obj.configuration.template_matching_in_plane_sampling + obj.configuration.discretization_bias;
                    %                     in_plane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                 else
                    %                     in_plane_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    %                     in_plane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                 end
                    %             else
                    %                 in_plane_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                 in_plane_sampling = obj.configuration.sampling / obj.configuration.refine_factor;
                    %                 cone_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                 cone_sampling = obj.configuration.sampling / obj.configuration.refine_factor;
                    %             end
                else
                    %                 newStr = extractBetween(obj.configuration.expected_symmetrie,2,length(obj.configuration.expected_symmetrie{1}));
                    %                 symmetry_order = str2num(newStr);
                    
                    %             if isfield(obj.configuration, "iterations") && (obj.configuration.iterations > 0 || obj.configuration.iterations > -1)
                    % % % % % % % % %                 if obj.configuration.sampling == 0
                    % % % % % % % % %                     in_plane_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                     in_plane_sampling = obj.configuration.in_plane_sampling / 2;
                    % % % % % % % % %                     cone_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                     cone_sampling = obj.configuration.in_plane_sampling / 2;
                    % % % % % % % % %                 else
                    % % % % % % % % %                     in_plane_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                     in_plane_sampling = obj.configuration.sampling / 2;
                    % % % % % % % % %                     cone_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                     cone_sampling = obj.configuration.sampling / 2;
                    % % % % % % % % %                 end
                    % % % % % % % % %
                    % % % % % % % % %                 obj.dynamic_configuration.in_plane_range = in_plane_range;
                    % % % % % % % % %                 obj.dynamic_configuration.in_plane_sampling = in_plane_sampling;
                    % % % % % % % % %                 obj.dynamic_configuration.cone_range = cone_range;
                    % % % % % % % % %                 obj.dynamic_configuration.cone_sampling = cone_sampling;
                    % % % % % % % % %                 %             else
                    % % % % % % % % %                 iterations = 0;
                    % % % % % % % % %                 %                 in_plane_range = 360 / symmetry_order;
                    % % % % % % % % %                 %                 in_plane_sampling = 360;
                    % % % % % % % % %                 %                 cone_range = 360;
                    % % % % % % % % %                 %                 cone_sampling = 360;
                    % % % % % % % % %                 while in_plane_sampling > atand(1/(size(template,1)/2))
                    % % % % % % % % %                     if iterations == 0
                    % % % % % % % % %                         if obj.configuration.sampling == 0
                    % % % % % % % % %                             if obj.configuration.in_plane_sampling < asind(1/size(template,1))
                    % % % % % % % % %                                 in_plane_range = obj.configuration.template_matching_in_plane_sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                                 in_plane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                                 cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                                 cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                             else
                    % % % % % % % % %                                 in_plane_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                                 in_plane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                                 cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                                 cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                             end
                    % % % % % % % % %                         else
                    % % % % % % % % %                             in_plane_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                             in_plane_sampling = obj.configuration.sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                             cone_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    % % % % % % % % %                             cone_sampling = obj.configuration.sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                         end
                    % % % % % % % % %                     else
                    % % % % % % % % %                         %	inplane_range [level i+1] = refine_factor * inplane_sampling [level i];
                    % % % % % % % % %                         %	cone_range    [level i+1] = refine_factor * cone_sampling [level i];
                    % % % % % % % % %                         in_plane_range = (in_plane_sampling * obj.configuration.refine_factor); % + (obj.configuration.discretization_bias / (obj.configuration.refine_factor * j))
                    % % % % % % % % %                         in_plane_sampling = in_plane_sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                         cone_range = (cone_sampling * obj.configuration.refine_factor); % + (obj.configuration.discretization_bias / (obj.configuration.refine_factor * j))
                    % % % % % % % % %                         cone_sampling = cone_sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                         %sampling = sampling / obj.configuration.refine_factor;
                    % % % % % % % % %                     end
                    % % % % % % % % %                     iterations = iterations + 1;
                    % % % % % % % % %                 end
                    %             end
                    iterations = 0;
                    %                 %             if isfield(obj.configuration, "iterations") && (obj.configuration.iterations > 0 || obj.configuration.iterations > -1)
                    %                 if obj.configuration.sampling == 0
                    %                     obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                 else
                    %                     obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.sampling / obj.configuration.refine_factor;
                    %                     obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                     obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.sampling / obj.configuration.refine_factor;
                    %                 end
                    %                 obj.configuration.("ite_r" + (iterations + 1)) = obj.configuration.iterations;
                    %                 obj.configuration.("rf_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("rff_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("dim_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("lim_r" + (iterations + 1)) = 0;
                    %                 obj.configuration.("limm_r" + (iterations + 1)) = 1;
                    %                 obj.configuration.("sym_r" + (iterations + 1)) = char(obj.configuration.expected_symmetrie);
                    %                 obj.configuration.("threshold_r" + (iterations + 1)) = obj.configuration.threshold;
                    %                 obj.configuration.("threshold_modus_r" + (iterations + 1)) = obj.configuration.threshold_mode;
                    %                 obj.configuration.("area_search_modus_r" + (iterations + 1)) = 1;
                    %                 %                 inplane_sampling = obj.configuration.("is_r" + (iterations + 1));
                    %
                    %                 %             else
                    %                 %                 obj.configuration.("ir_r" + (iterations + 1)) = 360 / symmetry_order;
                    %                 %                 obj.configuration.("is_r" + (iterations + 1)) = 360;
                    %                 inplane_sampling = obj.configuration.("is_r" + (iterations + 1));
                    %                 %                 obj.configuration.("cr_r" + (iterations + 1)) = 360;
                    %                 %                 obj.configuration.("cs_r" + (iterations + 1))  = 360;
                    %                 iterations = iterations + 1;
                    if obj.configuration.sampling == 0
                        %                 if obj.configuration.in_plane_sampling / 2 < atand(1/(size(template,1)/2))
                        inplane_range = obj.configuration.template_matching_in_plane_sampling;
                        inplane_sampling = inplane_range / obj.configuration.refine_factor;
                        cone_range = obj.configuration.template_matching_cone_sampling;
                        cone_sampling = cone_range / obj.configuration.refine_factor;
                    else
                        inplane_range = obj.configuration.sampling;
                        inplane_sampling = inplane_range / obj.configuration.refine_factor;
                        cone_range = obj.configuration.sampling;
                        cone_sampling = cone_range / obj.configuration.refine_factor;
                    end
                    
                    %                     skipped_iterations = 0;
                    %                     iterations_to_skip = (obj.configuration.template_matching_binning / binning) - 1;
                    %                 else
                    %                     inplane_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    %                     inplane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                     skipped_iterations = (obj.configuration.template_matching_binning / binning) - 1;
                    %                     iterations_to_skip = (obj.configuration.template_matching_binning / binning) - 1;
                    %                 end
                    %                 else
                    %                     if obj.configuration.in_plane_sampling < atand(1/(size(template,1)/2))/2
                    %                         inplane_sampling = obj.configuration.template_matching_in_plane_sampling / obj.configuration.refine_factor;
                    %                         cone_sampling = obj.configuration.template_matching_cone_sampling / obj.configuration.refine_factor;
                    %                         skipped_iterations = 0;
                    %                         iterations_to_skip = (template_matching_binning / binning) - 1;
                    %                     else
                    %                         inplane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                         cone_sampling = obj.dynamic_configuration.cone_sampling / obj.configuration.refine_factor;
                    %                         skipped_iterations = (template_matching_binning / binning) - 1;
                    %                         iterations_to_skip = (template_matching_binning / binning) - 1;
                    %                     end
                    %                 end
                    
                    while inplane_sampling > atand(1 / (size(template, 1) / 2)) / obj.configuration.atand_factor || iterations == 0
                        %                     if skipped_iterations < iterations_to_skip
                        %                         %                         if obj.configuration.sampling == 0
                        %                         %                             if obj.configuration.in_plane_sampling < atand(1/(size(template,1)/2))/2 % asind(1/size(template,1))
                        %                         %                                 inplane_sampling = inplane_sampling / obj.configuration.refine_factor;
                        %                         %                             else
                        %                         %                                 inplane_sampling = inplane_sampling / obj.configuration.refine_factor;
                        %                         %                             end
                        %                         %                         else
                        %                         inplane_sampling = inplane_sampling / obj.configuration.refine_factor;
                        %                         cone_sampling = cone_sampling / obj.configuration.refine_factor;
                        %
                        %                         %                         end
                        %                         skipped_iterations = skipped_iterations + 1;
                        %                         continue;
                        %                     end
                        if iterations == 0
                            %                         if obj.configuration.sampling == 0
                            %                             if obj.configuration.in_plane_sampling < atand(1/(size(template,1)/2))/2 % asind(1/size(template,1))
                            %                                 obj.configuration.("ir_r" + (iterations + 1)) = inplane_sampling + obj.configuration.discretization_bias;
                            %                                 obj.configuration.("is_r" + (iterations + 1)) = inplane_sampling / obj.configuration.refine_factor;
                            %                                 obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                            %                                 obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                            %                             else
                            obj.configuration.("ir_r" + (iterations + 1)) = inplane_range + (obj.configuration.discretization_bias / (iterations + 1));
                            obj.configuration.("is_r" + (iterations + 1)) = inplane_sampling;
                            obj.configuration.("cr_r" + (iterations + 1)) = cone_range + (obj.configuration.discretization_bias / (iterations + 1));
                            obj.configuration.("cs_r" + (iterations + 1)) = cone_sampling;
                        else
                            %	inplane_range [level i+1] = refine_factor * inplane_sampling [level i];
                            %	cone_range    [level i+1] = refine_factor * cone_sampling [level i];
                            obj.configuration.("ir_r" + (iterations + 1)) = obj.configuration.("is_r" + iterations) + (obj.configuration.discretization_bias / (iterations + 1)); % * obj.configuration.refine_factor; % + (obj.configuration.discretization_bias / (obj.configuration.refine_factor * j))
                            obj.configuration.("is_r" + (iterations + 1)) = obj.configuration.("is_r" + iterations) / obj.configuration.refine_factor;
                            obj.configuration.("cr_r" + (iterations + 1)) = obj.configuration.("cs_r" + iterations) + (obj.configuration.discretization_bias / (iterations + 1)); % * obj.configuration.refine_factor; % + (obj.configuration.discretization_bias / (obj.configuration.refine_factor * j))
                            obj.configuration.("cs_r" + (iterations + 1)) = obj.configuration.("cs_r" + iterations) / obj.configuration.refine_factor;
                            %sampling = sampling / obj.configuration.refine_factor;
                        end
                        
                        obj.configuration.("ite_r" + (iterations + 1)) = obj.configuration.iterations;
                        %                     obj.configuration.("rf_r" + (iterations + 1)) = 0;
                        %                     obj.configuration.("rff_r" + (iterations + 1)) = 0;
                        obj.configuration.("dim_r" + (iterations + 1)) = 0;
                        obj.configuration.("lim_r" + (iterations + 1)) = 0;
                        obj.configuration.("limm_r" + (iterations + 1)) = obj.configuration.area_search_mode;
                        obj.configuration.("sym_r" + (iterations + 1)) = char(obj.configuration.expected_symmetrie);
                        obj.configuration.("threshold_r" + (iterations + 1)) = obj.configuration.threshold;
                        obj.configuration.("threshold_modus_r" + (iterations + 1)) = obj.configuration.threshold_mode;
                        obj.configuration.("area_search_modus_r" + (iterations + 1)) = obj.configuration.area_search_mode;
                        obj.configuration.("cone_flip_r" + (iterations + 1)) = obj.configuration.cone_flip;
                        
                        if obj.configuration.bandpass_method == "angles"
                            obj.configuration.("high_r" + (iterations + 1)) = 2;
                            obj.configuration.("low_r" + (iterations + 1)) = 1 / tand(obj.configuration.("is_r" + (iterations + 1)));
                        end
                        
                        inplane_sampling = obj.configuration.("is_r" + (iterations + 1));
                        iterations = iterations + 1;
                        
                    end
                    
                    obj.dynamic_configuration.in_plane_range = obj.configuration.("ir_r" + (iterations));
                    obj.dynamic_configuration.in_plane_sampling = obj.configuration.("is_r" + (iterations));
                    obj.dynamic_configuration.cone_range = obj.configuration.("cr_r" + (iterations));
                    obj.dynamic_configuration.cone_sampling = obj.configuration.("cs_r" + (iterations));
                    
                    if obj.configuration.bandpass_method == "iterations"
                        bandpass_step = (((size(template, 1) / 2) / 2) - 3) / iterations;
                        
                        for i = 1:iterations
                            obj.configuration.("high_r" + i) = 2;
                            obj.configuration.("low_r" + i) = 3 + floor(bandpass_step * i);
                        end
                        
                    end
                    
                    %
                    %             if obj.configuration.sampling == 0
                    %                 if obj.configuration.in_plane_sampling < asind(1/size(template,1))
                    %                     in_plane_range = obj.configuration.template_matching_in_plane_sampling + obj.configuration.discretization_bias;
                    %                     in_plane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                 else
                    %                     in_plane_range = obj.configuration.in_plane_sampling + obj.configuration.discretization_bias;
                    %                     in_plane_sampling = obj.configuration.in_plane_sampling / obj.configuration.refine_factor;
                    %                     cone_range = obj.configuration.cone_sampling + obj.configuration.discretization_bias;
                    %                     cone_sampling = obj.configuration.cone_sampling / obj.configuration.refine_factor;
                    %                 end
                    %             else
                    %                 in_plane_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                 in_plane_sampling = obj.configuration.sampling / obj.configuration.refine_factor;
                    %                 cone_range = obj.configuration.sampling + obj.configuration.discretization_bias;
                    %                 cone_sampling = obj.configuration.sampling / obj.configuration.refine_factor;
                    %             end
                    %             dcp.new('subboxBig','d','subboxData','template','subboxRaw.em','masks','default','t','subboxData/crop.tbl','show',0);
                    %             dcp.new('first','d','particlesData','template','rawTemplate.em','masks','default','t','particlesData/crop.tbl','show',0);
                    %             dcp.new('central48good','t','central48good.tbl','d','central48Data','show',0);
                    
                    %             dvput('mraProject', 'mask', 'maskTooth32.em');
                    
                    %             oa = daverage('particlesData','t','particlesData/crop.tbl');
                    %             dwrite(oa.average,'rawTemplate.em');
                    %                 if ~isfield(obj.configuration, "inplane_range") && ~isfield(obj.configuration, "cone_range")
                    if ~exist("tables", "var")
                        tables_dir = dir("table.tbl");
                        
                        if ~isempty(tables_dir)
                            tables{1} = char(string(tables_dir(1).folder) + filesep + tables_dir(1).name);
                        else
                            error("ERROR: can not find table, delete processing step folder and rerun!")
                        end
                        
                    end
                    
                    %                 table_tmp = dread(tables{1});
                    %                 table_tmp(1:2:end, 34) = 1;
                    %                 table_tmp(2:2:end, 34) = 2;
                    %                 dwrite(table_tmp, tables{1});
                end
                
                field_names = fieldnames(obj.configuration);
                ite_r = contains(field_names, "ite_r");
                cr_r = contains(field_names, "cr_r");
                cs_r = contains(field_names, "cs_r");
                ir_r = contains(field_names, "ir_r");
                is_r = contains(field_names, "is_r");
                rf_r = contains(field_names, "rf_r");
                rff_r = contains(field_names, "rff_r");
                dim_r = contains(field_names, "dim_r");
                lim_r = contains(field_names, "lim_r");
                limm_r = contains(field_names, "limm_r");
                sym_r = contains(field_names, "sym_r");
                mra_r = contains(field_names, "mra_r");
                
                low_r = contains(field_names, "low_r");
                threshold_r = contains(field_names, "threshold_r");
                threshold_modus_r = contains(field_names, "threshold_modus_r");
                area_search_modus_r = contains(field_names, "area_search_modus_r");
                cone_flip_r = contains(field_names, "cone_flip_r");
                
                %     dvput project d -sym c1
                %     % is equivalent to
                %     dvput project d -sym_r1 c1
                field_names = field_names(logical(ite_r + cr_r + cs_r ...
                    + ir_r + is_r + rf_r + rff_r + dim_r + lim_r + limm_r ...
                    + area_search_modus_r + sym_r + low_r + threshold_r + threshold_modus_r + cone_flip_r));
                
                for i = 1:length(field_names)
                    %                 if contains(field_names{i}, "ite_")
                    %                     dvput(project_name, char(field_names{i}), iterations);
                    %                     continue;
                    %                 end
                    if contains(field_names{i}, "rf_")
                        
                        if obj.configuration.(field_names{i}) == -1
                            dvput(project_name, char(field_names{i}), iterations);
                        else
                            dvput(project_name, char(field_names{i}), obj.configuration.(field_names{i}));
                        end
                        
                        continue;
                    end
                    
                    if contains(field_names{i}, "ite_")
                        
                        if obj.configuration.(field_names{i}) == -1
                            dvput(project_name, char(field_names{i}), 1);
                        else
                            dvput(project_name, char(field_names{i}), obj.configuration.(field_names{i}));
                        end
                        
                        continue;
                    end
                    
                    if contains(field_names{i}, "lim_")
                        dvput(project_name, char(field_names{i}), size(template, 1) * obj.configuration.shift_limit_factor);
                        continue;
                    end
                    
                    if contains(field_names{i}, "limm_")
                        dvput(project_name, char(field_names{i}), 1);
                        continue;
                    end
                    
                    if contains(field_names{i}, "dim_")
                        dvput(project_name, char(field_names{i}), size(template, 1));
                        continue;
                    end
                    
                    %                 if contains(field_names{i}, "cr_")
                    %                     dvput(project_name, char(field_names{i}), obj.dynamic_configuration.cone_range);
                    %                     continue;
                    %                 end
                    %
                    %                 if contains(field_names{i}, "cs_")
                    %                     dvput(project_name, char(field_names{i}), obj.dynamic_configuration.cone_sampling);
                    %                     continue;
                    %                 end
                    %
                    %                 if contains(field_names{i}, "ir_")
                    %                     dvput(project_name, char(field_names{i}), obj.dynamic_configuration.in_plane_range);
                    %                     continue;
                    %                 end
                    %
                    %                 if contains(field_names{i}, "is_")
                    %                     dvput(project_name, char(field_names{i}), obj.dynamic_configuration.in_plane_sampling);
                    %                     continue;
                    %                 end
                    
                    if contains(field_names{i}, "sym_")
                        
                        if obj.configuration.use_symmetrie == true
                            dvput(project_name, char(field_names{i}), char(obj.configuration.expected_symmetrie));
                        else
                            dvput(project_name, char(field_names{i}), 'C1');
                        end
                        
                        continue;
                    end
                    
                    if contains(field_names{i}, "low_")
                        
                        if obj.configuration.(field_names{i}) < 1
                            dvput(project_name, char(field_names{i}), floor((size(template, 1) / 2) * obj.configuration.(field_names{i})));
                        else
                            dvput(project_name, char(field_names{i}), obj.configuration.(field_names{i}));
                        end
                        
                        continue;
                    end
                    
                    dvput(project_name, char(field_names{i}), obj.configuration.(field_names{i})');
                    
                    %                 dvput(obj.configuration.project_name, 'ite_r1', obj.configuration.ite_r1);
                    %                 dvput(obj.configuration.project_name, 'cr_r1', obj.configuration.cr_r1);
                    %                 dvput(obj.configuration.project_name, 'cs_r1', obj.configuration.cs_r1);
                    %                 dvput(obj.configuration.project_name, 'ir_r1', obj.configuration.ir_r1);
                    %                 dvput(obj.configuration.project_name, 'is_r1', obj.configuration.is_r1);
                    %                 dvput(obj.configuration.project_name, 'rf_r1', obj.configuration.rf_r1);
                    %                 dvput(obj.configuration.project_name, 'rff_r1', obj.configuration.rff_r1);
                    %                 dvput(obj.configuration.project_name, 'dim_r1', obj.configuration.dim_r1);
                    %                 dvput(obj.configuration.project_name, 'lim_r1', obj.configuration.lim_r1);
                    %                 dvput(obj.configuration.project_name, 'limm_r1', obj.configuration.lim_r1);
                    %    For parameters that are defined on different rounds (i.e.: ite_r1, ite_r2,...),
                    %    you can also invoke the parameter with its general name (i.e.: ite)
                    %    and then pass the parameter value as a cellarray {}, | separated list or an array []
                    %    in order to set the value of a given parameter in several rounds at once.
                    %
                    %     EXAMPLES:
                    %     dvput project  -ite [4,5]
                    %     dvput('project','d','ite',[4,5]);
                    %     dvput('project','d','sym',{'c1','c8'});
                    %     dvput project d sym c1|c8;
                end
                
                %                 else
                
                %                 end
                
                % TODO: make convenient parametrization 'matlab_parfor', 'matlab_gpu', 'standalone'
                dvput(project_name, 'dst', char(obj.configuration.destination));
                
                %             if obj.configuration.parallel_execution == true
                %                 dvput(char(project_name), 'dst', 'matlab_parfor')
                %             else
                %                 dvput(char(project_name), 'dst', 'standalone')
                %             end
                %             if obj.configuration.use_elliptic_mask
                %                 smoothing_mask_ones = template;
                %                 smoothing_mask_ones(:,:,:) = 1;
                %                 dwrite(smoothing_mask_ones, [char(alignment_project_folder_path) '/' char(project_name) '/settings/smoothingMaskOnes.em']);
                %                 elliptic_mask = gpuEllipsoid(ceil(length(template)/2), length(template));
                %                 dwrite(elliptic_mask, [char(alignment_project_folder_path) '/' char(project_name) '/settings/automatic_cmask.em']);
                %                 dwrite(elliptic_mask, [char(alignment_project_folder_path) '/' char(project_name) '/settings/automatic_mask.em']);
                %             end
                
                load([char(alignment_project_folder_path) '/' char(project_name) '/settings/virtual_project.mat']);
                
                %card.matlab_workers_average = round(obj.configuration.environment_properties.cpu_count_physical * obj.configuration.cpu_fraction);
                %card.how_many_processors = round(obj.configuration.environment_properties.cpu_count_physical * obj.configuration.cpu_fraction);
                
                card.matlab_workers_average = cpu_poolsize;
                
                if isscalar(obj.configuration.gpu) && obj.configuration.gpu == -1
                    card.gpu_identifier_set = 0:obj.configuration.environment_properties.gpu_count - 1;
                    card.how_many_processors = 1;
                elseif isscalar(obj.configuration.gpu) && obj.configuration.gpu == 0
                    card.gpu_identifier_set = [];
                    card.how_many_processors = cpu_poolsize;
                else
                    card.gpu_identifier_set = (obj.configuration.gpu - 1)';
                    card.how_many_processors = 1;
                end
                
                card.gpu_motor = 'spp';
                
                if obj.configuration.classes == 0
                    card.nref_r1 = 1;
                    card.nref_r2 = 1;
                    card.nref_r3 = 1;
                    card.nref_r4 = 1;
                    card.nref_r5 = 1;
                    card.nref_r6 = 1;
                    card.nref_r7 = 1;
                    card.nref_r8 = 1;
                else
                    card.nref_r1 = obj.configuration.classes;
                    card.nref_r2 = obj.configuration.classes;
                    card.nref_r3 = obj.configuration.classes;
                    card.nref_r4 = obj.configuration.classes;
                    card.nref_r5 = obj.configuration.classes;
                    card.nref_r6 = obj.configuration.classes;
                    card.nref_r7 = obj.configuration.classes;
                    card.nref_r8 = obj.configuration.classes;
                end
                
                if obj.configuration.swap_particles == true && obj.configuration.classes >= 2
                    card.mra_r1 = 1;
                    card.mra_r2 = 1;
                    card.mra_r3 = 1;
                    card.mra_r4 = 1;
                    card.mra_r5 = 1;
                    card.mra_r6 = 1;
                    card.mra_r7 = 1;
                    card.mra_r8 = 1;
                else
                    card.mra_r1 = 0;
                    card.mra_r2 = 0;
                    card.mra_r3 = 0;
                    card.mra_r4 = 0;
                    card.mra_r5 = 0;
                    card.mra_r6 = 0;
                    card.mra_r7 = 0;
                    card.mra_r8 = 0;
                end
                
                card.apix = apix * binning;
                card.file_template_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/multisettings_template_initial.sel'];
                card.file_table_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/multisettings_table_initial.sel'];
                card.file_fmask_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/multisettings_fmask_initial.sel'];
                
                if obj.configuration.mask_path ~= ""
                    card.file_mask = mask_em_files{1};
                    card.file_mask_classification = mask_em_files{1};
                    
                else
                    card.file_mask = [char(alignment_project_folder_path) '/' char(project_name) '/settings/mask.em'];
                    card.file_mask_classification = [char(alignment_project_folder_path) '/' char(project_name) '/settings/mask.em'];
                end
                
                save([char(alignment_project_folder_path) '/' char(project_name) '/settings/virtual_project.mat'], 'card');
                
                if obj.configuration.classes > 1 && obj.configuration.swap_particles == true
                else
                    card.file_fmask_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/fmask_initial_ref_001.em'];
                    
                    %                 if obj.configuration.classes == 2
                    %                     card.file_template_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings'];
                    %                     card.file_table_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings'];
                    %
                    %                     save([char(alignment_project_folder_path) '/' char(project_name) '/settings/virtual_project.mat'], 'card');
                    %                 else
                    card.file_template_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/template_initial_ref_001.em'];
                    card.file_table_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/table_initial_ref_001.tbl'];
                    %                 card.file_fmask_initial = [char(alignment_project_folder_path) '/' char(project_name) '/settings/mask.em'];
                    
                    if obj.configuration.mask_path ~= ""
                        card.file_mask = mask_em_files{1};
                        card.file_mask_classification = mask_em_files{1};
                        
                    else
                        card.file_mask = [char(alignment_project_folder_path) '/' char(project_name) '/settings/mask_ref_001.em'];
                        card.file_mask_classification = [char(alignment_project_folder_path) '/' char(project_name) '/settings/mask_ref_001.em'];
                    end
                    
                    save([char(alignment_project_folder_path) '/' char(project_name) '/settings/virtual_project.mat'], 'card');
                    %                 end
                    dvcheck(char(project_name));
                    dvunfold(char(project_name));
                    %                     % TODO: dirty
                    %                     if ~contains(project_name, "_eo")
                    %                         project_name = [project_name '_eo'];
                    %                     end
                    
                    dynamo_vpr_eo(project_name);
                    %                 [status, message, messageid] = rmdir(project_name, 's');
                    % TODO: dirty
                    if ~contains(project_name, "_eo")
                        project_name = [project_name '_eo'];
                    end
                end
                
                dvcheck(char(project_name));
                dvunfold(char(project_name));
                
                if (obj.configuration.classes > 1 && obj.configuration.swap_particles == true) || obj.configuration.split_by_y == false
                else
                    tomos_id = unique(new_table(:, 20));
                    
                    if obj.configuration.randomize_angles == true
                        new_table(:, [7 8 9]) = new_table(:, [7 8 9]) + ((rand() - 1.0) * card.cone_sampling_r1);
                        % new_table(:,[4 5 6]) = new_table(:,[4 5 6]) + ((rand() - 0.5) * card.cone_sampling_r1);
                    end
                    
                    h_id = [];
                    new_table = sortrows(new_table, 20);
                    
                    for i = 1:length(tomos_id)
                        t_idx = (new_table(:, 20) == tomos_id(i));
                        cur_y = new_table(t_idx, 25);
                        cur_hid = ones(sum(t_idx), 1);
                        cur_hid(cur_y > quantile(cur_y, 0.5)) = 2;
                        h_id = [h_id; cur_hid];
                    end
                    
                    half_id = h_id;
                    half_table_1 = new_table(half_id == 1, :);
                    half_table_1(:, 34) = 1;
                    half_table_2 = new_table(half_id == 2, :);
                    half_table_2(:, 34) = 2;
                    
                    eo_tables = dir("mraProject_bin_" + binning + "_eo" + filesep + "**" + filesep + "*.tbl");
                    dwrite(half_table_1, char(string(eo_tables(1).folder) + filesep + eo_tables(1).name));
                    dwrite(half_table_1, char(string(eo_tables(3).folder) + filesep + eo_tables(3).name));
                    dwrite(half_table_2, char(string(eo_tables(2).folder) + filesep + eo_tables(2).name));
                    dwrite(half_table_2, char(string(eo_tables(4).folder) + filesep + eo_tables(4).name));
                    %                 eo_mask = dir("mraProject_bin_" + binning + "_eo" + filesep + "settings" + filesep + "mask*.em");
                    %                 dwrite(mask, char(string(eo_mask(1).folder) + filesep + eo_mask(1).name));
                    %                 dwrite(mask, char(string(eo_mask(2).folder) + filesep + eo_mask(2).name));
                end
                
            else
                
                return_path = cd(alignment_project_folder_path);
            end
            
            %run mraProject/mraProject.m
            
            %             if obj.configuration.slurm == true
            %                 dvrun(char(project_name), 'queue', 'sbatch');
            %             else
            %                 dvrun(char(project_name));
            %             end
            if obj.configuration.classes > 1 %&& obj.configuration.swap_particles == true
                dynamo_execute_project(char(project_name));
                visualizations_path = obj.output_path + filesep + "visualizations";
                [SUCCESS, MESSAGE, MESSAGEID] = mkdir(obj.output_path + filesep + "visualizations");
                paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "last");
                iteration_path = dir(paths{1} + filesep + "*" + filesep + "*" + filesep + "results" + filesep + "ite_*");
                
                for h = 1:length(iteration_path) - 1
                    tab_all_path = dir(string(iteration_path(h).folder) + filesep + iteration_path(h).name + filesep + "averages" + filesep + "*.tbl");
                    tables = {char(string(tab_all_path(1).folder) + string(filesep) + tab_all_path(1).name)};
                    tbl = dread(tables{1});
                    tomogram_numbers = unique(tbl(:, 20));
                    
                    for i = 1:length(tomogram_numbers)
                        tom = i;
                        tbl_tom_sel = tbl(:, 20) == tom;
                        tbl_tom = tbl(tbl_tom_sel,:);
                        if size(tbl_tom, 1) > 0
                            f = figure('visible', 'off');
                            plot3(tbl_tom(:, 24), tbl_tom(:, 25), tbl_tom(:, 26), '.');
                            saveas(f, visualizations_path + filesep + "iteration_" + h + "_tomogram_" + i, "fig");
                            saveas(f, visualizations_path + filesep + "iteration_" + h + "_tomogram_" + i, "png");
                            close(f);
                            for j = 1:obj.configuration.classes
                                cls = j;
                                tbl_cls_sel = tbl(:, 34) == cls;
                                tbl_tom_cls = tbl((tbl_tom_sel & tbl_cls_sel),:);
                                if size(tbl_tom_cls, 1) > 0
                                    f = figure('visible', 'off');
                                    plot3(tbl_tom_cls(:, 24), tbl_tom_cls(:, 25), tbl_tom_cls(:, 26), '.');
                                    saveas(f, visualizations_path + filesep + "iteration_" + h + "_tomogram_" + i + "_class_" + j, "fig");
                                    saveas(f, visualizations_path + filesep + "iteration_" + h + "_tomogram_" + i + "_class_" + j, "png");
                                    close(f);
                                end
                            end
                        end
                    end
                    
                end
                
            else
                
                if ~contains(string(project_name), "_eo")
                    dynamo_execute_project(char(string(project_name) + "_eo"));
                else
                    dynamo_execute_project(char(string(project_name)));
                end
                
            end
            
            %             fid = fopen(obj.output_path + filesep + "SUCCESS_" + binning, "w");
            %             fclose(fid);
            
            %             if obj.configuration.show_results == true
            %                 ddb([char(project_name) ':a:ref=*'], 'j', ['c' num2str(length(template)/2)]);
            %             else
            %
            
            %             end
            
            cd(return_path);
            %             previous_binning = binning;
            %             binning = binning / 2;
            %             previous_project_name = project_name;
            %cd(return_path);
        end
        
        function card = generateCard(obj)
            card_fields = {{'name_project'}, ...
                {'path'}, ...
                {'file_template_initial'}, ...
                {'file_table_initial'}, ...
                {'folder_data'}, ...
                {'file_mask'}, ...
                {'file_mask_classification'}, ...
                {'file_fmask_initial'}, ...
                {'file_mask_smoothing'}, ...
                {'destination'}, ...
                {'how_many_processors'}, ...
                {'cluster_header'}, ...
                {'cluster_walltime'}, ...
                {'submit_order'}, ...
                {'gpu_identifier_set'}, ...
                {'gpu_motor'}, ...
                {'matlab_workers_average'}, ...
                {'intertwin'}, ...
                {'apix'}, ...
                {'initial_references'}, ...
                {'runfrom'}, ...
                {'options'}, ...
                {'MCR_CACHE_ROOT'}, ...
                {'multi_MCR_CACHE_ROOT'}, ...
                {'systemUsingProcessorTables'}, ...
                {'systemCardForParticle'}, ...
                {'systemNoMPIWrapUnfoldingGPU'}, ...
                {'symmetrize_with_fmask'}, ...
                {'project_type'}, ...
                {'adaptive_bandpass'}, ...
                {'adaptive_bandpass_pushback'}, ...
                {'adaptive_bandpass_threshold'}, ...
                {'adaptive_bandpass_initial'}, ...
                {'adaptive_bandpass_symmetrized'}, ...
                {'abp_recompute_second_average'}, ...
                {'adaptive_bandpass_even_odd'}, ...
                {'update_fmask'}, ...
                {'update_with_unweighted_average'}, ...
                {'fourierMinimumFractionForAverage'}, ...
                {'fCompensationSmoothingRadius'}, ...
                {'fCompensationSmoothingDecay'}, ...
                {'fCompensationSmoothingMask'}, ...
                {'useSmoothingMaskForFourierCompensation'}, ...
                {'averagingImplicitRotationMask'}, ...
                {'ite_r1'}, ...
                {'ite_r2'}, ...
                {'ite_r3'}, ...
                {'ite_r4'}, ...
                {'ite_r5'}, ...
                {'ite_r6'}, ...
                {'ite_r7'}, ...
                {'ite_r8'}, ...
                {'nref_r1'}, ...
                {'nref_r2'}, ...
                {'nref_r3'}, ...
                {'nref_r4'}, ...
                {'nref_r5'}, ...
                {'nref_r6'}, ...
                {'nref_r7'}, ...
                {'nref_r8'}, ...
                {'cone_range_r1'}, ...
                {'cone_range_r2'}, ...
                {'cone_range_r3'}, ...
                {'cone_range_r4'}, ...
                {'cone_range_r5'}, ...
                {'cone_range_r6'}, ...
                {'cone_range_r7'}, ...
                {'cone_range_r8'}, ...
                {'cone_sampling_r1'}, ...
                {'cone_sampling_r2'}, ...
                {'cone_sampling_r3'}, ...
                {'cone_sampling_r4'}, ...
                {'cone_sampling_r5'}, ...
                {'cone_sampling_r6'}, ...
                {'cone_sampling_r7'}, ...
                {'cone_sampling_r8'}, ...
                {'cone_flip_r1'}, ...
                {'cone_flip_r2'}, ...
                {'cone_flip_r3'}, ...
                {'cone_flip_r4'}, ...
                {'cone_flip_r5'}, ...
                {'cone_flip_r6'}, ...
                {'cone_flip_r7'}, ...
                {'cone_flip_r8'}, ...
                {'cone_check_peak_r1'}, ...
                {'cone_check_peak_r2'}, ...
                {'cone_check_peak_r3'}, ...
                {'cone_check_peak_r4'}, ...
                {'cone_check_peak_r5'}, ...
                {'cone_check_peak_r6'}, ...
                {'cone_check_peak_r7'}, ...
                {'cone_check_peak_r8'}, ...
                {'cone_freeze_reference_r1'}, ...
                {'cone_freeze_reference_r2'}, ...
                {'cone_freeze_reference_r3'}, ...
                {'cone_freeze_reference_r4'}, ...
                {'cone_freeze_reference_r5'}, ...
                {'cone_freeze_reference_r6'}, ...
                {'cone_freeze_reference_r7'}, ...
                {'cone_freeze_reference_r8'}, ...
                {'inplane_range_r1'}, ...
                {'inplane_range_r2'}, ...
                {'inplane_range_r3'}, ...
                {'inplane_range_r4'}, ...
                {'inplane_range_r5'}, ...
                {'inplane_range_r6'}, ...
                {'inplane_range_r7'}, ...
                {'inplane_range_r8'}, ...
                {'inplane_sampling_r1'}, ...
                {'inplane_sampling_r2'}, ...
                {'inplane_sampling_r3'}, ...
                {'inplane_sampling_r4'}, ...
                {'inplane_sampling_r5'}, ...
                {'inplane_sampling_r6'}, ...
                {'inplane_sampling_r7'}, ...
                {'inplane_sampling_r8'}, ...
                {'inplane_flip_r1'}, ...
                {'inplane_flip_r2'}, ...
                {'inplane_flip_r3'}, ...
                {'inplane_flip_r4'}, ...
                {'inplane_flip_r5'}, ...
                {'inplane_flip_r6'}, ...
                {'inplane_flip_r7'}, ...
                {'inplane_flip_r8'}, ...
                {'inplane_check_peak_r1'}, ...
                {'inplane_check_peak_r2'}, ...
                {'inplane_check_peak_r3'}, ...
                {'inplane_check_peak_r4'}, ...
                {'inplane_check_peak_r5'}, ...
                {'inplane_check_peak_r6'}, ...
                {'inplane_check_peak_r7'}, ...
                {'inplane_check_peak_r8'}, ...
                {'inplane_freeze_reference_r1'}, ...
                {'inplane_freeze_reference_r2'}, ...
                {'inplane_freeze_reference_r3'}, ...
                {'inplane_freeze_reference_r4'}, ...
                {'inplane_freeze_reference_r5'}, ...
                {'inplane_freeze_reference_r6'}, ...
                {'inplane_freeze_reference_r7'}, ...
                {'inplane_freeze_reference_r8'}, ...
                {'refine_r1'}, ...
                {'refine_r2'}, ...
                {'refine_r3'}, ...
                {'refine_r4'}, ...
                {'refine_r5'}, ...
                {'refine_r6'}, ...
                {'refine_r7'}, ...
                {'refine_r8'}, ...
                {'refine_factor_r1'}, ...
                {'refine_factor_r2'}, ...
                {'refine_factor_r3'}, ...
                {'refine_factor_r4'}, ...
                {'refine_factor_r5'}, ...
                {'refine_factor_r6'}, ...
                {'refine_factor_r7'}, ...
                {'refine_factor_r8'}, ...
                {'high_r1'}, ...
                {'high_r2'}, ...
                {'high_r3'}, ...
                {'high_r4'}, ...
                {'high_r5'}, ...
                {'high_r6'}, ...
                {'high_r7'}, ...
                {'high_r8'}, ...
                {'low_r1'}, ...
                {'low_r2'}, ...
                {'low_r3'}, ...
                {'low_r4'}, ...
                {'low_r5'}, ...
                {'low_r6'}, ...
                {'low_r7'}, ...
                {'low_r8'}, ...
                {'sym_r1'}, ...
                {'sym_r2'}, ...
                {'sym_r3'}, ...
                {'sym_r4'}, ...
                {'sym_r5'}, ...
                {'sym_r6'}, ...
                {'sym_r7'}, ...
                {'sym_r8'}, ...
                {'dim_r1'}, ...
                {'dim_r2'}, ...
                {'dim_r3'}, ...
                {'dim_r4'}, ...
                {'dim_r5'}, ...
                {'dim_r6'}, ...
                {'dim_r7'}, ...
                {'dim_r8'}, ...
                {'area_search_r1'}, ...
                {'area_search_r2'}, ...
                {'area_search_r3'}, ...
                {'area_search_r4'}, ...
                {'area_search_r5'}, ...
                {'area_search_r6'}, ...
                {'area_search_r7'}, ...
                {'area_search_r8'}, ...
                {'area_search_modus_r1'}, ...
                {'area_search_modus_r2'}, ...
                {'area_search_modus_r3'}, ...
                {'area_search_modus_r4'}, ...
                {'area_search_modus_r5'}, ...
                {'area_search_modus_r6'}, ...
                {'area_search_modus_r7'}, ...
                {'area_search_modus_r8'}, ...
                {'separation_in_tomogram_r1'}, ...
                {'separation_in_tomogram_r2'}, ...
                {'separation_in_tomogram_r3'}, ...
                {'separation_in_tomogram_r4'}, ...
                {'separation_in_tomogram_r5'}, ...
                {'separation_in_tomogram_r6'}, ...
                {'separation_in_tomogram_r7'}, ...
                {'separation_in_tomogram_r8'}, ...
                {'limit_xy_check_peak_r1'}, ...
                {'limit_xy_check_peak_r2'}, ...
                {'limit_xy_check_peak_r3'}, ...
                {'limit_xy_check_peak_r4'}, ...
                {'limit_xy_check_peak_r5'}, ...
                {'limit_xy_check_peak_r6'}, ...
                {'limit_xy_check_peak_r7'}, ...
                {'limit_xy_check_peak_r8'}, ...
                {'limit_z_check_peak_r1'}, ...
                {'limit_z_check_peak_r2'}, ...
                {'limit_z_check_peak_r3'}, ...
                {'limit_z_check_peak_r4'}, ...
                {'limit_z_check_peak_r5'}, ...
                {'limit_z_check_peak_r6'}, ...
                {'limit_z_check_peak_r7'}, ...
                {'limit_z_check_peak_r8'}, ...
                {'use_CC_r1'}, ...
                {'use_CC_r2'}, ...
                {'use_CC_r3'}, ...
                {'use_CC_r4'}, ...
                {'use_CC_r5'}, ...
                {'use_CC_r6'}, ...
                {'use_CC_r7'}, ...
                {'use_CC_r8'}, ...
                {'localnc_r1'}, ...
                {'localnc_r2'}, ...
                {'localnc_r3'}, ...
                {'localnc_r4'}, ...
                {'localnc_r5'}, ...
                {'localnc_r6'}, ...
                {'localnc_r7'}, ...
                {'localnc_r8'}, ...
                {'mra_r1'}, ...
                {'mra_r2'}, ...
                {'mra_r3'}, ...
                {'mra_r4'}, ...
                {'mra_r5'}, ...
                {'mra_r6'}, ...
                {'mra_r7'}, ...
                {'mra_r8'}, ...
                {'threshold_r1'}, ...
                {'threshold_r2'}, ...
                {'threshold_r3'}, ...
                {'threshold_r4'}, ...
                {'threshold_r5'}, ...
                {'threshold_r6'}, ...
                {'threshold_r7'}, ...
                {'threshold_r8'}, ...
                {'threshold_modus_r1'}, ...
                {'threshold_modus_r2'}, ...
                {'threshold_modus_r3'}, ...
                {'threshold_modus_r4'}, ...
                {'threshold_modus_r5'}, ...
                {'threshold_modus_r6'}, ...
                {'threshold_modus_r7'}, ...
                {'threshold_modus_r8'}, ...
                {'threshold2_r1'}, ...
                {'threshold2_r2'}, ...
                {'threshold2_r3'}, ...
                {'threshold2_r4'}, ...
                {'threshold2_r5'}, ...
                {'threshold2_r6'}, ...
                {'threshold2_r7'}, ...
                {'threshold2_r8'}, ...
                {'threshold2_modus_r1'}, ...
                {'threshold2_modus_r2'}, ...
                {'threshold2_modus_r3'}, ...
                {'threshold2_modus_r4'}, ...
                {'threshold2_modus_r5'}, ...
                {'threshold2_modus_r6'}, ...
                {'threshold2_modus_r7'}, ...
                {'threshold2_modus_r8'}, ...
                {'ccmatrix_r1'}, ...
                {'ccmatrix_r2'}, ...
                {'ccmatrix_r3'}, ...
                {'ccmatrix_r4'}, ...
                {'ccmatrix_r5'}, ...
                {'ccmatrix_r6'}, ...
                {'ccmatrix_r7'}, ...
                {'ccmatrix_r8'}, ...
                {'ccmatrix_type_r1'}, ...
                {'ccmatrix_type_r2'}, ...
                {'ccmatrix_type_r3'}, ...
                {'ccmatrix_type_r4'}, ...
                {'ccmatrix_type_r5'}, ...
                {'ccmatrix_type_r6'}, ...
                {'ccmatrix_type_r7'}, ...
                {'ccmatrix_type_r8'}, ...
                {'ccmatrix_batch_r1'}, ...
                {'ccmatrix_batch_r2'}, ...
                {'ccmatrix_batch_r3'}, ...
                {'ccmatrix_batch_r4'}, ...
                {'ccmatrix_batch_r5'}, ...
                {'ccmatrix_batch_r6'}, ...
                {'ccmatrix_batch_r7'}, ...
                {'ccmatrix_batch_r8'}, ...
                {'Xmatrix_r1'}, ...
                {'Xmatrix_r2'}, ...
                {'Xmatrix_r3'}, ...
                {'Xmatrix_r4'}, ...
                {'Xmatrix_r5'}, ...
                {'Xmatrix_r6'}, ...
                {'Xmatrix_r7'}, ...
                {'Xmatrix_r8'}, ...
                {'Xmatrix_maxMb_r1'}, ...
                {'Xmatrix_maxMb_r2'}, ...
                {'Xmatrix_maxMb_r3'}, ...
                {'Xmatrix_maxMb_r4'}, ...
                {'Xmatrix_maxMb_r5'}, ...
                {'Xmatrix_maxMb_r6'}, ...
                {'Xmatrix_maxMb_r7'}, ...
                {'Xmatrix_maxMb_r8'}, ...
                {'PCA_r1'}, ...
                {'PCA_r2'}, ...
                {'PCA_r3'}, ...
                {'PCA_r4'}, ...
                {'PCA_r5'}, ...
                {'PCA_r6'}, ...
                {'PCA_r7'}, ...
                {'PCA_r8'}, ...
                {'PCA_neigs_r1'}, ...
                {'PCA_neigs_r2'}, ...
                {'PCA_neigs_r3'}, ...
                {'PCA_neigs_r4'}, ...
                {'PCA_neigs_r5'}, ...
                {'PCA_neigs_r6'}, ...
                {'PCA_neigs_r7'}, ...
                {'PCA_neigs_r8'}, ...
                {'kmeans_r1'}, ...
                {'kmeans_r2'}, ...
                {'kmeans_r3'}, ...
                {'kmeans_r4'}, ...
                {'kmeans_r5'}, ...
                {'kmeans_r6'}, ...
                {'kmeans_r7'}, ...
                {'kmeans_r8'}, ...
                {'kmeans_ncluster_r1'}, ...
                {'kmeans_ncluster_r2'}, ...
                {'kmeans_ncluster_r3'}, ...
                {'kmeans_ncluster_r4'}, ...
                {'kmeans_ncluster_r5'}, ...
                {'kmeans_ncluster_r6'}, ...
                {'kmeans_ncluster_r7'}, ...
                {'kmeans_ncluster_r8'}, ...
                {'kmeans_ncoefficients_r1'}, ...
                {'kmeans_ncoefficients_r2'}, ...
                {'kmeans_ncoefficients_r3'}, ...
                {'kmeans_ncoefficients_r4'}, ...
                {'kmeans_ncoefficients_r5'}, ...
                {'kmeans_ncoefficients_r6'}, ...
                {'kmeans_ncoefficients_r7'}, ...
                {'kmeans_ncoefficients_r8'}, ...
                {'nclass_r1'}, ...
                {'nclass_r2'}, ...
                {'nclass_r3'}, ...
                {'nclass_r4'}, ...
                {'nclass_r5'}, ...
                {'nclass_r6'}, ...
                {'nclass_r7'}, ...
                {'nclass_r8'}, ...
                {'plugin_align_r1'}, ...
                {'plugin_align_r2'}, ...
                {'plugin_align_r3'}, ...
                {'plugin_align_r4'}, ...
                {'plugin_align_r5'}, ...
                {'plugin_align_r6'}, ...
                {'plugin_align_r7'}, ...
                {'plugin_align_r8'}, ...
                {'plugin_post_r1'}, ...
                {'plugin_post_r2'}, ...
                {'plugin_post_r3'}, ...
                {'plugin_post_r4'}, ...
                {'plugin_post_r5'}, ...
                {'plugin_post_r6'}, ...
                {'plugin_post_r7'}, ...
                {'plugin_post_r8'}, ...
                {'plugin_iter_r1'}, ...
                {'plugin_iter_r2'}, ...
                {'plugin_iter_r3'}, ...
                {'plugin_iter_r4'}, ...
                {'plugin_iter_r5'}, ...
                {'plugin_iter_r6'}, ...
                {'plugin_iter_r7'}, ...
                {'plugin_iter_r8'}, ...
                {'plugin_align_order_r1'}, ...
                {'plugin_align_order_r2'}, ...
                {'plugin_align_order_r3'}, ...
                {'plugin_align_order_r4'}, ...
                {'plugin_align_order_r5'}, ...
                {'plugin_align_order_r6'}, ...
                {'plugin_align_order_r7'}, ...
                {'plugin_align_order_r8'}, ...
                {'plugin_post_order_r1'}, ...
                {'plugin_post_order_r2'}, ...
                {'plugin_post_order_r3'}, ...
                {'plugin_post_order_r4'}, ...
                {'plugin_post_order_r5'}, ...
                {'plugin_post_order_r6'}, ...
                {'plugin_post_order_r7'}, ...
                {'plugin_post_order_r8'}, ...
                {'plugin_iter_order_r1'}, ...
                {'plugin_iter_order_r2'}, ...
                {'plugin_iter_order_r3'}, ...
                {'plugin_iter_order_r4'}, ...
                {'plugin_iter_order_r5'}, ...
                {'plugin_iter_order_r6'}, ...
                {'plugin_iter_order_r7'}, ...
                {'plugin_iter_order_r8'}, ...
                {'flags_r1'}, ...
                {'flags_r2'}, ...
                {'flags_r3'}, ...
                {'flags_r4'}, ...
                {'flags_r5'}, ...
                {'flags_r6'}, ...
                {'flags_r7'}, ...
                {'flags_r8'}, ...
                {'convergence_type_r1'}, ...
                {'convergence_type_r2'}, ...
                {'convergence_type_r3'}, ...
                {'convergence_type_r4'}, ...
                {'convergence_type_r5'}, ...
                {'convergence_type_r6'}, ...
                {'convergence_type_r7'}, ...
                {'convergence_type_r8'}, ...
                {'convergence_r1'}, ...
                {'convergence_r2'}, ...
                {'convergence_r3'}, ...
                {'convergence_r4'}, ...
                {'convergence_r5'}, ...
                {'convergence_r6'}, ...
                {'convergence_r7'}, ...
                {'convergence_r8'}, ...
                {'rings_r1'}, ...
                {'rings_r2'}, ...
                {'rings_r3'}, ...
                {'rings_r4'}, ...
                {'rings_r5'}, ...
                {'rings_r6'}, ...
                {'rings_r7'}, ...
                {'rings_r8'}, ...
                {'rings_random_r1'}, ...
                {'rings_random_r2'}, ...
                {'rings_random_r3'}, ...
                {'rings_random_r4'}, ...
                {'rings_random_r5'}, ...
                {'rings_random_r6'}, ...
                {'rings_random_r7'}, ...
                {'rings_random_r8'}, ...
                {'dynamic_mask_r1'}, ...
                {'dynamic_mask_r2'}, ...
                {'dynamic_mask_r3'}, ...
                {'dynamic_mask_r4'}, ...
                {'dynamic_mask_r5'}, ...
                {'dynamic_mask_r6'}, ...
                {'dynamic_mask_r7'}, ...
                {'dynamic_mask_r8'}};
        end
        
    end
    
end

%         "ite_r1": -1,
%         "cr_r1": 4,
%         "cs_r1": 2,
%         "ir_r1": 4,
%         "is_r1": 2,
%         "rf_r1": -1,
%         "rff_r1": 2,
%         "dim_r1": 24,
%         "lim_r1": [24, 24, 24],
%         "limm_r1": 2,
%         "sym_r1": "C1",
%         "low_r1": 0.5,
%         "area_search_modus_r1": 1,
%         "threshold_r1": 0.5,
%         "threshold_modus_r1": 5,
%         "help": {
%             "rf_r1_help": "------------------------------------------------------------
%                 name : refine
%                 shortform : rf
%                 type of input : 1
%                 round behaviour : round
%                 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                 Parameter name:   'refine'
%                 How many refinement iterations are carried out on each
%                 single particle.
%                 This refinement when comparing rotations of the reference
%                 against the data, takes the best orientation and looks again
%                 with a finer sampling.
%                 The sampling in the refined search will be half of the
%                 sampling used in the original one.  The range of the refined
%                 search encompasses all the orientations that neighobur the
%                 best orientation found in the original search.
%                 ------------------------------------------------------------",
%             "rff_r1_help": "------------------------------------------------------------
%                 name : refine_factor
%                 shortform : rff
%                 type of input : 1
%                 round behaviour : round
%                 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                 Parameter name:   'refine_factor'
%                 Controls the size of the angular neighborhood during the
%                 local refinement of the angular grid.
%                 In particular, the scanning range at refinement level [i+1]
%                 will be determined by the scaning step (NOT the scanning
%                 range!) at level [i];
%                 cone_range    [level i+1] = refine_factor * cone_sampling
%                 [level i];
%                 inplane_range [level i+1] = refine_factor * inplane_sampling
%                 [level i];
%                 ------------------------------------------------------------",
%             "dim_r1_help": "------------------------------------------------------------
%                 name : dim
%                 shortform : dim
%                 type of input : 1
%                 round behaviour : round
%                 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                 Parameter name: 'dim'
%                 Resamples the particles to this dimension, template and
%                 masks will be resampled accordingly.
%                 The value is in pixels of the data particles (use the A->pix
%                 button for conversions),
%                 and it is the full sidelength of the cube, NOT the radius!
%                 If the original dimension of the particle is a power of two
%                 of the required
%                 dimensionality,a binning is performed. Otherwise, particles
%                 are resized using interpolation.
%                 ------------------------------------------------------------",
%             "lim_r1_help": "------------------------------------------------------------
%                 name : area_search
%                 shortform : lim
%                 type of input : 1
%                 round behaviour : round
%                 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                 Parameter name: 'area search'
%                 (short form: 'lim')
%                 Restricts the search area to an ellipsoid centered and
%                 oriented in the last found position.
%                 The three parameters are the semiaxes of the ellipsoid.
%                 If a single parameters is introduced, the ellipsoid
%                 collapses into a sphere.
%                 If no restriction should be imposed, put a zero on the
%                 'area_search_modus' project parameter
%                 (in the GUI.this is the column to the right)
%                 HINT:
%                 The position 15 of the table keeps a record on how far apart
%                 was the real maximum of the cc from
%                 the restricted maximum
%                 ------------------------------------------------------------",
%             "limm_r1_help": "------------------------------------------------------------
%                 name : area_search_modus
%                 shortform : limm
%                 type of input : 1
%                 round behaviour : round
%                 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                 Parameter name: 'area search_modus'
%                 States how exactly the shifts (parameter 'area search') will
%                 be interpreted
%                 Posible values:
%                 0:  no limitations
%                 (can easily produce artifacts if the initial reference is
%                 bad)
%                 1:  limits are understood from the center of the particle
%                 cube.
%                 2:  limits are understood from the previous estimation on
%                 the particle position
%                 (i.e., the shifts available in the table)
%                 With this option, the originof the shifts changes at every
%                 iteration.
%                 3:  limis are understood from the estimation provided for
%                 the first iteration
%                 of the round.
%                 The origin of the shifts will change at each round.
%                 4:  limis are understood from the estimation provided for
%                 the first iteration
%                 of the project.
%                 The origin of the shifts is thus defined for the full
%                 project, and stays
%                 static all during the full computation.
%                 Note that options 3 and 4 are useful to avoid particles
%                 gradually shifting
%                 away from the initially user-entered locations.
%                 ------------------------------------------------------------"
%         },

% "name_project": "",
% "path": "",
% "file_template_initial": "",
% "file_table_initial": "",
% "folder_data": "",
% "file_mask": "",
% "file_mask_classification": "",
% "file_fmask_initial": "",
% "file_mask_smoothing": "",
% "destination": "",
% "how_many_processors": "",
% "cluster_header": "",
% "cluster_walltime": "",
% "submit_order": "",
% "gpu_identifier_set": "",
% "gpu_motor": "",
% "matlab_workers_average": "",
% "intertwin": "",
% "apix": "",
% "initial_references": "",
% "runfrom": "",
% "options": "",
% "MCR_CACHE_ROOT": "",
% "multi_MCR_CACHE_ROOT": "",
% "systemUsingProcessorTables": "",
% "systemCardForParticle": "",
% "systemNoMPIWrapUnfoldingGPU": "",
% "symmetrize_with_fmask": "",
% "project_type": "",
% "adaptive_bandpass": "",
% "adaptive_bandpass_pushback": "",
% "adaptive_bandpass_threshold": "",
% "adaptive_bandpass_initial": "",
% "adaptive_bandpass_symmetrized": "",
% "abp_recompute_second_average": "",
% "adaptive_bandpass_even_odd": "",
% "update_fmask": "",
% "update_with_unweighted_average": "",
% "fourierMinimumFractionForAverage": "",
% "fCompensationSmoothingRadius": "",
% "fCompensationSmoothingDecay": "",
% "fCompensationSmoothingMask": "",
% "useSmoothingMaskForFourierCompensation": "",
% "averagingImplicitRotationMask": "",
