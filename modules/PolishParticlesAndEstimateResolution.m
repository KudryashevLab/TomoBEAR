%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021,2022,2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published
% by the Free Software Foundation, either version 3 of the License,
% or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
            
            if obj.configuration.tilt_scheme == "dose_symmetric"
                indices = floor(P/2);
            elseif obj.configuration.tilt_scheme == "bi_directional"
                indices = P - 1;
            else
                errror("ERROR: unknown tilt scheme");
            end
            for k = 1:indices
                box_size = obj.configuration.box_size;
                
                tomos = SUSAN.Data.TomosInfo(N,P);
                dose_per_projection = dose / P;
                
                for i = 1:N
                    tomos.tomo_id(i) = tomos_id(i);
                    stack_path = string(aligned_tilt_stacks(i).folder) + filesep + string(aligned_tilt_stacks(i).name);
                    tomos.set_stack(i, stack_path);
                    tomos.set_angles(i, char(string(tlt_files{tomos_id(i)}.folder) + filesep + tlt_files{tomos_id(i)}.name));
                    tomos.set_defocus(i, char(string(defocus_files{tomos_id(i)}.folder) + filesep + string(defocus_files{tomos_id(i)}.name)));
                    if dose > 0
                        if obj.configuration.tilt_scheme == "dose_symmetric_parallel"
                            for j = 1:size(tomos.defocus, 1)
                                if tilt_angles(dose_order == j) >= -((floor(P/2) - k + 1) * tilt_angle_step)  && tilt_angles(dose_order == j) <= ((floor(P/2) - k + 1) * tilt_angle_step)
                                    if dose > 0
                                        tomos.defocus(dose_order == j,6,i) = b_factor_per_projection * (j - 1) * dose_per_projection;
                                    end
                                    tomos.proj_weight(dose_order == j,1,i) = 1;
                                else
                                    tomos.proj_weight(dose_order == j,1,i) = 0;
                                end
                            end
                        elseif obj.configuration.tilt_scheme == "bi_directional" || obj.configuration.tilt_scheme == "dose_symmetric_sequential" || obj.configuration.tilt_scheme == "dose_symmetric"
                            for j = 1:size(tomos.defocus, 1)
                                if  j < max(dose_order) - k + 1 
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
                    
                    tomos.pix_size(i) = scaled_apix;
                    
                    tomos.tomo_size(i,:) = [width, height, reconstruction_thickness / binning];
                    
                end
                tomos_name = char(particles_path + filesep + "tomos_bin_" + binning + ".tomostxt");
                tomos.save(tomos_name);
                %Hey, wer kommt aus der nähe von Frankfurt?
                %%
                %                         new_table(:,[24 25 26]) = new_table(:,[24 25 26]) + new_table(:,[4 5 6]);
                %                         new_table(:,[4 5 6]) = 0;
                %                         new_table(:,[24 25 26]) = previous_binning/binning*new_table(:,[24 25 26])+1;
                %                         table_name = char("table_bin_" + binning + ".tbl");
                %                         dwrite(new_table,table_name);
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
                    if obj.configuration.particle_count > size(new_table_1 ,1) || obj.configuration.particle_count > size(new_table_2 ,1)
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
                particles_raw = char(particles_path + filesep + "particles_bin_" + binning + ".ptclsraw");
                ptcls = SUSAN.Data.ParticlesInfo(combined_table, tomos);
                ptcls.half_id(1:particle_count) = 1;
                ptcls.half_id(particle_count+1:end) = 2;
                ptcls.save(particles_raw);
                box_size = round((length(mask) * box_size));
                
                if mod(box_size, 2) == 1
                    box_size = box_size + 1;
                end
                
                if obj.configuration.use_SUSAN_averager == false
                    if dose > 0
                        real_particles_path = char(particles_path + filesep + "particles_bin_" + binning + "_bs_" + box_size + "_dw");
                    else
                        real_particles_path = char(particles_path + filesep  + "particles_bin_" + binning + "_bs_" + box_size);
                    end
                    
                    if exist(real_particles_path, "dir")
                        rmdir(real_particles_path, "s");
                    end
                    
                    mkdir(real_particles_path);
                    if obj.configuration.use_SUSAN_particle_generator == true
                        subtomos = SUSAN.Modules.SubtomoRec;
                        subtomos.gpu_list = 0:gpuDeviceCount - 1;
                        %subtomos.padding = round(box_size / binning);
                        subtomos.set_ctf_correction(char(per_particle_ctf_correction)); % try also wiener if you like
                        %subtomos.set_padding_policy(char(padding_policy));
                        subtomos.set_normalization(char(normalization));
                        subtomos.reconstruct(char(real_particles_path), tomos_name, particles_raw, box_size);
                    else
                        % TODO: dtcrop
                    end
                    
                    vol1 = daverage(char(real_particles_path),'-t', new_table_1, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                    vol2 = daverage(char(real_particles_path),'-t', new_table_2, 'mw', round(obj.configuration.cpu_fraction * obj.configuration.environment_properties.cpu_count_physical));
                    
                    vol1 = vol1.average;
                    vol2 = vol2.average;
                else
                    avg = SUSAN.Modules.Averager;
                    avg.gpu_list = 0:gpuDeviceCount - 1;
                    
                    
                    
                    avg.bandpass.highpass = 0;
                    avg.bandpass.lowpass = (box_size / 2) - 1;
                    if binning > 1
                        avg.padding = round(box_size / binning);
                    else
                        avg.padding = 0;
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
                    %                         if obj.configuration.susan_box_size > 0
                    %                             box_size = round((size(template,1) * obj.configuration.susan_box_size) * (previous_binning / binning)); %obj.configuration.susan_box_size;
                    %                             obj.dynamic_configuration.susan_box_size = 1;
                    %                         else
                    
                    %                         end
                    avg.reconstruct(char(string(particles_path) + filesep + "map_bin_" + binning + "_" + k), tomos_name, particles_raw, box_size);
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
                    vol1 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half1.mrc")));
                    vol2 = dnan(dread(char(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half2.mrc")));
                end
                
                %                 particles_raw_1 = char(particles_path + filesep + "particles_bin_" + binning + "_1.ptclsraw");
                %                 ptcls = SUSAN.Data.ParticlesInfo(new_table_1, tomos);
                %                 ptcls.save(particles_raw_1);
                %
                %                 particles_raw_2 = char(particles_path + filesep + "particles_bin_" + binning + "_2.ptclsraw");
                %                 ptcls = SUSAN.Data.ParticlesInfo(new_table_2, tomos);
                %                 ptcls.save(particles_raw_2);
                
                
                if obj.configuration.show_figures == true || obj.configuration.save_figures == true
                    show ='on';
                else
                    show ='off';
                end
                
                if obj.configuration.use_symmetry == true && obj.configuration.use_SUSAN_symmetry == false
                    sym = char(obj.configuration.expected_symmetrie);
                else
                    sym = 'c1';
                end
                fsc = dfsc(vol1, vol2, 'apix', scaled_apix, 'show', show, 'mask', mask, 'sym', sym);
                if obj.configuration.save_figures == true
                    f = figure(1);
                    if obj.configuration.show_figures == false
                        f.Visible = 'off';
                    end
                    saveas(f,particles_path + filesep + "map_bin_" + binning + "_" + k + "_resolution", "fig");
                    saveas(f,particles_path + filesep + "map_bin_" + binning + "_" + k + "_resolution", "png");
                    
                end
                close(f);
                movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_previous.mrc");
                movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half1.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_1_previous.mrc");
                movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_class001_half2.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_2_previous.mrc");
                
                if isfield(fsc, "res_0143")
                    fsc = fsc.res_0143;
                else
                    fsc = fsc.res_013;
                end
                
                fid = fopen(particles_path + filesep + "ds_ini_bin_" + binning + "_" + k + "_resolution_" + fsc + ".txt", "w+");
                % TODO: write fsc into file
                fprintf(fid, "%s\n", fsc);
                fclose(fid);
                disp("INFO:CURRENT_FSC: " + fsc + " Angstrom");
                if k == 1
                    movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_previous.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_best.mrc");
                    movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_1_previous.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half1_best.mrc");
                    movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_2_previous.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half2_best.mrc");
                    fsc_best = fsc;
                    disp("INFO:BEST_FSC: " + fsc + " Angstrom");
                elseif fsc < fsc_best
                    movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_previous.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_best.mrc");
                    movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_1_previous.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half1_best.mrc");
                    movefile(particles_path + filesep + "map_bin_" + binning + "_" + k + "_half_2_previous.mrc", particles_path + filesep + "map_bin_" + binning + "_" + k + "_half2_best.mrc");
                    fsc_best = fsc;
                    disp("INFO:BEST_FSC: " + fsc + " Angstrom");
                end
                

                %                 fsc_previous = fsc
            end
            
        end
    end
end

