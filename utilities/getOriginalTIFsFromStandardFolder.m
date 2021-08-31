function original_tifs = getOriginalTIFsFromStandardFolder(configuration, flatten)


if nargin == 1
    flatten = false;
end

if isfield(configuration, "raw_files_folder") && flatten == true
    tif_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep)...
        + configuration.raw_files_folder + string(filesep) + "**" + string(filesep) + "*.tif";
    original_tifs = dir(tif_path);
elseif isfield(configuration, "raw_files_folder") && flatten == false
    tif_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.raw_files_folder;
    original_tif_folders = dir(tif_path);
    
    if ~isempty(original_tif_folders)
        original_tif_folders(1:2) = [];
    end
    
    original_tifs = {};
    for i = 1:length(original_tif_folders)
        original_tifs{i} = dir(tif_path + string(filesep) + original_tif_folders(i).name + string(filesep) + "*.tif");
    end
    
end

if isempty(original_tifs)
    disp("INFO: No micrographs found at standard location -> " + tif_path);
    %error("ERROR: No micrographs found at standard location " + mrc_path);
end
end

