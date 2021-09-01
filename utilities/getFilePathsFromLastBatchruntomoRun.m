function file_paths = getFilePathsFromLastBatchruntomoRun(configuration, file_extension)

% field_names = fieldnames(configuration.tomograms);
% if configuration.tomograms.(field_names{configuration.set_up.j}).tif == true
%     original_files = getOriginalTIFsFromStandardFolder(configuration);
% else
%     original_files = getOriginalMRCsFromStandardFolder(configuration);
% end
% if isfield(configuration.set_up, "j")
    %TODO:NOTE: check if condition needed or redesign
%     if isempty(configuration.tomogram_interval)
%         original_files = {original_files{configuration.set_up.j}};
%     else
%         original_files = {original_files{configuration.set_up.adjusted_j}};
%     end
% end
% TODO: delete not needed any more for backwards compatibility
% batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
%     + configuration.output_folder + string(filesep) + "*_batchruntomo_*");

% if length(batchruntomo_folders) == 0
    batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep) + "*_BatchRunTomo_*");
% end
order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders, configuration);
field_names = fieldnames(configuration.tomograms);
% for i = 1:length(original_files)
%     [path, name, extension] = fileparts(original_files{i}(1).folder);
    file_paths{1} = batchruntomo_folders(order(1)).folder + string(filesep)...
        + batchruntomo_folders(order(1)).name + string(filesep) + field_names{configuration.set_up.j} + string(filesep) + field_names{configuration.set_up.j} + "." + string(file_extension);
% end
end

