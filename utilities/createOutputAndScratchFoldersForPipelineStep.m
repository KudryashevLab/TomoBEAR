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


function createOutputAndScratchFoldersForPipelineStep(merged_configuration)
% TODO: check status
if exist(merged_configuration.output_path, "dir")...
        && merged_configuration.checkpoint_module == false
    [status_rmdir, message, message_id] = rmdir(merged_configuration.output_path, "s");
end

if exist(merged_configuration.scratch_path, "dir")...
        && merged_configuration.checkpoint_module == false
    [status_rmdir, message, message_id] = rmdir(merged_configuration.scratch_path, "s");
end

if ~exist(merged_configuration.output_path, "dir")
    [status_mkdir, message, message_id] = mkdir(merged_configuration.output_path);
end

if ~exist(merged_configuration.scratch_path, "dir")
    [status_mkdir, message, message_id] = mkdir(merged_configuration.scratch_path);
end
end