function motion_corected_mrcs = getMotionCorrectedMRCsFromPreviousPipelineStepFolders(configuration, flatten)


if nargin == 1
   flatten = false;
end

motion_corected_mrcs = {};

if flatten == true
    mrc_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep)...
        + "*" + "_motioncor2_" + "*" + string(filesep) + "**" + string(filesep) + "*.mrc";
    motion_corected_mrcs = dir(mrc_path);
elseif flatten == false
    mrc_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + "*" + "_motioncor2_" + "*";
    original_mrc_folders = dir(mrc_path);
    if isempty(original_mrc_folders)
        % TODO: same message text as below perhaps restructure function
        disp("INFO: No micrographs found at location " + mrc_path);
        return;
    end
    original_mrc_folders = dir(original_mrc_folders(end).folder + string(filesep) + original_mrc_folders(end).name);
    for i = 1:length(original_mrc_folders)
        motion_corected_mrcs{i} = dir(original_mrc_folders(i).folder + string(filesep) + original_mrc_folders(i).name + string(filesep) + "*.mrc");
    end
end

if isempty(motion_corected_mrcs)
    % TODO: perhaps make switch for error and exit or warning or throw
    % exception and catch it...
    disp("INFO: No micrographs found at location " + mrc_path);
    %error("ERROR: No micrographs found at standard location " + mrc_path);
end
end

