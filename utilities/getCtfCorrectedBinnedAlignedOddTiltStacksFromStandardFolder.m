function tilt_stacks = getCtfCorrectedBinnedAlignedOddTiltStacksFromStandardFolder(configuration, flatten)
if nargin == 1
    flatten = false;
end

if isfield(configuration, "ctf_corrected_binned_aligned_odd_tilt_stacks_folder") && flatten == true
    tilt_stack_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.ctf_corrected_binned_aligned_odd_tilt_stacks_folder...
        + string(filesep) + "**" + string(filesep) + "*.ali";
    tilt_stacks = dir(tilt_stack_path);
elseif isfield(configuration, "ctf_corrected_binned_aligned_odd_tilt_stacks_folder") && flatten == false
    tilt_stack_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.ctf_corrected_binned_aligned_odd_tilt_stacks_folder;
    tilt_stacks_folders = dir(tilt_stack_path);
    tilt_stacks = {};
    counter = 1;
    for i = 1:length(tilt_stacks_folders)
        if tilt_stacks_folders(i).isdir...
                && (tilt_stacks_folders(i).name ~= "."...
                && tilt_stacks_folders(i).name ~= "..")
            tilt_stacks{counter} = dir(tilt_stacks_folders(i).folder...
                + string(filesep) + tilt_stacks_folders(i).name...
                + string(filesep) + "*.ali");
            counter = counter + 1;
        end
    end
end

if isempty(tilt_stacks)
    disp("INFO: No dose weighted tilt stacks found at standard location " + tilt_stack_path);
end
end
