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


% NOTE: https://cryolo.readthedocs.io/en/stable/index.html

classdef crYOLO < Module
    methods
        function obj = crYOLO(configuration)
            obj@Module(configuration);
            createStandardFolder(obj.configuration, "particles_table_folder");
        end
        
        function obj = process(obj)
            
            return_path = cd(obj.output_path);
            
            steps_to_execute_fields = fieldnames(obj.configuration.steps_to_execute);
            
            if isempty(steps_to_execute_fields)
                error("ERROR: No IsoNet steps_to_execute were found in the JSON file!");
            end
            
            % NOTE: add 'success' files to be able to re-run substeps
            % NOTE: add 'stop' execution control step
            for subjob_idx=1:length(steps_to_execute_fields)
                disp("INFO: crYOLO substep " + string(subjob_idx) + ":" + string(steps_to_execute_fields{subjob_idx}));
                step_params = mergeConfigurations(obj.configuration.steps_to_execute_defaults.(steps_to_execute_fields{subjob_idx}), obj.configuration.steps_to_execute.(steps_to_execute_fields{subjob_idx}), "crYOLO", "dynamic");
                obj.(steps_to_execute_fields{subjob_idx})(step_params);
                disp("INFO: Execution for crYOLO substep " + string(subjob_idx) +" (" + string(steps_to_execute_fields{subjob_idx}) + ") has finished!");
            end
            
            cd(return_path);
        end
        
        function obj = config(obj, step_params)
                        
            use_params_cell = {'filter'}; 
            if step_params.filter == "LOWPASS"
                use_params_cell{length(use_params_cell)+1} = 'low_pass_cutoff';
            elseif step_params.filter == "JANNI"
                use_params_cell{length(use_params_cell)+1} = 'janni_model_path';
            end
            
            if step_params.train_mode == true
                use_params_cell{length(use_params_cell)+1} = 'train_image_folder';
                use_params_cell{length(use_params_cell)+1} = 'train_annot_folder';
                
                if ~isfolder(step_params.train_tomograms_folder) || isempty(step_params.train_tomograms_folder)
                    obj.LinkTomogramsToRequestedDirectory(step_params.tomograms_binning, step_params.train_tomograms_folder);
                    step_params.train_tomograms_folder = obj.output_path + string(filesep) + step_params.train_tomograms_folder;
                    step_params.train_image_folder = step_params.train_tomograms_folder;
                end
                
                if ~isfolder(step_params.train_annot_folder)
                    mkdir(step_params.train_annot_folder);
                    disp("WARNING: Has not found any annotation files! Be sure to prepare them before the training!");
                    step_params.train_annot_folder = obj.output_path + string(filesep) + step_params.train_annot_folder;                    
                end
            end
            
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            
            step_params.config_json_filepath = obj.output_path + string(filesep) + step_params.config_json_filepath;
            params_string = obj.getParamsString(use_params);
            params_string = step_params.config_json_filepath...
                + " " + step_params.target_boxsize...
                + " " + params_string;
            command_output = obj.executeCrYOLOCommand(params_string, step_params.cryolo_command);
        end

        function obj = train(obj, step_params)

            if ~isfile(step_params.config_json_filepath)
                error('ERROR: the requested config_json_filepath was not found!');
            elseif isfile(obj.output_path + string(filesep) + step_params.config_json_filepath)
                step_params.config_json_filepath = obj.output_path + string(filesep) + step_params.config_json_filepath;
            end

            if obj.configuration.gpu > 0
                step_params.gpu = obj.configuration.gpu - 1;
            else
                error("ERROR: Gpus are needed to train crYOLO!");
            end

            use_params_cell = {'early','warmup','gpu'};
            
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell, " ");

            if step_params.num_cpu == -1
                use_params.num_cpu = getCpuPoolSize(1);
            else
                use_params.num_cpu = getCpuPoolSize(1, step_params.num_cpu);
            end
            
            params_string = "-c " + step_params.config_json_filepath + " " + obj.getParamsString(use_params);
            command_output = obj.executeCrYOLOCommand(params_string, step_params.cryolo_command);
        end
        
        function obj = predict(obj, step_params)
             
            if ~isfile(step_params.config_json_filepath)
                error('ERROR: the requested config_json_filepath was not found!');
            elseif isfile(obj.output_path + string(filesep) + step_params.config_json_filepath)
                step_params.config_json_filepath = obj.output_path + string(filesep) + step_params.config_json_filepath;
            end

            if obj.configuration.gpu > 0
                step_params.gpu = obj.configuration.gpu - 1;
            else
                error("ERROR: Gpus are needed to predict using crYOLO!");
            end
            
            if ~isfile(step_params.trained_model_filepath)
                error('ERROR: the requested trained_model_filepath was not found!');
            elseif isfile(obj.output_path + string(filesep) + step_params.trained_model_filepath)
                 step_params.weights = obj.output_path + string(filesep) + step_params.trained_model_filepath;
            else
                 step_params.weights = step_params.trained_model_filepath;
            end
            
            if ~isfolder(step_params.test_tomograms_folder) || isempty(step_params.test_tomograms_folder)
                obj.LinkTomogramsToRequestedDirectory(step_params.tomograms_binning, step_params.test_tomograms_folder);
                step_params.input = obj.output_path + string(filesep) + step_params.test_tomograms_folder;
            elseif isfolder(obj.output_path + string(filesep) + step_params.test_tomograms_folder)
                step_params.input = obj.output_path + string(filesep) + step_params.test_tomograms_folder;
            else
                step_params.input = step_params.test_tomograms_folder;
            end
            
            if isfolder(obj.output_path + string(filesep) + step_params.predict_annot_folder)
                step_params.output = obj.output_path + string(filesep) + step_params.predict_annot_folder;
            else
                step_params.output = step_params.predict_annot_folder;
            end
            
            use_params_cell = {'weights', 'input', 'output', 'threshold',...
                'tracing_search_range','tracing_memory','tracing_min_length',...
                'gpu'};
            
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell, " ");

            if step_params.num_cpu == -1
                use_params.num_cpu = getCpuPoolSize(1);
            else
                use_params.num_cpu = getCpuPoolSize(1, step_params.num_cpu);
            end

            params_string = "-c " + step_params.config_json_filepath + " " + obj.getParamsString(use_params) + " --tomogram";
            command_output = obj.executeCrYOLOCommand(params_string, step_params.cryolo_command);
        end
        
        function obj = export_annotations(obj, step_params)

            cbox_paths = step_params.predict_annot_folder + string(filesep) + "CBOX_3D" + string(filesep) + "*.cbox";
            cbox_files = dir(cbox_paths);

            if isempty(cbox_files)
               error("ERROR: particles table was requested, but CBOX_3D annotated particles were not found!");
            end
            
            cbox_filt_dirpath = obj.output_path + string(filesep) + step_params.filtered_CBOX_3D_folder;
            if ~isfolder(cbox_filt_dirpath)
                mkdir(cbox_filt_dirpath)
            end
            
            dtbl_filt_dirpath = obj.output_path + string(filesep) + step_params.filtered_Dynamo_tbl_folder;
            if ~isfolder(dtbl_filt_dirpath)
                mkdir(dtbl_filt_dirpath)
            end
            
            % NOTE: get per each tomo separate particles table
            tab_tomo = {};
            disp("INFO: extracting particles with confidence threshold >= " + num2str(step_params.threshold));
            for i = 1:length(cbox_files)
                cbox_filepath= cbox_files(i).folder + string(filesep) + cbox_files(i).name;
                tab_tomo{i} = obj.getFilteredCBOX(cbox_filepath, cbox_filt_dirpath, step_params);
                obj.writeDynamoTable(cbox_filepath, dtbl_filt_dirpath, tab_tomo{i}, step_params);
            end
            
            % merge all tables and write in a single Dynamo table
            [~, name, ~] = fileparts(cbox_filepath);
            name_splitted = strsplit(name, "_");
            tomogram_binning = str2num(name_splitted{4});  
            obj.mergeDynamoTables(dtbl_filt_dirpath, tomogram_binning, step_params);
        end
        
        function obj = mergeDynamoTables(obj, dtbl_filt_dirpath, tomogram_binning, step_params)
            
            tab_tomo_path = dtbl_filt_dirpath + string(filesep) + "*.tbl";
            tab_tomo_files = dir(tab_tomo_path);   

            tab_tomo = {};
            for i = 1:length(tab_tomo_files)
                tab_tomo_filepath = tab_tomo_files(i).folder + string(filesep) + tab_tomo_files(i).name;
                tab_tomo{i} = dread(char(tab_tomo_filepath));
            end            
            
            tab_all = dynamo_table_blank(size(tab_tomo{1}, 1));
            sum_particles_previous_table = 0;
            particle_count = step_params.particle_count_in_total;

            for i = 1:length(tab_tomo)
                if isempty(tab_tomo{i}) || tab_tomo{i}(1,20) == 0
                    continue;
                end
                if i == 1
                    tab_all(1:end, :) = tab_tomo{i};
                else
                    tab_tomo_tmp = tab_tomo{i};
                    tab_tomo_tmp(:,1) = tab_tomo{i}(:,1) + sum_particles_previous_table;
                    tab_all(end + 1:end + size(tab_tomo{i}, 1), :) = tab_tomo_tmp;
                end

                sum_particles_previous_table = sum_particles_previous_table + size(tab_tomo{i}, 1);
                if particle_count > 0
                    if sum_particles_previous_table > particle_count
                        tab_all(particle_count + 1:end, :) = [];
                        break;
                    else
                        particle_count = particle_count - sum_particles_previous_table;
                    end
                end
            end
            disp("INFO: in total: " + num2str(sum_particles_previous_table) + " particles extracted");
            tab_all_file_path = char(obj.output_path + string(filesep) + "tab_ini_all_bin_" + tomogram_binning + "_" + num2str(size(tab_all,1)) + ".tbl");
            dwrite(tab_all, tab_all_file_path);

            link_destination = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder;
            createSymbolicLink(tab_all_file_path, link_destination, obj.log_file_id);
        end
%         
        function tab_tomo = writeDynamoTable(obj, cbox_filepath, dtbl_filt_dirpath, table, step_params)
            
            [~, name, ~] = fileparts(cbox_filepath);
            name_splitted = strsplit(name, "_");
            tomogram_number = str2num(name_splitted{2});
            tomogram_binning = str2num(name_splitted{4});
            
            success_filepath = dtbl_filt_dirpath + string(filesep) + "SUCCESS_" + tomogram_number;
            failure_filepath = dtbl_filt_dirpath + string(filesep) + "FAILURE_" + tomogram_number;
            if ~fileExists(success_filepath) && ~fileExists(failure_filepath)
                
                if step_params.particle_count_per_tomo > 0
                    particle_count = min(size(table,1), step_params.particle_count_per_tomo);
                    table = table(1:step_params.particle_count_per_tomo,:);
                else
                    particle_count = size(table,1);
                end
                disp("INFO: tomogram_" + num2str(tomogram_number) + ": " + num2str(particle_count) + " particles extracted");
                
                if particle_count > 0
                    tab_tomo = dynamo_table_blank(particle_count);

                    tab_tomo(1:particle_count,1) = 1:particle_count;
                    tab_tomo(1:particle_count,2:3) = ones(particle_count,2);

                    % NOTE: box left down corner > box center
                    tab_tomo(1:particle_count,24:25) = table(:,1:2) + table(:,4:5)/2;
                    tab_tomo(1:particle_count,26) = table(:,3);
                    
                    % NOTE: prediction confidence level
                    tab_tomo(1:particle_count,10) = table(:,9);
                    
                    tab_tomo(1:particle_count,20) = tomogram_number * ones(particle_count,1);
                    tab_tomo(1:particle_count,32) = ones(particle_count,1);

                    if tab_tomo(1,20) ~= 0
                        table_file_path = dtbl_filt_dirpath + string(filesep)...
                            + "tab_" + num2str(tomogram_number) + "_ini_bin_"...
                            + num2str(tomogram_binning) + "_"...
                            + num2str(particle_count) + ".tbl";

                        dwrite(tab_tomo, table_file_path);
                        fid = fopen(success_filepath, "w");
                        fclose(fid);
                    else
                        fid = fopen(failure_filepath, "w");
                        fclose(fid);
                    end
                else
                    fid = fopen(failure_filepath, "w");
                    fclose(fid);
                end
            end
        end
        
        function cbox_data_filt = getFilteredCBOX(obj, cbox_filepath, cbox_filt_dirpath, step_params)
            
            % read original CBOX and write confidence level-filtered CBOX
            cbox_fid = fopen(cbox_filepath, 'r');

            [~, cbox_name, cbox_ext] = fileparts(cbox_filepath);
            cbox_filt_filepath = cbox_filt_dirpath + string(filesep) + cbox_name + cbox_ext;            
            cbox_filt_fid = fopen(cbox_filt_filepath, 'w');
            
            % NOTE: loop over and rewrite lines before data_cryolo
            fl = rewriteLinesBeforePattern(cbox_fid, cbox_filt_fid, 'data_cryolo');
            fprintf(cbox_filt_fid, '%s\n', fl);
            
            % NOTE: loop over and rewrite lines before loop_
            fl = rewriteLinesBeforePattern(cbox_fid, cbox_filt_fid, 'loop_');
            fprintf(cbox_filt_fid, '%s\n', fl);
            
            % NOTE: loop over and rewrite _Property lines
            fl = rewriteLinesMatchingPattern(cbox_fid, cbox_filt_fid, '(_[a-zA-Z]+) (#[\d]+)');
            
            % NOTE: read particles coordinates and confidence level
            cbox_data = [];
            while ~feof(cbox_fid) && length(fl)>0
                cbox_extracted_data = textscan(fl,'%f','TreatAsEmpty','<NA>');
                cbox_data = [cbox_data; cbox_extracted_data{1}'];
                fl = fgetl(cbox_fid);
            end
            
            % NOTE: filter particles by confidence level threshold
            cbox_data_filt = cbox_data(cbox_data(:,9) >= step_params.threshold,:);
            if size(cbox_data_filt,1) > 0
                cbox_z_data_filt = sort(cbox_data_filt(:,3));

                % NOTE: write filtered particles
                cbox_data_cell = cellstr(string(cbox_data_filt));
                cbox_data_cell(cellfun(@isempty,cbox_data_cell)) = {'<NA>'};
                cbox_data_strarr = join(string(cbox_data_cell), " ");
                fprintf(cbox_filt_fid, '%s\n', cbox_data_strarr);

                % NOTE: loop over and rewrite lines before _slice_index
                fl = rewriteLinesBeforePattern(cbox_fid, cbox_filt_fid, '_slice_index #1');
                fprintf(cbox_filt_fid, '%s\n', fl);

                % NOTE: write filtered slice indexes
                fprintf(cbox_filt_fid, '%s\n', string(cbox_z_data_filt));
                fclose(cbox_filt_fid);
            else
                fclose(cbox_filt_fid);
                delete(cbox_filt_filepath);
            end
            fclose(cbox_fid);
            
            function last_line = rewriteLinesBeforePattern(fid_input, fid_output, pattern)
                while ~feof(fid_input)
                    fl = fgetl(fid_input);
                    if isempty(regexp(fl,pattern, 'once'))
                        nl = fl; fprintf(fid_output, '%s\n', nl);
                    else
                        break
                    end
                end
                last_line = fl;
            end
            
            function last_line = rewriteLinesMatchingPattern(fid_input, fid_output, pattern)
                while ~feof(fid_input)
                    fl = fgetl(fid_input);
                    if ~isempty(regexp(fl,pattern, 'once'))
                        nl = fl; fprintf(fid_output, '%s\n', nl);
                    else
                        break
                    end
                end
                last_line = fl;
            end
        end
        
%         function obj = export_annotations(obj, step_params)
%             
%             prtcl_coord_path = step_params.raw_prtcl_coords_dir + string(filesep) + "*.coords";
%             prtcl_coord_files = dir(prtcl_coord_path);
%             
%             if isempty(prtcl_coord_files)
%                error("ERROR: particles table was requested, but annotated raw particles coordinates were not found!");
%             end
%             
%             [~, name, ~] = fileparts(prtcl_coord_files(1).name);
%             name_splitted = strsplit(name, "_");
%             tomogram_binning = str2num(name_splitted{4});            
%             % NOTE: get per each tomo separate particles table
%             output_path = obj.output_path;
%             per_table_particle_count = step_params.per_table_particle_count;
%             tab_tomo = {};
%             for i = 1:length(prtcl_coord_files)
%                 prtcl_coord_filepath = prtcl_coord_files(i).folder + string(filesep) + prtcl_coord_files(i).name;
%                 tab_tomo{i} = produceParticlesTableForTomogram(prtcl_coord_filepath, per_table_particle_count, output_path);
%             end
%             
%             % NOTE: merge individual particles tables
%             tab_all = dynamo_table_blank(size(tab_tomo{1}, 1));
%             sum_particles_previous_table = 0;
%             particle_count = step_params.total_particle_count;
%             
%             break_flag = false;
%             for i = 1:length(tab_tomo)
%                 if isempty(tab_tomo{i}) || tab_tomo{i}(1,20) == 0
%                     continue;
%                 end
%                 if i == 1
%                     tab_all(1:end, :) = tab_tomo{i};
%                 else
%                     tab_tomo_tmp = tab_tomo{i};
%                     tab_tomo_tmp(:,1) = tab_tomo{i}(:,1) + sum_particles_previous_table;
%                     tab_all(end + 1:end + size(tab_tomo{i}, 1), :) = tab_tomo_tmp;
%                 end
%                 
%                 sum_particles_previous_table = sum_particles_previous_table + size(tab_tomo{i}, 1);
%                 if particle_count > 0
%                     if sum_particles_previous_table > particle_count
%                         tab_all(particle_count + 1:end, :) = [];
%                         tab_tomo{i}(particle_count + 1:end, :) = [];
%                         break_flag = true;
%                     else
%                         particle_count = particle_count - sum_particles_previous_table;
%                     end
%                 end
%                 
%                 if break_flag == true
%                 	break;
%                 end
%             end
%             
%             tab_all_file_path = char(output_path + string(filesep) + "tab_ini_all_bin_" + tomogram_binning + "_" + num2str(size(tab_all,1)) + ".tbl");
%             dwrite(tab_all, tab_all_file_path);
%             
%             link_destination = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder;
%             createSymbolicLink(tab_all_file_path, link_destination, obj.log_file_id);
%             
%             function tab_tomo = produceParticlesTableForTomogram(raw_prtcl_coords_filepath, particle_count, output_path)
%             
%                 [~, name, ~] = fileparts(raw_prtcl_coords_filepath);
%                 name_splitted = strsplit(name, "_");
%                 tomogram_number = str2num(name_splitted{2});
%                 tomogram_binning = str2num(name_splitted{4});
% 
%                 if fileExists(output_path + string(filesep) + "SUCCESS_" + tomogram_number)
%                     table_file = dir(output_path + string(filesep)...
%                         + "tab_" + num2str(tomogram_number) + "_ini_bin_"...
%                         + num2str(tomogram_binning) + "_*.tbl");
%                     table_file_path = table_file(1).folder + string(filesep) + table_file(1).name;
%                     tab_tomo = dread(char(table_file_path));
%                 else
%                     raw_tab_tomo = readtable(raw_prtcl_coords_filepath, 'FileType', 'text');
%                     raw_tab_tomo = table2array(raw_tab_tomo);
% 
%                     if particle_count > 0
%                         particle_count = min(size(raw_tab_tomo,1), particle_count);
%                         raw_tab_tomo = raw_tab_tomo(1:particle_count,:);
%                     else
%                         particle_count = size(raw_tab_tomo,1);
%                     end
%                     disp("INFO: " + num2str(particle_count) + " particles were found in tomogram_" + num2str(tomogram_number));
% 
%                     tab_tomo = dynamo_table_blank(particle_count);
% 
%                     tab_tomo(1:particle_count,1) = 1:particle_count;
%                     tab_tomo(1:particle_count,2:3) = ones(particle_count,2);
%                     tab_tomo(1:particle_count,24:26) = raw_tab_tomo(:,:);
% 
%                     tab_tomo(1:particle_count,20) = tomogram_number * ones(particle_count,1);
%                     tab_tomo(1:particle_count,32) = ones(particle_count,1);
% 
%                     if tab_tomo(1,20) ~= 0
%                         table_file_path = output_path + string(filesep)...
%                             + "tab_" + num2str(tomogram_number) + "_ini_bin_"...
%                             + num2str(tomogram_binning) + "_"...
%                             + num2str(particle_count) + ".tbl";
% 
%                         dwrite(tab_tomo, table_file_path);
% 
%                         %writetable(tab_tomo, table_file_path, 'WriteVariableNames', false, 'FileType', 'text', 'Delimiter', ' ');
% 
%                         fid = fopen(output_path + string(filesep)...
%                             + "SUCCESS_" + num2str(tomogram_number), "w");
%                         fclose(fid);
%                     else
%                         fid = fopen(output_path + string(filesep)...
%                             + "FAILURE_" + num2str(tomogram_number), "w");
%                         fclose(fid);
%                     end
%                 end
%             end
%         end
        
        function LinkTomogramsToRequestedDirectory(obj, tomograms_binning, tomograms_folder)
            
            tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true);
            if isempty(tomograms)
                error("ERROR: no ctf corrected tomograms were found!");
            end

            if tomograms_binning == -1
                binnings = sort(obj.configuration.binnings, "descend");
                tomograms_all = tomograms;
                for bin_idx=1:length(binnings)
                    tomograms = tomograms_all(contains({tomograms_all.name}, "bin_" + num2str(binnings(bin_idx))));
                    if ~isempty(tomograms)
                        binning = binnings(bin_idx);
                        break
                    end
                end
                tomograms = tomograms_all(contains({tomograms.name}, "bin_" + binning));
            elseif tomograms_binning >= 1
                binning = tomograms_binning;
                tomograms = tomograms(contains({tomograms.name}, "bin_" + binning));
            else
                error("ERROR: the input binning level value is incorrect...");
            end

            if isempty(tomograms)
                error("ERROR: no tomograms with the specified binning level were found!");
            end

            if ~isempty(obj.configuration.tomograms_to_use)
                tomograms_to_star_str = string(arrayfun(@(a)num2str(a, '%03.f'),obj.configuration.tomograms_to_use,'uni',0));
                tomograms = tomograms(contains(string({tomograms(:).name}), "tomogram_"+tomograms_to_star_str));

                if isempty(tomograms)
                    error("ERROR: no tomograms with the specified indices were found!");
                end
            end

            % NOTE: add possibility to use external tomograms
            tomograms_path = obj.output_path + string(filesep) + tomograms_folder;
            mkdir(tomograms_path);
            for tomo_idx=1:length(tomograms)
                tomogram_source = tomograms(tomo_idx).folder + string(filesep) + tomograms(tomo_idx).name;
                link_destination = tomograms_path + string(filesep) + tomograms(tomo_idx).name;
                createSymbolicLink(tomogram_source, link_destination, obj.log_file_id);
            end
        end
              
        function parameters_req = getRequestedOnlyParametersStructure(obj, parameters_all, parameters_req_names, array_delim)
            if nargin < 4
                array_delim = ",";
            end
            parameters_req = struct();
            for idx=1:length(parameters_req_names)
                param_value = parameters_all.(parameters_req_names{idx});
                if (isstring(param_value) && param_value ~= "")...
                        || (isnumeric(param_value) && isscalar(param_value) && param_value ~= -1)
                    parameters_req.(parameters_req_names{idx}) = param_value;
                elseif isnumeric(param_value) && ~isscalar(param_value) && ~isempty(param_value)
                    parameters_req.(parameters_req_names{idx}) = strjoin(string(param_value), array_delim);
                end
            end
        end
            
        function params_string = getParamsString(obj, params, dash_string)
            if nargin < 3
                dash_string = "--";
            end
            params_fields = fieldnames(params);
            params_string = "";
            for idx=1:length(params_fields)
                params_string = params_string + " " + dash_string + params_fields{idx} + " " + params.(params_fields{idx});
            end
        end
        
        function command_output = executeCrYOLOCommand(obj, params_string, cryolo_command)
            if obj.configuration.use_conda == true
                python_run_script_snippet = "LD_LIBRARY_PATH=" + obj.configuration.conda_path + string(filesep) + "lib:$LD_LIBRARY_PATH_COPY"...
                    + " conda run -n " + obj.configuration.cryolo_env; 
            end
 
            cryolo_command_snippet = obj.configuration.conda_path + string(filesep) + "envs"...
                + string(filesep) + obj.configuration.cryolo_env + string(filesep) + "bin"...
                + string(filesep) + cryolo_command;
            python_run_script_snippet = python_run_script_snippet + " python " + cryolo_command_snippet;
            command_output = executeCommand(python_run_script_snippet + " " + params_string, false, obj.log_file_id);
        end

    end
end

