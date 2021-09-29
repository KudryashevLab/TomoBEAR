function motion_corrected_mrcs = getMotionCorrectedMRCsFromStandardFolder(configuration, flatten)


if nargin == 1
   flatten = false;
end

if isfield(configuration, "motion_corrected_files_folder") && flatten == true
    mrc_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep)...
        + configuration.motion_corrected_files_folder + string(filesep) + "**" + string(filesep) + "*.mrc";
    motion_corrected_mrcs = dir(mrc_path);
elseif isfield(configuration, "motion_corrected_files_folder") && flatten == false
    mrc_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.motion_corrected_files_folder;
    original_mrc_folders = dir(mrc_path);
    motion_corrected_mrcs = {};
    counter = 1;
    for i = 1:length(original_mrc_folders)
        if original_mrc_folders(i).name == "." || original_mrc_folders(i).name == ".."
            continue;
        end
        
        motion_corrected_mrcs{counter} = dir(original_mrc_folders(i).folder + string(filesep) + original_mrc_folders(i).name + string(filesep) + "*.mrc");
        counter = counter + 1;
    end
end

if isempty(motion_corrected_mrcs)
    % TODO: perhaps make switch for error and exit or warning or throw
    % exception and catch it...
    disp("INFO: No micrographs found at standard location " + mrc_path);
    %error("ERROR: No micrographs found at standard location " + mrc_path);
end
end

