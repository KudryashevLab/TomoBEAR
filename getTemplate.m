function template = getTemplate(configuration, path)

file_path = configuration.processing_path + string(filesep) + configuration.output_folder + string(filesep) + configuration.templates_folder;
files = dir(file_path);
files(1) = [];
files(1) = [];
template_entry = contains({files.name}, "template_bin_" + num2str(configuration.template_matching_binning));
if nargin == 1 || path == false
    template = dread(char(files(template_entry).folder + string(filesep) + files(template_entry).name));
elseif nargin == 2 && path == true
    template = files(template_entry).folder + string(filesep) + files(template_entry).name;
end
end

