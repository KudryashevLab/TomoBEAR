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


function createDynamoLinks(dynamo_path, link_destination_path)
if nargin == 0
    error("ERROR: please provide path to dynamo")
end

if nargin == 1
    link_destination_path = "dynamo";
    create_files = true;
    copy_files = false;
    debug = true;
end

dynamo_path = addFileSeparator(dynamo_path);
link_destination_path = addFileSeparator(link_destination_path);

dynamo_source_paths = getDynamoFiles(dynamo_path)';
dynamo_destination_paths = getDynamoFiles(link_destination_path)';

if ~exist(link_destination_path, "dir")
    [success, message, message_id] = mkdir(link_destination_path);
    if success == true
        disp("INFO: link destination path (" + link_destination_path + ") successfully created");
    else
        error("ERROR: " + message + " (" + message_id + ")");
    end
end

for i = 1:length(dynamo_source_paths)
    file_source = dynamo_source_paths(i);
    file_destination = dynamo_destination_paths(i);
    if fileExists(file_source)
        [folder, ~, ~] = fileparts(file_destination);
        system("mkdir -p " + folder);
        if debug == true
            disp("DEBUG:INFO:SOURCE: " + file_source);
            disp("DEBUG:INFO:DESTINATION: " + file_destination);
        else
            disp(file_destination);
        end
        if copy_files == false && create_files == true
            system("ln -sf " + file_source + " " + file_destination);
        elseif copy_files == true && create_files == true
            system("cp " + file_source + " " + file_destination);
        end
    elseif i < 1110
        error("ERROR: file doesn't exist");
    else
    end
end
end