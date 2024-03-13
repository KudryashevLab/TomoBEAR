%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021,2022,2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published
% by the Free Software Foundation, either version 3 of the License,
% or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                createStandardFolder(obj.configuration, "binned_dose_weighted_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_dose_weighted_sum_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_even_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_odd_tomograms_folder", false);
                createStandardFolder(obj.configuration, "dose_weighted_tomograms_folder", false);
                createStandardFolder(obj.configuration, "dose_weighted_sum_tomograms_folder", false);
                createStandardFolder(obj.configuration, "even_tomograms_folder", false);
                createStandardFolder(obj.configuration, "odd_tomograms_folder", false);
            elseif obj.configuration.reconstruct == "full" || obj.configuration.reconstruct == "unbinned"
                createStandardFolder(obj.configuration, "tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_tomograms_folder", false);
                createStandardFolder(obj.configuration, "exact_filtered_tomograms_folder", false);
                createStandardFolder(obj.configuration, "dose_weighted_tomograms_folder", false);
                createStandardFolder(obj.configuration, "dose_weighted_sum_tomograms_folder", false);
                createStandardFolder(obj.configuration, "even_tomograms_folder", false);
                createStandardFolder(obj.configuration, "odd_tomograms_folder", false);
            elseif obj.configuration.reconstruct == "binned"
                createStandardFolder(obj.configuration, "binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "ctf_corrected_binned_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_exact_filtered_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_dose_weighted_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_dose_weighted_sum_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_even_tomograms_folder", false);
                createStandardFolder(obj.configuration, "binned_odd_tomograms_folder", false);
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
                    
                    % NOTE: switched off until refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         dose_weighted_tilt_stacks = getCtfCorrectedDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         dose_weighted_sum_tilt_stacks = getCtfCorrectedDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                     end
                    
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         binned_dose_weighted_tilt_stacks = getCtfCorrectedBinnedDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_tilt_stacks = binned_dose_weighted_tilt_stacks(~contains({binned_dose_weighted_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         binned_dose_weighted_sum_tilt_stacks = getCtfCorrectedBinnedDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_sum_tilt_stacks = binned_dose_weighted_sum_tilt_stacks(~contains({binned_dose_weighted_sum_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        even_tilt_stacks = getCtfCorrectedEvenTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        odd_tilt_stacks = getCtfCorrectedOddTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        binned_even_tilt_stacks = getCtfCorrectedBinnedEvenTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_even_tilt_stacks = binned_even_tilt_stacks(~contains({binned_even_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        binned_odd_tilt_stacks = getCtfCorrectedBinnedOddTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_odd_tilt_stacks = binned_odd_tilt_stacks(~contains({binned_odd_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                else
                    aligned_tilt_stack = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    binned_aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
                        dose_weighted_tilt_stacks = getDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
                        dose_weighted_sum_tilt_stacks = getDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                     % NOTE: switched off until refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         binned_dose_weighted_tilt_stacks = getBinnedDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_tilt_stacks = binned_dose_weighted_tilt_stacks(~contains({binned_dose_weighted_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         binned_dose_weighted_sum_tilt_stacks = getBinnedDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_sum_tilt_stacks = binned_dose_weighted_sum_tilt_stacks(~contains({binned_dose_weighted_sum_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        even_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        odd_tilt_stacks = getOddTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        binned_even_tilt_stacks = getBinnedEvenTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_even_tilt_stacks = binned_even_tilt_stacks(~contains({binned_even_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        binned_odd_tilt_stacks = getBinnedOddTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_odd_tilt_stacks = binned_odd_tilt_stacks(~contains({binned_odd_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                end
            elseif obj.configuration.reconstruct == "unbinned"
                if obj.configuration.use_ctf_corrected_stack == true
                    aligned_tilt_stack = getCtfCorrectedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        even_tilt_stacks = getCtfCorrectedEvenTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        odd_tilt_stacks = getCtfCorrectedOddTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                     % NOTE: switched off until refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         dose_weighted_tilt_stacks = getCtfCorrectedDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         dose_weighted_sum_tilt_stacks = getCtfCorrectedDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                     end
                else
                    aligned_tilt_stack = getAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        even_tilt_stacks = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        odd_tilt_stacks = getOddTiltStacksFromStandardFolder(obj.configuration, true);
                    end
                    
                     % NOTE: switched off until refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         dose_weighted_tilt_stacks = getDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         dose_weighted_sum_tilt_stacks = getDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                     end
                end
            elseif obj.configuration.reconstruct == "binned"
                if obj.configuration.use_ctf_corrected_stack == true
                    binned_aligned_tilt_stacks = getCtfCorrectedBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        binned_even_tilt_stacks = getCtfCorrectedBinnedAlignedEvenTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_even_tilt_stacks = binned_even_tilt_stacks(~contains({binned_even_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        binned_odd_tilt_stacks = getCtfCorrectedBinnedAlignedOddTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_odd_tilt_stacks = binned_odd_tilt_stacks(~contains({binned_odd_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                    
                     % NOTE: switched off until refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         binned_dose_weighted_tilt_stacks = getCtfCorrectedBinnedAlignedDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_tilt_stacks = binned_dose_weighted_tilt_stacks(~contains({binned_dose_weighted_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         binned_dose_weighted_sum_tilt_stacks = getCtfCorrectedBinnedAlignedDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_sum_tilt_stacks = binned_dose_weighted_sum_tilt_stacks(~contains({binned_dose_weighted_sum_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
                else
                    binned_aligned_tilt_stacks = getBinnedAlignedTiltStacksFromStandardFolder(obj.configuration, true);
                    if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                        binned_aligned_tilt_stacks = binned_aligned_tilt_stacks(~contains({binned_aligned_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files")
                        binned_even_tilt_stacks = getBinnedAlignedEvenTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_even_tilt_stacks = binned_even_tilt_stacks(~contains({binned_even_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files")
                        binned_odd_tilt_stacks = getBinnedAlignedOddTiltStacksFromStandardFolder(obj.configuration, true);
                        if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
                            binned_odd_tilt_stacks = binned_odd_tilt_stacks(~contains({binned_odd_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
                        end
                    end
                    
                     % NOTE: switched off until refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files")
%                         binned_dose_weighted_tilt_stacks = getBinnedAlignedDoseWeightedTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_tilt_stacks = binned_dose_weighted_tilt_stacks(~contains({binned_dose_weighted_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")
%                         binned_dose_weighted_sum_tilt_stacks = getBinnedAlignedDoseWeightedSumTiltStacksFromStandardFolder(obj.configuration, true);
%                         if ~any(obj.configuration.binnings == obj.configuration.aligned_stack_binning)
%                             binned_dose_weighted_sum_tilt_stacks = binned_dose_weighted_sum_tilt_stacks(~contains({binned_dose_weighted_sum_tilt_stacks.name}, "bin_" + obj.configuration.aligned_stack_binning));
%                         end
%                     end
                end
            else
                error("ERROR: tomogram type unknown!");
            end
            if obj.configuration.use_rawtlt == true
                if ~isempty(getFilePathsFromLastBatchruntomoRun(obj.configuration, "rawtlt"))
                    tlt_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "rawtlt");
                elseif ~isempty(getFilesFromLastModuleRun(obj.configuration,"AreTomo","rawtlt","last"))
                    tlt_file = getFilesFromLastModuleRun(obj.configuration,"AreTomo","rawtlt","last");
                else
                    error("ERROR: RAWTLT tilt files were requiested, but were not found!");
                end
                tlt_out_name_batch_run_tomo = tlt_file{1};
                tlt_out_name = obj.output_path + string(filesep) + name + ".tlt";
                createSymbolicLink(tlt_out_name_batch_run_tomo, tlt_out_name, obj.log_file_id);
            else
                if ~isempty(getFilePathsFromLastBatchruntomoRun(obj.configuration, "tlt"))
                    tlt_file = getFilePathsFromLastBatchruntomoRun(obj.configuration, "tlt");
                elseif ~isempty(getFilesFromLastModuleRun(obj.configuration,"AreTomo","tlt","last"))
                    tlt_file = getFilesFromLastModuleRun(obj.configuration,"AreTomo","tlt","last");
                else
                    error("ERROR: TLT tilt files are required, but were not found!");
                end
                tlt_in = fopen(tlt_file{1}, "r");
                tlt_out_name = obj.output_path + string(filesep) + name + ".tlt";
                tlt_out = fopen(tlt_out_name, "w");
                
                if obj.configuration.correct_angles == "center"
                    high_tilt = str2double(fgetl(tlt_in));
                    % TODO:DIRTY -> code clean
                    low_tilt = high_tilt;
                    while ~feof(tlt_in)
                        low_tilt_new = str2double(fgetl(tlt_in));
                        if ~isnan(low_tilt_new)
                            low_tilt = low_tilt_new;
                        end
                    end
                    fclose(tlt_in);
                    
                    shift = (high_tilt + low_tilt) / 2;
                    
                    tlt_in = fopen(tlt_file{1}, "r");
                    while ~feof(tlt_in)
                        % TODO: needs to be tested
                        tilt_adjusted = str2double(fgetl(tlt_in)) - shift;
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
                    + " -THICKNESS " + obj.configuration.reconstruction_thickness;
                
                if isfield(obj.configuration, "sirt_iter") && (obj.configuration.sirt_iter >= 1)
                    command = command + " -SIRTIterations " + obj.configuration.sirt_iter;
                elseif isfield(obj.configuration, "fake_sirt_iter") && (obj.configuration.fake_sirt_iter >= 1)
                    command = command + " -FakeSIRTiterations " + obj.configuration.fake_sirt_iter;
                end
                
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
                delete(tomogram_destination);
                if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                    createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "ctf_corrected_tomograms_folder", obj.log_file_id);
                else
                    createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "tomograms_folder", obj.log_file_id);
                end
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
                    name_splitted = strsplit(binned_aligned_tilt_stacks(j).name, ".");
                    name = name_splitted{1};
                    binned_aligned_tilt_stacks_tmp = binned_aligned_tilt_stacks(find(contains({binned_aligned_tilt_stacks.name}, name)));

                    %                     [folder, name, extension] = fileparts(binned_aligned_tilt_stacks(((obj.configuration.set_up.adjusted_j - 1) * length(obj.configuration.binnings)) + j).folder + string(filesep) + binned_aligned_tilt_stacks(((obj.configuration.set_up.adjusted_j - 1) * length(obj.configuration.binnings)) + j).name);
                    [folder, name, extension] = fileparts(binned_aligned_tilt_stacks_tmp.folder + string(filesep) + binned_aligned_tilt_stacks_tmp.name);
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
                    command = "tilt -InputProjections " + binned_aligned_tilt_stacks_tmp.folder + string(filesep) + binned_aligned_tilt_stacks_tmp.name...
                        + " -OutputFile " + tomogram_destination...
                        + " -TILTFILE " + tlt_out_name...
                        + " -THICKNESS " + num2str(obj.configuration.reconstruction_thickness / splitted_binning, '%.f');
                    
                    if isfield(obj.configuration, "sirt_iter") && (obj.configuration.sirt_iter >= 1)
                        command = command + " -SIRTIterations " + obj.configuration.sirt_iter;
                    elseif isfield(obj.configuration, "fake_sirt_iter") && (obj.configuration.fake_sirt_iter >= 1)
                        command = command + " -FakeSIRTiterations " + obj.configuration.fake_sirt_iter;
                    end
                    
                    if isfield(obj.configuration, "exclude_lists") && isfield(obj.configuration.exclude_lists, field_names{obj.configuration.set_up.j})
                        command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(field_names{obj.configuration.set_up.j})')), ",");
                    elseif ~isempty(getFilePathsFromLastBatchruntomoRun(obj.configuration, "fid"))
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
                    else
                        disp("WARNING: no views will be excluded, because no such information or fid file were found!");
                    end
                    
                    if obj.configuration.set_up.gpu > 0
                        command = command + " -UseGPU " + obj.configuration.set_up.gpu;
                    end
                    executeCommand(command, false, obj.log_file_id);
                    
                    executeCommand("trimvol -rx " + tomogram_destination...
                        + " " + rotated_tomogram_destination, false, obj.log_file_id);
                    delete(tomogram_destination);
                    if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                        createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "ctf_corrected_binned_tomograms_folder", obj.log_file_id);
                    else
                        createSymbolicLinkInStandardFolder(obj.configuration, rotated_tomogram_destination, "binned_tomograms_folder", obj.log_file_id);
                    end
                    
                    if obj.configuration.generate_exact_filtered_tomograms == true
                        disp("INFO: tomograms with exact filter (size: " + obj.configuration.exact_filter_size + ") will be generated.");
                        
                        exact_filtered_tomogram_destination = obj.output_path + string(filesep) + name + "_exact_filtered_full.rec";
                        
                        command = "tilt -InputProjections " + binned_aligned_tilt_stacks_tmp.folder + string(filesep) + binned_aligned_tilt_stacks_tmp.name...
                            + " -OutputFile " + exact_filtered_tomogram_destination...
                            + " -TILTFILE " + tlt_out_name...
                            + " -THICKNESS " + num2str(obj.configuration.reconstruction_thickness / splitted_binning, '%.f')...
                            + " -ExactFilterSize " + obj.configuration.exact_filter_size;
                        
                        if obj.configuration.set_up.gpu > 0
                            command = command + " -UseGPU " + obj.configuration.set_up.gpu;
                        end
                        
                        if isfield(obj.configuration, "exclude_lists") && isfield(obj.configuration.exclude_lists, name)
                            command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(name))), ",");
                        elseif ~isempty(getFilePathsFromLastBatchruntomoRun(obj.configuration, "fid"))
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
                        
                        exact_filtered_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_ef.rec";
                        executeCommand("trimvol -rx " + exact_filtered_tomogram_destination...
                            + " " + exact_filtered_rotated_tomogram_destination, false, obj.log_file_id);
                        delete(exact_filtered_tomogram_destination);
                        if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                            createSymbolicLinkInStandardFolder(obj.configuration, exact_filtered_rotated_tomogram_destination, "exact_filtered_ctf_corrected_binned_tomograms_folder", obj.log_file_id);
                        else
                            createSymbolicLinkInStandardFolder(obj.configuration, exact_filtered_rotated_tomogram_destination, "binned_exact_filtered_tomograms_folder", obj.log_file_id);
                        end
                    end
                    
                    if obj.configuration.generate_nad_filtered_tomograms == true
                        nad_filter_output_iterations_list = string(obj.configuration.nad_filter_output_iterations_list);
                        disp("INFO: tomograms with NAD filter (at iterations: " + strjoin(nad_filter_output_iterations_list, ",") + ") will be generated.");
                        
                        nad_filtered_tomogram_destination = obj.output_path + string(filesep) + name + "_nadf.rec";
                        
                        if isfield(obj.configuration, "nad_filter_number_of_iterations") && obj.configuration.nad_filter_number_of_iterations ~= -1
                            iter_num_command_snippet = " -n " + num2str(obj.configuration.nad_filter_number_of_iterations);
                        else
                            iter_num_command_snippet = "";
                        end
                        
                        if isfield(obj.configuration, "nad_filter_sigma_for_smoothing") && obj.configuration.nad_filter_sigma_for_smoothing ~= -1
                            smoothing_sigma_command_snippet = " -s " + num2str(obj.configuration.nad_filter_sigma_for_smoothing);
                        else
                            smoothing_sigma_command_snippet = "";
                        end
                        
                        if isfield(obj.configuration, "nad_filter_threshold_for_gradients") && obj.configuration.nad_filter_threshold_for_gradients ~= -1
                            gradients_threshold_command_snippet = " -k " + num2str(obj.configuration.nad_filter_threshold_for_gradients);
                        else
                            gradients_threshold_command_snippet = "";
                        end
                        
                        command = "nad_eed_3d"...
                            + " -i " + strjoin(nad_filter_output_iterations_list, ",")...
                            + iter_num_command_snippet...
                            + smoothing_sigma_command_snippet...
                            + gradients_threshold_command_snippet...
                            + " " + rotated_tomogram_destination...
                            + " " + nad_filtered_tomogram_destination;
                        executeCommand(command, false, obj.log_file_id);
                        
                        nad_filtered_tomograms = dir(nad_filtered_tomogram_destination + '*');
                        for file_id = 1:length(nad_filtered_tomograms)
                            nad_filtered_tomogram_destination_iter = nad_filtered_tomograms(file_id).folder + string(filesep) + nad_filtered_tomograms(file_id).name;
                            filename_split = strsplit(nad_filtered_tomogram_destination_iter, '-');
                            iter_num_str = filename_split(end);
                            nad_filtered_tomogram_destination_iter_new = obj.output_path + string(filesep) + name + "_nadf_" + iter_num_str + ".rec";
                            movefile(nad_filtered_tomogram_destination_iter, nad_filtered_tomogram_destination_iter_new);
                        end
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_even_files") && ~isempty(binned_even_tilt_stacks)
                        binned_even_tilt_stacks_tmp = binned_even_tilt_stacks(find(contains({binned_even_tilt_stacks.name}, name)));
                        disp("INFO: even tomograms will be generated.");
                        
                        even_tomogram_destination = obj.output_path + string(filesep) + name + "_unrotated_even.rec";
                        
                        command = "tilt -InputProjections " + binned_even_tilt_stacks_tmp.folder + string(filesep) + binned_even_tilt_stacks_tmp.name...
                            + " -OutputFile " + even_tomogram_destination...
                            + " -TILTFILE " + tlt_out_name...
                            + " -THICKNESS " + num2str(obj.configuration.reconstruction_thickness / splitted_binning, '%.f');%...
                        %+ " -ExactFilterSize " + obj.configuration.exact_filter_size;
                        
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
                        
                        even_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_even.rec";
                        
                        executeCommand("trimvol -rx " + even_tomogram_destination...
                            + " " + even_rotated_tomogram_destination, false, obj.log_file_id);
                        delete(even_tomogram_destination);
                        %                         if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                        %                             createSymbolicLinkInStandardFolder(obj.configuration, even_rotated_tomogram_destination, "ctf_corrected_binned_even_tomograms_folder", obj.log_file_id);
                        %                         else
                        createSymbolicLinkInStandardFolder(obj.configuration, even_rotated_tomogram_destination, "ctf_corrected_binned_even_tomograms_folder", obj.log_file_id);
                        %                         end
                    end
                    
                    if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_odd_files") && ~isempty(binned_odd_tilt_stacks)
                        binned_odd_tilt_stacks_tmp = binned_odd_tilt_stacks(find(contains({binned_odd_tilt_stacks.name}, name)));
                        disp("INFO: odd tomograms will be generated.");
                        
                        odd_tomogram_destination = obj.output_path + string(filesep) + name + "_unrotated_odd.rec";
                        
                        command = "tilt -InputProjections " + binned_odd_tilt_stacks_tmp.folder + string(filesep) + binned_odd_tilt_stacks_tmp.name...
                            + " -OutputFile " + odd_tomogram_destination...
                            + " -TILTFILE " + tlt_out_name...
                            + " -THICKNESS " + num2str(obj.configuration.reconstruction_thickness / splitted_binning, '%.f');%...
                        %+ " -ExactFilterSize " + obj.configuration.exact_filter_size;
                        
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
                        
                        odd_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_odd.rec";
                        
                        executeCommand("trimvol -rx " + odd_tomogram_destination...
                            + " " + odd_rotated_tomogram_destination, false, obj.log_file_id);
                        delete(odd_tomogram_destination);
                        %                         if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
                        %                             createSymbolicLinkInStandardFolder(obj.configuration, odd_rotated_tomogram_destination, "ctf_corrected_binned_odd_tomograms_folder", obj.log_file_id);
                        %                         else
                        createSymbolicLinkInStandardFolder(obj.configuration, odd_rotated_tomogram_destination, "ctf_corrected_binned_odd_tomograms_folder", obj.log_file_id);
                        %                         end
                    end
                    
                    % switched off before refactoring
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_files") && ~isempty(binned_dose_weighted_tilt_stacks)
%                         binned_dose_weighted_tilt_stacks_tmp = binned_dose_weighted_tilt_stacks(find(contains({binned_dose_weighted_tilt_stacks.name}, name)));
%                         disp("INFO: dose weighted tomograms will be generated.");
%                         
%                         dose_weighted_tomogram_destination = obj.output_path + string(filesep) + name + "_unrotated_dw.rec";
%                         
%                         command = "tilt -InputProjections " + binned_dose_weighted_tilt_stacks_tmp.folder + string(filesep) + binned_dose_weighted_tilt_stacks_tmp.name...
%                             + " -OutputFile " + dose_weighted_tomogram_destination...
%                             + " -TILTFILE " + tlt_out_name...
%                             + " -THICKNESS " + num2str(obj.configuration.reconstruction_thickness / splitted_binning, '%.f');
%                         %+ " -ExactFilterSize " + obj.configuration.exact_filter_size;
%                         
%                         if obj.configuration.set_up.gpu > 0
%                             command = command + " -UseGPU " + obj.configuration.set_up.gpu;
%                         end
%                         
%                         if isfield(obj.configuration, "exclude_lists") && isfield(obj.configuration.exclude_lists, name)
%                             command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(name))), ",");
%                         else
%                             fid_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "fid");
%                             executeCommand("model2point " + fid_files{1} + " " + obj.output_path + filesep + "fiducial.point", false, obj.log_file_id);
%                             fiducials = dlmread(obj.output_path + filesep + "fiducial.point");
%                             projection_ids = unique(fiducials(:,3)) + 1;
%                             if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, strjoin(splitted_name(1:2), "_"))
%                                 previous_projection_ids_logical = obj.configuration.tomograms.(strjoin(splitted_name(1:2), "_")).tilt_index_angle_mapping(3,:);
%                             else
%                                 previous_projection_ids_logical = obj.configuration.tilt_index_angle_mapping.(strjoin(splitted_name(1:2), "_"))(3,:);
%                             end
%                             previous_projection_ids_logical(previous_projection_ids_logical == 0) = [];
%                             projection_ids_logical = zeros([1 length(previous_projection_ids_logical)]);
%                             projection_ids_logical(projection_ids) = 1;
%                             final_projections = find(~projection_ids_logical);
%                             if ~isempty(strjoin(strsplit(num2str(final_projections)), ","))
%                                 command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(final_projections)), ",");
%                             end
%                         end
%                         
%                         executeCommand(command, false, obj.log_file_id);
%                         
%                         dose_weighted_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_dw.rec";
%                         
%                         executeCommand("trimvol -rx " + dose_weighted_tomogram_destination...
%                             + " " + dose_weighted_rotated_tomogram_destination, false, obj.log_file_id);
%                         delete(dose_weighted_tomogram_destination);
%                         if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
%                             createSymbolicLinkInStandardFolder(obj.configuration, dose_weighted_rotated_tomogram_destination, "ctf_corrected_binned_dose_weighted_tomograms_folder", obj.log_file_id);
%                         else
%                             createSymbolicLinkInStandardFolder(obj.configuration, dose_weighted_rotated_tomogram_destination, "binned_dose_weighted_tomograms_folder", obj.log_file_id);
%                         end
%                     end
%                     
%                     if isfield(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}), "motion_corrected_dose_weighted_sum_files")  && ~isempty(binned_dose_weighted_sum_tilt_stacks)
%                         binned_dose_weighted_sum_tilt_stacks_tmp = binned_dose_weighted_sum_tilt_stacks(find(contains({binned_dose_weighted_sum_tilt_stacks.name}, name)));
%                         disp("INFO: dose weighted sum tomograms will be generated.");
%                         
%                         dose_weighted_sum_tomogram_destination = obj.output_path + string(filesep) + name + "_dws.st";
%                         
%                         command = "tilt -InputProjections " + binned_dose_weighted_sum_tilt_stacks_tmp.folder + string(filesep) + binned_dose_weighted_sum_tilt_stacks_tmp.name...
%                             + " -OutputFile " + dose_weighted_sum_tomogram_destination...
%                             + " -TILTFILE " + tlt_out_name...
%                             + " -THICKNESS " + num2str(obj.configuration.reconstruction_thickness / splitted_binning, '%.f');
%                         %+ " -ExactFilterSize " + obj.configuration.exact_filter_size;
%                         
%                         if obj.configuration.set_up.gpu > 0
%                             command = command + " -UseGPU " + obj.configuration.set_up.gpu;
%                         end
%                         
%                         if isfield(obj.configuration, "exclude_lists") && isfield(obj.configuration.exclude_lists, name)
%                             command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(obj.configuration.exclude_lists.(name))), ",");
%                         else
%                             fid_files = getFilePathsFromLastBatchruntomoRun(obj.configuration, "fid");
%                             executeCommand("model2point " + fid_files{1} + " " + obj.output_path + filesep + "fiducial.point", false, obj.log_file_id);
%                             fiducials = dlmread(obj.output_path + filesep + "fiducial.point");
%                             projection_ids = unique(fiducials(:,3)) + 1;
%                             if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, strjoin(splitted_name(1:2), "_"))
%                                 previous_projection_ids_logical = obj.configuration.tomograms.(strjoin(splitted_name(1:2), "_")).tilt_index_angle_mapping(3,:);
%                             else
%                                 previous_projection_ids_logical = obj.configuration.tilt_index_angle_mapping.(strjoin(splitted_name(1:2), "_"))(3,:);
%                             end
%                             previous_projection_ids_logical(previous_projection_ids_logical == 0) = [];
%                             projection_ids_logical = zeros([1 length(previous_projection_ids_logical)]);
%                             projection_ids_logical(projection_ids) = 1;
%                             final_projections = find(~projection_ids_logical);
%                             if ~isempty(strjoin(strsplit(num2str(final_projections)), ","))
%                                 command = command + " -EXCLUDELIST2 " + strjoin(strsplit(num2str(final_projections)), ",");
%                             end
%                         end
%                         
%                         executeCommand(command, false, obj.log_file_id);
%                         
%                         dose_weighted_sum_rotated_tomogram_destination = obj.output_path + string(filesep) + name + "_dws.rec";
%                         
%                         executeCommand("trimvol -rx " + dose_weighted_sum_tomogram_destination...
%                             + " " + dose_weighted_sum_rotated_tomogram_destination, false, obj.log_file_id);
%                         delete(dose_weighted_sum_tomogram_destination);
%                         if contains(name, obj.configuration.ctf_corrected_stack_suffix) || obj.configuration.use_ctf_corrected_stack == true
%                             createSymbolicLinkInStandardFolder(obj.configuration, dose_weighted_sum_rotated_tomogram_destination, "ctf_corrected_binned_dose_weighted_sum_tomograms_folder", obj.log_file_id);
%                         else
%                             createSymbolicLinkInStandardFolder(obj.configuration, dose_weighted_sum_rotated_tomogram_destination, "binned_dose_weighted_sum_tomograms_folder", obj.log_file_id);
%                         end
%                     end
                end
            end
        end
    end
end

