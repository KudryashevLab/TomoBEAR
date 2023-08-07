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

function tomograms = getTomogramsFromPreviousPipelineStepFolders(configuration, flatten)
if nargin == 1
   flatten = false;
end

if flatten == true
    tomogram_path_without_file_extension =...
        configuration.previous_step_output_folder + string(filesep)...
        + "**" + string(filesep) + "*";
    tomogram_path = tomogram_path_without_file_extension + ".rec";
    tomograms = dir(tomogram_path);
    if isempty(tomograms)
        tomogram_path_without_file_extension = configuration.processing_path...
            + string(filesep) + configuration.output_folder + string(filesep)...
            + "*_batchruntomo_*" + string(filesep)...
            + "**" + string(filesep) + "*";
        tomogram_path = tomogram_path_without_file_extension + ".rec";
        tomograms = dir(tomogram_path);
        excluded_reconstructions = ~contains({tomograms.name}, "_full");
        tomograms = tomograms(excluded_reconstructions);
    end
elseif flatten == false
    tomogram_path = configuration.previous_step_output_folder + string(filesep) + "*";
    tomogram_folders = dir(tomogram_path);
    tomograms = {};
    counter = 1;
    for i = 1:length(tomogram_folders)
        if tomogram_folders(i).isdir...
                && (tomogram_folders(i).name ~= "." && tomogram_folders(i).name ~= "..")
            tomogram_path_without_file_extension = tomogram_folders(i).folder...
                + string(filesep) + tomogram_folders(i).name + string(filesep);
            tomograms{counter} = dir(tomogram_path_without_file_extension + "*.rec");
            counter = counter + 1;
        end    
    end
end
if isempty(tomograms)
    % TODO: perhaps make switch for error and exit or warning or throw
    % exception and catch it...
    disp("INFO: No tomograms found at location -> " + tomogram_path);
end
end

