function [combined_volume, combined_tdrot, combined_tilt, combined_narot] = combineCCVolumes(template_matching_path)

dir_list = dir(template_matching_path + "*angle*");
for i = 1:length(dir_list)
    splitted_folder_name_by_dot = strsplit(dir_list(i).name, ".");
    splitted_folder_name_by_underscore = strsplit(splitted_folder_name_by_dot{1:end-1}, "_");
    narot_string = splitted_folder_name_by_underscore{end};
    narot{i} = str2num(narot_string);
    
    cc_map{i} = dread(char(dir_list(i).folder + string(filesep) + dir_list(i).name + string(filesep) + "cc.mrc"));
    tdrot_map{i} = dread(char(dir_list(i).folder + string(filesep) + dir_list(i).name + string(filesep) + "tdrot.mrc"));
    tilt_map{i} = dread(char(dir_list(i).folder + string(filesep) + dir_list(i).name + string(filesep) + "tilt.mrc"));
end

combined_volume = zeros(size(cc_map{1}));
combined_tdrot = zeros(size(cc_map{1}));
combined_tilt = zeros(size(cc_map{1}));
combined_narot = zeros(size(cc_map{1}));

for i = 1:length(cc_map)
    [indices] = find(cc_map{i} > combined_volume);
    combined_volume(indices) = cc_map{i}(indices);
    combined_tdrot(indices) = tdrot_map{i}(indices);
    combined_tilt(indices) = tilt_map{i}(indices);
    combined_narot(indices) = narot{i};
end
end

