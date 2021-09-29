classdef GCTFCtfphaseflipCTFCorrection < Module
    methods
        function obj = GCTFCtfphaseflipCTFCorrection(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = process(obj)
            disp("INFO: **STARTING PARAMETERS**");
            disp("INFO: Input Folder: " + obj.input_path);
            disp("INFO: Output Folder: " + obj.output_path);
            % NOTE:TODO: it's probably the safest to trust the apix value in the
            % configuration for unbinned data
            field_names = fieldnames(obj.configuration.tomograms);
            if isfield(obj.configuration, "apix")
                apix = obj.configuration.apix;
            elseif obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix == 0
                folder_contents = getOriginalMRCs(obj.configuration);
                disp("INFO: determining pixel size from header");
                command = sprintf("header %s | grep Pixel", string(folder_contents(1).folder + string(filesep) + folder_contents(1).name));
                output = executeCommand(command, false, obj.log_file_id);
                printVariable(output);
                
                matching_results = regexp(output, "(\d+.\d+)", "match");
                obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix = str2double(matching_results{1});
                apix = str2double(matching_results{1});
            else
                disp("INFO: taking pixel size from configuration");
                apix = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix;
                printVariable(apix);
            end
            %
            % if configuration.binning == true
            %     disp("INFO: binning set to TRUE (aligned stacks which are binned to 2, 4, and 8 will be generated)");
            % else
            %     disp("INFO: binning set to FALSE");
            % end
            
            % if configuration.generate_exact_filtered_tomograms == true
            % else
            %     disp("INFO: no exact filter will be applied");
            % end
            
            % NOTE: this loop is dissecting tiltstacks, better to work on motion
            % corrected mrcs because of data duplication, still usefull if uncombined raw or
            % motion corrected data is unavailable
            % TODO: better to use flag configuration.use_aligned_stack if not then use
            % motion_corrected_files, but what about binning?
            % if isfield(configuration, "tomogram_output_prefix") && ~isempty(configuration.tomogram_output_prefix)
            %     dir_list = dir(configuration.previous_step_output_folder + string(filesep) + configuration.tomogram_output_prefix + "*");
            % else
            %     dir_list = dir(configuration.previous_step_output_folder + string(filesep) + configuration.tomogram_input_prefix + "*");
            % end
            if obj.configuration.use_rawtlt == true
                tilt_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "rawtlt");
            else
                tilt_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "tlt");
            end
            
            if obj.configuration.use_aligned_stack && ~isempty(getFilePathsFromLastBatchruntomoRun(obj.configuration, "ali"))
                tilt_stacks = getFilePathsFromLastBatchruntomoRun(obj.configuration, "ali");
            else
                xf_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "xf");
                xf_files = xf_files{1};
                % xf_files = xf_files{obj.configuration.set_up.j};
                tilt_stacks = getTiltStacksFromStandardFolder(obj.configuration, true);
                
                tilt_stacks = tilt_stacks(contains({tilt_stacks(:).name}, sprintf("%s_%03d", obj.configuration.tomogram_output_prefix, obj.configuration.set_up.j)));
            end
            [path, name, extension] = fileparts(tilt_files{1});
            tilt_index_angle_mapping = sort(obj.configuration.tomograms.(name).tilt_index_angle_mapping(2,:));
            for i = 1:length(tilt_stacks)
                [path, name, extension] = fileparts(tilt_files{i});
                if iscell(tilt_stacks)
                    [folder, tilt_stack_name, extension] = fileparts(tilt_stacks{i});
                else
                    [folder, tilt_stack_name, extension] = fileparts(tilt_stacks(i).folder + string(filesep) + tilt_stacks(i).name);
                end
                
                destination_folder = obj.output_path;
                
                
                slice_folder = destination_folder + string(filesep) + obj.configuration.slice_folder;
                
                obj.dynamic_configuration.defocus_slice_folder_path = slice_folder;
                
                [status_mkdir, message, message_id] = mkdir(slice_folder);
                
                defocus_file_destination = destination_folder + string(filesep) + name + ".defocus";
                defocus_file_id = fopen(defocus_file_destination, "w");
                
                % TODO: check why am I getting here .XF and .TLT file
                %     tilt_file_list = dir(dir_list(i).folder + string(filesep)...
                %         + dir_list(i).name + string(filesep) + "*.tlt");
                tilt_file_destination = destination_folder + string(filesep) + name + ".tlt";
                createSymbolicLink(tilt_files{i}, tilt_file_destination, obj.log_file_id);
                tilt_file_id = fopen(tilt_file_destination, "r");
                if tilt_file_id == -1
                    obj.status = 0;
                end
                
                % NOTE: use the raw stack if aligned stack binning is
                % higher than 1
                if (isfield(obj.configuration, "use_aligned_stack") && obj.configuration.use_aligned_stack == false) || obj.configuration.aligned_stack_binning > 1
                    xf_file_destination = destination_folder + string(filesep) + name + ".xf";
                    output = createSymbolicLink(xf_files{i}, xf_file_destination, obj.log_file_id);
                end
                
                
                disp("INFO: splitting " + tilt_stack_name + "...");
                %                 source = tilt_stacks(i).folder + string(filesep) + tilt_stacks(i).name;
                if iscell(tilt_stacks)
                    source = tilt_stacks{i};
                else
                    source = string(tilt_stacks(i).folder) + string(filesep) + string(tilt_stacks(i).name);
                end
                
                % TODO: introduce checks
                [status_mkdir, message, message_id] = mkdir(destination_folder);
                % TODO: add default "configuration.slice_folder" to simplify configuration, could also be done
                % in default configuration, both ways are acceptable
                %                 [folder, name, extension] = fileparts(tilt_stacks{i});
                destination = destination_folder + string(filesep) + tilt_stack_name;
                
                output = createSymbolicLink(source, destination, obj.log_file_id);
                output = executeCommand("newstack -split 1 -append mrc "...
                    + destination + " "...
                    + slice_folder + string(filesep) + name...
                    + "_" + obj.configuration.slice_suffix + "_", false, obj.log_file_id);
                return_folder = cd(slice_folder);
                disp("INFO: **GCTF ESTIMATION**");
                if isfield(obj.configuration, "nominal_defocus_in_nm") && obj.configuration.nominal_defocus_in_nm ~= 0
                    % TODO: could be also 2 numbers for lower and upper
                    % limit or factors in different variable names
                    lower_l = round(obj.configuration.nominal_defocus_in_nm / obj.configuration.defocus_limit_factor) * 10^4;
                    upper_l = round(obj.configuration.nominal_defocus_in_nm * obj.configuration.defocus_limit_factor) * 10^4;
                else
                    if isfield(obj.configuration, "apix")
                        apix = obj.configuration.apix;
                    else
                        apix = obj.configuration.greatest_apix;
                    end
                    disp("INFO: Starting Gctf estimation on " + name + "!");
                    output = executeCommand(obj.configuration.ctf_correction_command...
                        + " --apix " + apix...
                        + " "...
                        + name + "_" + obj.configuration.slice_suffix + "_"...
                        + sprintf("%02d", obj.configuration.tomograms.(name).tilt_index_angle_mapping(4,tilt_index_angle_mapping == 0))...
                        + ".mrc", false, obj.log_file_id);
                    delete(obj.output_path + string(filesep) + obj.configuration.slice_folder + string(filesep) + name + "_" + obj.configuration.slice_suffix + "_"...
                        + sprintf("%02d", obj.configuration.tomograms.(name).tilt_index_angle_mapping(4,tilt_index_angle_mapping == 0))...
                        + "_EPA.log");
                    delete(obj.output_path + string(filesep) + obj.configuration.slice_folder + string(filesep) + "micrographs_all_gctf.star");
                    delete(obj.output_path + string(filesep) + obj.configuration.slice_folder + string(filesep) + name + "_" + obj.configuration.slice_suffix + "_"...
                        + sprintf("%02d", obj.configuration.tomograms.(name).tilt_index_angle_mapping(4,tilt_index_angle_mapping == 0))...
                        + "_gctf.log")
                    delete(obj.output_path + string(filesep) + obj.configuration.slice_folder + string(filesep) + name + "_" + obj.configuration.slice_suffix + "_"...
                        + sprintf("%02d", obj.configuration.tomograms.(name).tilt_index_angle_mapping(4,tilt_index_angle_mapping == 0))...
                        + ".ctf")
                    line_divided_text = textscan(output, '%s', 'delimiter', '\n');
                    final_values = line_divided_text{1}{contains(line_divided_text{1}, "Final Values")};
                    final_values_splitted = strsplit(final_values);
                    global_defocus_1_in_angstrom = str2double(final_values_splitted{1});
                    global_defocus_2_in_angstrom = str2double(final_values_splitted{2});
                    global_defocus_average_in_angstrom = (global_defocus_1_in_angstrom + global_defocus_2_in_angstrom) / 2;
                    
                    % TODO: use cosine for defocus interval to be used for
                    % optimization
                    lower_l = global_defocus_average_in_angstrom / 2;
                    upper_l = global_defocus_average_in_angstrom * 1.5;
                end
                disp("INFO: CALCULATED LIMITS: Lower Limit: " + lower_l + " Upper Limit: " + upper_l);
                command = string(obj.configuration.ctf_correction_command)...
                    + " --apix " + apix...
                    + " --defL " + lower_l...
                    + " --defH " + upper_l;
                
                if obj.configuration.do_phase_flip ==  true
                    command = command + " --do_phase_flip";
                end
                
                if obj.configuration.do_EPA ==  true
                    command = command + " --do_EPA";
                end
                
                command = command + " " + name + "*.mrc";
                output = executeCommand(command, false, obj.log_file_id);
                view_list = dir(slice_folder + string(filesep) + name + "_*_" + "gctf.log");
                if obj.configuration.defocus_file_version <= 2
                    j_length = length(view_list);
                else
                    j_length = length(view_list) + 1;
                end
                for j = 1:j_length
                    
                    
                    if obj.configuration.defocus_file_version <= 2
                        gctf_obj.log_file_id = fopen(view_list(j).folder + string(filesep) + view_list(j).name, "r");
                        line_divided_text = textscan(gctf_obj.log_file_id, "%s", "delimiter", "\n");
                        final_values = line_divided_text{1}{contains(line_divided_text{1}, "Final Values")};
                        final_values_splitted = strsplit(final_values);
                        local_defocus_1_in_angstrom = str2double(final_values_splitted{1});
                        local_defocus_2_in_angstrom = str2double(final_values_splitted{2});
                        astigmatism_angle = str2double(final_values_splitted{3});
                        local_defocus_1_in_nanometers = local_defocus_1_in_angstrom / 10;
                        local_defocus_2_in_nanometers = local_defocus_2_in_angstrom / 10;
                        
                        if local_defocus_1_in_nanometers > local_defocus_2_in_nanometers
                            local_defocus_in_nanometers_temporary = local_defocus_2_in_nanometers;
                            local_defocus_2_in_nanometers = local_defocus_1_in_nanometers;
                            local_defocus_1_in_nanometers = local_defocus_in_nanometers_temporary;
                            astigmatism_angle = astigmatism_angle - 90;
                        end
                        tilt_angle = fgetl(tilt_file_id);
                        if j == 1
                            fwrite(defocus_file_id, sprintf("%s %s %s %s %s %s %s %s\n", num2str(j), num2str(j), num2str(tilt_angle), num2str(tilt_angle), num2str(local_defocus_1_in_nanometers), num2str(local_defocus_2_in_nanometers), num2str(astigmatism_angle), num2str(configuration.defocus_file_version)));
                        else
                            fwrite(defocus_file_id, sprintf("%s %s %s %s %s %s %s\n", num2str(j), num2str(j), num2str(tilt_angle), num2str(tilt_angle), num2str(local_defocus_1_in_nanometers), num2str(local_defocus_2_in_nanometers), num2str(astigmatism_angle)));
                        end
                    else
                        if j == 1
                            fwrite(defocus_file_id, sprintf("%s 0 0. 0. 0 %s\n", num2str(obj.configuration.defocus_file_version_3_flag), num2str(obj.configuration.defocus_file_version)));
                        else
                            gctf_obj.log_file_id = fopen(view_list(j-1).folder + string(filesep) + view_list(j-1).name, "r");
                            line_divided_text = textscan(gctf_obj.log_file_id, "%s", "delimiter", "\n");
                            final_values = line_divided_text{1}{contains(line_divided_text{1}, "Final Values")};
                            final_values_splitted = strsplit(final_values);
                            local_defocus_1_in_angstrom = str2double(final_values_splitted{1});
                            local_defocus_2_in_angstrom = str2double(final_values_splitted{2});
                            astigmatism_angle = str2double(final_values_splitted{3});
                            local_defocus_1_in_nanometers = local_defocus_1_in_angstrom / 10;
                            local_defocus_2_in_nanometers = local_defocus_2_in_angstrom / 10;
                            
                            if local_defocus_1_in_nanometers > local_defocus_2_in_nanometers
                                local_defocus_in_nanometers_temporary = local_defocus_2_in_nanometers;
                                local_defocus_2_in_nanometers = local_defocus_1_in_nanometers;
                                local_defocus_1_in_nanometers = local_defocus_in_nanometers_temporary;
                                astigmatism_angle = astigmatism_angle - 90;
                            end
                            tilt_angle = fgetl(tilt_file_id);
                            fwrite(defocus_file_id, sprintf("%s %s %s %s %s %s %s\n", num2str(j-1), num2str(j-1), num2str(tilt_angle), num2str(tilt_angle), num2str(local_defocus_1_in_nanometers), num2str(local_defocus_2_in_nanometers), num2str(astigmatism_angle)));
                        end
                    end
                end
                fclose(defocus_file_id);
                fclose(tilt_file_id);
                cd(return_folder);
                if obj.configuration.run_ctf_phase_flip
                    splitted_tilt_stack_path_name = strsplit(destination, ".");
                    ctf_corrected_stack_destination = splitted_tilt_stack_path_name(1)...
                        + "_" + obj.configuration.ctf_corrected_stack_suffix...
                        + "." + splitted_tilt_stack_path_name(2);
                    
                    command = "ctfphaseflip -input " + destination...
                        + " -output " + ctf_corrected_stack_destination...
                        + " -angleFn " + tilt_file_destination...
                        + " -defFn " + defocus_file_destination...
                        + " -defTol " + obj.configuration.defocus_tolerance...
                        + " -iWidth " + obj.configuration.iWidth...
                        + " -pixelSize " + apix...
                        + " -volt " + obj.configuration.keV...
                        + " -cs " + obj.configuration.spherical_aberation...
                        + " -ampContrast " + obj.configuration.ampContrast;
                    
                    if obj.configuration.use_aligned_stack == false
                        command = command + " -xform " + xf_file_destination;
                    end
                    
                    % TODO: get number as numeric for better version check
                    if obj.configuration.set_up.gpu > 0 && versionGreaterThan(obj.configuration.environment_properties.imod_version, "4.10.9")
                        command = command + " -gpu " + obj.configuration.set_up.gpu;
                    end
                    
                    executeCommand(command, false, obj.log_file_id);
                    % TODO: link ctf corrected stack
                end
                if obj.configuration.reconstruct_tomograms == true
                    disp("INFO: tomograms will be generated.");
                    ctf_corrected_tomogram_destination = splitted_tilt_stack_path_name(1) + "_"...
                        + obj.configuration.ctf_corrected_stack_suffix + "_"...
                        + obj.configuration.tomogram_suffix + "."...
                        + splitted_tilt_stack_path_name(2);
                    
                    command = "tilt -InputProjections " + ctf_corrected_stack_destination...
                        + " -OutputFile " + ctf_corrected_tomogram_destination...
                        + " -TILTFILE " + tilt_file_destination...
                        + " -THICKNESS " + obj.configuration.reconstruction_thickness / obj.configuration.aligned_stack_binning;
                    
                    if obj.configuration.set_up.gpu > 0
                            command = command + " -UseGPU " + num2str(obj.configuration.set_up.gpu);
                    end
                    
                    executeCommand(command, false, obj.log_file_id);
                    % TODO: if time and motivation implement exclude views by
                    % parametrization not by truncation
                    %                + " -EXCLUDELIST2 $EXCLUDEVIEWS");
                    
                    ctf_corrected_rotated_tomogram_destination = splitted_tilt_stack_path_name(1) + "_"...
                        + obj.configuration.ctf_corrected_stack_suffix + "_"...
                        + obj.configuration.tomogram_suffix + "."...
                        + splitted_tilt_stack_path_name(2);
                    executeCommand("trimvol -rx " + ctf_corrected_tomogram_destination...
                        + " " + ctf_corrected_rotated_tomogram_destination, false, obj.log_file_id);
                    
                    if obj.configuration.generate_exact_filtered_tomograms == true
                        disp("INFO: tomograms with exact filter (size: " + obj.configuration.exact_filter_size + ") will be generated.");
                        
                        ctf_corrected_exact_filtered_tomogram_destination = splitted_tilt_stack_path_name(1) + "_"...
                            + obj.configuration.ctf_corrected_stack_suffix + "_"...
                            + obj.configuration.exact_filter_suffix + "_"...
                            + obj.configuration.tomogram_suffix + "."...
                            + splitted_tilt_stack_path_name(2);
                        
                        command = "tilt -InputProjections " + ctf_corrected_stack_destination...
                            + " -OutputFile " + ctf_corrected_exact_filtered_tomogram_destination...
                            + " -TILTFILE " + tilt_file_destination...
                            + " -THICKNESS " + obj.configuration.reconstruction_thickness / obj.configuration.aligned_stack_binning...
                            + " -ExactFilterSize " + obj.configuration.exact_filter_size;
                        
                        if obj.configuration.set_up.gpu > 0
                            command = command + " -UseGPU " + num2str(obj.configuration.set_up.gpu);
                        end
                        
                        executeCommand(command, false, obj.log_file_id);
                        % TODO: if time and motivation implement exclude views by
                        % parametrization not by truncation
                        %                + "-EXCLUDELIST2 $EXCLUDEVIEWS");
                        ctf_corrected_exact_filtered_rotated_tomogram_destination = splitted_tilt_stack_path_name(1) + "_"...
                            + obj.configuration.ctf_corrected_stack_suffix + "_"...
                            + obj.configuration.exact_filter_suffix + "_"...
                            + obj.configuration.tomogram_suffix + "."...
                            + splitted_tilt_stack_path_name(2);
                        executeCommand("trimvol -rx " + ctf_corrected_exact_filtered_tomogram_destination...
                            + " " + ctf_corrected_exact_filtered_rotated_tomogram_destination, false, obj.log_file_id);
                    end
                end
            end
        end
        
        function obj = cleanUp(obj)
            if obj.configuration.keep_intermediates == false
                files = dir(obj.output_path);
                files(1) = [];
                files(1) = [];
                files = files(~contains({files(:).name}, ".defocus"));
                files = files(~contains({files(:).name}, ".log"));
                for i = 1:length(files)
                    if files(i).isdir == true
                        [success, message,message_id] = rmdir(files(i).folder + string(filesep) + files(i).name, "s");
                    else
                        delete(files(i).folder + string(filesep) + files(i).name);
                    end
                end
                
                %             [success, message,message_id] = rmdir(obj.dynamic_configuration.defocus_slice_folder_path);
            end
            obj = cleanUp@Module(obj);
        end
    end
end

