function concatAndAddPathsRecursive(path, sub_path_list, separator, debug)
if nargin == 2
    separator = string(filesep);
    debug = false;
end

if nargin == 3
    debug = false;
end

version_release = version('-release');

if debug == true
    disp("DEBUG: path to add: " + path);
end

if  ~verLessThan('matlab', '9.2')
	addpath(path);
else
	addpath(char(path));
end

if debug == true
    disp("DEBUG: added path: " + path);
end

folder_list_length = length(sub_path_list);
for i=1:folder_list_length
    if iscell(sub_path_list{i})
        continue;
    end
    if debug == true
        disp("DEBUG: concatenated path to add: " + concatenated_path);
    end
    if ~verLessThan('matlab', '9.2')
        concatenated_path = path + string(filesep) + sub_path_list{i};
    else
        concatenated_path = char(path + string(filesep) + sub_path_list{i});
    end
    
    addpath(concatenated_path);
    if debug == true
        disp("DEBUG: added concatenated path: " + concatenated_path);
        disp("DEBUG: list item number" + (i+1));
    end
    if i+1 <= folder_list_length
        if iscell(sub_path_list{i+1})
            if debug == true
                disp("DEBUG: traversing one level down");
            end
            concatAndAddPathsRecursive(concatenated_path, sub_path_list{i+1}, separator);
        end
    end
end 
end

