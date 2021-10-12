function file_paths = getFilesWithMatchingPatternFromLastBatchruntomoRun(configuration, pattern)

% original_mrcs = getOriginalMRCsFromStandardFolder(configuration);
original_mrcs = fieldnames(configuration.tomograms);
batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_BatchRunTomo_*");
order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders, configuration);
for i = 1:length(original_mrcs)
    [path, name, extension] = fileparts(original_mrcs{i});
    file_paths{i} = dir(batchruntomo_folders(order(1)).folder + string(filesep)...
        + batchruntomo_folders(order(1)).name + string(filesep) + name + string(filesep) + "*" + pattern);
    if pattern == ".tlt"
        file_paths{i} = file_paths{i}(~contains({file_paths{i}(:).name}, "_fid.tlt"));
    end
end
end

