classdef BinStacks < Module
    methods
        function obj = BinStacks(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "binned_aligned_tilt_stacks_folder", false);
            createStandardFolder(obj.configuration, "binned_tilt_stacks_folder", false);
            createStandardFolder(obj.configuration, "ctf_corrected_binned_aligned_tilt_stacks_folder", false);
        end
        
        function obj = process(obj)
            field_names = fieldnames(obj.configuration.tomograms);
            disp("INFO: Creating binned aligned stacks...");

            if isfield(obj.configuration, "apix")
                apix = obj.configuration.apix * obj.configuration.ft_bin;
            else
                apix = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix * obj.configuration.ft_bin;
            end
            integer_check = true;
            for i = 1:length(obj.configuration.binnings)
                if (obj.configuration.binnings(i) / obj.configuration.aligned_stack_binning) > 1 ...
                    && (~isinf(obj.configuration.binnings(i)) & floor(obj.configuration.binnings(i)) == obj.configuration.binnings(i))...
                    && (~isinf(obj.configuration.binnings(i) / obj.configuration.aligned_stack_binning) & floor(obj.configuration.binnings(i) / obj.configuration.aligned_stack_binning) == obj.configuration.binnings(i) / obj.configuration.aligned_stack_binning)
                    integer_check = false;
                    if obj.configuration.use_ctf_corrected_aligned_stack == true
                        obj.configuration.run_ctf_phaseflip = true;
                    end
                end
            end
            if obj.configuration.use_ctf_corrected_aligned_stack == true && integer_check == true
                
                if obj.configuration.aligned_stack_binning > 1
                    tilt_stacks_path = obj.configuration.processing_path...
                        + string(filesep) + obj.configuration.output_folder...
                        + string(filesep) + obj.configuration.ctf_corrected_binned_aligned_tilt_stacks_folder;
                    
                    % TODO: better take obj.output_path
                    output_path_splitted = strsplit(obj.output_path, "/");
                    name = output_path_splitted(end);
                    tilt_stacks_path = tilt_stacks_path...
                        + string(filesep) + name;
                    
                    tilt_stacks_path = tilt_stacks_path + string(filesep) + "*.ali";
                    
                    tilt_stacks = dir(tilt_stacks_path);
                    for i = 1:length(obj.configuration.binnings)
                        if obj.configuration.aligned_stack_binning == obj.configuration.binnings(i)
                            continue;
                        end
                        tilt_stacks = tilt_stacks(~contains({tilt_stacks.name}, "bin_" + num2str(obj.configuration.binnings(i))));
                    end
                    tilt_stacks = tilt_stacks(1).folder + string(filesep) + tilt_stacks(1).name;
                    
                else
                    tilt_stacks = getFilePathsFromLastBatchruntomoRun(obj.configuration, "ali");
                    tilt_stacks = tilt_stacks{1};
                end

                destination_path = obj.output_path;
                [status_mkdir, message, message_id] = mkdir(destination_path);
                
                stack_source = tilt_stacks;
                
                for j = 1:length(obj.configuration.binnings)
                    if obj.configuration.binnings(j) == obj.configuration.aligned_stack_binning
                        continue;
                    end
                    
                    bin_factor = obj.configuration.binnings(j) / (obj.configuration.aligned_stack_binning / obj.configuration.ft_bin);
                    binned_stack_suffix = "bin_" + num2str(bin_factor * obj.configuration.aligned_stack_binning * obj.configuration.ft_bin);
                    disp("INFO: Creating " + name + "_" + binned_stack_suffix + ".ali...");
                    stack_output_path = obj.output_path + string(filesep) + name + "_" + binned_stack_suffix + ".ali";
                    obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).binned_stacks{j} = stack_output_path;
                    executeCommand("newstack"...
                        + " -input " + stack_source...
                        + " -output " + stack_output_path...
                        + " -antialias " + obj.configuration.antialias_filter...
                        + " -bin " + num2str(bin_factor), false, obj.log_file_id);
                    
                    [output_binned_stacks_symbolic_links, obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).binned_stacks_symbolic_links{j}] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path, "ctf_corrected_binned_aligned_tilt_stacks_folder", obj.log_file_id);
                end
            else
                tilt_stacks = getTiltStacks(obj.configuration, true);
                tilt_stacks = tilt_stacks(contains({tilt_stacks(:).folder}, sprintf("tomogram_%03d", obj.configuration.set_up.j)));
                
                if isempty(tilt_stacks)
                    obj.status = 0;
                    return;
                end
                
                xf_file_paths = getFilePathsFromLastBatchruntomoRun(obj.configuration, "xf");

                [path, name, extension] = fileparts(tilt_stacks.name);

                xf_file_source = xf_file_paths{1};

                xf_file_destination = obj.output_path + string(filesep) + name + ".xf";
                
                obj.temporary_files(end + 1) = createSymbolicLink(xf_file_source, xf_file_destination, obj.log_file_id);
                
                stack_source = tilt_stacks.folder + string(filesep) + tilt_stacks.name;
                stack_destination = obj.output_path + string(filesep) + name + ".st";
                obj.temporary_files(end + 1) = createSymbolicLink(stack_source, stack_destination, obj.log_file_id);
                
                for j = 1:length(obj.configuration.binnings)
                    binned_stack_suffix = "bin_" + num2str(obj.configuration.binnings(j));
                    disp("INFO: Creating " + name + "_" + binned_stack_suffix + ".ali...");
                    stack_output_path = obj.output_path + string(filesep) + name + "_" + binned_stack_suffix + ".ali";
                    obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).binned_stacks{j} = stack_output_path;
                    [width, height, z] = getHeightAndWidthFromHeader(stack_destination, -1);
                    executeCommand("newstack"...
                        + " -size " + floor(height / (obj.configuration.binnings(j) / obj.configuration.ft_bin)) + "," + floor(width / (obj.configuration.binnings(j) / obj.configuration.ft_bin))...
                        + " -input " + stack_destination...
                        + " -output " + stack_output_path...
                        + " -xform " + xf_file_destination...
                        + " -antialias " + obj.configuration.antialias_filter...
                        + " -bin " + num2str(obj.configuration.binnings(j) / obj.configuration.ft_bin), false, obj.log_file_id);
                    
                    if obj.configuration.binnings(j) > 1
                        [output_binned_stacks_symbolic_links, obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).binned_stacks_symbolic_links{j}] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path, "binned_aligned_tilt_stacks_folder", obj.log_file_id);
                    else
                        [output_stacks_symbolic_links, obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).stacks_symbolic_links{j}] = createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path, "aligned_tilt_stacks_folder", obj.log_file_id);    
                    end
                    
                    if obj.configuration.run_ctf_phaseflip == true
                        tlt_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "rawtlt");
                        defocus_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "defocus");
                        splitted_tilt_stack_path_name = strsplit(stack_output_path, ".");
                        ctf_corrected_stack_destination = splitted_tilt_stack_path_name(1)...
                            + "_" + obj.configuration.ctf_corrected_stack_suffix...
                            + "." + splitted_tilt_stack_path_name(2);
                        
                        command = "ctfphaseflip -input " + stack_output_path...
                            + " -output " + ctf_corrected_stack_destination...
                            + " -angleFn " + tlt_file{1}...
                            + " -defFn " + defocus_file{1}...
                            + " -defTol " + obj.configuration.defocus_tolerance...
                            + " -iWidth " + obj.configuration.iWidth...
                            + " -maxWidth " + height...
                            + " -pixelSize " + apix * obj.configuration.binnings(j)...
                            + " -volt " + obj.configuration.keV...
                            + " -cs " + obj.configuration.spherical_aberation...
                            + " -ampContrast " + obj.configuration.ampContrast;
                        
                        if obj.configuration.use_aligned_stack == false
                            command = command + " -xform " + xf_file_destination;
                        end
                        
                        if obj.configuration.set_up.gpu > 0 && versionGreaterThan(obj.configuration.environment_properties.imod_version, "4.10.9")
                            command = command + " -gpu " + obj.configuration.set_up.gpu;
                        end
                        
                        executeCommand(command, false, obj.log_file_id);
                        %TODO: put in ctf corrected stacks folder
                        if obj.configuration.binnings(j) > 1
                            createSymbolicLinkInStandardFolder(obj.configuration, ctf_corrected_stack_destination, "ctf_corrected_binned_aligned_tilt_stacks_folder", obj.log_file_id, true);
                        else
                            createSymbolicLinkInStandardFolder(obj.configuration, ctf_corrected_stack_destination, "ctf_corrected_aligned_tilt_stacks_folder", obj.log_file_id, true);
                        end
                    end
                    if isfield(obj.configuration, "reconstruct_tomograms") && obj.configuration.reconstruct_tomograms == true
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
                    end
                end
            end
            disp("INFO: Binning stacks done!");
        end
    end
end

