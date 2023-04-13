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


function copyOrLinkFilesBasedOnSizeThreshold(source, destination, threshold, log_file_id)
file_list = dir(source);
file_list(1) = [];
file_list(1) = [];
for i = 1:length(file_list)
    if file_list(i).isdir == true
        [success, message, message_id] = mkdir(destination + string(filesep)...
            + file_list(i).name);
        copyOrLinkFilesBasedOnSizeThreshold(source + string(filesep)...
            + file_list(i).name, destination + string(filesep)...
            + file_list(i).name, threshold, log_file_id);
    elseif file_list(i).bytes > threshold...
            && string(file_list(i).name) ~= "SUCCESS"
        createSymbolicLink(source + string(filesep) + file_list(i).name,...
            destination + string(filesep) + file_list(i).name, log_file_id);
    elseif string(file_list(i).name) ~= "SUCCESS"
        copyfile(source + string(filesep) + file_list(i).name, destination);
    end
end
end


