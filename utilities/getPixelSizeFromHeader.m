function apix = getPixelSizeFromHeader(file_path, log_file_id)
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
pixel_line = output(contains(output, "Pixel"));
matching_results = regexp(pixel_line, "(\d+.\d+)", "match");
apix = matching_results{1}{1};
end
