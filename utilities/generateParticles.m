function particles_path = generateParticles(configuration, table_path, binning, box_size, append_tags, force_method)

if nargin < 6
    method = "";
    if nargin < 5
        append_tags = false;
    end
else
    method = force_method;
end

if strcmp(method,"") == true
    if isfield(configuration, "use_SUSAN") && configuration.use_SUSAN == true
        method = "susan";
    else
        method = "dynamo";
    end
end

disp(method);
disp("INFO: generating particles for binning " + binning);

particles_base_folder = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.particles_folder;

if strcmp(method, "susan") == true && configuration.use_dose_weighted_particles == true
    particles_path = particles_base_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size + "_dw";
else
    particles_path = particles_base_folder + string(filesep) + "particles_bin_" + binning + "_bs_" + box_size;
end

% if configuration.as_boxes == true
%     particles_path = particles_path + ".Boxes";
% end

% NB: this comment was exported from DynamoAlignmentProject
% tmp_folder = getFilesFromLastModuleRun(obj.configuration, "TemplateMatchingPostProcessing", "");
% particle_boundaries_files = dir(tmp_folder{1} + filesep + "*.tbl");
% particle_boundaries = [];
% for i = 1:length(particle_boundaries_files)
%     particle_boundaries_splitted = strsplit(particle_boundaries_files(i).name);
%     particle_boundaries(end + 1) = num2str(particle_boundaries_splitted{end});
% end

if strcmp(method, "susan") == true
    generateSUSANParticles(configuration, particles_path, table_path, binning, box_size);
else
    generateDynamoParticles(configuration, particles_path, table_path, binning, box_size, append_tags);
end

end

function generateDynamoParticles(configuration, particles_path, table_path, binning, box_size, append_tags)

if binning == 1
    binned_tomograms_paths = getCtfCorrectedTomogramsFromStandardFolder(configuration, true);

    if isempty(binned_tomograms_paths) == true
        binned_tomograms_paths = getTomogramsFromStandardFolder(configuration, true);
    end

    binned_tomograms_paths_filtered = binned_tomograms_paths;

    if isempty(binned_tomograms_paths_filtered)
        error("ERROR: no tomograms to crop particles are available for the selected binning level(" + binning + ")!");
    end

else
    binned_tomograms_paths = getCtfCorrectedBinnedTomogramsFromStandardFolder(configuration, true, binning);

    if isempty(binned_tomograms_paths) == true
        binned_tomograms_paths = getBinnedTomogramsFromStandardFolder(configuration, true, binning);
    end

    binned_tomograms_paths_filtered = binned_tomograms_paths(contains({binned_tomograms_paths.name}, "bin_" + binning));

    if isempty(binned_tomograms_paths_filtered)
        error("ERROR: no tomograms to crop particles are available for the selected binning level(" + binning + ")!");
    end

end

table = dread(table_path);

sub_tables_id = unique(table(:,23));

for sub_table_idx = 1:length(sub_tables_id)
    
    sub_table = table(table(:, 23) == sub_tables_id(sub_table_idx), :);
    tomos_id = unique(sub_table(:,20));

    for tomogram_idx = 1:length(tomos_id)

        sub_table_tomogram = sub_table(sub_table(:, 20) == tomos_id(tomogram_idx), :);

        index = find(contains({binned_tomograms_paths_filtered.name}, sprintf("%03d", tomos_id(tomogram_idx))));
        binned_tomogram_path = char(binned_tomograms_paths_filtered(index).folder + string(filesep) + binned_tomograms_paths_filtered(index).name);

        dtcrop(binned_tomogram_path, sub_table_tomogram, char(particles_path), box_size, 'allow_padding', configuration.dynamo_allow_padding, 'inmemory', configuration.dt_crop_in_memory, 'maxMb', configuration.dt_crop_max_mb, 'asBoxes', 0, 'append_tags', append_tags);

    end

end

if ~configuration.dynamo_allow_padding
    table = cleanCroppedParticlesTable(table, char(particles_path));
    dwrite(table, table_path);
end

% TODO: Parse dBoxes case
% if configuration.as_boxes == 1
%     if configuration.all_in_one_folder == true
%         particles_folder = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_folder + string(filesep) + "particles_bin_" + obj.configuration.template_matching_binning + "_bs_" + box_size;
%         ownDbox(string(particles_folder),string([char(particles_folder) '.Boxes']));
%         [status, message, messageid] = rmdir(char(particles_folder), 's');
%     end
% end

end

function generateSUSANParticles(configuration, particles_path, table_path, binning, box_size)

% Folder to put SUSAN metadata such as TOMOSTXT & PTCLSRAW files
particles_info_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.particles_susan_info_folder;

table = dread(table_path);

if binning > 1
    aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(configuration, true, binning);
else
    aligned_tilt_stacks_raw = getAlignedTiltStacksFromStandardFolder(configuration, true);
    
    % Create an empty structure aligned_tilt_stacks but
    % with the same fields as in aligned_tilt_stacks_raw
    aligned_tilt_stacks = reshape(fieldnames(aligned_tilt_stacks_raw), 1, []);
    aligned_tilt_stacks(2, :) = {[]};
    aligned_tilt_stacks = struct(aligned_tilt_stacks{:});
    aligned_tilt_stacks(1) = [];
    
    for idx = 1:numel(aligned_tilt_stacks_raw)
        if ~contains(aligned_tilt_stacks_raw(idx).name, "bin")
            aligned_tilt_stacks(end+1) = aligned_tilt_stacks_raw(idx);
        end
    end
end

[width, height, ~] = getHeightAndWidthFromHeader(string(aligned_tilt_stacks(1).folder) + filesep + string(aligned_tilt_stacks(1).name), -1);

%tlt_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "tlt", "last");
tlt_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(configuration, ".tlt");

%defocus_files = getFilesFromLastModuleRun(obj.configuration, "BatchRunTomo", "defocus", "last");
defocus_files = getFilesWithMatchingPatternFromLastBatchruntomoRun(configuration, ".defocus");

tomos_id = unique(table(:,20));

N = length(tomos_id);
                            
if isfield(configuration, "tilt_angles")
    P = length(configuration.tilt_angles);
else
    P = 0;
    tomos_fields = fieldnames(configuration.tomograms);
    for idx = 1:length(tomos_fields)
        tomo_field = configuration.tomograms.(tomos_fields{idx});
        if isstruct(tomo_field)
            P_tomo = length(tomo_field.original_angles);
        end
        if P_tomo > P
            P = P_tomo;
        end
    end
end

tomos = SUSAN.Data.TomosInfo(N, P);
dose_per_projection = configuration.dose / P;

for i = 1:N
    tomos.tomo_id(i) = tomos_id(i);
    stack_path = string(aligned_tilt_stacks(i).folder) + filesep + string(aligned_tilt_stacks(i).name);
    tomos.set_stack (i, stack_path);
    tomos.set_angles (i, char(string(tlt_files{tomos_id(i)}(1).folder) + filesep + tlt_files{tomos_id(i)}(1).name));
    
    if configuration.ctf_correction_method == "defocus_file"
        tomos.set_defocus(i, char(string(defocus_files{tomos_id(i)}(1).folder) + filesep + string(defocus_files{tomos_id(i)}(1).name)));
    end
    
    if configuration.use_dose_weighted_particles == true
        field_names = fieldnames(configuration.tomograms);
        if configuration.tilt_stacks == false
            projections_in_high_dose_image = configuration.tomograms.(field_names{tomos_id(i)}).high_dose_frames / configuration.tomograms.(field_names{tomos_id(i)}).low_dose_frames;
        else
            projections_in_high_dose_image = 0;
        end
        for j = 1:size(tomos.defocus, 1)

            if configuration.dose_weight_first_image == true

                if configuration.high_dose == true
                    tomos.defocus(j, 6, i) = configuration.b_factor_per_projection * ((configuration.dose_order(j) - 1 + projections_in_high_dose_image) * dose_per_projection);
                else
                    tomos.defocus(j, 6, i) = configuration.b_factor_per_projection * ((configuration.dose_order(j)) * dose_per_projection);
                end

            else

                if configuration.high_dose == true

                    if j > 1
                        tomos.defocus(j, 6, i) = configuration.b_factor_per_projection * ((configuration.dose_order(j) - 1 + projections_in_high_dose_image) * dose_per_projection);
                    end

                else
                    tomos.defocus(j, 6, i) = configuration.b_factor_per_projection * ((configuration.dose_order(j) - 1) * dose_per_projection);
                end

            end

        end

    end

    if configuration.exclude_projections == true

        if configuration.tilt_scheme == "dose_symmetric_parallel"

            for j = 1:size(tomos.defocus, 1)

                if tilt_angles(dose_order == j) >= -((floor(P / 2) - k + 1) * tilt_angle_step) && tilt_angles(dose_order == j) <= ((floor(P / 2) - k + 1) * tilt_angle_step)
                    tomos.proj_weight(dose_order == j, 1, i) = 1;
                else
                    tomos.proj_weight(dose_order == j, 1, i) = 0;
                end

            end

        elseif configuration.tilt_scheme == "bi_directional" || configuration.tilt_scheme == "dose_symmetric_sequential" || configuration.tilt_scheme == "dose_symmetric"

            for j = 1:size(tomos.defocus, 1)

                if j < max(dose_order) - exclude_projections
                    tomos.proj_weight(dose_order == j, 1, i) = 1;
                else
                    tomos.proj_weight(dose_order == j, 1, i) = 0;
                end

            end

        end

    end

    if isfield(configuration, "apix") && configuration.apix ~= 0
        tomos.pix_size(i) = configuration.apix * configuration.ft_bin * binning;
    else
        tomos.pix_size(i) = configuration.greatest_apix * configuration.ft_bin * binning;
    end

    tomos.tomo_size(i, :) = [width, height, configuration.reconstruction_thickness / binning];

end

tomos_path = char(particles_info_path + string(filesep) + "tomos_bin_" + binning + ".tomostxt");
tomos.save(tomos_path);

particles_raw_path = char(particles_info_path + string(filesep) + "particles_bin_" + binning + ".ptclsraw");
ptcls = SUSAN.Data.ParticlesInfo(table, tomos);
                            
if configuration.ctf_correction_method == "IMOD"
    tmp_positions = ptcls.position(:, 3);
    ptcls.position(:, 3) = 0;
    ptcls.update_defocus(tomos);
    ptcls.position(:, 3) = tmp_positions;
elseif configuration.ctf_correction_method == "defocus_file"
elseif configuration.ctf_correction_method == "SUSAN"
    error("ERROR: Sorry, this functionality is not fully deployed yet!");
    % TODO: extract all the following code to the SUSANCTFCorrection module
%     % N.B.: Can we not rely on template size here?
%     template = getTemplate(configuration);
%     sampling = size(template, 1); % spacing between particles, in pixels
%     grid_ctf = SUSAN.Data.ParticlesInfo.grid2D(sampling, tomos);
%     grid_ctf_path = char(particles_info_path + string(filesep) + "grid_ctf.ptclsraw");
%     grid_ctf.save(grid_ctf_path);
%     %% Create CtfEstimator
%     ctf_est = SUSAN.Modules.CtfEstimator(configuration.SUSAN_ctf_box_size);
%     ctf_est.binning = configuration.SUSAN_binning; % No binning (2^0).
% 
%     if configuration.gpu == -1
%         ctf_est.gpu_list = 0:gpuDeviceCount - 1;
%     else
%         ctf_est.gpu_list = configuration.gpu - 1;
%     end
%     
%     %ctf_est.gpu_list = [0 1 2 3]; % 4 GPUs available.
% 
%     ctf_est.resolution.min = configuration.SUSAN_resolution_min; % new parameter
%     ctf_est.resolution.max = binning * configuration.ft_bin * configuration.apix;
% 
%     if isfield(configuration, "global_lower_defocus_average_in_angstrom")
%         ctf_est.defocus.min = configuration.global_lower_defocus_average_in_angstrom;
%         ctf_est.defocus.max = configuration.global_upper_defocus_average_in_angstrom;
%     elseif isfield(configuration, "nominal_defocus_in_nm") && configuration.nominal_defocus_in_nm ~= 0
%         % TODO: could be also 2 numbers for lower and upper
%         % limit or factors in different variable names
%         ctf_est.defocus.min = round(configuration.nominal_defocus_in_nm / configuration.defocus_limit_factor) * 10^4;
%         ctf_est.defocus.max = round(configuration.nominal_defocus_in_nm * configuration.defocus_limit_factor) * 10^4;
%     else
%         ctf_est.defocus.min = obj.configuration.SUSAN_defocus_min; % angstroms
%         ctf_est.defocus.max = obj.configuration.SUSAN_defocus_max; % angstroms
%     end
%     ctf_est.verbose = 2;
%     ctf_est_path = char(particles_info_path + string(filesep) + "ctf_grid");
%     tomos_ctf = ctf_est.estimate(ctf_est_path, grid_ctf_path, tomos_path);
%     tomos_ctf.save(tomos_path);
end
 
ptcls.save(particles_raw_path);

% TODO: extract all the following code to the generateParticlesAverage()
% Place in this function possibility to use either Dynamo or SUSAN
% avg = SUSAN.Modules.Averager;
%                            
% if obj.configuration.gpu == -1
%     avg.gpu_list = 0:gpuDeviceCount - 1;
% else
%     avg.gpu_list = obj.configuration.gpu - 1;
% end
% 
% box_size = round((size(template, 1) * obj.configuration.box_size) * (previous_binning / binning));
% 
% if mod(box_size, 2) == 1
%     box_size = box_size + 1;
% end
% 
% avg.bandpass.lowpass = min(obj.configuration.susan_lowpass, (box_size / 2) / 2);
% avg.padding = obj.configuration.susan_padding / binning;
% avg.rec_halves = true;
% 
% if (obj.configuration.per_particle_ctf_correction == "wiener_ssnr")
%     avg.set_ctf_correction(char("wiener_ssnr"), obj.configuration.ssnr(1), obj.configuration.ssnr(2)); % what about SSNR....: set_ctf_correction('wiener_ssnr', 1, 0.8);
% else
%     avg.set_ctf_correction(char(obj.configuration.per_particle_ctf_correction)); % what about SSNR....: set_ctf_correction('wiener_ssnr', 1, 0.8);
% end
% 
% avg.set_padding_policy(char(obj.configuration.padding_policy));
% avg.set_normalization(char(obj.configuration.normalization));
% 
% if obj.configuration.use_symmetrie == true
%     avg.set_symmetry(char(obj.configuration.expected_symmetrie));
% end
% 
%                 if obj.configuration.susan_box_size > 0
%                     box_size = round((size(template,1) * obj.configuration.susan_box_size) * (previous_binning / binning)); %obj.configuration.susan_box_size;
%                     obj.dynamic_configuration.susan_box_size = 1;
%                 else
% 
% end

subtomos = SUSAN.Modules.SubtomoRec;
                           
if configuration.gpu == -1
    subtomos.gpu_list = 0:gpuDeviceCount - 1;
else
    subtomos.gpu_list = configuration.gpu - 1;
end

subtomos.padding = round(configuration.susan_padding / binning);

subtomos.set_ctf_correction(char(configuration.per_particle_ctf_correction)); % try also wiener if you like
subtomos.set_padding_policy(char(configuration.padding_policy));
subtomos.set_normalization(char(configuration.normalization));
subtomos.reconstruct(char(particles_path), tomos_path, particles_raw_path, box_size);

% Table cleaning if particles can be discarded
table = cleanCroppedParticlesTable(table, char(particles_path));
dwrite(table, table_path);

% Parse dBoxes case
% if obj.configuration.as_boxes == 1
%     % dBoxes.convertSimpleData(char("../../particles/particles_bin_" + binning  + "_bs_" + box_size),...
%     %     [char("../../particles/particles_bin_" + binning  + "_bs_" + box_size) '.Boxes'],...
%     %     'batch', obj.configuration.particle_batch, 'dc', obj.configuration.direct_copy);
%     ownDbox(string(particles_path), ...
%         string([char(particles_path) '.Boxes']));
% 
%     [status, message, messageid] = rmdir(char(particles_path), 's');
%     particles_path = [char(particles_path) '.Boxes'];
%     %                             new_table(:,1) = 1:length(new_table);
%     %movefile(char([char("../../particles/particles_bin_" + binning) '.Boxes']), char("../../particles/particles_bin_" + binning));

end