function order = sortDirOutputByPipelineStepNumbering(dir_list, configuration)
for j = 1:length(dir_list)
    dir_list_real_indices{j} = strsplit(dir_list(j).name, "_");
    dir_list_real_indices{j} = str2double(dir_list_real_indices{j}(1));
    if isnan(dir_list_real_indices{j})
        folder_splitted = strsplit(dir_list(j).folder, string(filesep));
        dir_list_real_indices{j} = strsplit(folder_splitted{end}, "_");
        dir_list_real_indices{j} = str2double(dir_list_real_indices{j}(1));
    end
end
dir_list_indices = 1:length(dir_list);
[sorted_list, order] = sort([dir_list_real_indices{:}], "desc");
order = order(sorted_list < configuration.set_up.i);
end

