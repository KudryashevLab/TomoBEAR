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

