classdef DynamoTiltSeriesAlignment < Module
    methods
        function obj = DynamoTiltSeriesAlignment(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "dynamo_folder", false);
            
            if obj.configuration.generate_fiducial_files == true
                createStandardFolder(obj.configuration, "fid_files_folder", false);
            end
        end
        
        function obj = process(obj)
            return_path = cd(obj.output_path);
            field_names = fieldnames(obj.configuration.tomograms);
            if obj.configuration.test_range == true
                indices = obj.configuration.gold_bead_size_in_nm;
                indices_small = obj.configuration.gold_bead_size_in_nm - 1:-1:obj.configuration.gold_bead_size_in_nm-obj.configuration.gold_bead_size_in_nm_testing_range;
                indices(end + 1:end+length(indices_small)) = indices_small;
                indices_large = obj.configuration.gold_bead_size_in_nm + 1:obj.configuration.gold_bead_size_in_nm+obj.configuration.gold_bead_size_in_nm_testing_range;
                indices(end + 1:end+length(indices_large)) = indices_large;
            else
                indices = obj.configuration.gold_bead_size_in_nm;
            end
            for z = indices
                name = obj.configuration.project_name + "_" + z + "_nm";
                success_file = "SUCCESS" + "_" + z + "_nm";
                failure_file = "FAILURE" + "_" + z + "_nm";
                if ((fileExists(success_file) || fileExists(failure_file)) && obj.configuration.test_whole_range == true)...
                        || (fileExists(failure_file) && obj.configuration.test_whole_range == false)
                    continue;
                elseif (~fileExists(success_file) && ~fileExists(failure_file) && exist(name + ".AWF", "dir"))
                    [success, message, message_id] = rmdir(name + ".AWF");
                    %                     delete(name + ".log");
                end
                try
                    % TODO put log in AWF folder
                    folder = obj.output_path;
                    
                    config_file_path = obj.output_path + string(filesep) + obj.configuration.config_file_name;
                    obj.generateConfigFile(config_file_path);
                    file = char(obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_stack_path);
                    obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).config_file_path = config_file_path;
                    if obj.configuration.use_newstack_for_binning == true
                        [folder, name, extension] = fileparts(file);
                        system("newstack -in " + file + " -ou binned_stack.st -bin " + obj.configuration.pre_aligned_stack_binning / obj.configuration.ft_bin);
                        file = 'binned_stack.st';
                    end
                    
                    u = dtsa(char(name), '--nogui', '-path', char(obj.output_path), 'fp', 1, 'cf', char(config_file_path));
                    diary(name + ".log");
                    

                    u.enter.tiltSeries(file);

                    min_and_max_tilt_angles = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_index_angle_mapping;
                    min_and_max_tilt_angles_sorted = sort(min_and_max_tilt_angles(2,:));
                    if obj.configuration.duplicated_tilts == "keep"
                        u.enter.tiltAngles(min_and_max_tilt_angles_sorted(:));
                    else
                        u.enter.tiltAngles(round(min_and_max_tilt_angles_sorted(1)):abs(round(min_and_max_tilt_angles_sorted(2)) - round(min_and_max_tilt_angles_sorted(1))):round(min_and_max_tilt_angles_sorted(end)));
                    end

                    if isfield(obj.configuration, "apix")
                        apix = obj.configuration.apix * obj.configuration.ft_bin;
                    else
                        apix = obj.configuration.tomograms.(field_names{obj.configuration.set_up.j}).apix * obj.configuration.ft_bin;
                    end
                    if obj.configuration.use_newstack_for_binning == true
                        u.enter.settingAcquisition.apix(apix * obj.configuration.pre_aligned_stack_binning);
                    else
                        u.enter.settingAcquisition.apix(apix);
                    end
                    u.enter.settingAcquisition.sphericalAberration(obj.configuration.spherical_aberation);
                    u.enter.settingAcquisition.voltage(obj.configuration.keV);
                    u.enter.settingAcquisition.nominalDefocus(-obj.configuration.nominal_defocus_in_nm);
                    %u.enter.settingAcquisition.amplitudeContrast
                    
                    
                    % TODO: expose num of cpus to json config or fraction or both
                    % based on decimal number or not
                    if obj.configuration.execution_method == "sequential"
                        if any(str2num(obj.configuration.original_parameters.settings_computing_cpus) == -1) || any(str2num(obj.configuration.original_parameters.settings_computing_cpus) == 0)
                            u.enter.settingComputing.parallelCPUUse(true);
                            u.enter.settingComputing.cpus([1 floor(obj.configuration.environmentProperties.cpu_count_physical * obj.configuration.cpu_fraction)]);
                        elseif all(str2num(obj.configuration.original_parameters.settings_computing_cpus) >= 1)
                            u.enter.settingComputing.parallelCPUUse(true);
                            u.enter.settingComputing.cpus(str2num(obj.configuration.original_parameters.settings_computing_cpus));
                        else
                            error("ERROR: please provide a value greater than zero for settings_computing_cpus");
                        end
                    elseif obj.configuration.execution_method == "parallel"
                        u.enter.settingComputing.parallelCPUUse(false);
                        u.enter.settingComputing.cpus(1);
                    end
                    if obj.configuration.use_newstack_for_binning == true
                        bead_radius = round(((z * 10) / (apix * obj.configuration.pre_aligned_stack_binning)) / 2);
                    else
                        bead_radius = round(((z * 10) / (apix)) / 2);
                    end
                    u.enter.settingDetection.beadRadius(bead_radius);
                    u.enter.settingDetection.maskRadius(round(bead_radius * obj.configuration.mask_radius_factor));
                    
                    %u.enter.detectPeaks.detectionBinningFactor(obj.configuration.detection_binning_factor);
                    
                    u.enter.templateSidelength(ceil(bead_radius  * obj.configuration.template_side_length_factor)); %* obj.configuration.mask_radius_factor
                    [status, output] = system("header -s " + file);
                    resolution = str2num(output);

%                     if obj.configuration.use_newstack_for_binning == true
%                         largest_resolution = max(resolution) / obj.configuration.pre_aligned_stack_binning;
%                     else
                        largest_resolution = max(resolution);
%                     end
                    u.area.indexing.step.shifter.parameterSet.maximalShift(largest_resolution * obj.configuration.max_shift_ratio);

                    if obj.configuration.take_defaults == false

                        u.area.indexing.step.chainSelector.parameterSet.minimumMarkerDistance(bead_radius * 2);
                        u.area.indexing.step.reindexer.parameterSet.proximityThreshold3DThinning(bead_radius * 2);
                        u.area.indexing.step.reindexer.parameterSet.proximityThresholdReprojection(bead_radius / 2);
                        u.area.indexing.step.reindexer.parameterSet.exclusionRadiusMultipleMatches(bead_radius / 2);
                        
                        u.area.indexing.step.tiltGapFiller.parameterSet.maximalDistanceThreshold((bead_radius * 2));
                        
                        u.area.refinement.step.traceGapFiller.parameterSet.exclusionRadius(bead_radius);
                        u.area.refinement.step.trimMarkers.parameterSet.proximityFusionThreshold(bead_radius);
                        u.area.refinement.step.trimMarkers.parameterSet.proximityDeletionThreshold(bead_radius * 2);
                        %u.enter.reconstructionBinnedHeight(obj.configuration.reconstruction_thickness / obj.configuration.aligned_stack_binning);
                        %"steps.chainSelector.minimumOccupancy": 10,
                        %"steps.chainSelector.minimumMarkersPerTilt": 1, 
            			%"steps.chainSelector.skipMarkedIndices": 1, 
                        %"steps.correctCTF.useImodPhaseFlip": 0,
                        %"steps.fittingModel.psi": "eachTilt", 
                        %"steps.fittingModel.psiRange": 3,
                        %"steps.reindexer.minimumOccupancy": 3,
                        %"steps.reindexer.proximityThreshold3DThinning": 30, 
                        %"steps.reindexer.proximityThresholdReprojection": 15,
                        %"steps.shifter.maximalHysteresis": 40, 
                        %"steps.shifter.skipManualDiscardsInShifts": 0, 
                        %"steps.tiltGapFiller.estimateResidualsThreshold": 1, 
                        %"steps.tiltGapFiller.maximalDistanceThreshold": 80, 
                        %"steps.tiltGapFiller.maximumMarkersDefiningGap": 3, 
                        %"steps.tiltGapFiller.minimumMarkersTargeted": 3, 
                        %"steps.tiltGapFiller.residualsThreshold": 5, 
                        %"steps.trimMarkers.minimumOccupancy": 5, 
                        %"steps.trimMarkers.proximityDeletionThreshold": 128, 
                        %"steps.trimMarkers.proximityFusionThreshold": 59
                    else
                        u.area.refinement.step.trimMarkers.parameterSet.maximalResidualObservation(10);
                        u.area.indexing.step.tiltGapFiller.parameterSet.residualsThreshold(5);


                    end
                    if obj.configuration.use_newstack_for_binning == true
                        u.enter.settingDetection.detectionBinningFactor(0);
                    else
                        u.enter.settingDetection.detectionBinningFactor(log2(obj.configuration.detection_binning_factor / obj.configuration.ft_bin));
                    end
                    % TODO: check how to input reconstruction full size
                    %             tilt_series = dread(file);
                    %             u.enter.fullReconstruction.reconstructionFullSize([size(tilt_series, 1) size(tilt_series, 2) obj.configuration.thickness]);
                    
                    %                 if obj.configuration.skip_ctf_estimation == true
                    %                     u.run.all('noctf', 1);
                    %                 else
                    %                     u.run.all('noctf', 0);
                    %                 end
                    u.run.area.uptoRefinement(); %'-skipProcessed', 1
                    if obj.configuration.generate_fiducial_files == true
                        dynamo_tilt_series_alignment_folder = dir(obj.output_path + string(filesep) + name + ".AWF" + string(filesep) + "align" + string(filesep) + "reconstructionTiltIndices.txt");
                        if isempty(dynamo_tilt_series_alignment_folder)
                            dynamo_tilt_series_alignment_folder = dir(obj.output_path + string(filesep) + name + ".AWF" + string(filesep) + "align" + string(filesep) + "reconstructionTiltIndices.dlm");
                            dlm = true;
                        else
                            dlm = false;
                        end
                        obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).dynamo_tilt_series_alignment_folder = obj.output_path + string(filesep) + name + ".AWF";
                        if ~isempty(dynamo_tilt_series_alignment_folder)
                            if dlm == true
                                try
                                    tilt_indices = load(dynamo_tilt_series_alignment_folder.folder + string(filesep) + dynamo_tilt_series_alignment_folder.name, "-mat");
                                    tilt_indices = tilt_indices.contents;
                                catch
                                    tilt_indices = load(dynamo_tilt_series_alignment_folder.folder + string(filesep) + dynamo_tilt_series_alignment_folder.name);
                                end
                            else
                                tilt_indices = textread(dynamo_tilt_series_alignment_folder.folder + string(filesep) + dynamo_tilt_series_alignment_folder.name);
                            end
                            tilt_series = dread(file);
                            tilt_series_projections = size(tilt_series, 3);
                            tilt_series_indices = [];
                            tilt_series_indices(tilt_indices) = 1;
                            tilt_series_indices(end+1:tilt_series_projections) = 0;
                            cum_sum_tilt_series_indices = cumsum(tilt_series_indices);
                            
                            point_file_name = name + ".AWF" + string(filesep) + string(field_names{obj.configuration.set_up.j}) + "_" + z + "_nm" + ".point";
                            obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).point_file_path = point_file_name;
                            fileID = fopen(point_file_name, "w");
                            working_markers = load(name + ".AWF" + string(filesep) + "workingMarkers.dms", "-mat");
                            for z = 1:length(working_markers.contents.shapes)
                                for j = 1:length(working_markers.contents.shapes(1,z).coordinates)
                                    if ~isempty(working_markers.contents.shapes(1,z).coordinates{1,j}) && any(tilt_indices == j)
                                        if obj.configuration.use_newstack_for_binning == true
                                            fprintf(fileID, "%0.0f %0.2f %0.2f %0.0f\n", z, working_markers.contents.shapes(1,z).coordinates{1,j}(1) * obj.configuration.pre_aligned_stack_binning / obj.configuration.ft_bin, working_markers.contents.shapes(1,z).coordinates{1,j}(2) * obj.configuration.pre_aligned_stack_binning / obj.configuration.ft_bin, cum_sum_tilt_series_indices(j)-1);
                                        else
                                            fprintf(fileID, "%0.0f %0.2f %0.2f %0.0f\n", z, working_markers.contents.shapes(1,z).coordinates{1,j}(1), working_markers.contents.shapes(1,z).coordinates{1,j}(2), cum_sum_tilt_series_indices(j)-1);
                                        end
                                    end
                                end
                            end
                            fclose(fileID);
                            %                 fid_file_name = string(field_names{obj.configuration.set_up.j}) + ".fid";
                            %                 [status_system, output] = system("point2model -image " + string(file) ...
                            %                     + " -input " + point_file_name + " -output " + fid_file_name);
                            %                 createSymbolicLinkInStandardFolder(obj.configuration, string(pwd) + string(filesep) + fid_file_name, "fid_files_folder", obj.log_file_id);
                            obj.status = 1;
                            fid = fopen(success_file, "w");
                            fclose(fid);
                            if obj.configuration.test_whole_range == true
                                continue;
                            else
                                fid = fopen("INDEX", "w");
                                fprintf(fid, "%s", num2str(1));
                                fclose(fid);
                                copyfile(string(pwd) + string(filesep) + point_file_name, string(field_names{obj.configuration.set_up.j}) + ".point")
                                obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).fiducial_file = createSymbolicLinkInStandardFolder(obj.configuration, string(pwd) + string(filesep) + string(field_names{obj.configuration.set_up.j}) + ".point", "fid_files_folder", obj.log_file_id);
                                diary off;
                                break;
                            end
                        else
                            if obj.configuration.propagate_failed_stacks == true
                                obj.status = 1;
                            else
                                obj.status = 0;
                            end
                            dynamo_tilt_series_alignment_folder = dir(obj.output_path + string(filesep) + name + ".AWF");
                            if obj.configuration.test_whole_range == false
                                [success, message, message_id] = rmdir(string(dynamo_tilt_series_alignment_folder(1).folder), "s");
                            end
                            fid = fopen(failure_file, "w");
                            fclose(fid);
                            continue;
                        end
                    end
                    diary off;
                    
                catch exception
                    disp(exception);
                    if obj.configuration.propagate_failed_stacks == true
                        obj.status = 1;
                    else
                        obj.status = 0;
                    end
                end
            end
            
            if obj.configuration.test_whole_range == true
                point_files = dir("*.AWF/*nm.point");
                fitting_doc_files = dir("*.AWF/info/fitting.doc");
                %               working_markers_doc_files = dir("*.AWF/info/workingMarkers.doc");
                rms = [];
                markers = [];
                observations = [];
                for z = 1:length(fitting_doc_files)
                    fitting_doc = readmatrix("" + fitting_doc_files(z).folder + string(filesep) + fitting_doc_files(z).name, 'Range', 'B:B', 'FileType', 'text', 'OutputType', 'string', 'Delimiter', ":");
                    rms(z) = str2num(fitting_doc(1));
                    markers(z) = str2num(fitting_doc(4));
                    observations(z) = str2num(fitting_doc(5));
                    %                     working_markers_doc = readmatrix("" + working_markers_doc_files(i).folder + string(filesep) + working_markers_doc_files(i).name, 'Range', 'B:B', 'FileType', 'text', 'OutputType', 'string', 'Delimiter', ":");
                end
                
                if obj.configuration.method == "rms"
                    [val, index] = min(rms);
                    disp("INFO: selecting");
                elseif obj.configuration.method == "markers"
                    [val, index] = max(markers);
                    disp("INFO: selecting");
                elseif obj.configuration.method == "observations"
                    [val, index] = max(observations);
                    disp("INFO: selecting");
                end
                fid = fopen("INDEX", "w");
                fprintf(fid, "%s", num2str(index));
                fclose(fid);
                obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_series_alignment_index = index;
                copyfile(point_files(index).folder + string(filesep) + point_files(index).name, string(field_names{obj.configuration.set_up.j}) + ".point")
                obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).fiducial_file = createSymbolicLinkInStandardFolder(obj.configuration, string(pwd) + string(filesep) + string(field_names{obj.configuration.set_up.j}) + ".point", "fid_files_folder", obj.log_file_id);
            else
                obj.dynamic_configuration.tomograms.(field_names{obj.configuration.set_up.j}).tilt_series_alignment_index = 1;
            end
            
            cd(return_path);
            disp("INFO: Dynamo alignment done!");
        end
        
        function generateConfigFile(obj, config_file_path)
            original_parameters = obj.configuration.original_parameters;
            field_names = fieldnames(original_parameters);
            %[path, name, extension] = fileparts(config_file_path);
            %splitted_path = strsplit(path, string(filesep));
            directive_file_id = fopen(config_file_path, 'w');
            for i = 1:length(field_names)
                key_cleaned = strrep(field_names{i},"_",".");
                if string(field_names{i}) == "steps_alignWorkingStack_alignmentBinLevel"...
                        || string(field_names{i}) == "steps_binner_workingBinningFactor"
                    if obj.configuration.use_newstack_for_binning == true
                        fprintf(directive_file_id,"> %s %s\n", key_cleaned, strjoin(string(num2str(0))));
                    else
                        fprintf(directive_file_id,"> %s %s\n", key_cleaned, strjoin(string(num2str(log2(obj.configuration.pre_aligned_stack_binning / obj.configuration.ft_bin)))));
                    end
                elseif string(field_names{i}) == "steps_detectPeaks_detectionBinningFactor"
                    if obj.configuration.use_newstack_for_binning == true
                        fprintf(directive_file_id,"> %s %s\n", key_cleaned, strjoin(string(num2str(0))));
                    else
                        fprintf(directive_file_id,"> %s %s\n", key_cleaned, strjoin(string(num2str(log2(obj.configuration.detection_binning_factor / obj.configuration.ft_bin)))));
                    end
                elseif isnumeric(original_parameters.(field_names{i}))
                    fprintf(directive_file_id,"> %s %s\n", key_cleaned, strjoin(string(num2str(original_parameters.(field_names{i})))));
                else
                    fprintf(directive_file_id,"> %s %s\n", key_cleaned, original_parameters.(field_names{i}));
                end
            end
            fclose(directive_file_id);
        end
    end
end

