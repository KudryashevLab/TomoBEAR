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


function runTomoBear(compute_environment, configuration_path, default_configuration_path, starting_tomogram, ending_tomogram, step, gpu)
if nargin <= 2
    if fileExists("CONFIGURATION")
        default_configuration_path = string(fread(fopen("CONFIGURATION"), "*char")');
    else
        default_configuration_path = "./configurations/defaults.json";
    end
end
if nargin <= 3
    starting_tomogram = -1;
    ending_tomogram = -1;
    step = -1;
    gpu = -2;
end
runPipeline(compute_environment, configuration_path, default_configuration_path, starting_tomogram, ending_tomogram, step, gpu);
end

