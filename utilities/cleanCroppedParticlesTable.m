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


function table = cleanCroppedParticlesTable(table, particles_path, as_boxes)
% Removes particles from the table which where not cropped (e.g. were
% discarded due to exceeding tomogram borders)

if as_boxes == true
    batches_paths = dir([particles_path filesep 'batch_*']);
    particle_files = [];
    for batch_idx = 1:length(batches_paths)
        batch_path = batches_paths(batch_idx).folder + string(filesep) + batches_paths(batch_idx).name;
        particle_files_batch = dir([char(batch_path) filesep 'particle*.em']);
        particle_files = cat(1, particle_files, particle_files_batch);
    end
else
    particle_files = dir([particles_path filesep 'particle*.em']);
end

ptags = zeros([length(particle_files) 1]);

for l = 1:length(particle_files)
    particle_name = strsplit(particle_files(l).name, ".");
    particle_number = strsplit(particle_name{1}, "_");
    ptag = str2double(particle_number{2});
    ptags(l) = ptag;
end

set_diff = setdiff(table(:, 1), ptags(:));
if ~isempty(set_diff)

    for i = 1:length(set_diff)
        table(table(:, 1) == set_diff(i), :) = [];
    end

end

end