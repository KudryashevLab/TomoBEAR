function meta_data_file_path = getMetaDataFilePath(configuration)

meta_data_folder_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.meta_data_folder;
meta_data_file_path = meta_data_folder_path + string(filesep) + configuration.project_name + "_history.mat";
end

