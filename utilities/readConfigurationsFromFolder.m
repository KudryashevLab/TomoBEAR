function configurations = readConfigurationsFromFolder(folder)
configuration_file_path = dir(folder + string(filesep) + "output.json");
if isempty(configuration_file_path)
    configuration_file_path = dir(folder + string(filesep) +  "*"...
        + string(filesep) + "output.json");
end
configurations = {};
for i = 1:length(configuration_file_path)
    configurations{i} = loadJSON("" + configuration_file_path(i).folder...
        + string(filesep) + configuration_file_path(i).name);
end
end