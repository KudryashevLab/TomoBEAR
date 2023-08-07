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

function xf_file_path = getXfOrAlnFilePaths(configuration, output_path, tomogram_name)
xf_file_path = getFilesFromLastModuleRun(configuration,"AreTomo","xf","last");
if ~isempty(xf_file_path)
    xf_file_path = xf_file_path{1};
else
    xf_file_path = getFilesFromLastModuleRun(configuration,"AreTomo","aln","last");
    if isempty(xf_file_path)
        xf_file_path = getFilePathsFromLastBatchruntomoRun(configuration, "xf");
        xf_file_path = xf_file_path{1};
    else
        fid_in = fopen(xf_file_path{1});
        lines_in_cells = textscan(fid_in, "%s","Delimiter","\n");
        fclose(fid_in);
        fid_out = fopen(output_path + filesep + tomogram_name + ".xf", "w+");
        for j = 4:length(lines_in_cells{1})
            numbers_in_line = textscan(lines_in_cells{1}{j}, "%f %f %f %f %f %f %f %f %f %f");
            rotation_matrix = rotz(numbers_in_line{2});
            fprintf(fid_out, "%f %f %f %f %f %f\n", rotation_matrix(1,1), rotation_matrix(1,2), rotation_matrix(2,1), rotation_matrix(2,2), numbers_in_line{4}, numbers_in_line{5});
        end
        fclose(fid_out);
        xf_file_path = output_path + filesep + tomogram_name + ".xf";
    end
end
end

