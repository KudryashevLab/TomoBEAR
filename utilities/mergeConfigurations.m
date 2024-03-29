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

function merged_configurations = mergeConfigurations(first_configuration, second_configuration, pipeline_step, script_name)
printVariable(first_configuration);
printVariable(second_configuration);
field_names = fieldnames(second_configuration);
merged_configurations = first_configuration;
for i = 1:length(field_names)
    if field_names{i} ~= "output_folder" && field_names{i} ~= "scratch_folder"
        if isstruct(second_configuration.(field_names{i})) && (field_names{i}) ~= "environmentProperties"
            if isscalar(second_configuration.(field_names{i}))
                if ~isfield(first_configuration, (field_names{i}))
                    first_configuration.(field_names{i}) = struct;
                end
                merged_configurations.(field_names{i}) = ...
                    mergeConfigurations(first_configuration.(field_names{i}), ...
                    second_configuration.(field_names{i}), pipeline_step, "dynamic");
            else
                for j = 1:length(second_configuration.(field_names{i}))
                    first_configuration.(field_names{i})(j) = struct(second_configuration.(field_names{i})(j));
                end
                for j = 1:length(second_configuration.(field_names{i}))
                    merged_configurations.(field_names{i})(j) = ...
                        mergeConfigurations(first_configuration.(field_names{i})(j), ...
                        second_configuration.(field_names{i})(j), pipeline_step, "dynamic");
                end
            end
        else
            merged_configurations.(field_names{i}) = ...
                second_configuration.(field_names{i});
        end
    elseif (field_names{i} == "output_folder" || field_names{i} == "scratch_folder")
        merged_configurations.(field_names{i}) = ...
            merged_configurations.(field_names{i}) ...
            + string(filesep) ...
            + pipeline_step + "_" + second_configuration.(field_names{i});
    end
end
% NOTE: be careful if a script outputs output_folder field as
% dynamic variable
if ~any(ismember(field_names, "output_folder")) && script_name ~= "dynamic"
    merged_configurations.pipeline_step_output_folder =...
        first_configuration.output_folder + string(filesep)...
        + pipeline_step + "_" + script_name;
    merged_configurations.pipeline_step_output_folder =...
        increaseFolderNumber(merged_configurations,...
        merged_configurations.pipeline_step_output_folder);
end

if ~any(ismember(field_names, "scratch_folder")) && script_name ~= "dynamic"
    merged_configurations.pipeline_step_scratch_folder =...
        first_configuration.scratch_folder + string(filesep)...
        + pipeline_step + "_" + script_name;
    merged_configurations.pipeline_step_scratch_folder =...
        increaseFolderNumber(merged_configurations,...
        merged_configurations.pipeline_step_scratch_folder);
end
printVariable(merged_configurations);
end