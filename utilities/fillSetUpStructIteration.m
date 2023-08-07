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

function configuration = fillSetUpStructIteration(configuration, j, previous_tomogram_status)
configuration.set_up.j = j;
configuration.set_up.cumulative_tomogram_status = cumsum(previous_tomogram_status);
if isscalar(configuration.gpu) && configuration.gpu == -1
    configuration.set_up.gpu_sequence = mod(configuration.set_up.cumulative_tomogram_status - 1,...
        configuration.environment_properties.gpu_count) + 1;
elseif isscalar(configuration.gpu) && configuration.gpu >= 0
    configuration.set_up.gpu_sequence = repmat(configuration.gpu, [1 length(previous_tomogram_status)]);
elseif ~isscalar(configuration.gpu)
    configuration.set_up.gpu_sequence = mod(configuration.set_up.cumulative_tomogram_status - 1,...
        length(configuration.gpu)) + 1;
    configuration.set_up.gpu_sequence = configuration.gpu(configuration.set_up.gpu_sequence)';
end
configuration.set_up.gpu = configuration.set_up.gpu_sequence(j);
configuration.set_up.adjusted_j = configuration.set_up.cumulative_tomogram_status(j);
end
