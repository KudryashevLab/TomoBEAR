classdef MotionCor2 < Module
    methods
        function obj = MotionCor2(configuration)
            obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "motion_corrected_files_folder", false);
        end
        
        function obj = process(obj)
            field_names = fieldnames(obj.configuration.tomograms);
            
            % TODO: check error messages and status
            [status_rmdir, message, message_id] = rmdir(obj.configuration.processing_path + string(filesep)...
                + obj.configuration.output_folder + string(filesep)...
                + obj.configuration.motion_corrected_files_folder + string(filesep) + field_names{obj.configuration.set_up.j}, "s");
            
            log_file_id_tmp = -1;
            
            mrc_list = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files;
            
            if  obj.configuration.method == "MotionCor2"
                [motion_corrected_files, symbolic_link_standard_folder] = obj.correctWithMotionCor2(mrc_list);
            else
                [motion_corrected_files, symbolic_link_standard_folder] =  obj.correctWithAlignFrames(mrc_list);
            end
            
            
            
            % TODO: check if next line is needed
            obj.dynamic_configuration.motioncor_output_postfix = obj.configuration.output_postfix;
            
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files = motion_corrected_files;
            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).motion_corrected_files_symbolic_links = symbolic_link_standard_folder;
            disp("INFO: Motion correction done!");
        end
        
        function [motion_corrected_files, symbolic_link_standard_folder] = correctWithMotionCor2(obj, mrc_list)
            % TODO: support for frame integration files
            field_names = fieldnames(obj.configuration.tomograms);

            % TODO: Look up default gain value for motioncorr2
            disp("INFO: Getting ready to process...");
            disp("INFO: Processing micrographs in " + obj.configuration.output_folder);
            motion_correction_arguments = "-Iter " + obj.configuration.iterations...
                + " -Tol " + obj.configuration.tolerance;
            
            if obj.configuration.set_up.gpu >  0
                motion_correction_arguments = motion_correction_arguments + " -Gpu " + (obj.configuration.set_up.gpu - 1)...
                    + " -GpuMemUsage " + obj.configuration.gpu_memory...
                    + " -UseGpus " + 1;
            else
                error("ERROR: Gpus are needed to run this module!");
            end
            
            motion_correction_arguments = motion_correction_arguments...
                ...%+ " -Patch " + obj.configuration.patch...
                + " -InFmMotion " + obj.configuration.in_fm_motion...
                + " -SumRange " + obj.configuration.sum_range(1) + " " + obj.configuration.sum_range(2)...
                + " -Outstack " + obj.configuration.outstack...
                + " -Bft " + obj.configuration.b_factor(1) + " " + obj.configuration.b_factor(2);
            
            if isfield(obj.configuration, "magnification_anisotropy_major_scale")...
                    && isfield(obj.configuration, "magnification_anisotropy_minor_scale")...
                    && isfield(obj.configuration, "magnification_anisotropy_major_axis_angle")...
                    && obj.configuration.magnification_anisotropy_major_axis_angle ~= 360
                motion_correction_arguments = motion_correction_arguments...
                    + " -Mag " + obj.configuration.magnification_anisotropy_major_scale...
                    + " " + obj.configuration.magnification_anisotropy_minor_scale...
                    + " " + obj.configuration.magnification_anisotropy_major_axis_angle;
            end
            motion_correction_arguments = motion_correction_arguments...
                    + " -kV " + obj.configuration.keV...
                    + " -PixSize " + obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix;
            if obj.configuration.apply_dose_weighting
                % TODO:NOTE: shouldn't the dose be a sum of frames
                motion_correction_arguments = motion_correction_arguments...
                    + " -FmDose " + obj.configuration.fm_dose;
            end
            
            % TODO: check if configuration.tilt even exists
            if obj.configuration.tilt ~= ""
                motion_correction_arguments = motion_correction_arguments...
                    + " -Tilt " + obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles(1) + " " + (obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles(2) - obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles(1));
            end
            
            
            % TODO: increase group for low dose images
            
            [output_folder, output_name, output_extension] = fileparts(obj.output_path);
            gain_correction_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.gain_correction_folder + string(filesep) + "gain_correction.mrc";
            gain_correction_path = dir(gain_correction_path);
            if obj.configuration.gain ~= ""
                [folder, name, extension] = fileparts(obj.configuration.gain);
                name_rep = strrep(name, " ", "\ ");
                gain_path =  folder + string(filesep) + name_rep + extension;
                if ~fileExists(output_folder + string(filesep) + name + ".mrc") && extension == ".dm4"
                    gain_path = output_folder + string(filesep) + name_rep + ".mrc";
                    executeCommand("dm2mrc -u " + folder + string(filesep) + name_rep + extension + " " + gain_path);
                elseif fileExists(output_folder + string(filesep) + name + ".mrc") && extension == ".dm4"
                    gain_path = output_folder + string(filesep) + name_rep + ".mrc";
                end
                
                motion_correction_arguments = motion_correction_arguments...
                    + " -Gain " + gain_path;
            elseif length(gain_correction_path) > 0
                motion_correction_arguments = motion_correction_arguments...
                    + " -Gain " + gain_correction_path(1).folder + string(filesep) + gain_correction_path(1).name;
            end
            
            if obj.configuration.ft_bin ~= 1
                motion_correction_arguments = motion_correction_arguments...
                    + " -FtBin " + obj.configuration.ft_bin;
            end

            % if obj.configuration.align ~= -1
                motion_correction_arguments = motion_correction_arguments...
                    + " -Align " + obj.configuration.align;
            % end            
            
            if obj.configuration.out_aln ~= ""
                motion_correction_arguments = motion_correction_arguments...
                    + " -OutAln " + obj.configuration.out_aln;
            end  

            if obj.configuration.gain ~= ""
                [folder, name, extension] = fileparts(obj.configuration.dark);
                name_rep = strrep(name, " ", "\ ");
                dark_path =  folder + string(filesep) + name_rep + extension;
                motion_correction_arguments = motion_correction_arguments...
                    + " -Dark " + dark_path;
            end
            
            
            if obj.configuration.defect ~= ""
                [folder, name, extension] = fileparts(obj.configuration.defect);
                name_rep = strrep(name, " ", "\ ");
                defect_path = output_folder + string(filesep) + name_rep + extension;
                if ~fileExists(output_folder + string(filesep) + name + ".txt") && extension == ".dm4"
                    if ~fileExists(output_folder + string(filesep) + name + ".mrc") && extension == ".dm4"
                        defect_path = output_folder + string(filesep) + name_rep + ".mrc";
                        executeCommand("dm2mrc -u " + folder + string(filesep) + name_rep + extension + " " + defect_path);
                        
                        defect_map = dread(output_folder + string(filesep) + name + ".mrc");
                        indices = find(defect_map);
                        [I, J] = ind2sub(size(defect_map),indices);
                        defect_path = output_folder + string(filesep) + name_rep + ".txt";
                        file_id = fopen(defect_path, "wt");
                        for i = 1:numel(I)
                            fprintf(file_id, "%s %s %s %s\n", num2str(I(i)), num2str(J(i)), num2str(1), num2str(1));
                        end
                    end
                elseif fileExists(output_folder + string(filesep) + name + ".txt") && extension == ".dm4"
                    defect_path = output_folder + string(filesep) + name_rep + ".txt";
                end
                
                motion_correction_arguments = motion_correction_arguments...
                    + " -DefectFile " + defect_path;
            elseif endsWith(obj.configuration.defect, ".txt")
                motion_correction_arguments = motion_correction_arguments...
                    + " -DefectFile " + obj.configuration.defect;
            end
            
            % TODO: remove if not needed
            % if isfield(configuration, "motion_corrected_files_folder")
            %     motion_corrected_files_folder = configuration.processing_path + string(filesep)...
            %     	+ configuration.output_folder + string(filesep)...
            %         + configuration.motion_corrected_files_folder;
            %     if exist(motion_corrected_files_folder, "dir")
            %         % TODO: add checks
            %         rmdir(motion_corrected_files_folder, "s");
            %     end
            %     % TODO: add checks
            % 	mkdir(motion_corrected_files_folder);
            % end
            
            % TODO: make motioncor command in parallel
            previous_path_parts_end = "";
            for i = 1:length(mrc_list)
                disp("INFO: Processing " + mrc_list(i) + "...");
                
                mrc_input = mrc_list{i};
                
                %     if regexp(mrc_input, "_[-+]0.0_")
                %         executeCommand("newstack -exclude 5-79 " + mrc_input + " test.mrc")
                %         mrc_input = mrc_list(i).folder + string(filesep) +
                %     end
                % TODO: Handle unused variables
                [path, name, extension] = fileparts(mrc_input);
                path_parts = strsplit(path, string(filesep));
                
                % TODO: decide if the condition "isfield(configuration,
                % "motion_corrected_files_folder")" is needed since standardized
                % folders are mandatory
                if string(previous_path_parts_end) ~= string(field_names{obj.configuration.set_up.j}) && isfield(obj.configuration, "motion_corrected_files_folder")
                    previous_path_parts_end = field_names{obj.configuration.set_up.j};
                    mkdir(obj.configuration.processing_path + string(filesep)...
                        + obj.configuration.output_folder + string(filesep)...
                        + obj.configuration.motion_corrected_files_folder + string(filesep) + field_names{obj.configuration.set_up.j});
                end
                
                %                 previous_step_output_folder_parts = strsplit(obj.configuration.previous_step_output_folder, string(filesep));
                
                %                 if field_names{obj.configuration.set_up.j} ~= previous_step_output_folder_parts(end)
                %                     [status_mkdir, message] = mkdir(obj.output_path + string(filesep) + field_names{obj.configuration.set_up.j});
                %                     if status_mkdir ~= 1
                %                         error("ERROR: Can't create tomogram folder for script output!");
                %                     end
                %                     output_folder = obj.output_path + string(filesep) + field_names{obj.configuration.set_up.j};
                %                 else
                %                     output_folder = obj.output_path;
                %                 end
                
                output_folder = obj.output_path;
                
                % TODO: is the output_postfix needed? makes
                % createSymbolicLinkInStandardFolder more complicated
                %mrc_output = output_folder + string(filesep) + name + "_" + configuration.output_postfix + ".mrc";
                mrc_output = output_folder + string(filesep) + name + ".mrc";
                
                motion_correction_output = output_folder + string(filesep) + name + "_" + obj.configuration.output_postfix + ".stdout";
                motion_correction_log = output_folder + string(filesep) + name + "_" + obj.configuration.output_postfix + ".log";
                
               [width, height, last_frame] = getHeightAndWidthFromHeader(mrc_list(i), obj.log_file_id);
%                 % TODO: Redo in matlab style or use just pixel size flag
%                 command = "header -s " + mrc_list(i) + " | cut -c17-";
% %                 output_header{i} = executeCommand(command, false, obj.log_file_id);
%                 [status, output_header{i}] = executeCommand(command, false, obj.log_file_id);
%                 
%                 % NOTE: dirty hack :)
%                 string_char = str2double(output_header{i});
%                 
%                 last_frame = string_char(end - 1);
                [~, ~, extension] = fileparts(mrc_input);
                if extension == ".tif"
                    command = obj.configuration.motion_correction_command...
                        + " -InTiff " + mrc_input;
                else
                    command = obj.configuration.motion_correction_command...
                        + " -InMrc " + mrc_input;
                end

                command = command...
                    + " -OutMrc " + mrc_output...
                    + " " + motion_correction_arguments + " "...
                    + " -LogFile " + motion_correction_log;

                if obj.configuration.fm_ref ~= ""
                    command = command...                    
                        + " -FmRef " + obj.configuration.fm_ref;
                else
                    command = command...                    
                        + " -FmRef " + last_frame;
                end

                if ~isempty(regexp(mrc_input, "_[-+]*0+\.0", "match")) && isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "high_dose") && obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).high_dose == true
                    command = command...
                        + " -Patch " + obj.configuration.patch;
                else
                    command = command...
                        + " -Patch " + "1 1";
                    % TODO:NOTE: group makes crash
                    if obj.configuration.group ~= 1
                        command = command...
                            + " -Group " + string(num2str(obj.configuration.group));
                    end
                end
                
                command = command...
                    + " | tee " + motion_correction_output...
                    + " | grep -e Start -e completed -e time -e MotionCor2:";
                %                 while true
                %                     try
                output_motioncor2{i} = executeCommand(command, false, obj.log_file_id);
                %                        break;
                %                     catch exception
                %                         error("ERROR: MotionCor2 failed... retrying!")
                %                     end
                %                 end
                [output_symbolic_link_standard_folder, symbolic_link_standard_folder(i)] = createSymbolicLinkInStandardFolder(obj.configuration, mrc_output, "motion_corrected_files_folder", obj.log_file_id);
                %     if isfield(configuration, "motion_corrected_files_folder")
                %         destination = configuration.processing_path + string(filesep)...
                %         + configuration.output_folder + string(filesep)...
                %         + configuration.motion_corrected_files_folder + string(filesep)...
                %         + path_parts(end) + string(filesep) + name + ".mrc";
                %         createSymbolicLink(mrc_output, destination, obj.log_file_id);
                %     end
                motion_corrected_files{i} = mrc_output;
            end
        end
        
        function [motion_corrected_files, symbolic_link_standard_folder] = correctWithAlignFrames(obj, mrc_list)
            error("ERROR: alignframes fall back not implemented yet");
            % TODO: Look up default gain value for motioncorr2
            disp("INFO: Getting ready to process...");
            disp("INFO: Processing micrographs in " + obj.configuration.output_folder);
            motion_correction_arguments = "-Iter " + obj.configuration.iterations...
                + " -Tol " + obj.configuration.tolerance;
            
            if obj.configuration.gpu == -1 && gpuDeviceCount > 0
                gpu_number = mod(obj.configuration.set_up.j, obj.configuration.environment_properties.gpu_count);
                motion_correction_arguments = motion_correction_arguments + " -Gpu " + gpu_number...
                    + " -GpuMemUsage " + obj.configuration.gpu_memory...
                    + " -UseGpus " + 1;
                %elseif obj.configuration.gpu == 99
            elseif gpuDeviceCount >= obj.configuration.gpu && obj.configuration.gpu ~= -1
                motion_correction_arguments = motion_correction_arguments + " -Gpu " + obj.configuration.gpu...
                    + " -GpuMemUsage " + obj.configuration.gpu_memory...
                    + " -UseGpus " + 1;
            else
                error("ERROR: gpus are needed to run this module");
            end
            
            motion_correction_arguments = motion_correction_arguments...
                + " -Patch " + obj.configuration.patch...
                + " -Outstack " + obj.configuration.outstack...
                + " -Bft " + obj.configuration.b_factor(1) + " " + obj.configuration.b_factor(2);
            
            if isfield(obj.configuration, "magnification_anisotropy_major_scale")...
                    && isfield(obj.configuration, "magnification_anisotropy_minor_scale")...
                    && isfield(obj.configuration, "magnification_anisotropy_major_axis_angle")...
                    && obj.configuration.magnification_anisotropy_major_axis_angle ~= 360
                motion_correction_arguments = motion_correction_arguments...
                    + " -Mag " + obj.configuration.magnification_anisotropy_major_scale...
                    + " " + obj.configuration.magnification_anisotropy_minor_scale...
                    + " " + obj.configuration.magnification_anisotropy_major_axis_angle;
            end
            
            if obj.configuration.apply_dose_weighting
                motion_correction_arguments = motion_correction_arguments...
                    + " -kV " + obj.configuration.keV...
                    + " -PixSize " + obj.configuration.apix...
                    + " -FmDose " + obj.configuration.fm_dose;
            end
            
            % TODO: check if configuration.tilt even exists
            if obj.configuration.tilt ~= ""
                motion_correction_arguments = motion_correction_arguments...
                    + " -Tilt " + obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles(1) + " " + (obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles(2) - obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).angles(1));
            end
            
            [output_folder, output_name, output_extension] = fileparts(obj.output_path);
            gain_correction_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.gain_correction_folder + string(filesep) + "gain_correction.mrc";
            gain_correction_path = dir(gain_correction_path);
            if obj.configuration.gain ~= ""
                [folder, name, extension] = fileparts(obj.configuration.gain);
                name_rep = strrep(name, " ", "\ ");
                gain_path =  folder + string(filesep) + name_rep + extension;
                if ~fileExists(output_folder + string(filesep) + name + ".mrc") && extension == ".dm4"
                    gain_path = output_folder + string(filesep) + name_rep + ".mrc";
                    executeCommand("dm2mrc -u " + folder + string(filesep) + name_rep + extension + " " + gain_path);
                elseif fileExists(output_folder + string(filesep) + name + ".mrc") && extension == ".dm4"
                    gain_path = output_folder + string(filesep) + name_rep + ".mrc";
                end
                
                motion_correction_arguments = motion_correction_arguments...
                    + " -Gain " + gain_path;
            elseif length(gain_correction_path) > 0
                motion_correction_arguments = motion_correction_arguments...
                    + " -Gain " + gain_correction_path(1).folder + string(filesep) + gain_correction_path(1).name;
            end
            
            if obj.configuration.ft_bin ~= 1
                motion_correction_arguments = motion_correction_arguments...
                    + " -FtBin " + obj.configuration.ft_bin;
            end
            
            if obj.configuration.defect ~= ""
                [folder, name, extension] = fileparts(obj.configuration.defect);
                name_rep = strrep(name, " ", "\ ");
                defect_path = output_folder + string(filesep) + name_rep + extension;
                if ~fileExists(output_folder + string(filesep) + name + ".txt") && extension == ".dm4"
                    if ~fileExists(output_folder + string(filesep) + name + ".mrc") && extension == ".dm4"
                        defect_path = output_folder + string(filesep) + name_rep + ".mrc";
                        executeCommand("dm2mrc -u " + folder + string(filesep) + name_rep + extension + " " + defect_path);
                        
                        defect_map = dread(output_folder + string(filesep) + name + ".mrc");
                        indices = find(defect_map);
                        [I, J] = ind2sub(size(defect_map),indices);
                        defect_path = output_folder + string(filesep) + name_rep + ".txt";
                        file_id = fopen(defect_path, "wt");
                        for i = 1:numel(I)
                            fprintf(file_id, "%s %s %s %s\n", num2str(I(i)), num2str(J(i)), num2str(1), num2str(1));
                        end
                    end
                elseif fileExists(output_folder + string(filesep) + name + ".txt") && extension == ".dm4"
                    defect_path = output_folder + string(filesep) + name_rep + ".txt";
                end
                
                motion_correction_arguments = motion_correction_arguments...
                    + " -DefectFile " + defect_path;
            end
            
            previous_path_parts_end = "";
            for i = 1:length(mrc_list)
                disp("INFO: Processing " + mrc_list(i) + "...");
                
                mrc_input = mrc_list{i};
                
                [path, name, extension] = fileparts(mrc_input);
                path_parts = strsplit(path, string(filesep));
                
                if string(previous_path_parts_end) ~= string(field_names{obj.configuration.set_up.j}) && isfield(obj.configuration, "motion_corrected_files_folder")
                    previous_path_parts_end = field_names{obj.configuration.set_up.j};
                    mkdir(obj.configuration.processing_path + string(filesep)...
                        + obj.configuration.output_folder + string(filesep)...
                        + obj.configuration.motion_corrected_files_folder + string(filesep) + field_names{obj.configuration.set_up.j});
                end
                
                output_folder = obj.output_path;
                
                mrc_output = output_folder + string(filesep) + name + ".mrc";
                
                motion_correction_output = output_folder + string(filesep) + name + "_" + obj.configuration.output_postfix + ".stdout";
                motion_correction_log = output_folder + string(filesep) + name + "_" + obj.configuration.output_postfix + ".log";
                
                
                % TODO: Redo in matlab style or use just pixel size flag
                command = "header -s " + mrc_list(i) + " | cut -c17-";
                output_header{i} = executeCommand(command, false, obj.log_file_id);
                
                % NOTE: dirty hack :)
                string_char = char(output_header{i});
                
                last_frame = string_char(end - 1);
                [~, ~, extension] = fileparts(mrc_input);
                if extension == ".tif"
                    command = obj.configuration.motion_correction_command...
                        + " -InTiff " + mrc_input;
                else
                    command = obj.configuration.motion_correction_command...
                        + " -InMrc " + mrc_input;
                end
                command = command...
                    + " -OutMrc " + mrc_output...
                    + " " + motion_correction_arguments + " "...
                    + " -FmRef " + last_frame...
                    + " -LogFile " + motion_correction_log;
                if ~isempty(regexp(mrc_input, "_[-+]*0+\.0", "match")) && isfield(obj.configuration, "high_dose") && obj.configuration.high_dose == true
                    command = command...
                        + " -Patch " + obj.configuration.patch;
                else
                    command = command...
                        + " -Patch " + "1 1";
                    if obj.configuration.group ~= 1
                        command = command...
                            + " -Group " + string(num2str(obj.configuration.group));
                    end
                end
                
                output_alignframes{i} = executeCommand(command, false, obj.log_file_id);
                
                [output_symbolic_link_standard_folder, symbolic_link_standard_folder(i)] = createSymbolicLinkInStandardFolder(obj.configuration, mrc_output, "motion_corrected_files_folder", obj.log_file_id);
                
                motion_corrected_files{i} = mrc_output;
            end
        end
        
        function obj = cleanUp(obj)
            if obj.configuration.keep_intermediates == false
                field_names = fieldnames(obj.configuration.tomograms);
                for i = 1:length(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files)
                    %                 [success, message,message_id] =
                    delete(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files{i});
                end
                
                for i = 1:length(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files_symbolic_links)
                    %                 [success, message,message_id] =
                    delete(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files_symbolic_links{i});
                end
                
                [folder, name, extension] = fileparts(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).raw_files_symbolic_links{1});
                [success, message,message_id] = rmdir(folder, "s");
                [folder, name, extension] = fileparts(folder);
                if isempty(dir(folder))
                    [success, message,message_id] = rmdir(folder, "s");
                end
                
                gain_correction_output_path = obj.configuration.processing_path...
                    + string(filesep) + obj.configuration.output_folder...
                    + string(filesep) + "*"...
                    + string(filesep) + "gain_correction.mrc";
                
                gain_correction = dir(gain_correction_output_path);
                if ~isempty(gain_correction)
                    for i = 1:length(gain_correction)
                        delete(gain_correction(i).folder + string(filesep) + gain_correction(i).name);
                    end
                end
            end
            obj = cleanUp@Module(obj);
        end
    end
end
