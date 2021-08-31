function [width, height, z] = getHeightAndWidthFromHeader(file_path, log_file_id)
if iscell(file_path)
    command = sprintf("header %s", file_path{1});
else
    command = sprintf("header %s", file_path);
end
if nargin == 2
    output = executeCommand(command, false, log_file_id);
else
    output = executeCommand(command, false);
end
output = textscan(output, "%s", "delimiter", "\n");
output = output{1};
pixel_line = output(contains(output, "Number of columns"));
matching_results = regexp(pixel_line, "(\d+)[ ]+(\d+)[ ]+(\d+)", "match");
matching_results = str2num(matching_results{1}{1});
width = matching_results(1);
height = matching_results(2);
z = matching_results(3);
end

