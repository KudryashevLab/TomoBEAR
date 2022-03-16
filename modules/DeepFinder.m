classdef DeepFinder < Module
    methods
        function obj = DeepFinder(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)
            if obj.configuration.pipeline_location == ""
                [status, pipeline_location] = system("pwd");
                pipeline_location = extractBetween(string(pipeline_location), 1, strlength(string(pipeline_location))-1);
            else
                pipeline_location = obj.configuration.pipeline_location;
            end
            
            return_path = cd(obj.configuration.output_path);
            
            paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "last");
            if ~isempty(paths)
                alignment_folder = dir(paths{1} + filesep + "alignment_project*");
                alignment_folder_splitted = strsplit(alignment_folder.name, "_");
                previous_binning = str2double(alignment_folder_splitted{end});
                iteration_path = dir(paths{1} + filesep + "*" + filesep + "*" + filesep + "results" + filesep + "ite_*");
                tab_all_path = dir(string(iteration_path(end-1).folder) + filesep + iteration_path(end-1).name + filesep + "averages" + filesep + "*.tbl");
                averages_all_path = dir(string(iteration_path(end-1).folder) + filesep + iteration_path(end-1).name + filesep + "averages" + filesep + "average_ref_*_ite_*.em");
            else
                tab_all_path = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder + string(filesep) + "*.tbl");
                tab_all_path_name = strsplit(tab_all_path.name, "_");
                previous_binning = str2double(tab_all_path_name{5});
            end
            if contains(tab_all_path(end).folder, "_eo/")
                table_path = "" + tab_all_path(end-1).folder + filesep + tab_all_path(end-1).name;
                table = dread(char(table_path));
                table_path = "" + tab_all_path(end).folder + filesep + tab_all_path(end).name;
                table = [table; dread(char(table_path))];
                
            else
                table_path = "" + tab_all_path(end).folder + filesep + tab_all_path(end).name;
                table = dread(char(table_path));
            end
            
            if obj.configuration.binning == 0
                binning = obj.configuration.template_matching_binning;
                mask_path = getMask(obj.configuration, true);
            else
                binning = obj.configuration.binning;
            end
            tomograms = {};
            if obj.configuration.use_ctf_corrected_tomograms == true
                if obj.configuration.use_denoised_tomograms == true
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getDenoisedCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getDenoisedCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end
                
                if isempty(tomograms) %|| obj.configuration.use_denoised_tomograms == true
                    disp("WARNING: no denoised ctf corrected tomograms found...");
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getDenoisedBinnedTomogramsFromStandardFolder(obj.configuration, true, binning);
                    else
                        tomograms = getDenoisedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end
                
                if isempty(tomograms) %|| obj.configuration.use_denoised_tomograms == false
                    disp("WARNING: no denoised tomograms found...");
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true, binning);
                    else
                        tomograms = getCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end

                if isempty(tomograms) %|| obj.configuration.use_denoised_tomograms == false
                    disp("WARNING: no ctf corrected tomograms found...");
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end

                if isempty(tomograms)
                    error("WARNING: no tomograms found!");
                end
            else
                if obj.configuration.use_denoised_tomograms == true
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getDenoisedBinnedTomogramsFromStandardFolder(obj.configuration, true, binning);
                    else
                        tomograms = getDenoisedTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end
                
                if isempty(tomograms) || obj.configuration.use_denoised_tomograms == false
                    if obj.configuration.template_matching_binning > 1
                        tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true, obj.configuration.template_matching_binning);
                    else
                        tomograms = getTomogramsFromStandardFolder(obj.configuration, true);
                    end
                end
            end
            

            if ~fileExists(obj.output_path + filesep + obj.configuration.project_name + "_weights" + filesep + "net_weights_FINAL.h5") && obj.configuration.net_weights == ""
                
                
                
                table = dynamo_table_rescale(table, 'factor', previous_binning / binning);
                dwrite(table, 'table.tbl');
                
                
                
                average = dread("" + averages_all_path(1).folder + filesep + averages_all_path(1).name);
                
                
                
                if obj.configuration.use_conda == true
                    output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.deep_finder_env + " python " + pipeline_location + filesep + "modules" + filesep + "DeepFinder" + filesep + "generate_XML.py --tblpath table.tbl", obj.log_file_id);
                else
                    [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
                end
                
                [width, height, z] = getHeightAndWidthFromHeader("" + tomograms(1).folder + filesep + tomograms(1).name, obj.log_file_id);
                
                
                if exist(obj.output_path + filesep + obj.configuration.project_name + "_weights", "dir")
                    rmdir(obj.output_path + filesep + obj.configuration.project_name + "_weights", "s");
                end
                
                mkdir(obj.output_path + filesep + obj.configuration.project_name + "_weights");
                
                fid_train = fopen("train_params.xml", "w+");
                fprintf(fid_train, "<paramsTrain>\n");
                fprintf(fid_train, "\t<path_out path=""" + obj.output_path + filesep + obj.configuration.project_name + "_weights" + filesep + """/>\n");
                path_tomo = {};
                path_target = {};
                unique_indices = unique(table(:, 20));
                if isempty(tomograms)
                    error("ERROR: no tomgrams found for processing!")
                end
                for i = 1:length(tomograms)
                    [folder, name, extension] = fileparts(tomograms(i).folder);
                    splitted_name = strsplit(name, "_");
                    if ~any(unique_indices == str2double(splitted_name{2}))
                        continue;
                    end
                    
                    %                 if obj.configuration.use_conda == true
                    %                     [status, output] = system("conda activate " + obj.configuration.deep_finder_env + " && LD_LIBRARY_PATH=" + obj.configuration.conda_path + "/lib:$LD_LIBRARY_PATH  python " + obj.configuration.deep_finder_repository_path + filesep + "bin" + filesep + "anotate -t " + + " -o object_list.xml");
                    %                 else
                    %                     [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
                    %                 end
                    fid_target = fopen(name + "_target_params.xml", "w+");
                    fprintf(fid_target, "<paramsGenerateTarget>\n");
                    fprintf(fid_target, "\t<path_objl path=""" + obj.output_path + filesep + name + ".xml""/>\n");
                    fprintf(fid_target, "\t<path_initial_vol path=""""/>\n");
                    fprintf(fid_target, "\t<tomo_size>\n");
                    fprintf(fid_target, "\t\t<X size=""" + width + """/>\n");
                    fprintf(fid_target, "\t\t<Y size=""" + height + """/>\n");
                    fprintf(fid_target, "\t\t<Z size=""" + z + """/>\n");
                    fprintf(fid_target, "\t</tomo_size>\n");
                    fprintf(fid_target, "\t<strategy strategy=""" + obj.configuration.strategy + """/>\n");
                    fprintf(fid_target, "\t<radius_list>\n");
                    fprintf(fid_target, "\t\t<class1 radius=""" + floor((length(average) * (previous_binning / binning)) / 2) + """/>\n");
                    fprintf(fid_target, "\t</radius_list>\n");
                    fprintf(fid_target, "\t<path_mask_list>\n");
                    if obj.configuration.strategy == "spheres"
                        fprintf(fid_target, "\t\t<class1 path=""""/>\n");
                    elseif obj.configuration.strategy == "shapes"
                        fprintf(fid_target, "\t\t<class1 path=" + " !!!TODO!!! " +"/>\n");
                    else
                        error("ERROR: unknown startegy, please check spelling!");
                    end
                    fprintf(fid_target, "\t</path_mask_list>\n");
                    fprintf(fid_target, "\t<path_target path=""" + obj.output_path + filesep + name + "_target.mrc""/>\n");
                    fprintf(fid_target, "</paramsGenerateTarget>\n");
                    fclose(fid_target);
                    
                    if obj.configuration.use_conda == true
                        output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.deep_finder_env + " python " + obj.configuration.deep_finder_repository_path + filesep + "bin" + filesep + "generate_target -p " + name + "_target_params.xml", obj.log_file_id);
                    else
                        [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
                    end
                    %                 fprintf(fid_train, "</paramsGenerateTarget>\n");
                    path_tomo{i} = "\t\t<tomo" + (i-1) + " path=""" + tomograms(i).folder + filesep + tomograms(i).name + """/>\n";
                    path_target{i} = "\t\t<target" + (i-1) + " path=""" + obj.output_path + filesep + name + "_target.mrc""/>\n";
                end
                fprintf(fid_train, "\t<path_tomo>\n");
                for i = 1:length(path_tomo)
                    fprintf(fid_train, path_tomo{i});
                end
                fprintf(fid_train, "\t</path_tomo>\n");
                fprintf(fid_train, "\t<path_target>\n");
                for i = 1:length(path_target)
                    fprintf(fid_train, path_target{i});
                end
                fprintf(fid_train, "\t</path_target>\n");
                
                
                fprintf(fid_train, "\t<path_objl_train path=""" + obj.output_path + filesep + "objl_train.xml" + """/>\n");
                fprintf(fid_train, "\t<path_objl_valid path=""" + obj.output_path + filesep + "objl_valid.xml" + """/>\n");
                fprintf(fid_train, "\t<number_of_classes n=""" + obj.configuration.classes + """/>\n");
                fprintf(fid_train, "\t<patch_size n=""" + pow2(nextpow2(floor((length(average) * (previous_binning / binning))))) + """/>\n");
                fprintf(fid_train, "\t<batch_size n=""" + obj.configuration.batch_size + """/>\n");
                fprintf(fid_train, "\t<number_of_epochs n=""" + obj.configuration.number_of_epochs + """/>\n");
                fprintf(fid_train, "\t<steps_per_epoch n=""" + obj.configuration.steps_per_epoch + """/>\n");
                fprintf(fid_train, "\t<steps_per_validation n=""" + obj.configuration.steps_per_validation + """/>\n");
                if obj.configuration.direct_read == true
                    fprintf(fid_train, "\t<flag_direct_read flag=""True""/>\n");
                else
                    fprintf(fid_train, "\t<flag_direct_read flag=""False""/>\n");
                end
                
                if obj.configuration.boot_strap == true
                    fprintf(fid_train, "\t<flag_bootstrap flag=""True""/>\n");
                else
                    fprintf(fid_train, "\t<flag_bootstrap flag=""False""/>\n");
                end
                
                if obj.configuration.random_shift_in_voxels == 0
                    fprintf(fid_train, "\t<random_shift shift=""" + floor(length(average)* (previous_binning / binning) * obj.configuration.shift_factor) + """/>\n");
                else
                    fprintf(fid_train, "\t<random_shift shift=""" + obj.configuration.random_shift_in_voxels + """/>\n");
                end
                fprintf(fid_train, "</paramsTrain>\n");
                fclose(fid_train);
                
                
                object_lists = dir("tomogram_*.xml");
                object_lists = object_lists(~contains({object_lists(:).name}, "target_params"));
                counter = 1;
                objects = {};
                for i = 1:length(object_lists)
                    fid = fopen("" + object_lists(i).folder + filesep + object_lists(i).name);
                    while ~feof(fid)
                        tline = string(fgetl(fid));
                        if ~contains(tline, "<?xml version='1.0' encoding='utf-8'?>")...
                                && ~contains(tline, "<objlist>")...
                                && ~contains(tline, "</objlist>")...
                                && tline ~= ""
                            objects{counter} = tline;
                            counter = counter + 1;
                        else
                            %                         disp(tline)
                        end
                    end
                    fclose(fid);
                end
                
                continuous_values = 1:counter-1;
                trainings_set = continuous_values < quantile(continuous_values, obj.configuration.trainings_set_fraction);
                objects = {objects{randperm(numel(objects))}};
                fid = fopen("objl_train.xml", "w+");
                fprintf(fid, "%s\n", "<?xml version='1.0' encoding='utf-8'?>");
                fprintf(fid, "%s\n", "<objlist>");
                trainings_objects = {objects{trainings_set}};
                for i = 1:length(trainings_objects)
                    fprintf(fid, "%s\n", trainings_objects{i});
                end
                fprintf(fid, "%s\n", "</objlist>");
                fclose(fid);
                
                fid = fopen("objl_valid.xml", "w+");
                fprintf(fid, "%s\n", "<?xml version='1.0' encoding='utf-8'?>");
                fprintf(fid, "%s\n", "<objlist>");
                validation_objects = {objects{~trainings_set}};
                for i = 1:length(validation_objects)
                    fprintf(fid, "%s\n", validation_objects{i});
                end
                fprintf(fid, "%s\n", "</objlist>");
                fclose(fid);
                
                if obj.configuration.use_conda == true
                    output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.deep_finder_env + " python " + obj.configuration.deep_finder_repository_path + filesep + "bin" + filesep + "train -p train_params.xml", obj.log_file_id);
                else
                    [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
                end
            end
            
            if obj.configuration.net_weights ~= ""
                if extractBetween(obj.configuration.net_weights, 1, 1) ~= "/"
                    net_weights = obj.output_path + filesep + obj.configuration.project_name + "_weights" + filesep + obj.configuration.net_weights;
                else
                    net_weights = obj.configuration.net_weights;
                end
            else
                net_weights = obj.output_path + filesep + obj.configuration.project_name + "_weights" + filesep +"net_weights_FINAL.h5";
            end
            particle_count = 0;
            for i = 1:length(tomograms)
                [folder, name, extension] = fileparts(tomograms(i).folder);
%                 splitted_name = strplit(name);
%                 if ~any(table(:, 20) == str2double(splitted_name{2}))
%                     continue;
%                 end
                if ~fileExists(obj.output_path + filesep + name + "_segmentation.mrc")
                    
                    if obj.configuration.use_conda == true
                        output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.deep_finder_env + " python " + obj.configuration.deep_finder_repository_path + filesep + "bin" + filesep + "segment -p " + pow2(nextpow2(floor((length(average) * (previous_binning / binning))))) * 2 + " -t " + tomograms(i).folder + filesep + tomograms(i).name + " -c 2 -w " + net_weights + " -o " + name + "_segmentation.mrc", obj.log_file_id);
                    else
                        [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
                    end
                end
                
                if ~fileExists(obj.output_path + filesep + name + "_segmentation.xml")
                    if obj.configuration.use_conda == true
                        output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.deep_finder_env + " python " + obj.configuration.deep_finder_repository_path + filesep + "bin" + filesep + "cluster -l " + name + "_segmentation.mrc" + " -r " + floor((length(average)* (previous_binning / binning)) / 2) + " -o " + name + "_segmentation.xml", obj.log_file_id);
                    else
                        [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
                    end
                    [tokens, matches] = regexp(output, "([\d]+)", "tokens", "match");
                    
                    if length(matches) == 5
                        particle_count = particle_count + str2double(matches{end});
                    end
                end
            end
            tab_all_path = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder;
            initial_tables = dir(tab_all_path + filesep + "*.tbl");
            
            if obj.configuration.use_conda == true
                output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.deep_finder_env + " python " + pipeline_location + filesep + "modules" + filesep + "DeepFinder" + filesep + "xml_to_dynamo_tbl.py --dirpath " + obj.output_path + " --tbl table.tbl --outputname " + obj.output_path + filesep + "tab_" + sprintf('%03d',(length(initial_tables) + 1)) + "_all_bin_" + binning  + "_" + particle_count + ".tbl", obj.log_file_id);
            else
                [status, output] = system("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path);
            end
            
            createSymbolicLink(obj.output_path + filesep + "tab_" + sprintf('%03d',(length(initial_tables) + 1)) + "_all_bin_" + binning  + "_" + particle_count + ".tbl", tab_all_path + filesep + "tab_" + sprintf('%03d',(length(initial_tables) + 1)) + "_all_bin_" + binning  + "_" + particle_count + ".tbl");
            cd(return_path);
        end
    end
end

