% https://drive.google.com/drive/folders/1Z7pKVEdgMoNaUmd_cOFhlt-QCcfcwF3_
classdef AreTomo < Module
    methods
        function obj = AreTomo(configuration)
            obj = obj@Module(configuration);
        end

        function obj = setUp(obj)
            obj = setUp@Module(obj);
        end

        function obj = process(obj)
            
            if obj.configuration.input_stack_binning > 1
                tilt_stacks = getBinnedTiltStacksFromStandardFolder(obj.configuration, true);
                tilt_stacks = tilt_stacks(contains({tilt_stacks.name}, "bin_" + num2str(obj.configuration.input_stack_binning)));
            else
                tilt_stacks = getTiltStacksFromStandardFolder(obj.configuration, true);
            end
            
%             if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
%                 even_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
%                 odd_tilt_stacks = getOddTiltStacksFromStandardFolder(obj.configuration, true);
%             end
% 
%             if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                 dose_weighted_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
%             end
% 
%             if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                 dose_weighted_sum_tilt_stacks = getDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%             end

            %if obj.configuration.weighted_back_projection == true
            %    wbp = 1;
            %end
            % TODO:NOTE: implement ROI reconstructions or is it not needed when
            % substacks or pseudo subtomograms are aligned?

            % TODO:NOTE: implement reconstruct aligned tilt series

            min_and_max_tilt_angles = getTiltAngles(obj.configuration);
            %             if false == true %length(min_and_max_tilt_angles) > 2
            fid = fopen(obj.output_path + filesep + obj.name + ".rawtlt", "w+");
            for i = 1:length(min_and_max_tilt_angles)
                if ~isempty(obj.configuration.dose_order)
                    if obj.configuration.dose > 0
                        dose_per_projection = obj.configuration.dose / length(min_and_max_tilt_angles);
                    else
                        dose_per_projection = 1;
                    end
                    fprintf(fid, "%s %s\n", num2str(min_and_max_tilt_angles(i)), num2str(dose_per_projection * obj.configuration.dose_order(i)));
                else
                    fprintf(fid, "%s\n", num2str(min_and_max_tilt_angles(i)));
                end
            end
            angular_file_command_snippet = "-AngFile " + obj.output_path + filesep + obj.name + ".rawtlt";
            %             else
            %angle_command_snippet = "-TiltRange " + min_and_max_tilt_angles(1) + " " + min_and_max_tilt_angles(end);
            
            if obj.configuration.patch ~= "0 0"
                patch_alignment_command_snippet = "-Patch " + strjoin(obj.configuration.patch," ");
            else
                patch_alignment_command_snippet = "";
            end
            
            tilt_axis_command_snippet = "-TiltAxis " + num2str(obj.configuration.rotation_tilt_axis) + " " + num2str(obj.configuration.tilt_axis_refine_flag);
            
            tilt_axis_offset_command_snippet = "-TiltCor " + num2str(obj.configuration.apply_tilt_axis_offset) + " " + num2str(obj.configuration.tilt_axis_offset);
            
            if obj.configuration.set_up.gpu >  0
                gpu_number = obj.configuration.set_up.gpu - 1;
            else
                error("ERROR: Gpus are needed to run this module!");
            end
            
            if obj.configuration.aligned_stack_binning < obj.configuration.input_stack_binning
                error("ERROR: Requested aligned_stack_binning (=" + num2str(obj.configuration.aligned_stack_binning)...
                    + ") is lower than required input_stack_binning (=" + num2str(obj.configuration.input_stack_binning) + ") !");
            end
            
            stack_source = string(tilt_stacks(obj.configuration.set_up.adjusted_j).folder) + string(filesep) + string(tilt_stacks(obj.configuration.set_up.adjusted_j).name);
            
            % Generate aligned stack of the requested binning level
            stack_destination = obj.output_path + filesep + obj.name + ".ali";
            executeCommand(obj.configuration.aretomo_command...
                    + " -InMrc " + stack_source...
                    + " -OutMrc " + stack_destination...
                    + " -VolZ 0 -OutBin " + num2str(obj.configuration.aligned_stack_binning / obj.configuration.input_stack_binning)...
                    + " -Gpu " + num2str(gpu_number) + " "...
                    + angular_file_command_snippet + " "...
                    + tilt_axis_command_snippet + " "...
                    + tilt_axis_offset_command_snippet + " "...
                    + patch_alignment_command_snippet...
                    + "-OutImod 1", false, obj.log_file_id);
            
            [~,filename,fileext] = fileparts(stack_source);
            alignment_file_out = obj.output_path + filesep + filename + fileext + ".aln";
            alignment_file_destination = obj.output_path + filesep + obj.name + ".aln";
            movefile(alignment_file_out, alignment_file_destination);
            
            % TODO: check linkage here
            if obj.configuration.aligned_stack_binning == 1
                folder_destination = obj.configuration.aligned_tilt_stacks_folder;
                filename_link_destination = obj.name + ".ali";
            else
                folder_destination = obj.configuration.binned_aligned_tilt_stacks_folder;
                filename_link_destination = obj.name + "_bin_" + num2str(obj.configuration.aligned_stack_binning) + ".ali";
            end
            
            path_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + folder_destination + filesep + obj.name;
            link_destination = path_destination + filesep + filename_link_destination;
            if exist(path_destination, "dir")
                rmdir(path_destination, "s");
            end
            mkdir(path_destination);
            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
            
            % Move IMOD-compatible files one level up
            imod_folder = obj.output_path + filesep + obj.name + ".ali_Imod";
            if exist(imod_folder, 'dir')
                imod_files = dir(imod_folder + string(filesep) + obj.name + "*.*");
                for file_id = 1:length(imod_files) 
                    imod_file_out = imod_files(file_id).folder + string(filesep) + imod_files(file_id).name;
                    [~, ~, imod_file_ext] = fileparts(imod_file_out);
                    imod_file_destination = obj.output_path + filesep + obj.name + imod_file_ext;
                    movefile(imod_file_out, imod_file_destination);
                end
            end
            
            % Generate aligned unbinned stack using alignment parameters
            % previously detected at the requested binning level
            xf_file = dir(obj.output_path + filesep + obj.name + ".xf");
            xf_file_path = xf_file(1).folder + string(filesep) + xf_file(1).name;
            
            tilt_stacks = getTiltStacksFromStandardFolder(obj.configuration, true);
            stack_source = string(tilt_stacks(obj.configuration.set_up.adjusted_j).folder) + string(filesep) + string(tilt_stacks(obj.configuration.set_up.adjusted_j).name);
            
            [~, size_to_output] = system("header -s " + stack_source);
            size_to_output = str2num(size_to_output);
            
            stack_destination_unbinned = obj.output_path + filesep + obj.name + "_bin_" + num2str(1) + ".ali";
            
            status = system("newstack -InputFile " + stack_source...
                + " -OutputFile " + stack_destination_unbinned...
                + " -TransformFile " + xf_file_path...
                + " -OffsetsInXandY 0.0,0.0 -BinByFactor 1 -ImagesAreBinned 1.0 -AdjustOrigin"...
                + " -SizeToOutputInXandY " + num2str(size_to_output(2)) + "," + num2str(size_to_output(1))...
                + " -TaperAtFill 1,0");
            
            % Exclude views according to aligned stack
            fid = fopen(xf_file_path, 'rt');
            txt = textscan(fid, '%s', 'Delimiter', '\n');
            fclose(fid);

            txt = txt{1}(~cellfun(@isempty, txt{1}));
            % NOTE: dirty! rewrite using regexp or other search patterns
            exclude_mask = contains(txt, '1.000     0.000     0.000     1.000      0.00      0.00');
            exclude_views = find(exclude_mask);
            exclude_views = exclude_views'; 
            
            if ~isempty(exclude_views)
                status = system("excludeviews -StackName " + stack_destination_unbinned...
                    + " -ViewsToExclude " + strjoin(string(exclude_views), ','));
            end
            
            xf_file = dir(obj.output_path + filesep + obj.name + ".tlt");
            xf_file_path = xf_file(1).folder + string(filesep) + xf_file(1).name;
            
            folder_destination = obj.configuration.aligned_tilt_stacks_folder;
            filename_link_destination = obj.name + "_bin_" + num2str(1) + ".ali";
            
            path_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + folder_destination + filesep + obj.name;
            link_destination = path_destination + filesep + filename_link_destination;
            if exist(path_destination, "dir")
                rmdir(path_destination, "s");
            end
            mkdir(path_destination);
            createSymbolicLink(stack_destination_unbinned, link_destination, obj.log_file_id);
            
            %TODO: provide the same data as after fiducial-based alignment
            %to make user experience smooth (check whether need code below)
%             for i = 1:length(obj.configuration.binnings)
%                 stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                 if ~fileExists(stack_destination)
%                     executeCommand(obj.configuration.aretomo_command...
%                         + " -InMrc " + stack_source...
%                         + " -OutMrc " + stack_destination...
%                         + " -VolZ 0 -OutBin " + num2str(obj.configuration.binnings(i)) + " "...
%                         + angular_file_command_snippet...
%                         + " "...
%                         + tilt_axis_command_snippet...
%                         + " "...    
%                         + patch_alignment_command_snippet, false, obj.log_file_id);
%                     
%                     [~,filename,fileext] = fileparts(stack_source);
%                     alignment_file_out = obj.output_path + filesep + filename + fileext + ".aln";
%                     alignment_file_destination = obj.output_path + filesep + obj.name + "_bin_" + num2str(obj.configuration.binnings(i)) + ".aln";
%                     movefile(alignment_file_out, alignment_file_destination);
%             
%                     if obj.configuration.binnings(i) > 1
%                         path_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name;
%                         if exist(path_destination, "dir")
%                             rmdir(path_destination, "s");
%                         end
%                         mkdir(path_destination);
%                         link_destination = path_destination + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                         %                 else
%                         %                     link_destination = obj.configuration.processing_path + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         %                     createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
%                 end
%                 
%                 % TODO: refactor (squash to one function) the code below
%                 % TODO: update & test the code below
%                 if obj.configuration.apply_dose_weighting == true
%                     stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_atdw.ali";
%                     executeCommand(obj.configuration.aretomo_command + " -InMrc " + tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                         + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_atdw.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angular_file_command_snippet + " -Wbp " + wbp + " -TiltAxis " + obj.configuration.tilt_axis_determination + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -PixSize " + obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}).apix + " -Kv " + obj.configuration.keV + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
%                     if obj.configuration.binnings(i) > 1
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     else
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
%                 end
% 
%                 if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
%                     stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_even.ali";
%                     executeCommand(obj.configuration.aretomo_command + " -InMrc " + even_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + even_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                         + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_even.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
% 
%                     if obj.configuration.binnings(i) > 1
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     else
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
% 
%                     stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_odd.ali";
%                     executeCommand(obj.configuration.aretomo_command + " -InMrc " + odd_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + odd_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                         + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_odd.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
% 
%                     if obj.configuration.binnings(i) > 1
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     else
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
%                 end
% 
%                 if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                     stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.ali";
%                     executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                         + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
%                     if obj.configuration.binnings(i) > 1
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     else
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
%                 end
% 
%                 if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                     stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.ali";
%                     executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                         + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
%                     if obj.configuration.binnings(i) > 1
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     else
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
%                 end
% 
%                 if obj.configuration.binnings(i) == obj.configuration.template_matching_binning
%                     stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
%                     executeCommand(obj.configuration.aretomo_command + " -InMrc " + tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                         + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec -VolZ " + obj.configuration.reconstruction_thickness + " -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + obj.configuration.flip_volume + " -Flipint " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
% 
%                     if obj.configuration.binnings(i) > 1
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     else
%                         if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name, "dir")
%                             rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name,"s");
%                         end
%                         mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name);
%                         link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name + filesep + obj.name + ".rec";
%                         createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                     end
% 
%                     if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.rec";
%                         executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                             + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.rec -VolZ " + obj.configuration.reconstruction_thickness + " -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + obj.configuration.flip_volume + " -Flipint " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
%                         if obj.configuration.binnings(i) > 1
%                             if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name, "dir")
%                                 rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name,"s");
%                             end
%                             mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name);
%                             link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
%                             createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                         else
%                             if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_tomograms_folder + filesep + obj.name, "dir")
%                                 rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_tomograms_folder + filesep + obj.name,"s");
%                             end
%                             mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_tomograms_folder + filesep + obj.name);
%                             link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name + filesep + obj.name + ".rec";
%                             createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                         end
%                     end
% 
%                     if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.rec";
%                         executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
%                             + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.rec -VolZ " + obj.configuration.reconstruction_thickness + " -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + obj.configuration.flip_volume + " -Flipint " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
%                         if obj.configuration.binnings(i) > 1
%                             if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name, "dir")
%                                 rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name,"s");
%                             end
%                             mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name);
%                             link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
%                             createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                         else
%                             if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name, "dir")
%                                 rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name,"s");
%                             end
%                             mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name);
%                             link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name + filesep + obj.name + ".rec";
%                             createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
%                         end
%                     end
%                 end
%            end
        end
        
        function obj = cleanUp(obj)
            
            % Delete contents of the IMOD-compatible files folder
            field_names = fieldnames(obj.configuration.tomograms);
            folder = obj.output_path + filesep + field_names{obj.configuration.set_up.j} + ".ali_Imod";
            if exist(folder, 'dir')
                %movefile(folder + filesep + "*", obj.output_path);
                files = dir(folder + filesep + "*");
                obj.deleteFilesOrFolders(files);
                obj.deleteFolderIfEmpty(folder);
            end
        end
    end
end
