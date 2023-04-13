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


function folder = createStandardFolder(configuration, standard_folder, delete)
if isfield(configuration, standard_folder)
    if nargin == 2
        delete = true;
    end
    
    folder = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.(standard_folder);
    if exist(folder, "dir") && delete == true
        % TODO: add checks
        [status, message, message_id] = rmdir(folder, "s");
    end
    % TODO: add checks
    if ~exist(folder, "dir")
        [status, message, message_id] = mkdir(folder);
    end
else
    error("ERROR: standard folder not known!");
end
end
