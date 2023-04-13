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


function poolsize = getCpuPoolSize(cores, cores_requested)

% get number of cores available on the used machine
% and assigned to MATLAB
if cores <= 1
    if nargin == 1
        poolsize = round(feature('numcores') / cores);
    else
        poolsize = round(cores_requested / cores);
    end
else
    poolsize = round(cores);
end
    
% check whether required poolsize do not exceed number of workers
% allowed by used parcluster profile settings
pc = parcluster('local');
if poolsize > pc.NumWorkers
    poolsize = pc.NumWorkers;
end

end