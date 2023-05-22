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


function binned_tomograms = getDenoisedCtfCorrectedBinnedTomogramsFromStandardFolder(configuration, flatten, binning)
if nargin == 1
    flatten = false;
    binning = 0;
elseif nargin == 2
    binning = 0;
end

if isfield(configuration, "denoised_ctf_corrected_binned_tomograms_folder") && flatten == true
    binned_tomograms_path = configuration.processing_path...
        + string(filesep) + configuration.output_folder + string(filesep)...
        + configuration.denoised_ctf_corrected_binned_tomograms_folder...
        + string(filesep) + "**" + string(filesep) + "*.rec";
    binned_tomograms = dir(binned_tomograms_path);
    if isempty(binned_tomograms)
        binned_tomograms_path = configuration.processing_path...
            + string(filesep) + configuration.output_folder + string(filesep)...
            + configuration.denoised_ctf_corrected_binned_tomograms_folder...
            + string(filesep) + "**" + string(filesep) + "*.mrc";
        binned_tomograms = dir(binned_tomograms_path);
    end
elseif isfield(configuration, "denoised_ctf_corrected_binned_tomograms_folder") && flatten == false
    binned_tomograms_path = configuration.processing_path...
        + string(filesep) + configuration.output_folder + string(filesep)...
        + configuration.denoised_ctf_corrected_binned_tomograms_folder;
    tomogram_folders = dir(binned_tomograms_path);
    binned_tomograms = {};
    counter = 1;
    for i = 1:length(tomogram_folders)
        if tomogram_folders(i).isdir...
                && (tomogram_folders(i).name ~= "."...
                && tomogram_folders(i).name ~= "..")
            binned_tomograms{counter} = dir(tomogram_folders(i).folder...
                + string(filesep) + tomogram_folders(i).name...
                + string(filesep) + "*.rec");
            counter = counter + 1;
        end
    end
end
if binning ~= 0
        if flatten == true
            indices = contains({binned_tomograms.name}, "bin_" + num2str(binning));
            binned_tomograms = binned_tomograms(indices);
        else
            indices = contains(binned_tomograms, "bin_" + num2str(binning));
            binned_tomograms = binned_tomograms(indices);
        end
end
if isempty(binned_tomograms)
    disp("INFO: No denoised ctf corrected binned tomograms found at standard location " + binned_tomograms_path);
end