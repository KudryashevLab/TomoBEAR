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


% NOTE: https://github.com/IsoNet-cryoET/IsoNet

classdef IsoNet < Module
    methods
        function obj = IsoNet(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)
            
            return_path = cd(obj.output_path);
            
            steps_to_execute_fields = fieldnames(obj.configuration.steps_to_execute);
            
            if isempty(steps_to_execute_fields)
                error("ERROR: No IsoNet steps_to_execute were found in the JSON file!");
            end
            
            % NOTE: add 'success' files to be able to re-run substeps
            
            for subjob_idx=1:length(steps_to_execute_fields)
                disp("INFO: IsoNet substep " + string(subjob_idx) + ":" + string(steps_to_execute_fields{subjob_idx}));
                step_params = mergeConfigurations(obj.configuration.steps_to_execute_defaults.(steps_to_execute_fields{subjob_idx}), obj.configuration.steps_to_execute.(steps_to_execute_fields{subjob_idx}), "IsoNet", "dynamic");
                obj.(steps_to_execute_fields{subjob_idx})(steps_to_execute_fields{subjob_idx}, step_params);
                disp("INFO: Execution for IsoNet substep " + string(subjob_idx) +" (" + string(steps_to_execute_fields{subjob_idx}) + ") has finished!");
            end
            
            cd(return_path);
        end
        
        function obj = prepare_star(obj, step_name, step_params)
            
            if step_params.use_ctf_corrected_tomograms == false
                tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true);
                if isempty(tomograms)
                    error("ERROR: no non-ctf corrected tomograms were found!");
                end
            else
                tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true);
                if isempty(tomograms)
                    error("ERROR: no ctf corrected tomograms were found!");
                end
            end
            
            if step_params.tomograms_binning == -1
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
            elseif step_params.tomograms_binning > 1
                binning = step_params.tomograms_binning;
                tomograms = tomograms(contains({tomograms.name}, "bin_" + binning));
            else
                error("ERROR: only binned tomograms usage is possible in IsoNet module...");
            end
                 
            if isempty(tomograms)
                error("ERROR: no tomograms with the specified binning of were found!");
            end
            
            if ~isempty(obj.configuration.tomograms_to_use)
                tomograms_to_star_str = string(arrayfun(@(a)num2str(a, '%03.f'),obj.configuration.tomograms_to_use,'uni',0));
                tomograms = tomograms(contains(string({tomograms(:).name}), "tomogram_"+tomograms_to_star_str));
                
                if isempty(tomograms)
                    error("ERROR: no tomograms with the specified indices were found!");
                end
            end
            
            % NOTE: add possibility to use external tomograms
            tomograms_path = obj.output_path + string(filesep) + step_params.folder_name;
            mkdir(tomograms_path);
            for tomo_idx=1:length(tomograms)
                tomogram_source = tomograms(tomo_idx).folder + string(filesep) + tomograms(tomo_idx).name;
                link_destination = tomograms_path + string(filesep) + tomograms(tomo_idx).name;
                createSymbolicLink(tomogram_source, link_destination, obj.log_file_id);
            end
            
            use_params = obj.getRequestedOnlyParametersStructure(step_params, {'output_star', 'number_subtomos'});
            % NOTE: Add eer_upsampling parsing for EER data case!!!
            use_params.pixel_size = obj.configuration.apix * obj.configuration.ft_bin * binning;            
            
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + tomograms_path + params_string;
            command_output = obj.executeIsoNetCommand(params_string);
            
            if step_params.add_defocus_to_star == true
                disp("INFO: adding defocus info to STAR file...");
                output_star_def = obj.editDefocusValueInStarFile(step_params.output_star);
                movefile(step_params.output_star, step_params.output_star + "~");
                movefile(output_star_def, step_params.output_star);
                % rewrite original star file with defocus included!!!
            else
                disp("INFO: adding defocus info to STAR file was disabled by user!");
            end
        end
        
        function new_star_path = editDefocusValueInStarFile(obj, star_path)
            
            % NOTE: get defocus info from .defocus files
            defocus_files = getDefocusFiles(obj.configuration, '.defocus');
            
            star_fid = fopen(star_path, 'r');

            [star_path, star_name, star_ext] = fileparts(star_path);
            if star_path ~= ""
                new_star_path = star_path + string(filesep) + star_name + "_def" + star_ext;
            else
                new_star_path = star_name + "_def" + star_ext;
            end
            new_star_fid = fopen(new_star_path, 'w');

            % NOTE: loop over lines before _rln fields and write them
            while ~feof(star_fid)
                fl = fgetl(star_fid);
                if isempty(regexp(fl,'_rln', 'once'))
                    nl = fl; fprintf(new_star_fid, '%s\n', nl);
                else
                    break
                end
            end

            % NOTE: loop over lines of _rln fields and write them

            while ~feof(star_fid)
                if ~isempty(regexp(fl,'_rln', 'once'))
                    nl = fl; fprintf(new_star_fid, '%s\n', nl);
                else
                    break
                end
                fl = fgetl(star_fid);
            end

            % NOTE: read tomograms data, add defoci and write them
            while ~feof(star_fid)
                if ~isempty(regexp(fl,'tomogram_', 'once'))
                    flsp = split(strtrim(fl));

                    % NOTE: 2nd column is tomogram filepath
                    [~, tomo_name, ~] = fileparts(flsp(2));

                    % NOTE: 2nd part of tomogram filename is tomogram number
                    tomo_name_split = split(tomo_name, '_');
                    tomo_num = str2double(tomo_name_split(2));
                    
                    defocus_file = defocus_files(tomo_num);
                    defocus_file_path = defocus_file{1}.folder + string(filesep) + defocus_file{1}.name; 
                    defocus_ave = obj.getAverageDefocusFromDefocusFile(defocus_file_path);
                    
                    % NOTE: 4th column is tomogram global defocus
                    fprintf(new_star_fid, '%s\t%s\t%s\t%.2f\t%s\t%s\n',flsp{1},flsp{2},flsp{3},defocus_ave,flsp{5},flsp{6});
                else
                    break
                end
                fl = fgetl(star_fid);
            end

            fclose(star_fid);
            fclose(new_star_fid);
        end
        
        function defocus_ave = getAverageDefocusFromDefocusFile(obj, defocus_file_path)
            
            defocus_fid = fopen(defocus_file_path, 'rt');
            txt = textscan(defocus_fid , '%s', 'Delimiter', '\n');
            txt = txt{1};
            
            % NOTE: use value bigger than upper bond as initial minima
            angle_abs_min = 90;
            for idx=1:length(txt)
                txt_data = split(strtrim(txt{idx}));
                % NOTE: <7 values is header of .defocus file v3 
                if length(txt_data) < 7
                    continue;
                end
                angle_abs = abs(str2double(txt_data{3}));
                if angle_abs < angle_abs_min
                    angle_abs_min = angle_abs;
                    defocus_ave_min = (str2double(txt_data{5}) + str2double(txt_data{6}))/2;
                end
            end
            fclose(defocus_fid);
            
            defocus_ave = defocus_ave_min;
        end
        
        function obj = deconv(obj, step_name, step_params)
            
            if ~isfile(step_params.star_file)
                error('ERROR: the requested star_file was not found!');
            end

            use_params_cell = {'deconv_folder',...
                'snrfalloff', 'deconvstrength', 'highpassnyquist',...
                'chunk_size', 'overlap_rate'};
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            use_params.deconv_folder = obj.output_path + string(filesep) + use_params.deconv_folder;
            if step_params.ncpu == -1
                use_params.ncpu = getCpuPoolSize(1);
            else
                use_params.ncpu = getCpuPoolSize(1, step_params.ncpu);
            end
            
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + step_params.star_file + params_string;
            command_output = obj.executeIsoNetCommand(params_string);
        end
        
        function obj = make_mask(obj, step_name, step_params)
             
            if ~isfile(step_params.star_file)
                error('ERROR: the requested star_file was not found!');
            end
            
            use_params_cell = {'mask_folder',...
                'patch_size', 'mask_boundary',...
                'density_percentage', 'std_percentage',...
                'z_crop', 'use_deconv_tomo'};
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            use_params.mask_folder = obj.output_path + string(filesep) + use_params.mask_folder;
            
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + step_params.star_file + params_string;
            command_output = obj.executeIsoNetCommand(params_string);
        end
        
        function obj = extract(obj, step_name, step_params)
             
            if ~isfile(step_params.star_file)
                error('ERROR: the requested star_file was not found!');
            end
            
            use_params_cell = {'subtomo_folder', 'subtomo_star'...
                'cube_size', 'crop_size',...
                'use_deconv_tomo'};
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            use_params.subtomo_folder = obj.output_path + string(filesep) + use_params.subtomo_folder;
            
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + step_params.star_file + params_string;
            command_output = obj.executeIsoNetCommand(params_string);
        end
        
        function obj = refine(obj, step_name, step_params)
             
            if ~isfile(step_params.subtomo_star)
                error('ERROR: the requested subtomo_star was not found!');
            end
            
            if obj.configuration.gpu > 0
                step_params.gpuID = obj.configuration.gpu - 1;
            else
                error("ERROR: Gpus are needed to train IsoNet!");
            end
            
            use_params_cell = {'iterations',... 
                'data_dir','result_dir',...
                'pretrained_model', 'continue_from',...
                'epochs', 'batch_size', 'steps_per_epoch',...
                'noise_level', 'noise_start_iter', 'noise_mode', 'noise_dir',...
                'learning_rate', 'drop_out', 'convs_per_depth',...
                'kernel', 'unet_depth', 'filter_base',...
                'batch_normalization', 'normalize_percentile',...
                'gpuID'};
            
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            use_params.result_dir = obj.output_path + string(filesep) + use_params.result_dir;
            
            if step_params.preprocessing_ncpus == -1
                use_params.preprocessing_ncpus = getCpuPoolSize(1);
            else
                use_params.preprocessing_ncpus = getCpuPoolSize(1, step_params.preprocessing_ncpus);
            end
            
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + step_params.subtomo_star + params_string;
            command_output = obj.executeIsoNetCommand(params_string);
        end
        
        function obj = predict(obj, step_name, step_params)
             
            if ~isfile(step_params.star_file)
                error('ERROR: the requested star_file was not found!');
            end
            
            if obj.configuration.gpu > 0
                step_params.gpuID = obj.configuration.gpu - 1;
            else
                error("ERROR: Gpus are needed to train IsoNet!");
            end
            
            use_params_cell = {'model', 'output_dir'...
                'cube_size', 'crop_size',...
                'batch_size', 'normalize_percentile',...
                'gpuID'};
            use_params = obj.getRequestedOnlyParametersStructure(step_params, use_params_cell);
            use_params.output_dir = obj.output_path + string(filesep) + use_params.output_dir;
            
            params_string = obj.getParamsString(use_params);
            params_string = step_name + " " + step_params.star_file + params_string;
            command_output = obj.executeIsoNetCommand(params_string);
        end
        
        function parameters_req = getRequestedOnlyParametersStructure(obj, parameters_all, parameters_req_names)
            parameters_req = struct();
            for idx=1:length(parameters_req_names)
                param_value = parameters_all.(parameters_req_names{idx});
                if (isstring(param_value) && param_value ~= "")...
                        || (isnumeric(param_value) && isscalar(param_value) && param_value ~= -1)
                    parameters_req.(parameters_req_names{idx}) = param_value;
                elseif isnumeric(param_value) && ~isscalar(param_value) && ~isempty(param_value)
                    parameters_req.(parameters_req_names{idx}) = strjoin(string(param_value), ",");
                end
            end
        end
            
        function params_string = getParamsString(obj, params)
            params_fields = fieldnames(params);
            params_string = "";
            for idx=1:length(params_fields)
                params_string = params_string + " --" + params_fields{idx} + " " + params.(params_fields{idx});
            end
        end
        
        function command_output = executeIsoNetCommand(obj, params_string)
            python_run_script_snippet = "PYTHONPATH=" + fullfile(obj.configuration.repository_path, '..');
            if obj.configuration.use_conda == true
                python_run_script_snippet = python_run_script_snippet + " LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.isonet_env; 
            end
            python_run_script_snippet = python_run_script_snippet + " python " + obj.configuration.repository_path + filesep + "bin/isonet.py";
            command_output = executeCommand(python_run_script_snippet + " " + params_string, false, obj.log_file_id);
        end

    end
end

