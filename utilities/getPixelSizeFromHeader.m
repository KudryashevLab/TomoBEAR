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


function apix = getPixelSizeFromHeader(file_path, log_file_id)
if iscell(file_path)
    command = sprintf("header %s", file_path{1});
else
    command = sprintf("header %s", file_path);
end
if nargin == 2
    output = executeCommand(command, false, log_file_id);
else
    output = executeCommand(command, false);
end
output = textscan(output, "%s", "delimiter", "\n");
output = output{1};
pixel_line = output(contains(output, "Pixel"));
matching_results = regexp(pixel_line, "(\d+.\d+)", "match");
apix = matching_results{1}{1};
end
