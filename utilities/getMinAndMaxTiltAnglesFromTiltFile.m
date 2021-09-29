function min_and_max_tilt_angles = getMinAndMaxTiltAnglesFromTiltFile(configuration)

tomograms = getTomograms(configuration, true);
batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_batchruntomo_*");

if length(batchruntomo_folders) == 0
    batchruntomo_folders = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_BatchRunTomo_*");
end

order = sortDirOutputByPipelineStepNumbering(batchruntomo_folders);
for i = 1:length(tomograms)
    [path, name, extension] = fileparts(tomograms(i).name);
    tilt_file_id = fopen(batchruntomo_folders(order(1)).folder + string(filesep)...
        + batchruntomo_folders(order(1)).name + string(filesep) + name + string(filesep) + name + ".tlt", "r");
    tilt_file_content = textscan(tilt_file_id, "%s", "Delimiter", "", "endofline", "\n");
    tilt_file_content = tilt_file_content{1};
    min_and_max_tilt_angles{i} = [str2double(tilt_file_content{1}) str2double(tilt_file_content{end})];
end
end