function [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, tomogram_name, previous_tomogram_status)
dynamic_configuration_out = struct;
if isfield(merged_configuration, "skip") && merged_configuration.skip == true
    status = previous_tomogram_status;
    return;
end
merged_configuration.pipeline_step_output_folder = merged_configuration.pipeline_step_output_folder + string(filesep) + tomogram_name;
merged_configuration.pipeline_step_scratch_folder = merged_configuration.pipeline_step_scratch_folder + string(filesep) + tomogram_name;
merged_configuration.output_path = merged_configuration.output_path + string(filesep) + tomogram_name;
merged_configuration.scratch_path = merged_configuration.scratch_path + string(filesep) + tomogram_name;
success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
failure_file_path = merged_configuration.output_path + string(filesep) + "FAILURE";
if fileExists(success_file_path) && merged_configuration.ignore_success_files == false
    disp("INFO: Skipping pipeline step for tomogram " + tomogram_name + " due to availability of a SUCCESS file!")
    dynamic_configuration_out = loadJSON(merged_configuration.output_path + string(filesep) + "output.json");
    status = 1;
    return;
elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
    disp("INFO: Skipping pipeline step for tomogram " + tomogram_name + " due to availability of a FAILURE file!")
    status = 0;
    return;
elseif ~isempty(previous_tomogram_status) && previous_tomogram_status == 0
    status = 0;
    fid = fopen(failure_file_path, 'wt');
    fclose(fid);
    return;
end
createOutputAndScratchFoldersForPipelineStep(merged_configuration);
saveJSON(merged_configuration.output_path + string(filesep) + "input.json", merged_configuration);
function_handle = str2func(pipeline_definition);
instantiated_class = function_handle(merged_configuration);
if merged_configuration.execute == true
    instantiated_class = instantiated_class.setUp();
    instantiated_class = instantiated_class.process();
    dynamic_configuration_out = instantiated_class.dynamic_configuration;
else
    dynamic_configuration_out = loadJSON(instantiated_class.output_path + string(filesep) + "output.json");
end
instantiated_class = instantiated_class.cleanUp();
status = instantiated_class.status;
if status == 1
    fid = fopen(success_file_path, 'wt');
    saveJSON(instantiated_class.output_path + string(filesep) + "output.json", dynamic_configuration_out);
elseif status == 0
    fid = fopen(failure_file_path, 'wt');
end
fclose(fid);
end
