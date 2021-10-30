function [destination, output] = createSymbolicLink(source, destination, log_file_id)
if nargin < 2
    error("ERROR: to create a symbolic link a source and destination is needed!");
end

if nargin == 2
    log_file_id = -1;
end

command = "ln -sfv " + source + " " + destination;
output = executeCommand(command, false, log_file_id);
end

