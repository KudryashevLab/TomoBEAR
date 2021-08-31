function mask = getMask(configuration, path)

file_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.templates_folder;
files = dir(file_path);
files(1) = [];
files(1) = [];
mask_entry = contains({files.name}, "mask_bin_" + num2str(configuration.template_matching_binning));
if nargin == 1 || path == false
    mask = dread(char(files(mask_entry).folder + string(filesep) + files(mask_entry).name));
elseif nargin == 2 && path == true
    mask = files(mask_entry).folder + string(filesep) + files(mask_entry).name;
end
end

