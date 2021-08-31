function [destination, output] = createSymbolicLink(source, destination, log_file_id)
command = "ln -sfv " + source...
    + " "...
    + destination;

output = executeCommand(command, false, log_file_id);
end

