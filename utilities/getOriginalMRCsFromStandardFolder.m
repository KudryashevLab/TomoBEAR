function original_mrcs = getOriginalMRCsFromStandardFolder(configuration, flatten)
if nargin == 1
    flatten = false;
end

if isfield(configuration, "raw_files_folder") && flatten == true
    mrc_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.raw_files_folder + string(filesep)...
        + "**" + string(filesep) + "*.mrc";
    original_mrcs = dir(mrc_path);
elseif isfield(configuration, "raw_files_folder") && flatten == false
    mrc_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.raw_files_folder;
    original_mrc_folders = dir(mrc_path);
    
    if ~isempty(original_mrc_folders)
        original_mrc_folders(1:2) = [];
    end
    
    original_mrcs = {};
    for i = 1:length(original_mrc_folders)
        original_mrcs{i} = dir(mrc_path + string(filesep)...
            + original_mrc_folders(i).name + string(filesep) + "*.mrc");
    end
end

if isempty(original_mrcs)
    disp("INFO: No micrographs found at standard location " + mrc_path);
end
end

