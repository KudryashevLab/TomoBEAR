% NOTE: https://arxiv.org/pdf/1810.05420.pdf
% NOTE: https://github.com/juglab/cryoCARE_pip

classdef CryoCARE < Module
    methods
        function obj = CryoCARE(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)
            tilt_stacks = false;
            
            if obj.configuration.binning == 0
                binnings_sorted = sort(obj.configuration.binnings);
                binning = binnings_sorted(end);
                even_tomograms = getCtfCorrectedBinnedEvenTomogramsFromStandardFolder(obj.configuration, true, binning);
                odd_tomograms = getCtfCorrectedBinnedOddTomogramsFromStandardFolder(obj.configuration, true, binning);
                if isempty(even_tomograms)
                    even_tomograms = getBinnedEvenTomogramsFromStandardFolder(obj.configuration, true, binning);
                    odd_tomograms = getBinnedOddTomogramsFromStandardFolder(obj.configuration, true, binning);
                end
                if isempty(even_tomograms) || isempty(odd_tomograms)
                    disp("INFO: no tomograms found with last specified binning!");
                end
            elseif obj.configuration.binning > 1
                binning = obj.configuration.binning;
                even_tomograms = getCtfCorrectedBinnedEvenTomogramsFromStandardFolder(obj.configuration, true, binning);
                odd_tomograms = getCtfCorrectedBinnedOddTomogramsFromStandardFolder(obj.configuration, true, binning);
                if isempty(even_tomograms)
                    even_tomograms = getBinnedEvenTomogramsFromStandardFolder(obj.configuration, true, binning);
                    odd_tomograms = getBinnedOddTomogramsFromStandardFolder(obj.configuration, true, binning);
                end
                if isempty(even_tomograms) || isempty(odd_tomograms)
                    disp("INFO: no tomograms found with specified binning!");
                end
            end
            
            if isempty(even_tomograms)
                disp("INFO: processing with unbinned tilt stacks!");
                tilt_stacks = true;
                even_tomograms = getEvenTiltStacksFromStandardFolder(obj.configuration, true);
                odd_tomograms = getOddTiltStacksFromStandardFolder(obj.configuration, true);
                binning = 1;
                %                 even_tomograms = getCtfCorrectedBinnedEvenTiltStacksFromStandardFolder(obj.configuration, true, binning);
                %                 odd_tomograms = getCtfCorrectedBinnedOddTiltStacksFromStandardFolder(obj.configuration, true, binning);
            end
            
            if isempty(even_tomograms)
                error("ERROR: no even or odd tilt stacks or tomograms");
            end
            
            return_path = cd(obj.output_path);
            
            %% cat train_data_config.json
            % {
            %   "even": [
            %     "/path/to/even.rec"
            %   ],
            %   "odd": [
            %     "/path/to/odd.rec"
            %   ],
            %   "patch_shape": [
            %     72,
            %     72,
            %     72
            %   ],
            %   "num_slices": 1200,
            %   "split": 0.9,
            %   "tilt_axis": "Y",
            %   "n_normalization_samples": 500,
            %   "path": "./"
            % }
            disp("INFO: generating config to generate train data...")
            train_data_config_struct = struct;
            train_data_config_struct.even = cell(1);
            train_data_config_struct.odd = cell(1);
            if isscalar(obj.configuration.tomograms_to_train_on) && obj.configuration.tomograms_to_train_on == 0
                tomograms_to_train_on = length(even_tomograms);
            elseif isscalar(obj.configuration.tomograms_to_train_on)
                tomograms_to_train_on = randi([1 length(even_tomograms)],1,obj.configuration.tomograms_to_train_on);
            else
                tomograms_to_train_on = obj.configuration.tomograms_to_train_on;
            end


            counter = 1;
            for i = 1:tomograms_to_train_on
                train_data_config_struct.even{counter} = "" + even_tomograms(i).folder + filesep + even_tomograms(i).name;
                train_data_config_struct.odd{counter} = "" + odd_tomograms(i).folder + filesep + odd_tomograms(i).name;
                counter = counter + 1; 
            end
            
            [width, height, z] = getHeightAndWidthFromHeader(train_data_config_struct.even{i}, -1);
            patch_shape = obj.configuration.patch_shape;
            if tilt_stacks == false
                patch_shape = patch_shape / binning;
                train_data_config_struct.patch_shape = {patch_shape, patch_shape, patch_shape};
                train_data_config_struct.num_slices = round((width / patch_shape) * (height / patch_shape) * (z / patch_shape));
                train_data_config_struct.tilt_axis = "Y";
                train_data_config_struct.split = round(max(height * obj.configuration.train_split, patch_shape) / height, 2);
            else
                patch_shape = patch_shape / 1;
                train_data_config_struct.patch_shape = {patch_shape, patch_shape};
                train_data_config_struct.num_slices = round((width / patch_shape) * (height / patch_shape) * (z / obj.configuration.neighbouring_projections));
                train_data_config_struct.tilt_axis = "X";
                train_data_config_struct.split = round(max(width * obj.configuration.train_split, patch_shape) / width, 2);
            end
            train_data_config_struct.n_normalization_samples = train_data_config_struct.num_slices * floor(i/2);
            train_data_config_struct.path = obj.output_path;
            train_data_config_json = jsonencode(train_data_config_struct, 'PrettyPrint', true);
            fid = fopen("train_data_config.json", "w+");
            fprintf(fid, "%s", train_data_config_json);
            fclose(fid);
            if ~fileExists("train_data.npz") && ~fileExists("val_data.npz")
                if obj.configuration.use_conda == true
                    % obj.configuration.conda_path + filesep + "bin" + filesep + "conda activate " + obj.configuration.cryoCARE_env + 
                    output_data = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.cryoCARE_env + " python " + obj.configuration.cryoCARE_repository_path + filesep + "cryocare/scripts/cryoCARE_extract_train_data.py --conf " + obj.output_path + filesep + "train_data_config.json", false, obj.log_file_id);
                else
                    output = executeCommand("python " + obj.configuration.cryoCARE_repository_path + filesep + "", false, obj.log_file_id);
                end
            end
            disp("INFO: generating training data finished...");
            %% cat train_config.json
            % {
            %   "train_data": "./",
            %   "epochs": 100,
            %   "steps_per_epoch": 200,
            %   "batch_size": 16,
            %   "unet_kern_size": 3,
            %   "unet_n_depth": 3,
            %   "unet_n_first": 16,
            %   "learning_rate": 0.0004,
            %   "model_name": "model_name",
            %   "path": "./"
            % }
            disp("INFO: generating config for training...");
            train_config_struct = struct;
            train_config_struct.train_data = obj.output_path;
            train_config_struct.epochs = obj.configuration.epochs;
            train_config_struct.steps_per_epoch = floor(train_data_config_struct.num_slices / obj.configuration.batch_size / 10) ; %obj.configuration.steps_per_epoch;
            train_config_struct.batch_size = obj.configuration.batch_size;
            if tilt_stacks == false
                train_config_struct.axes = "ZYXC";
            else
                train_config_struct.axes = "YXC";
            end
            train_config_struct.unet_kern_size = obj.configuration.unet_kern_size;
            train_config_struct.unet_n_depth = obj.configuration.unet_n_depth;
            train_config_struct.unet_n_first = obj.configuration.unet_n_first;
            train_config_struct.learning_rate = obj.configuration.learning_rate;
            train_config_struct.train_tensorboard = obj.configuration.tensorboard;
            train_config_struct.model_name = obj.configuration.project_name + "_model";
            train_config_struct.path = obj.output_path;
            train_config_json = jsonencode(train_config_struct, 'PrettyPrint', true);
            fid = fopen("train_config.json", "w+");
            fprintf(fid, "%s", train_config_json);
            fclose(fid);
            if ~exist(obj.configuration.project_name + "_model" + filesep + "history.dat","file")
                if obj.configuration.use_conda == true
                    output_train = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.cryoCARE_env + " python " + obj.configuration.cryoCARE_repository_path + filesep + "cryocare/scripts/cryoCARE_train.py --conf " + obj.output_path + filesep + "train_config.json", false, obj.log_file_id);
                else
                    output = executeCommand("python " + obj.configuration.cryoCARE_repository_path + filesep + "", false, obj.log_file_id);
                end
            end
            disp("INFO: training finished...");
            %% predict_config.json
            % {
            %   "model_name": "model_name",
            %   "path": "./",
            %   "even": "/path/to/even.rec",
            %   "odd": "/path/to/odd.rec",
            %   "n_tiles": [1,1,1],
            %   "output_name": "denoised.rec"
            % }
            
            for i = 1:length(even_tomograms)
                name_parts = strsplit((even_tomograms(i).name), ".");
                name_parts = strsplit(name_parts{1}, "_");
                if exist("" + strjoin({name_parts{1:2}}, "_") + filesep + even_tomograms(i).name, "file")
                    disp("INFO: skipping predicting tomogram " + i + " due to existence of tomogram...");
                    continue;
                else
                    disp("INFO: generating config for predicting tomogram " + i + "...");
                end
                if tilt_stacks == true
                    if exist("tilt_stack_even", "dir")
                        rmdir("tilt_stack_even", "s");
                        rmdir("tilt_stack_odd", "s");
                        rmdir("denoised_tilt_stack", "s");
                    end
                    mkdir("tilt_stack_even");
                    mkdir("tilt_stack_odd");
                    mkdir("denoised_tilt_stack");
                    output = executeCommand("newstack -split 1 -append mrc "...
                        + even_tomograms(i).folder + filesep + even_tomograms(i).name + " "...
                        + "tilt_stack_even" + filesep...
                        + "slice_", false, obj.log_file_id);
                    
                    output = executeCommand("newstack -split 1 -append mrc "...
                        + odd_tomograms(i).folder + filesep + odd_tomograms(i).name + " "...
                        + "tilt_stack_odd" + filesep...
                        + "slice_", false, obj.log_file_id);
                    
                    even_files = dir("tilt_stack_even" + filesep + "*.mrc");
                    odd_files = dir("tilt_stack_odd" + filesep + "*.mrc");
                    index = length(even_files);
                else
                    index = 1;
                end
                
                if exist(strjoin({name_parts{1:2}}, "_"), "dir")
                    [SUCCESS,MESSAGE,MESSAGEID] = rmdir(strjoin({name_parts{1:2}}, "_"), "s");
                end
                [SUCCESS,MESSAGE,MESSAGEID] = mkdir(strjoin({name_parts{1:2}}, "_"));
                for j = 1:index
                    
                    predict_config_struct = struct;
                    predict_config_struct.model_name = obj.configuration.project_name + "_model";
                    predict_config_struct.path = obj.output_path;

                    if tilt_stacks == false
                        predict_config_struct.even = train_data_config_struct.even{i};
                        predict_config_struct.odd = train_data_config_struct.odd{i};                    
                        predict_config_struct.n_tiles = {floor(z / patch_shape), floor(width / patch_shape), floor(height / patch_shape)};
                        predict_config_struct.output_name = "" + strjoin({name_parts{1:2}}, "_") + filesep + even_tomograms(i).name;
                    else
                        predict_config_struct.even = "" + even_files(j).folder + filesep + even_files(j).name;
                        predict_config_struct.odd = "" + odd_files(j).folder + filesep + odd_files(j).name;                    
                        predict_config_struct.n_tiles = {floor(width / patch_shape), floor(height / patch_shape)};
                        predict_config_struct.output_name = obj.output_path + filesep + "denoised_tilt_stack" + filesep + even_files(j).name;
                    end

                    predict_config_json = jsonencode(predict_config_struct,'PrettyPrint',true);
                    fid = fopen("predict_config.json", "w+");
                    fprintf(fid, "%s", predict_config_json);
                    fclose(fid);

                    if obj.configuration.use_conda == true
                        output = executeCommand("LD_LIBRARY_PATH=" + obj.configuration.conda_path + filesep + "lib:$LD_LIBRARY_PATH conda run -n " + obj.configuration.cryoCARE_env + " python " + obj.configuration.cryoCARE_repository_path + filesep + "cryocare/scripts/cryoCARE_predict.py --conf " + obj.output_path + filesep + "predict_config.json", false, obj.log_file_id);
                    else
                        output = executeCommand("python " + obj.configuration.cryoCARE_repository_path + filesep + "FSC_FDRcontrol.py -halfmap1 " + half_map_1 + " -halfmap2 " + half_map_2 + " -symmetry " + obj.configuration.expected_symmetrie + " -numAsymUnits " + obj.configuration.numAsymUnits + " -p " + obj.configuration.greatest_apix + " -mask " + mask_path, false, obj.log_file_id);
                    end
                    if tilt_stacks == true
                        output_stack_list{j} = char(obj.output_path + filesep + "denoised_tilt_stack" + filesep + even_files(j).name);
                    end
                end
                if tilt_stacks == true
                    stack_output_path = "" + strjoin({name_parts{1:2}}, "_") + filesep + even_tomograms(i).name;
                    executeCommand("newstack " + strjoin(output_stack_list, " ") + " " + stack_output_path, false, obj.log_file_id);
                    if binning > 1
                        createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path, "denoised_binned_tilt_stacks_folder", obj.log_file_id, true);
                    else
                        createSymbolicLinkInStandardFolder(obj.configuration, stack_output_path, "denoised_tilt_stacks_folder", obj.log_file_id, true);
                    end
                else
                    if binning > 1
                        createSymbolicLinkInStandardFolder(obj.configuration, obj.output_path + filesep + predict_config_struct.output_name, "denoised_ctf_corrected_binned_tomograms_folder", obj.log_file_id, true);
                    else
                        createSymbolicLinkInStandardFolder(obj.configuration, obj.output_path + filesep + predict_config_struct.output_name, "denoised_ctf_corrected_tomograms_folder", obj.log_file_id, true);
                    end
                end
            end
            disp("INFO: predicting denoised tomograms finished...");
            cd(return_path);
        end
    end
end

