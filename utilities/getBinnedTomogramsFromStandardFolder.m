function binned_tomograms = getBinnedTomogramsFromStandardFolder(configuration, flatten, binning)
if nargin == 1
    flatten = false;
    binning = false;
elseif nargin == 2
    binning = false;
end

if isfield(configuration, "binned_tomograms_folder") && flatten == true
    binned_tomograms_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.binned_tomograms_folder + string(filesep)...
        + "**" + string(filesep) + "*.rec";
    binned_tomograms = dir(binned_tomograms_path);
    if isempty(binned_tomograms)
        binned_tomograms_path = configuration.processing_path...
            + string(filesep) + configuration.output_folder + string(filesep)...
            + configuration.binned_tomograms_folder + string(filesep)...
            + "**" + string(filesep) + "*.mrc";
        binned_tomograms = dir(binned_tomograms_path);
    end
elseif isfield(configuration, "binned_tomograms_folder") && flatten == false
    binned_tomograms_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.binned_tomograms_folder;
    tomogram_folders = dir(binned_tomograms_path);
    binned_tomograms = {};
    counter = 1;
    for i = 1:length(tomogram_folders)
        if tomogram_folders(i).isdir...
                && (tomogram_folders(i).name ~= "." && tomogram_folders(i).name ~= "..")
            binned_tomograms{counter} = dir(tomogram_folders(i).folder...
                + string(filesep) + tomogram_folders(i).name...
                + string(filesep) + "*.rec");
            counter = counter + 1;
        end
    end
end

if binning ~= 0
    if flatten == true
        indices = contains({binned_tomograms.name}, "bin_" + num2str(binning));
        binned_tomograms = binned_tomograms(indices);
    else
        indices = contains(binned_tomograms, "bin_" + num2str(binning));
        binned_tomograms = binned_tomograms(indices);
    end
end

if isempty(binned_tomograms)
    disp("INFO: No tomograms found at standard location -> " + binned_tomograms_path);
end
end