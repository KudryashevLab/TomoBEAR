function tiltxf_file_paths = getTltxfFilePaths(configuration)
original_mrcs = getOriginalMRCsFromStandardFolder(configuration);
batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_batchruntomo_*");
order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders);
for i = 1:length(original_mrcs)
    [path, name, extension] = fileparts(original_mrcs{i}(1).folder);
    tiltxf_file_paths{i} = batchruntomo_folders(order(1)).folder + string(filesep)...
        + batchruntomo_folders(order(1)).name + string(filesep) + name + string(filesep) + name + ".tltxf";
end
end

