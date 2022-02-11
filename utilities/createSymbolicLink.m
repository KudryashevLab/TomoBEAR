function [destination, output] = createSymbolicLink(source, destination, log_file_id, relative)
if nargin == 2 || nargin == 3
    relative = true;
elseif nargin == 4
elseif nargin < 2
    error("ERROR: to create a symbolic link a source and destination is needed!");
end

if nargin == 2
    log_file_id = -1;
end
if relative == true
    command = "ln -srfv " + source + " " + destination;
else
    command = "ln -sfv " + source + " " + destination;
end
output = executeCommand(command, false, log_file_id);
end

