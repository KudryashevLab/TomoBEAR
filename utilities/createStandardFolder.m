function folder = createStandardFolder(configuration, standard_folder, delete)
if isfield(configuration, standard_folder)
    if nargin == 2
        delete = true;
    end
    
    folder = configuration.processing_path + string(filesep)...
        + configuration.output_folder + string(filesep)...
        + configuration.(standard_folder);
    if exist(folder, "dir") && delete == true
        % TODO: add checks
        [status, message, message_id] = rmdir(folder, "s");
    end
    % TODO: add checks
    if ~exist(folder, "dir")
        [status, message, message_id] = mkdir(folder);
    end
else
    error("ERROR: standard folder not known!");
end
end
