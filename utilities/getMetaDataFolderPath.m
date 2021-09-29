function meta_data_folder_path = getMetaDataFolderPath(configuration)

meta_data_folder_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.meta_data_folder;
end

