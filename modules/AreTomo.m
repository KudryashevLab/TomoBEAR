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
            tilt_stacks = getTiltStacksFromStandardFolder(obj.configuration, true);

            if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                even_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
                odd_tilt_stacks = getOddTiltStacksFromStandardFolder(obj.configuration, true);
            end

            if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                dose_weighted_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
            end

            if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                dose_weighted_sum_tilt_stacks = getDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
            end

            if obj.configuration.weighted_back_projection == true
                wbp = 1;
            end
            % TODO:NOTE: implement ROI reconstructions or is it not needed when
            % substacks or pseudo subtomograms are aligned?

            % TODO:NOTE: implement tilt angle offset

            % TODO:NOTE: implement tilt axis input

            % TODO:NOTE: implement reconstruct aligned tilt series

            min_and_max_tilt_angles = getTiltAngles(obj.configuration);
            %             if false == true %length(min_and_max_tilt_angles) > 2
            fid = fopen(obj.output_path + filesep + "tiltAngles.txt", "w+");
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
            angular_file_command_snippet = "–AngFile " + obj.output_path + filesep + "tiltAngles.txt";
            %             else
            angle_command_snippet = "-TiltRange " + min_and_max_tilt_angles(1) + " " + min_and_max_tilt_angles(end);
            
            if obj.configuration.patch
                patch_alignment_command_snippet = "-Patch " + strjoin(obj.configuration.patch," ");
            end
            stack_destination = obj.output_path + filesep + obj.name + "_bin_1.ali";

            executeCommand(obj.configuration.aretomo_command + " -InMrc " + tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                + " -OutMrc " + stack_destination + " -VolZ 0 -OutBin 1 " + angle_command_snippet + " -Wbp " + wbp + " -TiltAxis " + obj.configuration.tilt_axis_determination + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
            link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
            if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name, "dir")
                rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name,"s");
            end
            mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name);
            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);

            for i = 1:length(obj.configuration.binnings)
                if obj.configuration.binnings(i) ~= 1
                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                    if ~fileExists(stack_destination)
                        executeCommand(obj.configuration.aretomo_command + " -InMrc " + tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                            + " -OutMrc " + stack_destination + " -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -Wbp " + wbp + " -TiltAxis " + obj.configuration.tilt_axis_determination + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);

                        if obj.configuration.binnings(i) > 1
                            if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_tilt_stacks_folder + filesep + obj.name, "dir")
                                rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_tilt_stacks_folder + filesep + obj.name,"s");
                            end
                            mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_tilt_stacks_folder + filesep + obj.name);
                            link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                            %                 else
                            %                     link_destination = obj.configuration.processing_path + filesep + obj.configuration.aligned_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                            %                     createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                        end
                    end
                end

                if obj.configuration.apply_dose_weighting == true
                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_atdw.ali";
                    executeCommand(obj.configuration.aretomo_command + " -InMrc " + tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                        + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_atdw.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angular_file_command_snippet + " -Wbp " + wbp + " -TiltAxis " + obj.configuration.tilt_axis_determination + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -PixSize " + obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}).apix + " -Kv " + obj.configuration.keV + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
                    if obj.configuration.binnings(i) > 1
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    else
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    end
                end

                if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_even.ali";
                    executeCommand(obj.configuration.aretomo_command + " -InMrc " + even_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + even_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                        + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_even.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);

                    if obj.configuration.binnings(i) > 1
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_even_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    else
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_even_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    end

                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_odd.ali";
                    executeCommand(obj.configuration.aretomo_command + " -InMrc " + odd_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + odd_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                        + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_odd.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);

                    if obj.configuration.binnings(i) > 1
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_odd_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    else
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_odd_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    end
                end

                if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.ali";
                    executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                        + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
                    if obj.configuration.binnings(i) > 1
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    else
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    end
                end

                if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.ali";
                    executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                        + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.ali -VolZ 0 -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + 0 + " -FlipInt " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
                    if obj.configuration.binnings(i) > 1
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    else
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.aligned_dose_weighted_sum_tilt_stacks_folder + filesep + obj.name + filesep + obj.name + ".ali";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    end
                end

                if obj.configuration.binnings(i) == obj.configuration.template_matching_binning
                    stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
                    executeCommand(obj.configuration.aretomo_command + " -InMrc " + tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                        + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec -VolZ " + obj.configuration.reconstruction_thickness + " -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + obj.configuration.flip_volume + " -Flipint " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);

                    if obj.configuration.binnings(i) > 1
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_tomograms_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    else
                        if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name, "dir")
                            rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name,"s");
                        end
                        mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name);
                        link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.tomograms_folder + filesep + obj.name + filesep + obj.name + ".rec";
                        createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                    end

                    if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                        stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.rec";
                        executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                            + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dw.rec -VolZ " + obj.configuration.reconstruction_thickness + " -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + obj.configuration.flip_volume + " -Flipint " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
                        if obj.configuration.binnings(i) > 1
                            if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name, "dir")
                                rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name,"s");
                            end
                            mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name);
                            link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
                            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                        else
                            if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_tomograms_folder + filesep + obj.name, "dir")
                                rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_tomograms_folder + filesep + obj.name,"s");
                            end
                            mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_tomograms_folder + filesep + obj.name);
                            link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_tomograms_folder + filesep + obj.name + filesep + obj.name + ".rec";
                            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                        end
                    end

                    if isfield(obj.configuration.tomograms.(obj.field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                        stack_destination = obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.rec";
                        executeCommand(obj.configuration.aretomo_command + " -InMrc " + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).folder + filesep + dose_weighted_sum_tilt_stacks(obj.configuration.set_up.adjusted_j).name...
                            + " -OutMrc " + obj.output_path + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + "_dws.rec -VolZ " + obj.configuration.reconstruction_thickness + " -OutBin " + obj.configuration.binnings(i) / obj.configuration.ft_bin + " " + angle_command_snippet + " -AlnFile " + obj.name + ".st.aln" + " -Wbp " + wbp + " -AlignZ " + (obj.configuration.align_height_ratio * obj.configuration.reconstruction_thickness) + " -FlipVol " + obj.configuration.flip_volume + " -Flipint " + obj.configuration.flip_intensity + " -Gpu " + (obj.configuration.set_up.gpu - 1), false, obj.log_file_id);
                        if obj.configuration.binnings(i) > 1
                            if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name, "dir")
                                rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name,"s");
                            end
                            mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name);
                            link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.binned_dose_weighted_sum_tomograms_folder + filesep + obj.name + filesep + obj.name + "_bin_" + obj.configuration.binnings(i) + ".rec";
                            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                        else
                            if exist(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name, "dir")
                                rmdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name,"s");
                            end
                            mkdir(obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name);
                            link_destination = obj.configuration.processing_path + filesep + obj.configuration.output_folder + filesep + obj.configuration.dose_weighted_sum_tomograms_folder + filesep + obj.name + filesep + obj.name + ".rec";
                            createSymbolicLink(stack_destination, link_destination, obj.log_file_id);
                        end
                    end
                end
            end
        end
    end
end
