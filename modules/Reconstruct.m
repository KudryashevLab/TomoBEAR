classdef Reconstruct < Module
    methods
        function obj = Reconstruct(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            if obj.configuration.reconstruct == "both" || obj.configuration.reconstruct == "all"
                createStandardFolder(obj.configuration, "tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "exact_filtered_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_exact_filtered_tomograms_folder", false);
            elseif obj.configuration.reconstruct == "full" || obj.configuration.reconstruct == "unbinned"
                createStandardFolder(obj.configuration, "tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_tomograms_folder", false);
                createStandardFolder(obj.configuration, "exact_filtered_tomograms_folder", false);
            elseif obj.configuration.reconstruct == "binned"
                createStandardFolder(obj.configuration, "binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_exact_filtered_tomograms_folder", false);
            else
                error("ERROR: tomogram type unknown!");
            end
            
        end
        
        function obj = process(obj)
            field_names = fieldnames(obj.configuration.tomograms);
            name = field_names{obj.configuration.set_up.j};
            disp("INFO: " + obj.configuration.reconstruct + " tomograms will be generated.");
            if obj.configuration.reconstruct == "all"
                if obj.configuration.use_ctf_corrected_stack == true
                    aligned_tilt_stack = getCtfCorrectedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    binned_aligned_tilt_stacks = getCtfCorrectedBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                else
                    aligned_tilt_stack = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    binned_aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                end
            elseif obj.configuration.reconstruct == "unbinned"
                if obj.configuration.use_ctf_corrected_stack == true
                    aligned_tilt_stack = getCtfCorrectedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                else
                    aligned_tilt_stack = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                end
            elseif obj.configuration.reconstruct == "binned"
                if obj.configuration.use_ctf_corrected_stack == true
                    binned_aligned_tilt_stacks = getCtfCorrectedBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                else
                    binned_aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                end
            else
                error("ERROR: tomogram type unknown!");
            end
            if obj.configuration.use_rawtlt == true
                tlt_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "rawtlt");
                tlt_out_name_batch_run_tomo = tlt_file{1};
                tlt_out_name = obj.output_path + string(filesep) + name + ".tlt";
                createSymbolicLink(tlt_out_name_batch_run_tomo, tlt_out_name, obj.log_file_id);
            else
                tlt_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "tlt");
                tlt_in = fopen(tlt_file{1}, "r");
                tlt_out_name = obj.output_path + string(filesep) + name + ".tlt";
                tlt_out = fopen(tlt_out_name, "w");
                
                if obj.configuration.correct_angles == "center"
                    tlt_in = fopen(tlt_file{1}, "r");
                    
                    tlt_out_name = obj.output_path + string(filesep) + name + ".tlt";
                    tlt_out = fopen(tlt_out_name, "w");
                    
                    high_tilt = fgetl(tlt_in);
                    % TODO:DIRTY -> code clean
                    while ~feof(tlt_in)
                        low_tilt = fgetl(tlt_in);
                    end
                    fclose(tlt_in);
                    
                    shift = (high_tilt + low_tilt) / 2;
                    
                    tlt_in = fopen(tlt_file{1}, "r");
                    while ~feof(tlt_in)
                        % TODO: needs to be tested
                        tilt_adjusted = num2str(fgetl(tlt_in)) + shift;
                        fprintf(tlt_out, "%.2f\n", tilt_adjusted);
                    end
                elseif obj.configuration.correct_angles == "subtract"
                    edf_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "edf");
                    edf_in = fopen(edf_file{1}, "r");
                    
                    while ~feof(edf_in)
                        tmp = fgetl(edf_in);
                        if contains(string(tmp), "AngleOffset")
                            align_offset = regexp(string(tmp), "\d+.\d+", "match");
                        end
                    end
                    fclose(edf_in);
                    
                    while ~feof(tlt_in)
                        tmp = fgetl(tlt_in);
                        angle_num = str2double(tmp) + str2double(align_offset);
                        fprintf(tlt_out, "%.2f\n", angle_num);
                    end
                end
                fclose(tlt_in);
                fclose(tlt_out);
            end
            
            % if obj.configuration.set_up.gpu > 0
            %     gpu_number = obj.configuration.set_up.gpu;
            % end
            
            if exist("aligned_tilt_stack", "var")
                
                tomogram_destination = obj.output_path + string(filesep) + name + "_full.rec";
                obj.temporary_files(end + 1) = tomogram_destination;
                
                command = "tilt -InputProjections " + aligned_tilt_stack(obj.configuration.set_up.j).folder + string(filesep) + aligned_tilt_stack(obj.configuration.set_up.j).name...
                    + " -OutputFile " + tomogram_destination...
                    + " -TILTFILE " + tlt_out_name...
                    + " -THICKNESS " + obj.configuration.reconstruction_thickness / obj.configuration.aligned_stack_binning;
                
                
                if obj.configuration.set_up.gpu > 0
                    command = command + " -UseGPU " + obj.configuration.set_up.gpu ;
                end
                
                if isfield(obj.configuration, "exclude_lists")
                    if isfield(obj.configuration.exclude_lists, name)
                        command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(name))), ",");
                    end
                end
                
                executeCommand(command, false, obj.log_file_id);
                
                
                rotated_tomogram_destination = obj.output_path + string(filesep) + name + ".rec";
                executeCommand("trimvol -rx " + tomogram_destination...
                    + " " + rotated_tomogram_destination, false, obj.log_file_id);
                createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "tomograms_folder", obj.log_file_id);
                %                 if obj.configuration.generate_exact_filtered_tomograms == true
                %                     disp("INFO: tomograms with exact filter (size: " + obj.configuration.exact_filter_size + ") will be generated.");
                %
                %                     exact_filtered_tomogram_destination = obj.output_path + string(filesep) + name + "_exact_filtered_full.rec";
                %
                %                     command = "tilt -InputProjections " + aligned_tilt_stack(obj.configuration.set_up.adjusted_j).folder + string(filesep) + aligned_tilt_stack(obj.configuration.set_up.adjusted_j).name...
                %                         + " -OutputFile " + exact_filtered_tomogram_destination...
                %                         + " -TILTFILE " + tlt_file{1}...
                %                         + " -THICKNESS " + obj.configuration.reconstruction_thickness / obj.configuration.aligned_stack_binning...
                %                         + " -ExactFilterSize " + obj.configuration.exact_filter_size;
                %
                %                     if obj.configuration.use_gpu == true
                %                         command = command + " -UseGPU " + gpu_number;
                %                     end
                %                     executeCommand(command, false, obj.log_file_id);
                %                     % TODO: if time and motivation implement exclude views by
                %                     % parametrization not by truncation
                %                     %                + "-EXCLUDELIST2 $EXCLUDEVIEWS");
                %                     exact_filtered_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_exact_filtered.rec";
                %                     executeCommand("trimvol -rx " + exact_filtered_tomogram_destination...
                %                         + " " + exact_filtered_rotated_tomogram_destination, false, obj.log_file_id);
                %                     createSymbolicLinkInStandardFolder(obj.configuration, exact_filtered_rotated_tomogram_destination, "exact_filtered_tomograms_folder", obj.log_file_id);
                %                 end
            end
            
            
            if exist("binned_aligned_tilt_stacks", "var")
                binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(find(contains({binned_aligned_tilt_stacks.name}, name)));
                for j = 1:length(binned_aligned_tilt_stacks)
                    %                     [folder, name, extension] = fileparts(binned_aligned_tilt_stacks(((obj.configuration.set_up.adjusted_j - 1) * length(obj.configuration.binnings)) + j).folder + string(filesep) + binned_aligned_tilt_stacks(((obj.configuration.set_up.adjusted_j - 1) * length(obj.configuration.binnings)) + j).name);
                    [folder, name, extension] = fileparts(binned_aligned_tilt_stacks(j).folder + string(filesep) + binned_aligned_tilt_stacks(j).name);
                    rotated_tomogram_destination = obj.output_path + string(filesep) + name + ".rec";
                    if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                        [output, tomogram_destination] = createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "ctf_corrected_binned_tomograms_folder", obj.log_file_id, false);
                    else
                        [output, tomogram_destination] = createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "binned_tomograms_folder", obj.log_file_id, false);
                    end
                    
                    if fileExists(tomogram_destination) %obj.configuration.binnings(j) == obj.configuration.aligned_stack_binning &&
                        continue;
                    end
                    
                    splitted_name = strsplit(name, "_");
                    if contains(name, obj.configuration.ctf_corrected_stack_suffix)
                        splitted_binning = str2num(splitted_name{end-1});
                    else
                        splitted_binning = str2num(splitted_name{end});
                    end
                    
                    tomogram_destination = obj.output_path + string(filesep) + name + "_full.rec";
                    obj.temporary_files(end + 1) = tomogram_destination;
                    command = "tilt -InputProjections " + binned_aligned_tilt_stacks(j).folder + string(filesep) + binned_aligned_tilt_stacks(j).name...
                        + " -OutputFile " + tomogram_destination...
                        + " -TILTFILE " + tlt_out_name...
                        + " -THICKNESS " +  obj.configuration.reconstruction_thickness / splitted_binning;
                    
                    if isfield(obj.configuration, "exclude_lists") && isfield(obj.configuration.exclude_lists, field_names{obj.configuration.set_up.j})
                        command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(field_names{obj.configuration.set_up.j})')), ",");
                    else
                        fid_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "fid");
                        executeCommand("model2point " + fid_files{1} + " " + obj.output_path + filesep + "fiducial.point", false, obj.log_file_id);
                        fiducials = dlmread(obj.output_path + filesep + "fiducial.point");
                        projection_ids = unique(fiducials(:,3)) + 1;
                        if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, strjoin(splitted_name(1:2), "_")) || isempty(obj.configuration.tilt_index_angle_mapping.(strjoin(splitted_name(1:2), "_")))
                            previous_projection_ids_logical = obj.configuration.tomograms.(strjoin(splitted_name(1:2), "_")).tilt_index_angle_mapping(3,:);
                        else
                            previous_projection_ids_logical = obj.configuration.tilt_index_angle_mapping.(strjoin(splitted_name(1:2), "_"))(3,:);
                        end
                        previous_projection_ids_logical(previous_projection_ids_logical == 0) = [];
                        projection_ids_logical = zeros([1 length(previous_projection_ids_logical)]);
                        projection_ids_logical(projection_ids) = 1;
                        final_projections = find(~projection_ids_logical);
                        if ~isempty(strjoin(strsplit(num2str(final_projections)), ","))
                            command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(final_projections)), ",");
                        end
                    end
                    
                    if obj.configuration.set_up.gpu > 0
                        command = command + " -UseGPU " + obj.configuration.set_up.gpu;
                    end
                    executeCommand(command, false, obj.log_file_id);
                    
                    executeCommand("trimvol -rx " + tomogram_destination...
                        + " " + rotated_tomogram_destination, false, obj.log_file_id);
                    
                    if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                        createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "ctf_corrected_binned_tomograms_folder", obj.log_file_id);
                    else
                        createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "binned_tomograms_folder", obj.log_file_id);
                    end
                    
                    if obj.configuration.generate_exact_filtered_tomograms == true
                        disp("INFO: tomograms with exact filter (size: " + obj.configuration.exact_filter_size + ") will be generated.");
                        
                        exact_filtered_tomogram_destination = obj.output_path + string(filesep) + name + "_exact_filtered_full.rec";
                        
                        command = "tilt -InputProjections " + binned_aligned_tilt_stacks(j).folder + string(filesep) + binned_aligned_tilt_stacks(j).name...
                            + " -OutputFile " + exact_filtered_tomogram_destination...
                            + " -TILTFILE " + tlt_out_name...
                            + " -THICKNESS " + obj.configuration.reconstruction_thickness / splitted_binning...
                            + " -ExactFilterSize " + obj.configuration.exact_filter_size;
                        
                        if obj.configuration.set_up.gpu > 0
                            command = command + " -UseGPU " + obj.configuration.set_up.gpu;
                        end
                        
                        if isfield(obj.configuration, "exclude_lists") && isfield(obj.configuration.exclude_lists, name)
                            command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(name))), ",");
                        else
                            fid_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "fid");
                            executeCommand("model2point " + fid_files{1} + " " + obj.output_path + filesep + "fiducial.point", false, obj.log_file_id);
                            fiducials = dlmread(obj.output_path + filesep + "fiducial.point");
                            projection_ids = unique(fiducials(:,3)) + 1;
                            if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, strjoin(splitted_name(1:2), "_"))
                                previous_projection_ids_logical = obj.configuration.tomograms.(strjoin(splitted_name(1:2), "_")).tilt_index_angle_mapping(3,:);
                            else
                                previous_projection_ids_logical = obj.configuration.tilt_index_angle_mapping.(strjoin(splitted_name(1:2), "_"))(3,:);
                            end
                            previous_projection_ids_logical(previous_projection_ids_logical == 0) = [];
                            projection_ids_logical = zeros([1 length(previous_projection_ids_logical)]);
                            projection_ids_logical(projection_ids) = 1;
                            final_projections = find(~projection_ids_logical);
                            if ~isempty(strjoin(strsplit(num2str(final_projections)), ","))
                                command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(final_projections)), ",");
                            end
                        end
                        executeCommand(command, false, obj.log_file_id);
                        
                        exact_filtered_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_exact_filtered.rec";
                        executeCommand("trimvol -rx " + exact_filtered_tomogram_destination...
                            + " " + exact_filtered_rotated_tomogram_destination, false, obj.log_file_id);
                        if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                            createSymbolicLinkInStandardFolder(obj.configuration, exact_filtered_rotated_tomogram_destination, "exact_filtered_ctf_corrected_binned_tomograms_folder", obj.log_file_id);
                        else
                            createSymbolicLinkInStandardFolder(obj.configuration, exact_filtered_rotated_tomogram_destination, "exact_filtered_binned_tomograms_folder", obj.log_file_id);
                        end
                    end
                end
            end
        end
    end
end

