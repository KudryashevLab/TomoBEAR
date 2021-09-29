function copyOrLinkFilesBasedOnSizeThreshold(source, destination, threshold, log_file_id)

file_list = dir(source);
file_list(1) = [];
file_list(1) = [];
for i = 1:length(file_list)
    if file_list(i).isdir == true
        [success, message, message_id] = mkdir(destination + string(filesep) + file_list(i).name);
        copyOrLinkFilesBasedOnSizeThreshold(source + string(filesep) + file_list(i).name, destination + string(filesep) + file_list(i).name, threshold, log_file_id);
    elseif file_list(i).bytes > threshold && string(file_list(i).name) ~= "SUCCESS"
        createSymbolicLink(source + string(filesep) + file_list(i).name, destination + string(filesep) + file_list(i).name, log_file_id);
    elseif string(file_list(i).name) ~= "SUCCESS"
        copyfile(source + string(filesep) + file_list(i).name, destination);
    end
end
end


