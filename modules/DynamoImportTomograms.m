%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


classdef DynamoImportTomograms < Module
    methods
        function obj = DynamoImportTomograms(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "dynamo_folder", false);
        end
        
        function obj = process(obj)
            %             if isfield(obj.configuration, "import_binned_tomograms") && obj.configuration.import_binned_tomograms == true
            %                 tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true);
            %                 [path, name, extension] = fileparts(tomograms(1).folder);
            %                 % TODO: what happens in cases when both binned and unbinned tomograms should be added
            %             else
            %                 tomograms = getTomograms(obj.configuration, true);
            %                 [path, name, extension] = fileparts(tomograms(1).name);
            %             end
            
            if obj.configuration.import_tomograms == "binned"
                binned_tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true);
                [path, name, extension] = fileparts(binned_tomograms(1).folder);
                if isempty(binned_tomograms)
                    binned_tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true);
                end
                if isempty(binned_tomograms)
                    error("ERROR: no binned tomograms found either ctf corrected or non ctf corrcetd ones!");
                end
                % TODO: what happens in cases when both binned and unbinned tomograms should be added
            elseif obj.configuration.import_tomograms == "unbinned" || obj.configuration.import_tomograms == "full"
                tomograms = getTomogramsFromStandardFolder(obj.configuration, true);
                [path, name, extension] = fileparts(tomograms(1).name);
                if isempty(tomograms)
                    tomograms = getCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                end
                if isempty(tomograms)
                    error("ERROR: no unbinned tomograms found either ctf corrected or non ctf corrcetd ones!");
                end
            elseif obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all"
                tomograms = getTomogramsFromStandardFolder(obj.configuration, true);
                if isempty(tomograms)
                    tomograms = getCtfCorrectedTomogramsFromStandardFolder(obj.configuration, true);
                end
                
                if ~isempty(tomograms)
                    [path, name, extension] = fileparts(tomograms(1).name);
                end
                
                binned_tomograms = getBinnedTomogramsFromStandardFolder(obj.configuration, true);
                if isempty(binned_tomograms)
                    binned_tomograms = getCtfCorrectedBinnedTomogramsFromStandardFolder(obj.configuration, true);
                end
                
                if ~isempty(binned_tomograms)
                    [path, name, extension] = fileparts(binned_tomograms(1).folder);
                end
                
                if isempty(tomograms) && isempty(binned_tomograms)
                    error("ERROR: no tomograms found either binned or unbinned ones and either ctf corrected or non ctf corrcetd ones!");
                end
                %tomograms(end + 1: end + length(binned_tomograms)) = binned_tomograms;
            end
            
            %             splitted_name = strsplit(name, "_");
            %             if
            % if
            % obj.configuration.tomograms.tomogram_001.adjusted_tomogram_number_position
            % > 1
            %       vll_file_name = obj.output_path + string(filesep) + strjoin(splitted_name(1:obj.configuration.tomograms.tomogram_001.adjusted_tomogram_number_position - 1), "_") + ".vll";
            % else
            %       vll_file_name = obj.output_path + string(filesep) + strjoin(splitted_name(1), "_") + ".vll";
            % end
            vll_file_name = obj.output_path + string(filesep) + obj.configuration.tomogram_output_prefix + ".vll";
            
            vll_file_id = fopen(vll_file_name, "w");
            
            %min_and_max_tilt_angles = getMinAndMaxTiltAnglesFromTiltFile(obj.configuration);
            field_names = fieldnames(obj.configuration.tomograms);
            if obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all"...
                    || obj.configuration.import_tomograms == "binned"
                for i = 1:length(binned_tomograms) / length(obj.configuration.binnings)
                    [folder, name, extension] = fileparts(binned_tomograms(idivide(int32(i)-1,(length(binned_tomograms)/length(unique({binned_tomograms.folder})))) + 1).name);
                    splitted_name = strsplit(name, "_");
                    if ~isfield(obj.configuration, "tilt_index_angle_mapping") || ~isfield(obj.configuration.tilt_index_angle_mapping, splitted_name{1})
                        min_and_max_tilt_angles{i} = obj.configuration.tomograms.(strjoin({splitted_name{1:2}}, "_")).tilt_index_angle_mapping;
                    else
                        min_and_max_tilt_angles{i} = obj.configuration.tilt_index_angle_mapping.(strjoin({splitted_name{1:2}}, "_"));
                    end
                end
            elseif obj.configuration.import_tomograms == "unbinned" || obj.configuration.import_tomograms == "full"
                for i = 1:length(tomograms)
                     [folder, name, extension] = fileparts(tomograms(i).name);
                    splitted_name = strsplit(name, "_");
                    if ~isfield(obj.configuration.tilt_index_angle_mapping, splitted_name{1})
                        min_and_max_tilt_angles{i} = obj.configuration.tomograms.(strjoin({splitted_name{1:2}}, "_")).tilt_index_angle_mapping;
                    else
                        min_and_max_tilt_angles{i} = obj.configuration.tilt_index_angle_mapping.(strjoin({splitted_name{1:2}}, "_"));
                    end
                end
            end
            
            if obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all"...
                    || obj.configuration.import_tomograms == "unbinned"  || obj.configuration.import_tomograms == "full"
                for i = 1:length(tomograms)
                    [path, name, extension] = fileparts(tomograms(i).name);
                    splitted_name = strsplit(name, "_");
                    [status_system, output] = system("realpath "...
                        + tomograms(i).folder + string(filesep) + tomograms(i).name);
                    fprintf(vll_file_id, "%s", string(output));
                    fprintf(vll_file_id, "* label = %s\n", name);
                    % TODO: ask daniel if that is right
                    if obj.configuration.tilt_type == "single"
                        fprintf(vll_file_id, "* ftype = %s\n", "1");
                    elseif obj.configuration.tilt_type == "dual"
                        fprintf(vll_file_id, "* ftype = %s\n", "0");
                    end
                    fprintf(vll_file_id, "* index = %s\n", splitted_name{2});
                    tomogram_number = idivide(int32(i)-1,(length(tomograms)/length(unique({tomograms.folder})))) + 1;
                    fprintf(vll_file_id, "* ytilt = %.2f %.2f\n",min_and_max_tilt_angles{tomogram_number}(2,1),...
                        min_and_max_tilt_angles{tomogram_number}(2,end));
                    fprintf(vll_file_id, "* apix = %.3f\n", obj.configuration.tomograms.(field_names{tomogram_number}).apix  * obj.configuration.ft_bin);
                    fprintf(vll_file_id, "\n");
                end
            end
            
            if obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all"...
                    || obj.configuration.import_tomograms == "binned"
                for i = 1:length(binned_tomograms)
                    [path, name, extension] = fileparts(binned_tomograms(i).name);
                    splitted_name = strsplit(name, "_");
                    splitted_binning = strsplit(splitted_name{end}, "_");
                    [status_system, output] = system("realpath "...
                        + binned_tomograms(i).folder + string(filesep) + binned_tomograms(i).name);
                    fprintf(vll_file_id, "%s", string(output));
                    fprintf(vll_file_id, "* label = %s\n", name);
                    % TODO: ask daniel if that is right
                    if obj.configuration.tilt_type == "single"
                        fprintf(vll_file_id, "* ftype = %s\n", "1");
                    elseif obj.configuration.tilt_type == "dual"
                        fprintf(vll_file_id, "* ftype = %s\n", "0");
                    end
                    fprintf(vll_file_id, "* index = %s\n", splitted_name{2});
                    binned_tomogram_number = idivide(int32(i)-1,(length(binned_tomograms)/length(unique({binned_tomograms.folder})))) + 1;
                    fprintf(vll_file_id, "* ytilt = %.2f %.2f\n",min_and_max_tilt_angles{binned_tomogram_number}(2,1),...
                        min_and_max_tilt_angles{binned_tomogram_number}(2,end));
                    
                    fprintf(vll_file_id, "* apix = %.3f\n", obj.configuration.tomograms.(strjoin({splitted_name{1:2}}, "_")).apix * obj.configuration.ft_bin * str2double(splitted_binning{1}));
                    fprintf(vll_file_id, "\n");
                end
            end
            
            return_path = cd(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.dynamo_folder);
            if isfield(obj.configuration, "import_tomograms")...
                    && (obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all" || obj.configuration.import_tomograms == "binned")...
                    && ~fileExists(obj.configuration.tomogram_output_prefix + ".ctlg")
                dynamo_catalogue_manager('create', char(obj.configuration.tomogram_output_prefix));
                disp("INFO: Catalogue created!");
            elseif isfield(obj.configuration, "import_tomograms")...
                    && (obj.configuration.import_tomograms == "full" || obj.configuration.import_tomograms == "unbinned")...
                    && ~fileExists(obj.configuration.tomogram_output_prefix + ".ctlg")
                % TODO: needs to be tested if indexing for naming is ok
                dynamo_catalogue_manager('create', char(obj.configuration.tomogram_output_prefix));
                disp("INFO: Catalogue created!");
            else
                disp("INFO: Catalogue already exists!");
            end
            
            if isfield(obj.configuration, "import_tomograms")...
                    && (obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all" || obj.configuration.import_tomograms == "binned")
                dcm('c', char(obj.configuration.tomogram_output_prefix), 'addvll', char(vll_file_name));
            elseif isfield(obj.configuration, "import_tomograms")...
                    && (obj.configuration.import_tomograms == "full" || obj.configuration.import_tomograms == "unbinned")...
                    && ~fileExists(obj.configuration.tomogram_output_prefix + ".ctlg")
                dcm('c', char(obj.configuration.tomogram_output_prefix), 'addvll', char(vll_file_name));
            end
            %             if isfield(obj.configuration, "import_tomograms")...
            %                     && (obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all" || obj.configuration.import_tomograms == "binned")...
            %                     && ~fileExists(strjoin({splitted_name{1:end-3}}, "_") + ".ctlg")
            %                 dynamo_catalogue_manager('create', strjoin(splitted_name(1:obj.configuration.angle_position - 2), "_"));
            %                 disp("INFO: Catalogue created!");
            %             elseif isfield(obj.configuration, "import_tomograms")...
            %                     && (obj.configuration.import_tomograms == "full" || obj.configuration.import_tomograms == "unbinned")...
            %                     && ~fileExists(strjoin({splitted_name{1:end}}, "_") + ".ctlg")
            %                 % TODO: needs to be tested if indexing for naming is ok
            %                 dynamo_catalogue_manager('create', strjoin(splitted_name(1:end - 1), "_"));
            %                 disp("INFO: Catalogue created!");
            %             else
            %                 disp("INFO: Catalogue already exists!");
            %             end
            %
            %             if isfield(obj.configuration, "import_tomograms")...
            %                     && (obj.configuration.import_tomograms == "both" || obj.configuration.import_tomograms == "all" || obj.configuration.import_tomograms == "binned")
            %                 dcm('c', strjoin(splitted_name(1:obj.configuration.angle_position - 2), "_"), 'addvll', char(vll_file_name));
            %             elseif isfield(obj.configuration, "import_tomograms")...
            %                     && (obj.configuration.import_tomograms == "full" || obj.configuration.import_tomograms == "unbinned")...
            %                     && ~fileExists(strjoin({splitted_name{1:end}}, "_") + ".ctlg")
            %                 dcm('c', strjoin(splitted_name(1:end - 1), "_"), 'addvll', char(vll_file_name));
            %             end
            cd(return_path);
        end
    end
end

