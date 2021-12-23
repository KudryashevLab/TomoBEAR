classdef GenerateParticles < Module
    methods
        function obj = GenerateParticles(configuration)
            obj@Module(configuration);
        end
        
        function obj = process(obj)
            return_path = cd(obj.configuration.output_path);
            paths = getFilesFromLastModuleRun(obj.configuration, "DynamoAlignmentProject", "", "prelast");
            if ~isempty(paths)
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
            table = "" + tab_all_path(end).folder + filesep + tab_all_path(end).name;
            if obj.configuration.use_SUSAN == true
                generateSUSANParticles(obj.configuration, table, previous_binning);
            else
                generateDynamoParticles(obj.configuration, table, previous_binning);
            end
            cd(return_path);
        end
    end
end