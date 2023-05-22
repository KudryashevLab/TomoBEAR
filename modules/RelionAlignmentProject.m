%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


classdef RelionAlignmentProject < Module
    methods
        function obj = RelionAlignmentProject(configuration)
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

                if obj.configuration.binning > 0
                    %binning = obj.configuration.binning;
                    binning = 1;
                else
                    binning = 1;

                    paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "last");
                    alignment_folder = dir(paths{1} + filesep + "alignment_project*");
                    alignment_folder_splitted = strsplit(alignment_folder.name, "_");
                    previous_binning = str2double(alignment_folder_splitted{end});
                end

                if ~fileExists(obj.output_path + filesep + "ImportTomo/job001/RELION_JOB_EXIT_SUCCESS")
                    mkdir(obj.output_path + filesep + "tomograms");
                    %% preparin ptcls.star
                    new_table_1 = dread([tab_all_path(1).folder filesep tab_all_path(1).name]);
                    new_table_2 = dread([tab_all_path(2).folder filesep tab_all_path(2).name]);
                    %combined_table = [new_table_1; new_table_2];
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

                    tid = unique(combined_table(:,20));

                    %tomo_size = [4096,4096,1000];

                    %apix = getPixelsizeFromHeader1.894; % pixel size



                    TomoManifoldIndex = 1; % idk what's that, 1
                    fp_star = fopen(obj.output_path + filesep + "ptcls.star", "w+");
                    i = 1;
                    fprintf(fp_star, '\ndata_particles\n\nloop_\n');
                    fprintf(fp_star, '_rlnTomoName          #%d\n',i); i = i+1; % from tbl(,20)
                    fprintf(fp_star, '_rlnTomoParticleId    #%d\n',i); i = i+1; % from tbl(,1)
                    fprintf(fp_star, '_rlnTomoManifoldIndex #%d\n',i); i = i+1; % idk what's that, 1
                    fprintf(fp_star, '_rlnCoordinateX       #%d\n',i); i = i+1; % Position of particle in micrograph
                    fprintf(fp_star, '_rlnCoordinateY       #%d\n',i); i = i+1; % Position of particle in micrograph
                    fprintf(fp_star, '_rlnCoordinateZ       #%d\n',i); i = i+1; % Position (delta) of particle in micrograph
                    fprintf(fp_star, '_rlnOriginXAngst      #%d\n',i); i = i+1; % 0
                    fprintf(fp_star, '_rlnOriginYAngst      #%d\n',i); i = i+1; % 0
                    fprintf(fp_star, '_rlnOriginZAngst      #%d\n',i); i = i+1; % 0
                    fprintf(fp_star, '_rlnAngleRot          #%d\n',i); i = i+1; % First Euler Angle
                    fprintf(fp_star, '_rlnAngleTilt         #%d\n',i); i = i+1; % Second Euler Angle
                    fprintf(fp_star, '_rlnAnglePsi          #%d\n',i); i = i+1; % Third Euler Angle
                    fprintf(fp_star, '_rlnClassNumber       #%d\n',i); i = i+1; % Position of particle in micrograph
                    fprintf(fp_star, '_rlnRandomSubset      #%d\n',i); i = i+1; % Position of particle in micrograph
                    for j = 1:length(tid)
                        tbl_tomo = combined_table(combined_table(:,20)==tid(j),:);
                        for k = 1:size(tbl_tomo,1)
                            R = dynamo_euler2matrix(tbl_tomo(k,7:9));
                            euler = obj.rot_M2eZYZ(R); % here u need to convert euler angles from dynamo convention to relion (ZYZ)
                            pos = (previous_binning / binning) * (tbl_tomo(k,[24 25 26]) + tbl_tomo(k,[4 5 6])); % recenter
                            fprintf(fp_star, '%s\t%06d\t%d',sprintf('tomogram_%03d',tid(j)),tbl_tomo(k,1),TomoManifoldIndex);
                            fprintf(fp_star, '\t%.1f\t%.1f\t%.1f',round(pos(1)),round(pos(2)),round(pos(3)));
                            fprintf(fp_star, '\t%.4f\t%.4f\t%.4f',0,0,0); % shifts r 0 after recentering
                            fprintf(fp_star, '\t%12.6f\t%12.6f\t%12.6f',euler(1),euler(2),euler(3));
                            fprintf(fp_star, '\t%d\t%12d',1,mod(tbl_tomo(k,1),2)+1); % class = 1, even-odd
                            fprintf(fp_star, '\n');
                        end
                    end
                    fclose(fp_star);
                    %% preparin defocus.txt
                    % micrograph number, defocus u, defocus v, astigmatism angle, phase shift
                    % ( = 0), cc, maximum resolution
                    for i=1:length(tid)
                        obj.configuration.set_up.j = tid(i);
                        lst = getFilesFromLastModuleRun(obj.configuration, "GCTFCtfphaseflipCTFCorrection", "*/*_gctf.log", "last");
                        % system(['ls ' path sprintf('/9_GCTFCtfphaseflipCTFCorrection_1/tomogram_%03d/slices/*_gctf.log', tid(i))]);
                        lst_tmp = dir(lst{1});
                        def = fopen(sprintf(obj.output_path + filesep + "tomograms" + filesep + "tomogram_%03d_defocus.txt", tid(i)), "w+");
                        for j=1:length(lst_tmp)
                            fid = fopen(cell2mat("" + lst_tmp(j).folder + filesep + lst_tmp(j).name), 'r');
                            line_divided_text = textscan(fid, "%s", "delimiter", "\n");
                            final_values = line_divided_text{1}{contains(line_divided_text{1}, "Final Values")};
                            res_lim = line_divided_text{1}{contains(line_divided_text{1}, "Resolution limit")};
                            fin_val_splt = strsplit(final_values);res_lim_splt = strsplit(res_lim);
                            fclose(fid);
                            fprintf(def, '%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n',j,str2double(cell2mat(fin_val_splt(1))),str2double(cell2mat(fin_val_splt(2))), str2double(cell2mat(fin_val_splt(3))), 0, str2double(cell2mat(fin_val_splt(4))),str2double(cell2mat(res_lim_splt(7))));
                        end
                        fclose(def);
                    end
                    %% preparin tomos.star
                    dose_per_tilt = 4;
                    fp_star = fopen(obj.output_path + filesep + "tomos.star", "w+");
                    i = 1;
                    fprintf(fp_star, '\ndata_\n\nloop_\n');
                    fprintf(fp_star, '_rlnTomoName                  #%d\n',i); i = i+1;
                    fprintf(fp_star, '_rlnTomoTiltSeriesName        #%d\n',i); i = i+1;
                    fprintf(fp_star, '_rlnTomoImportCtfFindFile     #%d\n',i); i = i+1;
                    fprintf(fp_star, '_rlnTomoImportImodDir         #%d\n',i); i = i+1;
                    fprintf(fp_star, '_rlnTomoImportFractionalDose  #%d\n',i); i = i+1; % dose per tilt
                    fprintf(fp_star, '_rlnTomoImportOrderList       #%d\n',i); i = i+1; % order list is just a text file with 2 columns: acquisition order, tilt angle
                    for j = 1:length(tid)
                        fprintf(fp_star, '%s\t%s\t%s\t%s\t%.1f\t%s\n',sprintf('tomogram_%03d',tid(j)),sprintf(obj.output_path + filesep + "tomograms/tomogram_%03d/tomogram_%03d.st",tid(j),tid(j)),sprintf(obj.output_path + filesep + "tomograms/tomogram_%03d_defocus.txt",tid(j)),sprintf(obj.output_path + filesep + "tomograms/tomogram_%03d",tid(j)),dose_per_tilt, obj.output_path + filesep + "order_list.csv");
                    end
                    fclose(fp_star);

                    % example of order_list.csv:
                    min_angle = 100;
                    max_angle = -100;
                    fid = fopen(obj.output_path + filesep + "order_list.csv", "w+");
                    for i = 1:length(tid)
                        obj.configuration.set_up.j = tid(i);
                        tilt_angles = getTiltAngles(obj.configuration, true);
                        min_angle = min([tilt_angles min_angle]);
                        max_angle = max([tilt_angles max_angle]);
                        step = tilt_angles(2) - tilt_angles(1);
                    end

                    counter = 1;
                    for i = min_angle:step:max_angle
                        fprintf(fid, "%s,%s\n", num2str(counter), num2str(i));
                        counter = counter + 1;
                    end
                    fclose(fid);
                    % example of order_list.csv:
                    % 1,0
                    % 2,3
                    % 3,-3
                    % 4,-6
                    % 5,6
                    % 6,9
                    % 7,-9
                    % 8,-12
                    % 9,12
                    % 10,15
                    % 11,-15
                    % 12,-18
                    % 13,18
                    % 14,21
                    % 15,-21
                    % 16,-24
                    % 17,24
                    % 18,27
                    % 19,-27
                    % 20,-30
                    % 21,30
                    % 22,33
                    % 23,-33
                    % 24,-36
                    % 25,36
                    % 26,39
                    % 27,-39
                    % 28,-42
                    % 29,42
                    % 30,45
                    % 31,-45
                    % 32,-48
                    % 33,48

                    %%
                    % then u need to create a relion project directory, cd there
                    % inside create a tomograms directory where u can place soft links to ur
                    % IMOD folders. Inside each imod folder u should have unbinned
                    % raw stack, newst.com and tilt.com, check that everything is these com
                    % scripts is valid
                    fid = fopen(obj.output_path + filesep + ".gui_projectdir", "w+");
                    fclose(fid);

                    % generating project directory
                    %system("relion --do_projdir --tomo")

                    fid = fopen(obj.output_path + filesep + "default_pipeline.star", "w+");
                    fprintf(fid, "\n");
                    fprintf(fid, "# version 30001\n");
                    fprintf(fid, "\n");
                    fprintf(fid, "data_pipeline_general\n");
                    fprintf(fid, "\n");
                    fprintf(fid, "_rlnPipeLineJobCounter                       1");
                    fprintf(fid, "\n");
                    fclose(fid);

                    for i = 1:length(tid)
                        obj.configuration.set_up.j = tid(i);
                        files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "ali");
                        [folder, name, extension] = fileparts(files{1});
                        createSymbolicLink(folder, obj.output_path + filesep + "tomograms" + filesep, obj.log_file_id);
                    end

                    apix = getApix(obj.configuration);
                    mkdir(obj.output_path + filesep + "ImportTomo/job001/");
                    executeCommand("LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY relion_tomo_import_tomograms  --i " + obj.output_path + filesep + "tomos.star --o "...
                        + obj.output_path + filesep + "ImportTomo/job001/tomograms.star --angpix " + (apix * obj.configuration.ft_bin)...
                        + " --voltage " + obj.configuration.keV + " --Cs " + obj.configuration.spherical_aberation...
                        + " --Q0 0.07 --ol " + obj.output_path + filesep + "order_list.csv --flipYZ  --flipZ --hand -1 --pipeline_control "...
                        + obj.output_path + filesep + "ImportTomo/job001/", false, obj.log_file_id);
                end
                if ~fileExists(obj.output_path + filesep + "ImportTomo/job002/RELION_JOB_EXIT_SUCCESS")
                    mkdir(obj.output_path + filesep + "ImportTomo/job002/");
                    executeCommand("LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY relion_tomo_import_particles  --i " + obj.output_path + filesep + "ptcls.star --o "...
                        + obj.output_path + filesep + "ImportTomo/job002/ --t "...
                        + obj.output_path + filesep + "ImportTomo/job001/tomograms.star --pipeline_control "...
                        + obj.output_path + filesep + "ImportTomo/job002/", false, obj.log_file_id);
                end
                if ~fileExists(obj.output_path + filesep + "PseudoSubtomo/job003/RELION_JOB_EXIT_SUCCESS")
                    mkdir(obj.output_path + filesep + "PseudoSubtomo/job003/");
                    executeCommand("LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY relion_tomo_subtomo --i " + obj.output_path + filesep + "ImportTomo/job002/optimisation_set.star --o "...
                        + obj.output_path + filesep + "PseudoSubtomo/job003/ --b " + ceil(length(mask) * 2) + " --crop " + ceil(length(mask) * 0.7) ...
                        + " --bin " + (previous_binning / binning) + " --j " + obj.configuration.environment_properties.cpu_count_logical...
                        + " --pipeline_control " + obj.output_path + filesep + "PseudoSubtomo/job003/", false, obj.log_file_id);
                end
                if ~fileExists(obj.output_path + filesep + "test_rec.mrc")
                    executeCommand("LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY mpirun -np " + obj.configuration.environment_properties.cpu_count_physical...
                        + " relion_reconstruct_mpi --i " + obj.output_path + filesep + "PseudoSubtomo/job003/particles.star --ctf --sym "...
                        + lower(obj.configuration.expected_symmetrie) + " --o " + obj.output_path + filesep + "test_rec.mrc", false, obj.log_file_id);
                end
                if ~fileExists(obj.output_path + filesep + "ReconstructParticleTomo/job004/RELION_JOB_EXIT_SUCCESS")
                    mkdir(obj.output_path + filesep + "ReconstructParticleTomo/job004/");
                    executeCommand("LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY mpirun -np " + obj.configuration.environment_properties.cpu_count_physical...
                        + " relion_tomo_reconstruct_particle_mpi --i " + obj.output_path + filesep + "PseudoSubtomo/job003/optimisation_set.star --o "...
                        + obj.output_path + filesep + "ReconstructParticleTomo/job004/ --b " + ceil(length(mask) * 2)...
                        + " --crop " + ceil(length(mask) * 0.7) + " --bin " + (previous_binning / binning) + " --j "...
                        + obj.configuration.environment_properties.cpu_count_physical + " --j_out "...
                        + (obj.configuration.environment_properties.cpu_count_logical / obj.configuration.environment_properties.cpu_count_physical)...
                        + " --j_in " + (obj.configuration.environment_properties.cpu_count_logical / obj.configuration.environment_properties.cpu_count_physical) + " --sym "...
                        + lower(obj.configuration.expected_symmetrie) + " --pipeline_control "...
                        + obj.output_path + filesep + "ReconstructParticleTomo/job004/", false, obj.log_file_id);
                end
                if ~fileExists(obj.output_path + filesep + "Refine3D/job005/RELION_JOB_EXIT_SUCCESS")
                    mkdir(obj.output_path + filesep + "Refine3D/job005/scratch");
                    if obj.configuration.gpu == -1
                        gpu_list = 0:gpuDeviceCount - 1;
                        jobs = gpuDeviceCount + 1;
                        threads = 1;
                    elseif obj.configuration.gpu == 0
                        gpu_list = [];
                        jobs = 3;
                        threads = 20;%(obj.configuration.environment_properties.cpu_count_logical / obj.configuration.environment_properties.cpu_count_physical);
                    else
                        gpu_list = obj.configuration.gpu - 1;
                        jobs = 3;
                        threads = 1;
                    end
                    dwrite(dread(string(mask_path.folder) + filesep + mask_path.name), char(obj.output_path + filesep + "mask.mrc"));
                    apix = getApix(obj.configuration);
                    executeCommand("alterheader -del " + apix + "," + apix + "," + apix + "," + " " + obj.output_path + filesep + "mask.mrc", false, obj.log_file_id);
                    command = "LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY mpirun --mca orte_base_help_aggregate 0 -np " + jobs + " relion_refine_mpi --o " + obj.output_path + filesep... %obj.configuration.environment_properties.cpu_count_physical
                        + "Refine3D/job005/run --auto_refine --split_random_halves --ios " + obj.output_path + filesep + "PseudoSubtomo/job003/optimisation_set.star"...
                        + " --ref " + obj.output_path + filesep + "ReconstructParticleTomo/job004/merged.mrc --ini_high 15"... % --dont_combine_weights_via_disc
                        + " --preread_images --pool 1 --pad 1 --skip_gridding --ctf --particle_diameter " + floor((length(mask)*0.75)*apix)...
                        + " --flatten_solvent --zero_mask --solvent_mask " + obj.output_path + filesep + "mask.mrc" + " --solvent_correct_fsc "...
                        + "--oversampling 1 --healpix_order 3 --auto_local_healpix_order 4 --offset_range 6 --offset_step 2 --sym "...
                        + lower(obj.configuration.expected_symmetrie) + " --low_resol_join_halves 40 --norm --scale  --j "...
                        + threads + " --free_gpu_memory 1024"...%((obj.configuration.environment_properties.cpu_count_logical / obj.configuration.environment_properties.cpu_count_physical) / 2)...
                        + " --gpu --pipeline_control " + obj.output_path + filesep + "Refine3D/job005/ --scratch_dir " + obj.output_path + filesep + "Refine3D/job005/scratch --maxsig 10000"; %
                    %                     optimiser_star_files = dir()
                    %                     if ~isempty
                    executeCommand(command, false, obj.log_file_id); %  --onthefly_shifts

                    % relion_refine_mpi --o Refine3D/job013/run --auto_refine --split_random_halves --ios PseudoSubtomo/job003/optimisation_set.star --solvent_correct_fsc
                    % --ref ReconstructParticleTomo/job006/merged.mrc --ini_high 30 --dont_combine_weights_via_disc --pool 8 --pad 2 --skip_gridding --auto_ignore_angles
                    % --auto_resol_angles --ctf --particle_diameter 200 --flatten_solvent --zero_mask --oversampling 1 --healpix_order 2 --auto_local_healpix_order 3
                    % --offset_range 6 --offset_step 4 --sym C4 --low_resol_join_halves 40 --norm --scale --j 8 --gpu "" --pipeline_control Refine3D/job013/
                end
                if ~fileExists(obj.output_path + filesep + "PostProcess/job006/RELION_JOB_EXIT_SUCCESS")
                    mkdir(obj.output_path + filesep + "PostProcess/job006/");
                    executeCommand("LD_LIBRARY_PATH=$LD_LIBRARY_PATH_COPY relion_postprocess --mask " + string(mask_path.folder) + filesep + mask_path.name + " --ios "...
                        + obj.output_path + filesep + "Refine3D/job005/run_optimisation_set.star --i "...
                        + obj.output_path + filesep + "Refine3D/job005/run_half1_class001_unfil.mrc --o "...
                        + obj.output_path + filesep + "PostProcess/job006/postprocess --angpix -1 --auto_bfac --autob_lowres 10 --pipeline_control "...
                        + obj.output_path + filesep + "PostProcess/job006/");
                end
            else
                error("ERROR: no alignment projects were executed up to now!")
            end
        end

        function eu = rot_M2eZYZ(obj, R)

            eu = zeros(1,3);
            tol = 5e-5;

            if( R(3,3) < (1-tol))

                if( R(3,3) > (tol-1) )

                    % GENERAL CASE
                    eu(2) = acos ( R(3,3) )*180/pi;
                    eu(1) = atan2( R(2,3), R(1,3) )*180/pi;
                    eu(3) = atan2( R(3,2),-R(3,1) )*180/pi;

                else

                    % r22 <= -1
                    eu(2) = 180;
                    eu(1) = -atan2( R(2,1), R(2,2) )*180/pi;
                    eu(3) = 0;

                end
            else

                % r22 <= -1
                eu(2) = 0;
                eu(1) = atan2( R(2,1), R(2,2) )*180/pi;
                eu(3) = 0;

            end
        end
    end
end
