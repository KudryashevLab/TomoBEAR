function tilt_index_angle_mapping = getTiltIndexAngleMapping(configuration)

meta_data_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.meta_data_folder;
load(meta_data_path + string(filesep)...
                            + configuration.project_name...
                            + "_tilt_index_angle_mapping", "tilt_index_angle_mapping");
end

