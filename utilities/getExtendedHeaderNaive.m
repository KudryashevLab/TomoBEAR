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

function extended_header_lines = getExtendedHeaderNaive(file_path, log_file_id)
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
titles_line_idx = find(contains(output, "Titles"));
titles_line = output(titles_line_idx);
titles_line = strsplit(titles_line{1});
titles_line_cnt = str2double(titles_line{1});
extended_header_lines = output((titles_line_idx+2):end);
end

