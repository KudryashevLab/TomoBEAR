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