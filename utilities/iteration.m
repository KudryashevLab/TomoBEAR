function [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, tomogram_name, previous_tomogram_status)
% function [dynamic_configuration_out, status] = iteration(merged_configuration, pipeline_definition, ...
%         output_folder, scratch_folder, i, ...
%         configuration_history, dynamic_configuration_in, ...
%         tomogram_name, j, previous_tomogram_status, semaphore_key)
    %             processing_path = merged_configuration.processing_path;
    
    dynamic_configuration_out = struct;
%     pipeline_definition = strsplit(output_folder, string(filesep));
%     pipeline_definition = strsplit(pipeline_definition{end}, "_");    
%     if ~isempty(dir(merged_configuration.processing_path + string(filesep) + merged_configuration.output_folder + string(filesep) + "*" + pipeline_definition{2} + "*"))
%         pipeline_definition = strjoin({pipeline_definition{end-1:end}}, "_");
%     else
%         pipeline_definition = pipeline_definition{end-1};
%     end
    
%     if ~isfield(configuration_history, pipeline_definition)
%         configuration_history.(pipeline_definition) = struct;
%     end
    %configuration_history.(pipeline_definition) = struct;
    %             output_folder = "";
    %             scratch_folder = "";
    %             status = 0;
    if isfield(merged_configuration, "skip") && merged_configuration.skip == true
        status = previous_tomogram_status;
%         configuration_history.(pipeline_definition) = finishPipelineStep(...
%             dynamic_configuration_in, pipeline_definition, ...
%             configuration_history, i);
        return;
    end
  
%     merged_configuration.output_folder = merged_configuration.output_folder + string(filesep) + tomogram_name;
%     merged_configuration.scratch_folder = merged_configuration.scratch_folder + string(filesep) + tomogram_name;
    merged_configuration.pipeline_step_output_folder = merged_configuration.pipeline_step_output_folder + string(filesep) + tomogram_name;
    merged_configuration.pipeline_step_scratch_folder = merged_configuration.pipeline_step_scratch_folder + string(filesep) + tomogram_name;
    merged_configuration.output_path = merged_configuration.output_path + string(filesep) + tomogram_name;
    merged_configuration.scratch_path = merged_configuration.scratch_path + string(filesep) + tomogram_name;
    
    success_file_path = merged_configuration.output_path + string(filesep) + "SUCCESS";
    failure_file_path = merged_configuration.output_path + string(filesep) + "FAILURE";
    %                 status = 0;
    if fileExists(success_file_path) && merged_configuration.ignore_success_files == false
        disp("INFO: Skipping pipeline step for tomogram " + tomogram_name + " due to availability of a SUCCESS file!")
        dynamic_configuration_out = loadJSON(merged_configuration.output_path + string(filesep) + "output.json");
%         configuration_history.(pipeline_definition) = finishPipelineStep(...
%             dynamic_configuration_in, pipeline_definition, ...
%             configuration_history, i);
        status = 1;
        return;
    elseif fileExists(failure_file_path) && merged_configuration.ignore_success_files == false
        disp("INFO: Skipping pipeline step for tomogram " + tomogram_name + " due to availability of a FAILURE file!")
%         configuration_history.(pipeline_definition) = finishPipelineStep(...
%             dynamic_configuration_in, pipeline_definition, ...
%             configuration_history, i);
        status = 0;
        return;
    elseif ~isempty(previous_tomogram_status) && previous_tomogram_status == 0
        status = 0;
%         configuration_history.(pipeline_definition) = finishPipelineStep(...
%             dynamic_configuration_in, pipeline_definition, ...
%             configuration_history, i);
        fid = fopen(failure_file_path, 'wt');
        fclose(fid);
        return;
    end
    
%     output_folder_splitted = strsplit(output_folder, "/");
%     merged_configuration.pipeline_step_output_folder = strjoin(output_folder_splitted(end-2:end), "/");
%     scratch_folder_splitted = strsplit(scratch_folder, "/");
%     merged_configuration.pipeline_step_scratch_folder = strjoin(scratch_folder_splitted(end-2:end), "/");



    
    createOutputAndScratchFoldersForPipelineStep(merged_configuration);
	saveJSON(merged_configuration.output_path + string(filesep) + "input.json", merged_configuration);

%     pipeline_step_name = strsplit(pipeline_definition, "_");
%     function_handle = str2func(pipeline_step_name{1});

    function_handle = str2func(pipeline_definition);
    instantiated_class = function_handle(merged_configuration);
    instantiated_class = instantiated_class.setUp();
    if merged_configuration.execute == true
        instantiated_class = instantiated_class.process();
        dynamic_configuration_out = instantiated_class.dynamic_configuration;
    else
        dynamic_configuration_out = loadJSON(instantiated_class.output_path + string(filesep) + "output.json");
    end
    instantiated_class = instantiated_class.cleanUp();
    
    % dynamic_configuration_tmp.duration(j) = instantiated_class.duration;
    % dynamic_configuration_out = mergeConfigurations(dynamic_configuration_in, instantiated_class.dynamic_configuration, 0, "dynamic");
    status = instantiated_class.status;
%     configuration_history.(pipeline_definition) = mergeConfigurations(configuration_history.(pipeline_definition), instantiated_class.dynamic_configuration, 0, "dynamic");
    % configuration_history.(pipeline_definition).tomograms.(tomogram_name).processed_pipeline_steps = merged_configuration.tomograms.(tomogram_name).processed_pipeline_steps;
    % configuration_history.(pipeline_definition).tomograms.(tomogram_name).processed_pipeline_steps(i-1) = 1;
    
%     parforSave(semaphore_key, getMetaDataFilePath(merged_configuration), configuration_history);

    if status == 1
        fid = fopen(success_file_path, 'wt');
        saveJSON(instantiated_class.output_path + string(filesep) + "output.json", dynamic_configuration_out);
    elseif status == 0
        fid = fopen(failure_file_path, 'wt');
    end
    fclose(fid);
end
