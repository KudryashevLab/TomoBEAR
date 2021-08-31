function [folder, previous_folder] = increaseFolderNumber(configuration, folder)

dir_list = dir(folder + "*");
if ~isempty(dir_list) && configuration.increase_folder_numbers == true
    previous_folder = dir_list(end).folder + string(filesep) + dir_list(end).name;
    splitted_output_folder_string = strsplit(dir_list(end).name, "_");
    number = str2double(splitted_output_folder_string(end));
    joined_output_folder_string = strjoin(splitted_output_folder_string(1:end - 1), "_");
    joined_output_folder_string = joined_output_folder_string + "_" + string(number + 1);
    splitted_path_string = strsplit(configuration.output_folder, string(filesep));
    if string(inputname(2)) == "output_folder"
        configuration.pipeline_step_output_folder = splitted_path_string(1) + string(filesep) + joined_output_folder_string;
    else
        configuration.pipeline_step_scratch_folder = splitted_path_string(1) + string(filesep) + joined_output_folder_string;
    end
    folder = configuration.processing_path + string(filesep) + configuration.pipeline_step_output_folder;
else
    previous_folder = folder + "_1";
    folder = folder + "_1";
    splitted_output_folder = strsplit(folder, string(filesep));
    folder = strjoin(splitted_output_folder(end-1:end), string(filesep));
end
end

