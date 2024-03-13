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

function multiple_extensions = checkForMultipleExtensions(files)
for i = 1:length(files) 
    [~, ~, extension{i}] = fileparts(files{i});
end
unique_extensions = unique(extension);
% TODO: extract possible extensions to default configuration
unique_extensions(contains(unique_extensions, ".mrc")) = [];
unique_extensions(contains(unique_extensions, ".st")) = [];
unique_extensions(contains(unique_extensions, ".tif")) = [];
unique_extensions(contains(unique_extensions, ".eer")) = [];
multiple_extensions = ~isempty(unique_extensions);
end

