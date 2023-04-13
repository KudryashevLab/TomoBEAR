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


function dynamic_configuration = finishPipelineStep(...
    dynamic_configuration, pipeline_definition,...
    configuration_history, i)
% TODO: merge only dynamic_configuration in, first it
% needs to be stored or is it already stored? seems so...
if ~isfield(configuration_history, pipeline_definition)
    disp("INFO: No history available for step " + num2str(i - 1) +...
        " (" + pipeline_definition + ")!")
    dynamic_configuration_temporary = struct();
else
    dynamic_configuration_temporary = configuration_history.(pipeline_definition);
end
disp("INFO: Skipping processing step " + num2str(i - 1) +...
    " (" + pipeline_definition + ")!");
% NOTE: downstreams all properties of every
% dynamic_configuration_temporary and possibly overwrites
% with new values
if ~isempty(fieldnames(dynamic_configuration_temporary))
    dynamic_configuration = mergeConfigurations(dynamic_configuration,...
        dynamic_configuration_temporary, 0, "dynamic");
end
end