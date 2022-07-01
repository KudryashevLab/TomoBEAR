function table = cleanCroppedParticlesTable(table, particles_path)
% Removes particles from the table which where not cropped (e.g. were
% discarded due to exceeding tomogram borders)

particle_files = dir([particles_path filesep 'particle*.em']);
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