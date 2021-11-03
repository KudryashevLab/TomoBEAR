function original_files = getOriginalFilesFromFilePaths(file_paths, grouped)
if nargin == 1
    grouped = false;
end

counter = 1;
for i = 1:length(file_paths)
    original_files{counter} = dir(file_paths{i});
    if isempty(original_files{counter})
        continue;
    end
    counter = counter + 1;
end

if iscell(original_files) && grouped ~= true
    original_files_tmp = struct("name", '', "folder", '', "date", '',...
        "bytes", 0, "isdir", false, "datenum", 0);
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

