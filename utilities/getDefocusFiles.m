function file_paths = getDefocusFiles(configuration, pattern)
% TODO: check for "." in pattern
original_mrcs = fieldnames(configuration.tomograms);
ctf_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_GCTFCtfphaseflipCTFCorrection_*");
order = sortDirOutputByPipelineStepNumbering(ctf_folders, configuration);
for i = 1:length(original_mrcs)
    [path, name, extension] = fileparts(original_mrcs{i});
    file_paths{i} = dir(ctf_folders(order(1)).folder + string(filesep)...
        + ctf_folders(order(1)).name + string(filesep) + name + string(filesep) + "*" + pattern);
end
end

