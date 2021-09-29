function createOutputAndScratchFoldersForPipelineStep(merged_configuration)
% TODO: check status
if exist(merged_configuration.output_path, "dir") && merged_configuration.checkpoint_module == false
    [status_rmdir, message, message_id] = rmdir(merged_configuration.output_path, "s");
end

if exist(merged_configuration.scratch_path, "dir") && merged_configuration.checkpoint_module == false
    [status_rmdir, message, message_id] = rmdir(merged_configuration.scratch_path, "s");
end

if ~exist(merged_configuration.output_path, "dir")
    [status_mkdir, message, message_id] = mkdir(merged_configuration.output_path);
end

if ~exist(merged_configuration.scratch_path, "dir")
    [status_mkdir, message, message_id] = mkdir(merged_configuration.scratch_path);
end
end