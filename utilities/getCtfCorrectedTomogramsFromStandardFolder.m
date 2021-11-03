function tomograms = getCtfCorrectedTomogramsFromStandardFolder(configuration, flatten)
if nargin == 1
    flatten = false;
end

if isfield(configuration, "ctf_corrected_tomograms_folder") && flatten == true
    tomograms_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.ctf_corrected_tomograms_folder + string(filesep)...
        + "**" + string(filesep) + "*.rec";
    tomograms = dir(tomograms_path);
    if length(tomograms) == 0
        tomograms_path = configuration.processing_path + string(filesep)...
            + configuration.output_folder + string(filesep)...
            + configuration.ctf_corrected_tomograms_folder...
            + string(filesep) + "**" + string(filesep) + "*.mrc";
        tomograms = dir(tomograms_path);
    end
elseif isfield(configuration, "ctf_corrected_tomograms_folder") && flatten == false
    tomograms_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.ctf_corrected_tomograms_folder;
    tomogram_folders = dir(tomograms_path);
    tomograms = {};
    counter = 1;
    for i = 1:length(tomogram_folders)
        if tomogram_folders(i).isdir...
                && (tomogram_folders(i).name ~= "." && tomogram_folders(i).name ~= "..")
            tomograms{counter} = dir(tomogram_folders(i).folder...
                + string(filesep) + tomogram_folders(i).name...
                + string(filesep) + "*.rec");
            if length(tomograms{counter}) == 0 
                tomograms{counter} = dir(tomogram_folders(i).folder...
                    + string(filesep) + tomogram_folders(i).name...
                    + string(filesep) + "*.mrc");
            end
            counter = counter + 1;
        end
    end
end

if isempty(tomograms)
    disp("INFO: No tomograms found at standard location " + tomograms_path);
end
end

