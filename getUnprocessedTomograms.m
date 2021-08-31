function [dynamic_configuration, file_count_changed] = getUnprocessedTomograms(configuration, log_file_id)

dynamic_configuration = struct;
original_files = getOriginalFiles(configuration, false);

if checkForMultipleExtensions({original_files.name})
    error("ERROR: Multiple unknown extensions found!");
end
file_count = length(original_files);
if ~isfield(configuration, "file_count") || (isfield(configuration, "file_count") && (configuration.file_count < file_count))
    dynamic_configuration.file_count = length(original_files);
    file_count_changed = true;
else
    dynamic_configuration.file_count = configuration.file_count;
    dynamic_configuration.tomograms_count = configuration.tomograms_count;
    dynamic_configuration.starting_tomogram = configuration.starting_tomogram;
    file_count_changed = false;
    return;
end

if configuration.automatic_filename_parts_recognition == true
    for i = 1:length(original_files)
        [name_number_mat, name_number_tok, name_number_ext] = regexp(original_files(i).name, configuration.name_number_regex, "match", 'tokens', 'tokenExtents');
        [angle_mat, angle_tok, angle_ext] = regexp(original_files(i).name, configuration.angle_regex, "match", 'tokens', 'tokenExtents');
        prefix = original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(1,2));

        if ~isempty(angle_ext)
            if name_number_ext{1}(2,2) >= angle_ext{1}(1) || (~isempty(regexp(original_files(i).name, "[-]*" ,"match")) && name_number_ext{1}(2,2) == angle_ext{1}(1) - 1)
                double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):angle_ext{1}(1)-2), "_")) >= 2;
            else
                double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):name_number_ext{1}(2,2)), "_")) >= 2;
            end
            
            if double_numbering == false
                tomogram_number_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(2,1)), "_"));
            else
                break;
            end
         
            splitted_name = strsplit(original_files(i).name, "_"); 
            tomogram_numbers(i) = str2double(splitted_name{tomogram_number_position});

        elseif contains(original_files(i).name, ".frames.") || (isfield(configuration, "tilt_stacks") && configuration.tilt_stacks == false)
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
        dynamic_configuration.original_files(i).name = original_files(i).name;
        dynamic_configuration.original_files(i).folder = original_files(i).folder;
        
        [name_number_mat, name_number_tok, name_number_ext] = regexp(original_files(i).name, configuration.name_number_regex, "match", 'tokens', 'tokenExtents');
        dynamic_configuration.original_files(i).prefix = original_files(i).name(name_number_ext{1}(1,1):name_number_ext{1}(1,2));
        %TODO: probably need to modify prefix extraction
        %         [name_mat, name_tok, name_ext] = regexp(original_files(i).name, configuration.name_regex, "match", 'tokens', 'tokenExtents');
        %         [number_mat, number_tok, number_ext] = regexp(original_files(i).name(name_ext{1}(1,1):name_ext{1}(1,2)), configuration.number_regex, "match", 'tokens', 'tokenExtents');
        %         dynamic_configuration.original_files(i).prefix = original_files(i).name(name_ext{1}(1,1):name_ext{1}(1,2));
        
        
        dynamic_configuration.original_files(i).prefix_length = length(strsplit(dynamic_configuration.original_files(i).prefix, "_"));
        [angle_mat, angle_tok, angle_ext] = regexp(original_files(i).name, configuration.angle_regex, "match", 'tokens', 'tokenExtents');
        if ~isempty(angle_ext)
            dynamic_configuration.original_files(i).angle_position = length(strsplit(original_files(i).name(1:angle_ext{1}(2)), "_"));
            dynamic_configuration.original_files(i).position_adjustment = length(strsplit(dynamic_configuration.original_files(i).prefix, "_")) - 1;
            
            
            dynamic_configuration.original_files(i).angle_extents = angle_ext{1};
            dynamic_configuration.original_files(i).angle = str2double(original_files(i).name(angle_ext{1}(1):angle_ext{1}(2)));
            if isfield(configuration, "first_tilt_angle") && configuration.first_tilt_angle ~= ""
                dynamic_configuration.original_files(i).zero_tilt = dynamic_configuration.original_files(i).angle == configuration.first_tilt_angle;
            elseif i == 1
                dynamic_configuration.first_tilt_angle = dynamic_configuration.original_files(i).angle;
                dynamic_configuration.original_files(i).zero_tilt = 1;
            else
                dynamic_configuration.original_files(i).zero_tilt = dynamic_configuration.original_files(i).angle == dynamic_configuration.first_tilt_angle;
            end
                
            
            if name_number_ext{1}(2,2) >= angle_ext{1}(1) || (~isempty(regexp(original_files(i).name, "[-]*" ,"match")) && name_number_ext{1}(2,2) == angle_ext{1}(1) - 1)
                dynamic_configuration.original_files(i).double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):angle_ext{1}(1)-2), "_")) >= 2;
            else
                dynamic_configuration.original_files(i).double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):name_number_ext{1}(2,2)), "_")) >= 2;
            end
            
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
            
            
            
            
            
            [month_date_time_mat, month_date_time_tok, month_date_time_ext] = regexp(original_files(i).name, configuration.month_date_time_regex, "match", 'tokens', 'tokenExtents');
            if isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = 0;
                dynamic_configuration.original_files(i).time_position = 0;
            elseif ~isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_"));
                dynamic_configuration.original_files(i).time_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_"));
                dynamic_configuration.original_files(i).adjusted_date_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).adjusted_time_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
            end
            dynamic_configuration.original_files(i).tilt_stack = false;
            dynamic_configuration.tilt_stacks = false;
        elseif contains(dynamic_configuration.original_files(i).name, ".frames.") || (isfield(configuration, "tilt_stacks") && configuration.tilt_stacks == false)
            dynamic_configuration.original_files(i).zero_tilt = configuration.tilt_angles(i) == configuration.tilt_angles(1);
            dynamic_configuration.original_files(i).position_adjustment = length(strsplit(dynamic_configuration.original_files(i).prefix, "_")) - 1;
%             if name_number_ext{1}(2,2) >= angle_ext{1}(1) || (~isempty(regexp(original_files(i).name, "[-]*" ,"match")) && name_number_ext{1}(2,2) == angle_ext{1}(1) - 1)
%                 dynamic_configuration.original_files(i).double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):angle_ext{1}(1)-2), "_")) >= 2;
%             else
                dynamic_configuration.original_files(i).double_numbering = length(strsplit(original_files(i).name(name_number_ext{1}(2,1):name_number_ext{1}(2,2)), "_")) >= 2;
%             end
            
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
            
            if dynamic_configuration.original_files(i).tomogram_number_position == dynamic_configuration.original_files(i).prefix_length
                dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = true;
                dynamic_configuration.original_files(i).prefix_extents = name_number_ext{1}(1,:);
            else
                dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number = false;
            end
            
%             if dynamic_configuration.original_files(i).double_numbering == false
%                 if  dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number == true
%                     dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment + 1 + 1;
%                 else
%                     dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment + 1;
%                 end
%                 
%             else
%                 if  dynamic_configuration.original_files(i).missing_underscore_between_tomogram_name_and_number == true
%                     dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).tomogram_number_position - dynamic_configuration.original_files(i).position_adjustment + 1;
%                 else
%                     dynamic_configuration.original_files(i).adjusted_angle_position = dynamic_configuration.original_files(i).angle_position - dynamic_configuration.original_files(i).position_adjustment;
%                 end
%             end
            
            [month_date_time_mat, month_date_time_tok, month_date_time_ext] = regexp(original_files(i).name, configuration.month_date_time_regex, "match", 'tokens', 'tokenExtents');
            if isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = 0;
                dynamic_configuration.original_files(i).time_position = 0;
            elseif ~isempty(month_date_time_ext)
                dynamic_configuration.original_files(i).date_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_"));
                dynamic_configuration.original_files(i).time_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_"));
                dynamic_configuration.original_files(i).adjusted_date_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(1,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
                dynamic_configuration.original_files(i).adjusted_time_position = length(strsplit(original_files(i).name(name_number_ext{1}(1,1):month_date_time_ext{1}(2,2)), "_")) - dynamic_configuration.original_files(i).position_adjustment;
            end
            
            dynamic_configuration.tilt_stacks = false;
            dynamic_configuration.original_files(i).tilt_stack = false;
            dynamic_configuration.original_files(i).angle = configuration.tilt_angles(i);
        else
            dynamic_configuration.original_files(i).tilt_stack = true;
            dynamic_configuration.tilt_stacks = true;
        end
    end
    
    if dynamic_configuration.tilt_stacks == false
        % if configuration.tilt_scheme == "bi_directional"
            start_indices = find([dynamic_configuration.original_files(:).zero_tilt]);
            file_paths = (string({original_files.folder}) + string(filesep) + string({original_files.name}))';
        % elseif configuration.tilt_scheme == "dose_symmetric"
        %     start_indices = find([dynamic_configuration.original_files(:).zero_tilt]);
        %     file_paths = (string({original_files.folder}) + string(filesep) + string({original_files.name}))';
        % else
            % error("ERROR: unknown tilt scheme: " + configuration.tilt_scheme);
        % end
    else
        start_indices = 1:length(dynamic_configuration.original_files(:));
        file_paths = (string({original_files.folder}) + string(filesep) + string({original_files.name}))';
    end
    %sorted_files = file_paths;
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
        for i = 1:length(original_files)
            if ~isempty(regexp(original_files(i).name,"_[+-]*0{2}\.0", "match"))
                start_indices(counter) = i;
                counter = counter + 1;
            end
        end
    end
    % % TODO: Find another / better way to distinguish tomograms
    % % TODO: extend for cases without known index of date and time
    % if (isfield(configuration, "date_position")...
    %         && 0 ~= configuration.date_position) || (isfield(configuration, "time_position")...
    %         && 0 ~= configuration.time_position) || (isfield(configuration, "angle_position")...
    %         && 0 ~= configuration.angle_position) % NOTE: line starts not with variable to be tested because no line break is possible with "..." operator (configuration.date_position ~= 0...) else it needs to go in braces
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
        %parfor i = 1:file_count
        disp("INFO: Processing file " + i + " out of " + file_count + "!");
        [path, name, extension] = fileparts(file_paths(i));
        name_parts = strsplit(name, '_');
        if isfield(configuration, "date_position") && configuration.date_position ~= 0
            month_day = name_parts(configuration.date_position);
            % TODO: not very pretty to do it for each file
        else
            % NOTE: assumption is that data is copied like that "cp --preserve=timestamps -R /sbdata/EM/Krios_K2/2018-12-29_yizhang_5ht3rMVs_64k/64k_97e/* ."
            %disp("INFO: no date postion given!");
            %output = executeCommand("stat " + mrc_files(i), false, log_file_id);
            [status, output] = system("stat " + file_paths(i));
            [mat,tok,ext] = regexp(output, "Modify: (\d+-\d+-\d+) (\d+:\d+:\d+.\d+)", "match",...
                'tokens', 'tokenExtents');
            month_day = tok{1}{1};
            % TODO: not very pretty to do it for each file
        end
        if isfield(configuration, "time_position") && configuration.time_position ~= 0
            time = name_parts(configuration.time_position);
        else
            %disp("INFO: no time postion given!");
            %output = executeCommand("stat " + mrc_files(i), false, log_file_id);
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
    %         tomogram_counter = 1;
    %         % TODO: decide if a routine for finding angle_position is useful
    %         first_angle = 0;
    %         first_angle_set = false;
    %         if isfield(configuration, "angle_position")
    %             for i = 1:length(sorted_files)
    %                 [path, name, extension] = fileparts(sorted_files(i));
    %                 name_parts = strsplit(name, '_');
    %                 angle = str2double(name_parts(configuration.angle_position));
    %                 if first_angle_set == false
    %                     first_angle = angle;
    %                     first_angle_set = true;
    %                 end
    %                 if angle == first_angle
    %                     start_indices(tomogram_counter) = i;
    %                     tomogram_counter = tomogram_counter + 1;
    %                 end
    %             end
    %         end
else
    sorted_files = file_paths;
end

%     % TODO: decide on another condition
%     %elseif configuration.angle_position ~= 0 % NOTE: could be sorted on creation date if creation date is reliable, needs to be figured out when it is preserved
% elseif configuration.high_dose == 1
%     % NOTE: Tries to find the next high dose image based on file size
%     % TODO: mrc list needs to be resorted based on extracted_dates_tabularized_sorted.extracted_date_strings_indices
%     bytes = [mrc_list.bytes]';
%     mean_bytes = mean(bytes);
%     start_indices = find(bytes > (2 * mean_bytes));
%     % TODO: check if condition is ok
% elseif configuration.fixed_number ~= 0
%     start_indices = 1:configuration.fixed_number:numel(mrc_list);
% end

% TODO: Make it also work for other tilt schemes
% NOTE: Checks if some high dose file was found
if length(start_indices) == 1
    start_indices(2) = numel(original_files) + 1;
    iteration_count = length(start_indices) - 2;
else
    iteration_count = length(start_indices) - 1;
end

if ~isfield(dynamic_configuration, "tomograms_count") || (isfield(dynamic_configuration, "tomograms_count") && (dynamic_configuration.tomograms_count < iteration_count))
    % TODO:NOTE: probably if statement not needed because both are plus one
    if iteration_count == 0
        dynamic_configuration.tomograms_count = iteration_count + 1;
    else
        dynamic_configuration.tomograms_count = iteration_count + 1;
    end
else
    dynamic_configuration.tomograms = configuration.tomograms;
    return;
end



if isfield(configuration, "tomogram_input_prefix") && isempty(configuration.tomogram_input_prefix) %( || configuration.tomogram_input_prefix == "")
    tomogram_input_prefix = string(splitted_mrc_name(1:configuration.angle_position - 2));
    variable_string = printVariableToString(tomogram_input_prefix);
    printToFile(log_file_id, variable_string);
else
    tomogram_input_prefix = configuration.tomogram_input_prefix;
end

if isfield(configuration, "tomogram_output_prefix") && ~isempty(configuration.tomogram_output_prefix) % configuration.tomogram_output_prefix ~= "" % TODO: probably remove: && ~isempty(configuration.tomogram_output_prefix)
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
        % TODO: introduce skipped flag
        if length(tomogram_file_indices) < configuration.minimum_files
            disp("INFO: Not enough files for this tomogram to do reconstructions!");
            %         continue;
            dynamic_configuration.tomograms.(tomogram_name).skipped = true;
        else
            dynamic_configuration.tomograms.(tomogram_name).skipped = false;
        end
        
        
        %         if ~isStringScalar(tomogram_input_prefix)
        
        %         else
        %             tomogram_name = sprintf("%s_%03d", tomogram_input_prefix, current_tomogram_index);
        %         end
        %     dynamic_configuration.tomograms.(tomogram_name) = struct();
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
            
            %         begin_last_duplicate_series = find(diff_index_to_dupes > 1, 1, "last") + 1;
            
            %         dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_series_begin_last_index = begin_last_duplicate_series;
        else
            dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_found = false;
        end
        
        
        dynamic_configuration.tomograms.(tomogram_name).original_angles = angles;
        dynamic_configuration.tomograms.(tomogram_name).original_tomogram_file_indices = tomogram_file_indices;
        dynamic_configuration.tomograms.(tomogram_name).original_file_paths = sorted_files(tomogram_file_indices);
        
        if configuration.duplicated_tilts ~= "keep"
            tomogram_file_indices(index_to_dupes) = [];
            angles(index_to_dupes) = [];
        end
        
        % TODO: introduce skipped flag
        if length(tomogram_file_indices) < configuration.minimum_files
            disp("INFO: After cleaning duplicates not enough files left to do reconstructions for this tomogram!");
            % NOTE: to be able to check one flag only but to know when it was
            % skipped
            dynamic_configuration.tomograms.(tomogram_name).skipped = true;
            dynamic_configuration.tomograms.(tomogram_name).skipped_after_cleaning_duplicates = true;
            %         continue;
        else
            dynamic_configuration.tomograms.(tomogram_name).skipped_after_cleaning_duplicates = false;
        end
        
        dynamic_configuration.tomograms.(tomogram_name).angles = angles;
        dynamic_configuration.tomograms.(tomogram_name).tomogram_file_indices = tomogram_file_indices;
        dynamic_configuration.tomograms.(tomogram_name).name = {dynamic_configuration.original_files(tomogram_file_indices).name};
        dynamic_configuration.tomograms.(tomogram_name).folder = dynamic_configuration.original_files(tomogram_file_indices(1)).folder;
        dynamic_configuration.tomograms.(tomogram_name).file_paths = sorted_files(tomogram_file_indices);
        dynamic_configuration.tomograms.(tomogram_name).tomogram_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).tomogram_number_position;
        dynamic_configuration.tomograms.(tomogram_name).adjusted_tomogram_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_tomogram_number_position;
        dynamic_configuration.tomograms.(tomogram_name).tilt_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).tilt_number_position;
%         dynamic_configuration.tomograms.(tomogram_name).angle_position = dynamic_configuration.original_files(tomogram_file_indices(1)).angle_position;
        dynamic_configuration.tomograms.(tomogram_name).adjusted_tilt_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_tilt_number_position;
%         dynamic_configuration.tomograms.(tomogram_name).adjusted_angle_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_angle_position;
        dynamic_configuration.tomograms.(tomogram_name).date_position = dynamic_configuration.original_files(tomogram_file_indices(1)).date_position;
        dynamic_configuration.tomograms.(tomogram_name).time_position = dynamic_configuration.original_files(tomogram_file_indices(1)).time_position;
        dynamic_configuration.tomograms.(tomogram_name).zero_tilt = [dynamic_configuration.original_files(tomogram_file_indices).zero_tilt];
        [sorted_angle_values, sorted_angle_indices] = sort([dynamic_configuration.original_files(tomogram_file_indices).angle]);
        dynamic_configuration.tomograms.(tomogram_name).sorted_angles = sorted_angle_values;
        dynamic_configuration.tomograms.(tomogram_name).sorted_zero_tilt = dynamic_configuration.tomograms.(tomogram_name).zero_tilt(sorted_angle_indices);
        dynamic_configuration.tomograms.(tomogram_name).prefix = dynamic_configuration.original_files(tomogram_file_indices(1)).prefix;
        dynamic_configuration.tomograms.(tomogram_name).missing_underscore_between_tomogram_name_and_number = dynamic_configuration.original_files(tomogram_file_indices(1)).missing_underscore_between_tomogram_name_and_number;
        dynamic_configuration.tomograms.(tomogram_name).double_numbering = dynamic_configuration.original_files(tomogram_file_indices(1)).double_numbering;
        [folder, name, extension] = fileparts(dynamic_configuration.tomograms.(tomogram_name).name{1});
        dynamic_configuration.tomograms.(tomogram_name).tif = string(extension) == ".tif";
        
        %     dynamic_configuration_temporary = populate_folder_tomo(configuration,...
        %         current_tomogram_index,...
        %         tomogram_files);
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
        %         current_tomogram_index = configuration.starting_tomogram + current_tomogram;
        tomogram_name = sprintf("%s_%03d", tomogram_output_prefix, current_tomogram_index);
        fprintf("Processing Tomogram "...
            + num2str(current_tomogram_index) + "\n");
        % NOTE: handle case for handling the last element
        if i + 2 > length(start_indices)
            tomogram_file_indices = start_indices(i + 1):length(sorted_files);
        else
            tomogram_file_indices = start_indices(i + 1):start_indices(i + 2)-1;
        end
        % TODO: introduce skipped flag
        %         if length(tomogram_file_indices) < configuration.minimum_files
        %             disp("INFO: Not enough files for this tomogram to do reconstructions!");
        %             %         continue;
        %             dynamic_configuration.tomograms.(tomogram_name).skipped = true;
        %         else
        %             dynamic_configuration.tomograms.(tomogram_name).skipped = false;
        %         end
        
        
        %         if ~isStringScalar(tomogram_input_prefix)
        
        %         else
        %             tomogram_name = sprintf("%s_%03d", tomogram_input_prefix, current_tomogram_index);
        %         end
        %     dynamic_configuration.tomograms.(tomogram_name) = struct();
        %         angles = [dynamic_configuration.original_files(tomogram_file_indices).angle];
        
        %         if configuration.duplicated_tilts == "first"
        %             [uniqueA, i, j] = unique(angles,"first");
        %         elseif configuration.duplicated_tilts == "last" || configuration.duplicated_tilts == "keep"
        %             [uniqueA, i, j] = unique(angles,"last");
        %         end
        %
        %         index_to_dupes = find(not(ismember(1:numel(angles),i)));
        
        
        %         if ~isempty(index_to_dupes)
        %             dynamic_configuration.tomograms.(tomogram_name).duplicates_found = true;
        %             dynamic_configuration.tomograms.(tomogram_name).duplicates = index_to_dupes;
        %         else
        %             dynamic_configuration.tomograms.(tomogram_name).duplicates_found = false;
        %             dynamic_configuration.tomograms.(tomogram_name).duplicates = index_to_dupes;
        %         end
        
        %         diff_index_to_dupes = diff(index_to_dupes);
        %         if any(diff_index_to_dupes > 1)
        %             dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_found = true;
        %
        %             %         begin_last_duplicate_series = find(diff_index_to_dupes > 1, 1, "last") + 1;
        %
        %             %         dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_series_begin_last_index = begin_last_duplicate_series;
        %         else
        %             dynamic_configuration.tomograms.(tomogram_name).multiple_duplicates_found = false;
        %         end
        
        
        %         dynamic_configuration.tomograms.(tomogram_name).original_angles = angles;
        %         dynamic_configuration.tomograms.(tomogram_name).original_tomogram_file_indices = tomogram_file_indices;
        dynamic_configuration.tomograms.(tomogram_name).original_file_paths = sorted_files(tomogram_file_indices);
        %
        %         if configuration.duplicated_tilts ~= "keep"
        %             tomogram_file_indices(index_to_dupes) = [];
        %             angles(index_to_dupes) = [];
        %         end
        
        %         % TODO: introduce skipped flag
        %         if length(tomogram_file_indices) < configuration.minimum_files
        %             disp("INFO: After cleaning duplicates not enough files left to do reconstructions for this tomogram!");
        %             % NOTE: to be able to check one flag only but to know when it was
        %             % skipped
        %             dynamic_configuration.tomograms.(tomogram_name).skipped = true;
        %             dynamic_configuration.tomograms.(tomogram_name).skipped_after_cleaning_duplicates = true;
        %             %         continue;
        %         else
        %             dynamic_configuration.tomograms.(tomogram_name).skipped_after_cleaning_duplicates = false;
        %         end
        
        %         dynamic_configuration.tomograms.(tomogram_name).angles = angles;
        %         dynamic_configuration.tomograms.(tomogram_name).tomogram_file_indices = tomogram_file_indices;
        dynamic_configuration.tomograms.(tomogram_name).name = {dynamic_configuration.original_files(tomogram_file_indices).name};
        dynamic_configuration.tomograms.(tomogram_name).folder = dynamic_configuration.original_files(tomogram_file_indices(1)).folder;
        dynamic_configuration.tomograms.(tomogram_name).file_paths = sorted_files(tomogram_file_indices);
        %         dynamic_configuration.tomograms.(tomogram_name).tomogram_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).tomogram_number_position;
        %         dynamic_configuration.tomograms.(tomogram_name).adjusted_tomogram_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_tomogram_number_position;
        %         dynamic_configuration.tomograms.(tomogram_name).tilt_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).tilt_number_position;
        %         dynamic_configuration.tomograms.(tomogram_name).angle_position = dynamic_configuration.original_files(tomogram_file_indices(1)).angle_position;
        %         dynamic_configuration.tomograms.(tomogram_name).adjusted_tilt_number_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_tilt_number_position;
        %         dynamic_configuration.tomograms.(tomogram_name).adjusted_angle_position = dynamic_configuration.original_files(tomogram_file_indices(1)).adjusted_angle_position;
        %         dynamic_configuration.tomograms.(tomogram_name).date_position = dynamic_configuration.original_files(tomogram_file_indices(1)).date_position;
        %         dynamic_configuration.tomograms.(tomogram_name).time_position = dynamic_configuration.original_files(tomogram_file_indices(1)).time_position;
        %         dynamic_configuration.tomograms.(tomogram_name).zero_tilt = [dynamic_configuration.original_files(tomogram_file_indices).zero_tilt];
        
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
        end
       
        dynamic_configuration.tomograms.(tomogram_name).prefix = dynamic_configuration.original_files(tomogram_file_indices(1)).prefix;
        [folder, name, extension] = fileparts(dynamic_configuration.tomograms.(tomogram_name).name{1});
        dynamic_configuration.tomograms.(tomogram_name).tif = string(extension) == ".tif";
        current_tomogram = current_tomogram + 1;
    end
end
dynamic_configuration.starting_tomogram = current_tomogram;
end



