function multiple_extensions = checkForMultipleExtensions(files)
for i = 1:length(files) 
    [~, ~, extension{i}] = fileparts(files{i});
end
unique_extensions = unique(extension);
% TODO: extract possible extensions to default configuration
unique_extensions(contains(unique_extensions, ".mrc")) = [];
unique_extensions(contains(unique_extensions, ".tif")) = [];
multiple_extensions = ~isempty(unique_extensions);
end

