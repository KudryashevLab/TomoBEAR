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

function file_paths = getDefocusFiles(configuration, pattern)
% TODO: check for "." in pattern
original_mrcs = fieldnames(configuration.tomograms);
ctf_folder_dir = dir(configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep) + "*_GCTFCtfphaseflipCTFCorrection_*");
ctf_folder_path = ctf_folder_dir(1).folder + string(filesep) + ctf_folder_dir(1).name;
for i = 1:length(original_mrcs)
    [path, name, extension] = fileparts(original_mrcs{i});
    file_paths{i} = dir(ctf_folder_path + string(filesep) + name + string(filesep) + "*" + pattern);
end
end

