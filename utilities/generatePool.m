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


function generatePool(cores, force, path, debug)
persistent previous_cores;
if isempty(previous_cores)
	previous_cores = 0;
end

poolobj = gcp('nocreate');
pc = parcluster('local');
if string(path) ~= ""
    pc.JobStorageLocation = char(path);
end

if force || previous_cores == 0 || previous_cores ~= cores
    
    poolsize = getCpuPoolSize(cores);
    
    % open a pool
    if isempty(poolobj)
        disp("INFO:poolsize: " + poolsize);
        poolobj = parpool(pc, poolsize);
    else
        current_poolsize = poolobj.NumWorkers;
        if current_poolsize ~= poolsize
            disp("INFO:poolsize: " + poolsize);
            delete(poolobj);
            poolobj = parpool(pc, poolsize);
        end
    end
end
previous_cores = cores;
end


