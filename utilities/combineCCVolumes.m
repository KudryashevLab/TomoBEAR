%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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

