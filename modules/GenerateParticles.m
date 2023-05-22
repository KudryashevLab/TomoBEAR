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


classdef GenerateParticles < Module
    methods
        function obj = GenerateParticles(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)
            return_path = cd(obj.configuration.output_path);
            
            paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "prelast");
            
            if isfield(obj.configuration, "particles_table_path") && obj.configuration.particles_table_path ~= ""
                tab_all_path  = dir(obj.configuration.particles_table_path);
                previous_binning = -1;
            elseif ~isempty(paths)
                alignment_folder = dir(paths{1} + filesep + "alignment_project*");
                alignment_folder_splitted = strsplit(alignment_folder.name, "_");
                previous_binning = str2double(alignment_folder_splitted{end});
                iteration_path = dir(paths{1} + filesep + "*" + filesep + "*" + filesep + "results" + filesep + "ite_*");
                tab_all_path = dir(string(iteration_path(end-1).folder) + filesep + iteration_path(end-1).name + filesep + "averages" + filesep + "*.tbl");
            else
                tab_all_path = dir(obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder + string(filesep) + obj.configuration.particles_table_folder + string(filesep) + "*.tbl");
                tab_all_path_name = strsplit(tab_all_path.name, "_");
                previous_binning = str2double(tab_all_path_name{5});
            end
            particles_table = tab_all_path(end).folder + string(filesep) + tab_all_path(end).name;
            
            if isfield(obj.configuration, "particles_binning") && obj.configuration.particles_binning ~= -1
                particles_binning = obj.configuration.particles_binning;
            elseif previous_binning ~= -1
                particles_binning = previous_binning;
            else
                error("ERROR: Binning level was not auto-identified and was not set by the user! Please, use particles_binning parameter.")
            end
            
            rec_resampled = getMask(obj.configuration);
            
            if ~isempty(rec_resampled) && obj.configuration.box_size >= 1 && obj.configuration.box_size <= 10
                box_size = round(size(rec_resampled, 1) * obj.configuration.box_size);
            else
                box_size = obj.configuration.box_size;
            end
            if mod(box_size, 2) == 1
                disp("INFO: resulting box size is odd, adding 1 to make it even!")
                box_size = box_size + 1;
            end
            
            if obj.configuration.use_SUSAN == true
                generateParticles(obj.configuration, particles_table, particles_binning, box_size, true, "susan");
            else
                generateParticles(obj.configuration, particles_table, particles_binning, box_size, true, "dynamo");
            end
            cd(return_path);
        end
    end
end