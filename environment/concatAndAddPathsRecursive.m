function concatAndAddPathsRecursive(path, sub_path_list, separator)
if nargin == 2
    separator = string(filesep);
end

version_release = version('-release');

if version_release == "2018a" || version_release == "2018b" || version_release == "2019a"
	addpath(path);
else
	addpath(char(path));
end

folder_list_length = length(sub_path_list);
for i=1:folder_list_length
    if iscell(sub_path_list{i})
        continue;
    end
    
    if version_release == "2018a" || version_release == "2018b" || version_release == "2019a"
        concatenated_path = path + string(filesep) + sub_path_list{i};
    else
        concatenated_path = char(path + string(filesep) + sub_path_list{i});
    end
    
    addpath(concatenated_path);
    if i+1 <= folder_list_length
        if iscell(sub_path_list{i+1})
            concatAndAddPathsRecursive(concatenated_path, sub_path_list{i+1}, separator);
        end
    end
end 
end

