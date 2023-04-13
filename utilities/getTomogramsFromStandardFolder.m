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


function tomograms = getTomogramsFromStandardFolder(configuration, flatten)
if nargin == 1
    flatten = false;
end

if isfield(configuration, "tomograms_folder") && flatten == true
    tomograms_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.tomograms_folder + string(filesep)...
        + "**" + string(filesep) + "*.rec";
    
    tomograms = dir(tomograms_path);
    if length(tomograms) == 0
        tomograms_path = configuration.processing_path + string(filesep)...
            + configuration.output_folder + string(filesep)...
        + configuration.tomograms_folder + string(filesep)...
        + "**" + string(filesep) + "*.mrc";
        tomograms = dir(tomograms_path);
    end
elseif isfield(configuration, "tomograms_folder") && flatten == false
    tomograms_path = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.tomograms_folder;
    tomogram_folders = dir(tomograms_path);
    tomograms = {};
    counter = 1;
    for i = 1:length(tomogram_folders)
        if tomogram_folders(i).isdir...
                && (tomogram_folders(i).name ~= "."...
                && tomogram_folders(i).name ~= "..")
            tomograms{counter} = dir(tomogram_folders(i).folder...
                + string(filesep) + tomogram_folders(i).name...
                + string(filesep) + "*.rec");
            if length(tomograms{counter}) == 0 
                tomograms{counter} = dir(tomogram_folders(i).folder...
                    + string(filesep) + tomogram_folders(i).name...
                    + string(filesep) + "*.mrc");
            end
            counter = counter + 1;
        end
    end
end

if isempty(tomograms)
    disp("INFO: No tomograms found at standard location " + tomograms_path);
end
end

