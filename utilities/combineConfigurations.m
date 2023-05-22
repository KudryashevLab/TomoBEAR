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


function [first_configuration_out, second_configuration_out] = combineConfigurations(first_configurations_in, second_configurations_in)
if length(first_configurations_in) > 1
    for j = 1:length(first_configurations_in) - 1
        if j == 1
            first_configuration_out = mergeConfigurations(first_configurations_in{j},...
                first_configurations_in{j + 1}, 0, "dynamic");
            if nargin == 3
                second_configuration_out = mergeConfigurations(second_configurations_in{j},...
                    second_configurations_in{j + 1}, 0, "dynamic");
            end
        else
            first_configuration_out = mergeConfigurations(first_configuration_out,...
                first_configurations_in{j + 1}, 0, "dynamic");
            if nargin == 3
                second_configuration_out = mergeConfigurations(second_configuration_out,...
                    second_configurations_in{j + 1}, 0, "dynamic");
            end
        end
    end
elseif length(first_configurations_in) == 1
    first_configuration_out = first_configurations_in{1};
    if nargin == 3
        second_configuration_out = second_configurations_in{1};
    end
else
    error("ERROR: no configurations to combine!");
end
end