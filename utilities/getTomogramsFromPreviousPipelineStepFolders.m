function tomograms = getTomogramsFromPreviousPipelineStepFolders(configuration, flatten)


if nargin == 1
   flatten = false;
end

if flatten == true
    tomogram_path_without_file_extension = configuration.previous_step_output_folder + string(filesep) + "**" + string(filesep) + "*";
    tomogram_path = tomogram_path_without_file_extension + ".rec";
    tomograms = dir(tomogram_path);
    if isempty(tomograms)
        tomogram_path_without_file_extension = configuration.processing_path + string(filesep)...
            + configuration.output_folder + string(filesep)...
            + "*_batchruntomo_*" + string(filesep) + "**" + string(filesep) + "*";
        tomogram_path = tomogram_path_without_file_extension + ".rec";

        tomograms = dir(tomogram_path);
        excluded_reconstructions = ~contains({tomograms.name}, "_full");
        tomograms = tomograms(excluded_reconstructions);
    end
elseif flatten == false
    tomogram_path = configuration.previous_step_output_folder + string(filesep) + "*";
    tomogram_folders = dir(tomogram_path);
    %tomogram_folders = dir(tomogram_folders(end).folder + string(filesep) + tomogram_folders(end).name);
    tomograms = {};
    counter = 1;
    for i = 1:length(tomogram_folders)
        if tomogram_folders(i).isdir...
                && (tomogram_folders(i).name ~= "." && tomogram_folders(i).name ~= "..")
            tomogram_path_without_file_extension = tomogram_folders(i).folder + string(filesep) + tomogram_folders(i).name + string(filesep);
            tomograms{counter} = dir(tomogram_path_without_file_extension + "*.rec");
            counter = counter + 1;
        end    
    end
end

if isempty(tomograms)
    % TODO: perhaps make switch for error and exit or warning or throw
    % exception and catch it...
    disp("INFO: No tomograms found at location -> " + tomogram_path);
    %error("ERROR: No micrographs found at standard location " + mrc_path);
end
end

