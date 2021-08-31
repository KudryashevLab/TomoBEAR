function ownDbox(source_folder, destination_folder, batch, delete_source_folder, padding)
if nargin == 2
    batch = 1000;
    delete_source_folder = false;
    padding = 6;
end

particles = dir(string(source_folder) + filesep + "particle_*");
vol = dread(string(particles(1).folder) + filesep + particles(1).name);
for i = 1:length(particles)
    particle_name_splitted_extension = strsplit(particles(i).name, ".");
	particle_name_splitted_extension_name = strsplit(particle_name_splitted_extension{1}, "_");
    particle_numbers(i) = str2double(particle_name_splitted_extension_name{2});
end

if ~exist(destination_folder, "dir")
    [status_mkdir, message, message_id] = mkdir(string(destination_folder));
else
    [status, message, message_id] = rmdir(string(destination_folder), "s");
    [status_mkdir, message, message_id] = mkdir(string(destination_folder));
end

for i = 1:ceil(max(particle_numbers)/batch)
    destination_folder_current{i} = string(destination_folder) + filesep + "batch_" + ((i - 1) * batch);
    [status_mkdir, message, message_id] = mkdir(destination_folder_current{i});
    particles_to_move = particle_numbers < (i * batch) &  particle_numbers >= ((i - 1) * batch);
    selected_files{i} = particles(particles_to_move);
    parfor j = 1:length(selected_files{i})
        movefile(string(selected_files{i}(j).folder) + filesep + selected_files{i}(j).name, destination_folder_current{i});
    end
end

dwrite(particle_numbers', string(destination_folder) + filesep + "tags.em");

fid = fopen(string(destination_folder) + filesep + "settings.card", "w+");
fprintf(fid, "fractioned=%d;\n", 1);
fprintf(fid, "padding=%d;\n", padding);
fprintf(fid, "batch=%d;\n", batch);
fprintf(fid, "extension=%s;\n", "em");
fprintf(fid, "size=%d  %d  %d;\n", length(vol), length(vol), length(vol));
fprintf(fid, "Mb=%s;\n", num2str(((length(vol) * length(vol) * length(vol) * 4) + 512) / 1024/ 1024));
fclose(fid);
end

