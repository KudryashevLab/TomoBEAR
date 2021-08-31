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
    dynamic_configuration = mergeConfigurations(dynamic_configuration, dynamic_configuration_temporary, 0, "dynamic");
end
end