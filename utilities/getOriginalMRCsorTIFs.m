function [original_files, tif_flag] = getOriginalMRCsorTIFs(configuration, grouped)
if nargin == 2
    grouped = false;
else
    

tif_flag = 0;
if isfield(configuration, "tomogram_input_prefix") && iscell(configuration.tomogram_input_prefix)
    counter = 1;
    for i = 1:length(configuration.tomogram_input_prefix)
        for j = 1:length(configuration.data_path)
            mrc_path(counter) = configuration.data_path{j} + string(filesep)...
                + configuration.tomogram_input_prefix{i} + "*.mrc";
            counter = counter + 1;
        end
    end
elseif isfield(configuration, "tomogram_input_prefix") && configuration.tomogram_input_prefix ~= ""
    mrc_path = configuration.data_path + string(filesep)...
        + configuration.tomogram_input_prefix + "*.mrc";
else
    mrc_path = configuration.data_path + string(filesep) + "*.mrc";
end

counter = 1;
for i = 1:length(mrc_path)
    original_files{counter} = dir(mrc_path{i});
    if isempty(original_files{counter})
        continue;
    end
    counter = counter + 1;
end

if counter == 1
    [original_files, tif_flag] = getOriginalTIFs(configuration);
end

if isempty(original_files)
	error("ERROR: No micrographs found at location " + mrc_path);
end
if iscell(original_files)
    original_files_tmp = struct("name",'',"folder",'',"date",'',"bytes",0,"isdir",false,"datenum",0);
    for i = 1:length(original_files)
        if i == 1
            original_files_tmp(1:length(original_files{i})) = original_files{i};
        else
            original_files_tmp(end + 1:end + length(original_files{i})) = original_files{i};
        end
    end
    original_files = original_files_tmp;
end
end

