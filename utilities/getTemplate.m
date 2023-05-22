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


function template = getTemplate(configuration, path)
file_path = configuration.processing_path + string(filesep)...
    + configuration.output_folder + string(filesep)...
    + configuration.templates_folder;
files = dir(file_path);
files(1) = [];
files(1) = [];
template_entry = contains({files.name},...
    "template_bin_" + num2str(configuration.template_matching_binning));
if nargin == 1 || path == false
    template = dread(char(files(template_entry).folder...
        + string(filesep) + files(template_entry).name));
elseif nargin == 2 && path == true
    template = files(template_entry).folder...
        + string(filesep) + files(template_entry).name;
end
end

