function file_count_changed = getFileCountChanged(configuration)
[file_list, ~] = getOriginalMRCsorTIFs(configuration);
if ~isfield(configuration, "file_count")...
        || (isfield(configuration, "file_count")...
        && (configuration.file_count < length(file_list)))
    file_count_changed = true;
else
    file_count_changed = false;
end
end

