function tilt_angles = getTiltAngles(configuration, get_all_angles)
if nargin == 1
    get_all_angles = false;
end
field_names = fieldnames(configuration.tomograms);
tlt_file_rec = getFilesFromLastModuleRun(configuration, "Reconstruct", "tlt");
tlt_file_brt = getFilesFromLastModuleRun(configuration, "BatchRunTomo", "tlt");
if ((isempty(tlt_file_rec) || ~fileExists(tlt_file_rec{1})) && (isempty(tlt_file_brt) || ~fileExists(tlt_file_brt{1}))) || get_all_angles == true
    if ~isfield(configuration, "tilt_index_angle_mapping") || ~isfield(configuration.tilt_index_angle_mapping, field_names{configuration.set_up.j}) || isempty(configuration.tilt_index_angle_mapping.(field_names{configuration.set_up.j}))
        angles = sort(configuration.tomograms.(field_names{configuration.set_up.j}).tilt_index_angle_mapping(2,:));
        tilt_angles = angles(find(configuration.tomograms.(field_names{configuration.set_up.j}).tilt_index_angle_mapping(3,:)));
    else
        angles = sort(configuration.tilt_index_angle_mapping.(field_names{configuration.set_up.j})(2,:));
        tilt_angles = angles(find(configuration.tilt_index_angle_mapping.(field_names{configuration.set_up.j})(3,:)));
    end
else
    if ~isempty(tlt_file_rec) && fileExists(tlt_file_rec{1})
        fid = fopen(tlt_file_rec{1});
    elseif ~isempty(tlt_file_brt) && fileExists(tlt_file_brt{1})
        fid = fopen(tlt_file_brt{1});
    else
        error("ERROR: no tlt file found");
    end
    high_tilt = fgetl(fid);
    % TODO:DIRTY -> code clean
    while ~feof(fid)
        low_tilt = fgetl(fid);
    end
    tilt_angles = [str2double(high_tilt) str2double(low_tilt)];
    fclose(fid);
end
end

