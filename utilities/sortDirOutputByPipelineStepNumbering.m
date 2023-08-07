%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021,2022,2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published
% by the Free Software Foundation, either version 3 of the License,
% or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

