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

function [dynamic_configuration, file_count_changed] = getUnprocessedTomograms(configuration, log_file_id)
dynamic_configuration = struct;
original_files = getOriginalFiles(configuration, false);
original_files = original_files(~startsWith({original_files.name}, "."));

if ~isempty(original_files) && checkForMultipleExtensions({original_files.name})
    error("ERROR: Multiple unknown extensions found!");
end
file_count = length(original_files);
if ~isfield(configuration, "file_count") || (isfield(configuration, "file_count") && (configuration.file_count < file_count))
    dynamic_configuration.file_count = length(original_files);
    if isempty(original_files)
        file_count_changed = false;
        return;
    else
        file_count_changed = true;
    end
else
    dynamic_configuration.file_count = configuration.file_count;
    dynamic_configuration.tomograms_count = configuration.tomograms_count;
    if ~isfield(configuration, "starting_tomogram")
        dynamic_configuration.starting_tomogram = 1;
    else
        dynamic_configuration.starting_tomogram = configuration.starting_tomogram;
    end
    file_count_changed = false;
    return;
end

if configuration.automatic_filename_parts_recognition == true
    for i = 1:length(original_files)
        current_file_name = original_files(i).name;
        current_file_name(current_file_name == '[') = '_';
        current_file_name(current_file_name == ']') = '';
        [name_number_mat, name_number_tok, name_number_ext] = regexp(current_file_name, configuration.name_number_regex, "match", 'tokens', 'tokenExtents');
        [angle_mat, angle_tok, angle_ext] = regexp(current_file_name, configuration.angle_regex, "match", 'tokens', 'tokenExtents');
        prefix = current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(1,2));
        
        if ~isempty(angle_ext)
            if name_number_ext{1}(2,2) >= angle_ext{1}(1) || (~isempty(regexp(current_file_name, "[-]*" ,"match")) && name_number_ext{1}(2,2) == angle_ext{1}(1) - 1)
                double_numbering = length(strsplit(current_file_name(name_number_ext{1}(2,1):angle_ext{1}(1)-2), "_")) >= 2;
            else
                double_numbering = length(strsplit(current_file_name(name_number_ext{1}(2,1):name_number_ext{1}(2,2)), "_")) >= 2;
            end
            
            if double_numbering == false
                tomogram_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_"));
            else
                break;
            end
            
            splitted_name = strsplit(current_file_name, "_");
            tomogram_numbers(i) = str2double(splitted_name{tomogram_number_position});
            
        elseif contains(current_file_name, ".frames.") || (isfield(configuration, "tilt_stacks") && configuration.tilt_stacks == false)
            break;
        else
            break;
        end
    end
    if exist("tomogram_numbers", "var")
        [~, idx] = sort(tomogram_numbers);
        original_files = original_files(idx);
    end
    for i = 1:length(original_files)
        current_file_name = original_files(i).name;
        current_file_name(current_file_name == '[') = '_';
        current_file_name(current_file_name == ']') = '';
        dynamic_configuration.original_files(i).name = original_files(i).name;
        dynamic_configuration.original_files(i).folder = original_files(i).folder;
        [name_number_mat, name_number_tok, name_number_ext] = regexp(current_file_name, configuration.name_number_regex, "match", 'tokens', 'tokenExtents');
        dynamic_configuration.original_files(i).prefix = current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(1,2));
        %TODO: probably need to modify prefix extraction
        dynamic_configuration.original_files(i).prefix_length = length(strsplit(dynamic_configuration.original_files(i).prefix, "_"));
        [angle_mat, angle_tok, angle_ext] = regexp(current_file_name, configuration.angle_regex, "match", 'tokens', 'tokenExtents');
        if ~isempty(angle_ext) && contains(dynamic_configuration.original_files(i).name, "Square")
            dynamic_configuration.original_files(i).double_numbering = true;
            underscore_indices = strfind(dynamic_configuration.original_files(i).name,"_");
            square_number = extractBetween(dynamic_configuration.original_files(i).name, 7, underscore_indices(1)-1);
            triple_index(i,1) = str2double(square_number{1});
            ts_number = extractBetween(dynamic_configuration.original_files(i).name, underscore_indices(2)+1, underscore_indices(3)-1);
            triple_index(i,2) = str2double(ts_number{1});
            dynamic_configuration.original_files(i).angle_position = length(strsplit(current_file_name(1:angle_ext{1}(2)), "_"));
            dynamic_configuration.original_files(i).position_adjustment = length(strsplit(dynamic_configuration.original_files(i).prefix, "_")) - 1;
            
            dynamic_configuration.original_files(i).angle_extents = angle_ext{1};
            dynamic_configuration.original_files(i).angle = str2double(current_file_name(angle_ext{1}(1):angle_ext{1}(2)));
            triple_index(i,3) = dynamic_configuration.original_files(i).angle;
            if isfield(configuration, "first_tilt_angle") &&  ~isstring(configuration.first_tilt_angle)
                dynamic_configuration.original_files(i).zero_tilt = dynamic_configuration.original_files(i).angle == configuration.first_tilt_angle;
            elseif i == 1
                dynamic_configuration.first_tilt_angle = dynamic_configuration.original_files(i).angle;
                dynamic_configuration.original_files(i).zero_tilt = 1;
            else
                dynamic_configuration.original_files(i).zero_tilt = dynamic_configuration.original_files(i).angle == dynamic_configuration.first_tilt_angle;
            end
            dynamic_configuration.tilt_stacks = false;


            dynamic_configuration.original_files(i).tomogram_number_position = 1;
            dynamic_configuration.original_files(i).adjusted_tomogram_number_position = 1;
            dynamic_configuration.original_files(i).tilt_number_position = 3;
            dynamic_configuration.original_files(i).adjusted_tilt_number_position = 3;
            dynamic_configuration.original_files(i).date_position = 5;
            dynamic_configuration.original_files(i).time_position = 6;
            dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = true;
            dynamic_configuration.original_files(i).double_numbering = true;
        elseif ~isempty(angle_ext) 
            dynamic_configuration.original_files(i).angle_position = length(strsplit(current_file_name(1:angle_ext{1}(2)), "_"));
            dynamic_configuration.original_files(i).position_adjustment = length(strsplit(dynamic_configuration.original_files(i).prefix, "_")) - 1;
            
            dynamic_configuration.original_files(i).angle_extents = angle_ext{1};
            dynamic_configuration.original_files(i).angle = str2double(current_file_name(angle_ext{1}(1):angle_ext{1}(2)));
            if isfield(configuration, "first_tilt_angle") &&  ~isstring(configuration.first_tilt_angle)
                dynamic_configuration.original_files(i).zero_tilt = dynamic_configuration.original_files(i).angle == configuration.first_tilt_angle;
            elseif i == 1
                dynamic_configuration.first_tilt_angle = dynamic_configuration.original_files(i).angle;
                dynamic_configuration.original_files(i).zero_tilt = 1;
            else
                dynamic_configuration.original_files(i).zero_tilt = dynamic_configuration.original_files(i).angle == dynamic_configuration.first_tilt_angle;
            end
            
            if name_number_ext{1}(2,2) >= angle_ext{1}(1) || (~isempty(regexp(current_file_name, "[-]*" ,"match")) && name_number_ext{1}(2,2) == angle_ext{1}(1) - 1)
                dynamic_configuration.original_files(i).double_numbering = length(strsplit(current_file_name(name_number_ext{1}(2,1):angle_ext{1}(1)-2), "_")) >= 2;
            else
                dynamic_configuration.original_files(i).double_numbering = length(strsplit(current_file_name(name_number_ext{1}(2,1):name_number_ext{1}(2,2)), "_")) >= 2;
            end
            
            if dynamic_configuration.original_files(i).double_numbering == false
                dynamic_configuration.original_files(i).tomogram_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_"));
                dynamic_configuration.original_files(i).adjusted_tomogram_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                
                dynamic_configuration.original_files(i).tilt_number_position = 0;
                dynamic_configuration.original_files(i).adjusted_tilt_number_position = 0;
                
            else
                dynamic_configuration.original_files(i).tomogram_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_"));
                dynamic_configuration.original_files(i).tilt_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,2)), "_"));
                dynamic_configuration.original_files(i).adjusted_tomogram_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).adjusted_tilt_number_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):name_number_ext{1}(2,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
            end
            
            if dynamic_configuration.original_files(i).tomogram_number_position == dynamic_configuration.original_files(i).prefix_length
                dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = true;
                dynamic_configuration.original_files(i).prefix_extents = name_number_ext{1}(1,:);
            else
                dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = false;
            end
            
            if dynamic_configuration.original_files(i).double_numbering == false
                if  dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number == true
                    dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment + 1 + 1;
                else
                    dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment + 1;
                end
                
            else
                if  dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number == true
                    dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment + 1;
                else
                    dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment;
                end
            end
            
            [month_date_time_mat, month_date_time_tok, month_date_time_ext] = regexp(current_file_name, configuration.month_date_time_regex, "match", 'tokens', 'tokenExtents');
            if isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = 0;
                dynamic_configuration.original_files(i).time_position = 0;
            elseif ~isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_"));
                dynamic_configuration.original_files(i).time_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_"));
                dynamic_configuration.original_files(i).adjusted_date_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).adjusted_time_position = length(strsplit(current_file_name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).date_time = strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_");
                dynamic_configuration.original_files(i).date = dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).date_position};
                dynamic_configuration.original_files(i).time = dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).time_position};
                dynamic_configuration.original_files(i).date_time = dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).date_position} + "_" + dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).time_position};
                configuration.ignore_file_system_time_stamps = false;
            end
            dynamic_configuration.original_files(i).tilt_stack = false;
            dynamic_configuration.tilt_stacks = false;
        elseif contains(dynamic_configuration.original_files(i).name, ".frames.") || (isfield(configuration, "tilt_stacks") && configuration.tilt_stacks == false)
            dynamic_configuration.original_files(i).double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):name_number_ext{1}(2,2)), "_")) >= 2;
            dynamic_configuration.original_files(i).position_adjustment = length(strsplit(dynamic_configuration.original_files(i).prefix, "_")) - 1;
            
            if dynamic_configuration.original_files(i).double_numbering == false
                dynamic_configuration.original_files(i).tomogram_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_"));
                dynamic_configuration.original_files(i).adjusted_tomogram_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                
                dynamic_configuration.original_files(i).tilt_number_position = 0;
                dynamic_configuration.original_files(i).adjusted_tilt_number_position = 0;
                
            else
                dynamic_configuration.original_files(i).tomogram_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_"));
                dynamic_configuration.original_files(i).tilt_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,2)), "_"));
                dynamic_configuration.original_files(i).adjusted_tomogram_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).adjusted_tilt_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
            end
            
            if ~exist("previous_tomogram_number", "var") || (isfield(configuration, "projections") && mod(i, configuration.projections))
                projection_number = 1;
            else
                projection_number = projection_number + 1;
            end
            projection_number = projection_number + 1;
            dynamic_configuration.original_files(i).zero_tilt = configuration.tilt_angles(projection_number) == configuration.tilt_angles(1);
            
            if dynamic_configuration.original_files(i).tomogram_number_position == dynamic_configuration.original_files(i).prefix_length
                dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = true;
                dynamic_configuration.original_files(i).prefix_extents = name_number_ext{1}(1,:);
            else
                dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = false;
            end
            
            [month_date_time_mat, month_date_time_tok, month_date_time_ext] = regexp(original_files(i).name, configuration.month_date_time_regex, "match", 'tokens', 'tokenExtents');
            if isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = 0;
                dynamic_configuration.original_files(i).time_position = 0;
            elseif ~isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_"));
                dynamic_configuration.original_files(i).time_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_"));
                dynamic_configuration.original_files(i).adjusted_date_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).adjusted_time_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).date_time = srsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_");
                dynamic_configuration.original_files(i).date = dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).date_position};
                dynamic_configuration.original_files(i).time = dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).time_position};
                dynamic_configuration.original_files(i).date_time = dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).date_position} + "_" + dynamic_configuration.original_files(i).date_time{dynamic_configuration.original_files(i).time_position};
                configuration.ignore_file_system_time_stamps = false;
            end
            
            dynamic_configuration.tilt_stacks = false;
            dynamic_configuration.original_files(i).tilt_stack = false;
            dynamic_configuration.original_files(i).angle = configuration.tilt_angles(projection_number);
        else
            dynamic_configuration.original_files(i).tilt_stack = true;
            dynamic_configuration.tilt_stacks = true;
        end
        
        % re-write with the user-enforced parameters values if present
        % NOTE:TODO: dirty, subject for later refactoring!
        if isfield(configuration, "tomogram_number_position") && configuration.tomogram_number_position ~= -1
            dynamic_configuration.original_files(i).tomogram_number_position = configuration.tomogram_number_position;
        end
        
        if isfield(configuration, "tilt_number_position") && configuration.tilt_number_position ~= -1
            dynamic_configuration.original_files(i).tilt_number_position = configuration.tilt_number_position;
        end
        
        if isfield(configuration, "angle_position") && configuration.angle_position ~= -1
            dynamic_configuration.original_files(i).angle_position = configuration.angle_position;
        end
        
        if isfield(configuration, "date_position") && configuration.date_position ~= -1
            dynamic_configuration.original_files(i).date_position = configuration.date_position;
        end
        
        if isfield(configuration, "time_position") && configuration.time_position ~= -1
            dynamic_configuration.original_files(i).time_position = configuration.time_position;
        end
        
    end
    
    %[values, indices] = sort({dynamic_configuration.original_files.name});
    if contains(dynamic_configuration.original_files(i).name, "Square") && dynamic_configuration.tilt_stacks == false
        [~, I] = sortrows(triple_index, [1 2]);
        dynamic_configuration.original_files = dynamic_configuration.original_files(I);
    end

    if dynamic_configuration.tilt_stacks == false
        start_indices = find([dynamic_configuration.original_files(:).zero_tilt]);
        file_paths = (string({dynamic_configuration.original_files.folder}) + string(filesep) + string({dynamic_configuration.original_files.name}))';
    else
        start_indices = 1:length(dynamic_configuration.original_files(:));
        file_paths = (string({dynamic_configuration.original_files.folder}) + string(filesep) + string({dynamic_configuration.original_files.name}))';
    end
else
    bytes = [original_files.bytes]';
    mean_bytes = mean(bytes);
    % TODO: implement something if high dose images are not used
    start_indices = find(bytes > (2 * mean_bytes));
    
    if any(start_indices)
        configuration.high_dose = 1;
        dynamic_configuration.high_dose = 1;
        disp("INFO: high dose images detected!");
    else
        configuration.high_dose = 0;
        dynamic_configuration.high_dose = 0;
        disp("INFO: high dose images are not detected!");
    end
    
    if length(configuration.data_path) > 1 && tif_flag ~= true
        dynamic_configuration.mrc_count_per_tomogram = median(start_indices(2:end) - start_indices(1:end - 1));
    else
        counter = 1;
        for i = 2:length(original_files)
            if ~isempty(regexp(original_files(i).name,"_[+-]*0{2}\.0", "match")) % abs(dynamic_configuration.original_files(i-1).angle) < abs(dynamic_configuration.original_files(i).angle)
                start_indices(counter) = i-1;
                counter = counter + 1;
            end
        end
    end
    file_paths = (string({original_files.folder}) + string(filesep) + string({original_files.name}))';
end

if configuration.ignore_file_system_time_stamps == false
    % TODO: Possibly extract to function, loop taken from below
    extracted_date_strings = string([]);
    extracted_date_strings_indices = (1:length(file_paths))';
    if isfield(configuration, "date_position") && configuration.date_position ~= 0
        month_day_format = "MMMdd";
    else
        month_day_format = "yyyy-MM-dd";
    end
    if isfield(configuration, "time_position") && configuration.time_position ~= 0
        time_format = "HH.mm.ss";
    else
        time_format = "HH:mm:ss.SSSSSSSSS";
    end
    
    for i = 1:file_count
        disp("INFO: Processing file " + i + " out of " + file_count + "!");
        [path, name, extension] = fileparts(file_paths(i));
        name_parts = strsplit(name, '_');
        if isfield(configuration, "date_position") && configuration.date_position ~= 0
            if isfield(dynamic_configuration.original_files(i),"date")
                month_day = dynamic_configuration.original_files(i).date;
            else
                month_day = name_parts(configuration.date_position);
            end
        else
            % NOTE: assumption is that data is copied like that "cp --preserve=timestamps -R /sbdata/EM/Krios_K2/2018-12-29_yizhang_5ht3rMVs_64k/64k_97e/* ."
            [status, output] = system("stat " + file_paths(i));
            [mat,tok,ext] = regexp(output, "Modify: (\d+-\d+-\d+) (\d+:\d+:\d+.\d+)", "match",...
                'tokens', 'tokenExtents');
            month_day = tok{1}{1};
        end
        if isfield(configuration, "time_position") && configuration.time_position ~= 0
            if isfield(dynamic_configuration.original_files(i),"time")
                time = dynamic_configuration.original_files(i).time;
            else
                time = name_parts(configuration.time_position);
            end
        else
            [status, output] = system("stat " + file_paths(i));
            [mat,tok,ext] = regexp(output, "Modify: (\d+-\d+-\d+) (\d+:\d+:\d+.\d+)", "match",...
                'tokens', 'tokenExtents');
            time = tok{1}{2};
        end
        extracted_date_strings(i) = month_day + " " + time;
    end
    extracted_date_strings = extracted_date_strings';
    extracted_dates = datetime(extracted_date_strings, "Format", month_day_format + " " + time_format, "TimeZone", "local");
    extracted_dates_tabularized = table(extracted_dates, extracted_date_strings_indices);
    extracted_dates_tabularized_sorted = sortrows(extracted_dates_tabularized, "extracted_dates");
    
    sorted_files = file_paths(extracted_dates_tabularized_sorted.extracted_date_strings_indices);
    
    zero_tilt = [dynamic_configuration.original_files.zero_tilt];
    zero_sorted = zero_tilt(extracted_dates_tabularized_sorted.extracted_date_strings_indices);
    start_indices = find(zero_sorted);
else
    sorted_files = file_paths;
end

% TODO: Make it also work for other tilt schemes
% NOTE: Checks if some high dose file was found
if length(start_indices) == 1
    start_indices(2) = numel(original_files) + 1;
    iteration_count = length(start_indices) - 2;
else
    iteration_count = length(start_indices) - 1;
end

if ~isfield(dynamic_configuration, "tomograms_count") || (isfield(dynamic_configuration, "tomograms_count") && (dynamic_configuration.tomograms_count < iteration_count))
    dynamic_configuration.tomograms_count = iteration_count + 1;
else
    dynamic_configuration.tomograms = configuration.tomograms;
    return;
end

if isfield(configuration, "tomogram_input_prefix") && isempty(configuration.tomogram_input_prefix)
    tomogram_input_prefix = string(splitted_mrc_name(1:configuration.angle_position - 2));
    variable_string = printVariableToString(tomogram_input_prefix);
    printToFile(log_file_id, variable_string);
else
    tomogram_input_prefix = configuration.tomogram_input_prefix;
end

if isfield(configuration, "tomogram_output_prefix") && ~isempty(configuration.tomogram_output_prefix)
    tomogram_output_prefix = configuration.tomogram_output_prefix;
else
    tomogram_output_prefix = tomogram_input_prefix;
end

dynamic_configuration.tomograms = struct();
if dynamic_configuration.tilt_stacks == false
    current_tomogram = 0;
    for i = 0:iteration_count
        if ~isfield(configuration, "starting_tomogram")
            current_tomogram_index = 1 + current_tomogram;
        else
            current_tomogram_index = configuration.starting_tomogram + current_tomogram;
        end
        tomogram_name = sprintf("%s_%03d", tomogram_output_prefix, current_tomogram_index);
        fprintf("Processing Tomogram "...
            + num2str(current_tomogram_index) + "\n");
        
        % NOTE: handle case for handling the last element
        if i + 2 > length(start_indices)
            tomogram_file_indices = start_indices(i + 1):length(sorted_files);
        else
            tomogram_file_indices = start_indices(i + 1):start_indices(i + 2)-1;
        end
        disp("INFO: Number of files available: " + num2str(length(tomogram_file_indices)));
        if length(tomogram_file_indices) < configuration.minimum_files
            disp("INFO: Not enough files for this tomogram to do reconstructions!");
            dynamic_configuration.tomograms.(tomogram_name).skipped = true;
        else
            dynamic_configuration.tomograms.(tomogram_name).skipped = false;
        end
        
        angles = [dynamic_configuration.original_files(tomogram_file_indices).angle];
        
        if configuration.duplicated_tilts == "first"
            [uniqueA, i, j] = unique(angles,"first");
        elseif configuration.duplicated_tilts == "last" || configuration.duplicated_tilts == "keep"
            [uniqueA, i, j] = unique(angles,"last");
        end
        
        index_to_dupes = find(not(ismember(1:numel(angles),i)));
        
        
        if ~isempty(index_to_dupes)
            dynamic_configuration.tomograms.(tomogram_name).duplicates_found = true;
            dynamic_configuration.tomograms.(tomogram_name).duplicates = index_to_dupes;
        else
            dynamic_configuration.tomograms.(tomogram_name).duplicates_found = false;
            dynamic_configuration.tomograms.(tomogram_name).duplicates = index_to_dupes;
        end
        
        diff_index_to_dupes = diff(index_to_dupes);
        if any(diff_index_to_dupes > 1)
            dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_found = true;
        else
            dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_found = false;
        end
        
        dynamic_configuration.tomograms.(tomogram_name).original_angles = angles;
        dynamic_configuration.tomograms.(tomogram_name).original_tomogram_file_indices = tomogram_file_indices;
        dynamic_configuration.tomograms.(tomogram_name).original_file_paths = file_paths(tomogram_file_indices);%sorted_files(tomogram_file_indices);
        
        if configuration.duplicated_tilts ~= "keep"
            tomogram_file_indices(index_to_dupes) = [];
            angles(index_to_dupes) = [];
        end
        
        if length(tomogram_file_indices) < configuration.minimum_files
            disp("INFO: After cleaning duplicates not enough files left to do reconstructions for this tomogram!");
            % NOTE: to be able to check one flag only but to know when it was
            % skipped
            dynamic_configuration.tomograms.(tomogram_name).skipped = true;
            dynamic_configuration.tomograms.(tomogram_name).skipped_after_cleaning_duplicates = true;
        else
            dynamic_configuration.tomograms.(tomogram_name).skipped_after_cleaning_duplicates = false;
        end
        
        [~, time_sort_idx] = ismember(sorted_files(tomogram_file_indices), file_paths(tomogram_file_indices));
        dynamic_configuration.tomograms.(tomogram_name).angles = angles(time_sort_idx);
        dynamic_configuration.tomograms.(tomogram_name).tomogram_file_indices = tomogram_file_indices;
        dynamic_configuration.tomograms.(tomogram_name).name = {dynamic_configuration.original_files(tomogram_file_indices).name};
        dynamic_configuration.tomograms.(tomogram_name).folder = dynamic_configuration.original_files(tomogram_file_indices(1)).folder;
        dynamic_configuration.tomograms.(tomogram_name).file_paths = sorted_files(tomogram_file_indices);
        dynamic_configuration.tomograms.(tomogram_name).tomogram_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).tomogram_number_position;
        dynamic_configuration.tomograms.(tomogram_name).adjusted_tomogram_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_tomogram_number_position;
        dynamic_configuration.tomograms.(tomogram_name).tilt_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).tilt_number_position;
        dynamic_configuration.tomograms.(tomogram_name).adjusted_tilt_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_tilt_number_position;
        dynamic_configuration.tomograms.(tomogram_name).date_position = dynamic_configuration.original_files(tomogram_file_indices(1)).date_position;
        dynamic_configuration.tomograms.(tomogram_name).time_position = dynamic_configuration.original_files(tomogram_file_indices(1)).time_position;
        
        if isfield(configuration, "live_data_mode") && configuration.live_data_mode == true
            [~, last_collected_frame_name, ~] = fileparts(sorted_files(tomogram_file_indices(end)));
            last_collected_frame_name_split = strsplit(last_collected_frame_name, '_');
            dynamic_configuration.tomograms.(tomogram_name).last_collected_frame_date = last_collected_frame_name_split(dynamic_configuration.tomograms.(tomogram_name).date_position);
            dynamic_configuration.tomograms.(tomogram_name).last_collected_frame_time = last_collected_frame_name_split(dynamic_configuration.tomograms.(tomogram_name).time_position);
        end
        
        dynamic_configuration.tomograms.(tomogram_name).zero_tilt = [dynamic_configuration.original_files(tomogram_file_indices).zero_tilt];
        [sorted_angle_values, sorted_angle_indices] = sort([dynamic_configuration.original_files(tomogram_file_indices).angle]);
        dynamic_configuration.tomograms.(tomogram_name).sorted_angles = sorted_angle_values;
        dynamic_configuration.tomograms.(tomogram_name).sorted_zero_tilt = dynamic_configuration.tomograms.(tomogram_name).zero_tilt(sorted_angle_indices);
        dynamic_configuration.tomograms.(tomogram_name).prefix = dynamic_configuration.original_files(tomogram_file_indices(1)).prefix;
        dynamic_configuration.tomograms.(tomogram_name).missing_underscore_between_tomogram_name_and_number = dynamic_configuration.original_files(tomogram_file_indices(1)).missing_underscore_between_tomogram_name_and_number;
        dynamic_configuration.tomograms.(tomogram_name).double_numbering = dynamic_configuration.original_files(tomogram_file_indices(1)).double_numbering;
        [folder, name, extension] = fileparts(dynamic_configuration.tomograms.(tomogram_name).name{1});
        dynamic_configuration.tomograms.(tomogram_name).tif = string(extension) == ".tif";
        dynamic_configuration.tomograms.(tomogram_name).mrc = string(extension) == ".mrc";
        dynamic_configuration.tomograms.(tomogram_name).eer = string(extension) == ".eer";
        current_tomogram = current_tomogram + 1;
    end
else
    current_tomogram = 0;
    for i = 0:iteration_count
        if ~isfield(configuration, "starting_tomogram")
            current_tomogram_index = 1 + current_tomogram;
        else
            current_tomogram_index = configuration.starting_tomogram + current_tomogram;
        end
        
        tomogram_name = sprintf("%s_%03d", tomogram_output_prefix, current_tomogram_index);
        fprintf("Processing Tomogram "...
            + num2str(current_tomogram_index) + "\n");
        
        % NOTE: handle case for handling the last element
        if i + 2 > length(start_indices)
            tomogram_file_indices = start_indices(i + 1):length(sorted_files);
        else
            tomogram_file_indices = start_indices(i + 1):start_indices(i + 2)-1;
        end
        
        dynamic_configuration.tomograms.(tomogram_name).original_file_paths = sorted_files(tomogram_file_indices);
        dynamic_configuration.tomograms.(tomogram_name).name = {dynamic_configuration.original_files(tomogram_file_indices).name};
        dynamic_configuration.tomograms.(tomogram_name).folder = dynamic_configuration.original_files(tomogram_file_indices(1)).folder;
        dynamic_configuration.tomograms.(tomogram_name).file_paths = sorted_files(tomogram_file_indices);
        
        fid = fopen(dynamic_configuration.tomograms.(tomogram_name).folder + string(filesep) + dynamic_configuration.original_files(tomogram_file_indices).name + ".mdoc");
        counter = 1;
        if fid ~= -1
            while ~feof(fid)
                tmp = string(fgets(fid));
                if contains(tmp, "TiltAngle")
                    tmp_match = regexp(tmp, "[+-]*\d+.\d+", "match");
                    angle = str2num(tmp_match);
                    dynamic_configuration.original_files(tomogram_file_indices).angle(counter) = angle;
                    dynamic_configuration.tomograms.(tomogram_name).sorted_angles(counter) = angle;
                    if angle <= 0.5 && angle >= -0.5
                        dynamic_configuration.tomograms.(tomogram_name).zero_tilt(counter) = 1;
                        dynamic_configuration.tomograms.(tomogram_name).sorted_zero_tilt(counter) = 1;
                    else
                        dynamic_configuration.tomograms.(tomogram_name).zero_tilt(counter) = 0;
                        dynamic_configuration.tomograms.(tomogram_name).sorted_zero_tilt(counter) = 0;
                    end
                    counter = counter + 1;
                end
                if contains(tmp, "ExposureDose")
                    tmp_match = regexp(tmp, "\d+.\d+", "match");
                    dose = str2num(tmp_match);
                    dynamic_configuration.original_files(tomogram_file_indices).dose(counter - 1) = dose;
                    dynamic_configuration.tomograms.(tomogram_name).dose(counter - 1) = dose;
                end
            end
            dynamic_configuration.tomograms.(tomogram_name).high_dose = unique(dynamic_configuration.tomograms.(tomogram_name).dose) >= 2;
        elseif isfield(dynamic_configuration, "tilt_stacks") && dynamic_configuration.tilt_stacks == true
            dynamic_configuration.tomograms.(tomogram_name).sorted_angles = sort(configuration.tilt_angles);
        end
        
        dynamic_configuration.tomograms.(tomogram_name).prefix = dynamic_configuration.original_files(tomogram_file_indices(1)).prefix;
        [folder, name, extension] = fileparts(dynamic_configuration.tomograms.(tomogram_name).name{1});
        dynamic_configuration.tomograms.(tomogram_name).tif = string(extension) == ".tif";
        dynamic_configuration.tomograms.(tomogram_name).mrc = string(extension) == ".mrc";
        dynamic_configuration.tomograms.(tomogram_name).eer = string(extension) == ".eer";
        current_tomogram = current_tomogram + 1;
    end
end

if ~isfield(configuration, "live_data_mode") || configuration.live_data_mode == false
    dynamic_configuration.starting_tomogram = current_tomogram;
end

end



