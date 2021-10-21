classdef TomoAlign < Module
    methods
        function obj = TomoAlign(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)            
            if (isfield(obj.configuration, "use_tomowarpalign") && obj.configuration.use_tomowarpalign == true)
                resid_file_paths = getFilePathsFromLastBatchruntomoRun(obj.configuration, "resid");
                align_com_file_paths = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, "align.com");
                newst_com_file_paths = getFilesWithMatchingPatternFromLastBatchruntomoRun(obj.configuration, "newst.com");
            end
            
            if (isfield(obj.configuration, "use_tomowarpalign") && obj.configuration.use_tomowarpalign == true)...
                    || (isfield(obj.configuration, "use_aligned_stack") && obj.configuration.use_aligned_stack == true)
                tltxf_file_paths = getTltxfFilePaths(obj.configuration);
            end
            
            fid_file_paths = getFidFilePaths(obj.configuration);
            tlt_file_paths = getFilePathsFromLastBatchruntomoRun(obj.configuration, "tlt");
            xf_file_paths = getFilePathsFromLastBatchruntomoRun(obj.configuration, "xf");
            if isfield(obj.configuration, "use_aligned_stack") && obj.configuration.use_aligned_stack == true
                
                ali_file_paths = getFilePathsFromLastBatchruntomoRun(obj.configuration, "ali");
            elseif (isfield(obj.configuration, "use_aligned_stack") && obj.configuration.use_aligned_stack == false)...
                    || ((isfield(obj.configuration, "use_tomowarpalign") && obj.configuration.use_tomowarpalign == true))
                prexg_file_paths = getFilePathsFromLastBatchruntomoRun(obj.configuration, "prexg");
                tilt_stacks = getTiltStacksFromStandardFolder(obj.configuration, true);
            else
                disp("ERROR: Not possible case!");
            end
            
            
            for i = 1:length(fid_file_paths)
                [path, name, extension] = fileparts(fid_file_paths{i});
                % TODO: add checks
                output_destination = output_path + string(filesep) + name;
                mkdir(output_destination);
                if isfield(obj.configuration, "use_tomowarpalign") && obj.configuration.use_tomowarpalign == false
                    if isfield(obj.configuration, "use_aligned_stack") && obj.configuration.use_aligned_stack == true
                        createSymbolicLink(ali_file_paths{i}, output_destination + string(filesep) + name + ".ali", log_file_id);
                        createSymbolicLink(tltxf_file_paths{i}, output_destination + string(filesep) + name + ".tiltxf", log_file_id);
                        createSymbolicLink(fid_file_paths{i}, output_destination + string(filesep) + name + ".fid", log_file_id);
                        % IMPORTANT:NOTE: if the aligned tiltseries (.ali) is binned with regard to the prealigned one (.preali),
                        %   you may need to use the -S option of the imodtrans program (see IMOD manual).
                        fid_ali_output = output_destination + string(filesep) + name + "_ali.fid";
                        executeCommand("imodtrans "...
                            + " -i " + ali_file_paths{i}...
                            + " -2 " + tltxf_file_paths{i}...
                            + " " + fid_file_paths{i}...
                            + " " + fid_ali_output, log_file_id);
                        if isfield(obj.configuration, "show_transformed_fiducial_model") && obj.configuration.show_transformed_fiducial_model == true
                            executeCommand("3dmod " + " " + ali_file_paths{i} + " " + fid_ali_output);
                        end
                        fid_output = fid_ali_output + ".txt";
                        output = executeCommand("model2point -object -float " + fid_ali_output + " " + fid_output);
                        
                    else
                        createSymbolicLink(tilt_stacks(i).folder + string(filesep) + tilt_stacks(i).name, output_destination + string(filesep) + name + ".st", log_file_id);
                        createSymbolicLink(prexg_file_paths{i}, output_destination + string(filesep) + name + ".tiltxf", log_file_id);
                        createSymbolicLink(fid_file_paths{i}, output_destination + string(filesep) + name + ".fid", log_file_id);
                        
                        prexg_inverse_output = output_destination + string(filesep) + name + "_inverse.prexg";
                        executeCommand("xfinverse "...
                            + " " + prexg_file_paths{i}...
                            + " " + prexg_inverse_output);
                        fid_st_output = output_destination + string(filesep) + name + "_st.fid";
                        executeCommand("imodtrans "...
                            + " -i " + tilt_stacks(i).folder + string(filesep) + tilt_stacks(i).name...
                            + " -2 " + prexg_inverse_output ...
                            + " " + fid_file_paths{i}...
                            + " " + fid_st_output);
                        fid_output = fid_st_output + ".txt";
                        output = executeCommand("model2point -object -float " + fid_st_output + " " + fid_output);
                        
                    end
                    tomoalign_command = "tomoalign "...
                        + " -a " + fid_output...
                        + " -i " + tlt_file_paths{i}...
                        + " -o " + name + ".alignment";
                    
                    if isfield(obj.configuration, "optimize_alignment") && obj.configuration.optimize_alignment ~= ""
                        
                        tomoalign_command = tomoalign_command...
                            + " -A " + obj.configuration.optimize_alignment;
                        
                        if contains(obj.configuration.optimize_alignment, "r")
                            if isfield(obj.configuration, "intitial_rotation_angle")
                                tomoalign_command = tomoalign_command...
                                    + " -r " + obj.configuration.optimize_alignment;
                            else
                                disp("ERROR: No parameter (intitial_rotation_angle) for intitial rotation angle is given!")
                            end
                        end
                    else
                        tomoalign_command = tomoalign_command...
                            + " -I " + xf_file_paths{i};
                    end
                    
                    if isfield(obj.configuration, "reference_image_in_degreese")
                        tomoalign_command = tomoalign_command...
                            + " -R " + obj.configuration.reference_image_in_degreese;
                    end
                    
                    if isfield(obj.configuration, "leave_one_out_test") && obj.configuration.leave_one_out_test == true
                        tomoalign_command = tomoalign_command...
                            + " -l ";
                    end
                    
                    if isfield(obj.configuration, "sample_thickness") && obj.configuration.sample_thickness ~= ""
                        tomoalign_command = tomoalign_command...
                            + " -t " + obj.configuration.sample_thickness;
                    end
                    
                    if isfield(obj.configuration, "use_splines") && obj.configuration.use_splines == true
                        tomoalign_command = tomoalign_command...
                            + " -s ";
                    else
                        if isfield(obj.configuration, "use_3d_motion") && obj.configuration.use_3d_motion == true
                            tomoalign_command = tomoalign_command...
                                + " -3 ";
                        end
                        if isfield(obj.configuration, "polynomial_order_in_x") && obj.configuration.polynomial_order_in_x == true
                            tomoalign_command = tomoalign_command...
                                + " -x " + obj.configuration.polynomial_order_in_x;
                        end
                        
                        if isfield(obj.configuration, "polynomial_order_in_y") && obj.configuration.polynomial_order_in_y == true
                            tomoalign_command = tomoalign_command...
                                + " -y " + obj.configuration.polynomial_order_in_y;
                        end
                        
                        if isfield(obj.configuration, "polynomial_order_in_z") && obj.configuration.polynomial_order_in_z == true
                            tomoalign_command = tomoalign_command...
                                + " -z " + obj.configuration.polynomial_order_in_z;
                        end
                        
                        if isfield(obj.configuration, "polynomial_order_for_x_motion") && obj.configuration.polynomial_order_for_x_motion == true
                            tomoalign_command = tomoalign_command...
                                + " -X " + obj.configuration.polynomial_order_for_x_motion;
                        end
                        
                        if isfield(obj.configuration, "polynomial_order_for_y_motion") && obj.configuration.polynomial_order_for_y_motion == true
                            tomoalign_command = tomoalign_command...
                                + " -Y " + obj.configuration.polynomial_order_for_y_motion;
                        end
                        
                        if isfield(obj.configuration, "polynomial_order_for_z_motion") && obj.configuration.polynomial_order_for_z_motion == true
                            tomoalign_command = tomoalign_command...
                                + " -Z " + obj.configuration.polynomial_order_for_z_motion;
                        end
                        
                        if isfield(obj.configuration, "remove_mixed_polynomial_terms") && obj.configuration.remove_mixed_polynomial_terms ~= ""
                            tomoalign_command = tomoalign_command...
                                + " -m " + obj.configuration.remove_mixed_polynomial_terms;
                        end
                    end
                    
                    
                    if isfield(obj.configuration, "use_aligned_stack") && obj.configuration.use_aligned_stack == true
                        tomoalign_command = tomoalign_command...
                            + " -b " + obj.configuration.aligned_stack_binning / obj.configuration.ft_bin;
                    end
                    
                    output = executeCommand(tomoalign_command);
                else
                    return_path = cd(output_destination);
                    [folder, name, extension] = fileparts(resid_file_paths{i});
                    resid_link_path = output_destination + string(filesep) + name + extension;
                    createSymbolicLink(resid_file_paths{i}, resid_link_path, log_file_id);
                    
                    align_com_file_path = align_com_file_paths{i}.folder + string(filesep) + align_com_file_paths{i}.name;
                    [folder, name, extension] = fileparts(align_com_file_path);
                    align_com_link_path = output_destination + string(filesep) + name + extension;
                    createSymbolicLink(align_com_file_path, align_com_link_path, log_file_id);
                    
                    [folder, name, extension] = fileparts(prexg_file_paths{i});
                    prexg_link_path = output_destination + string(filesep) + name +  extension;
                    createSymbolicLink(prexg_file_paths{i}, prexg_link_path, log_file_id);
                    
                    [folder, name, extension] = fileparts(tltxf_file_paths{i});
                    tltxf_link_path = output_destination + string(filesep) + name + extension;
                    createSymbolicLink(tltxf_file_paths{i}, tltxf_link_path, log_file_id);
                    
                    [folder, name, extension] = fileparts(xf_file_paths{i});
                    xf_link_path = output_destination + string(filesep) + name + extension;
                    createSymbolicLink(xf_file_paths{i}, xf_link_path, log_file_id);
                    
                    newst_com_file_path = newst_com_file_paths{i}.folder + string(filesep) + newst_com_file_paths{i}.name;
                    [folder, name, extension] = fileparts(newst_com_file_path);
                    newst_com_link_path = output_destination + string(filesep) + name + extension;
                    createSymbolicLink(newst_com_file_path, newst_com_link_path, log_file_id);
                    
                    tilt_stack_file_path = tilt_stacks(i).folder + string(filesep) + tilt_stacks(i).name;
                    [folder, name, extension] = fileparts(tilt_stack_file_path);
                    tilt_stack_link_path = output_destination + string(filesep) + name + extension;
                    createSymbolicLink(tilt_stack_file_path, tilt_stack_link_path, log_file_id);
                    
                    
                    tomowarpalign_command = "tomowarpalign "...
                        + " -a " + align_com_link_path...
                        + " -n " + newst_com_link_path;
                    %           + " -t " + tilt_stack_link_path;
                    
                    if isfield(obj.configuration, "warp_image_range") && ~isempty(obj.configuration.warp_image_range)
                        tomowarpalign_command = tomowarpalign_command...
                            + warp_image_range;
                    end
                    
                    output = executeCommand(tomowarpalign_command);
                    cd(return_path);
                end
                
                if isfield(obj.configuration, "reconstruct") && obj.configuration.reconstruct == true
                    output = executeCommand("tomorec");
                end
            end
        end
    end
end

