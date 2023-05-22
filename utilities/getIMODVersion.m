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


function imod_version = getIMODVersion()
output = executeCommand("3dmod -h", true, -1, true);
output_lines = textscan(output,"%s","Delimiter","","endofline","\n");
output_lines = output_lines{1}{2};
imod_version = regexp(output_lines, "\d+\.\d+\.\d+", "match");
% TODO:NOTE everywhere available but what if folder is not named by version
if string(getenv("IMOD_DIR")) ~= "" && length(imod_version) > 1 || isempty(imod_version)
    imod_version = regexp(string(getenv("IMOD_DIR")), "[\d]+\.[\d]+\.[\d]+", "match");
end
imod_version = string(imod_version);
end

