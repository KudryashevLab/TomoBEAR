function output = executeCommand(command, ignore_errors, log_file_id, hide_output)
if nargin < 4
    hide_output = false;
end
    %printVariable(command);
    [status, command_output] = system(command);
    if nargin >= 2 && ignore_errors == true
        if status ~= 0 && command ~= "3dmod -h"
            disp("WARNING: command " + command...
                + " executed with errors: " + newline + command_output)
        end
        
        if hide_output == false
            printVariable(status);
            printVariable(command_output);
        end
    else
        assert(status == 0, "ERROR:COMMAND: " + command...
            + " executed with errors: " + newline + command_output);
    end
    variable_string_command = printVariableToString(command);
    variable_string_command_output = printVariableToString(command_output);
    if nargin >= 3 && log_file_id ~= -1
        printToFile(log_file_id, variable_string_command);
        printToFile(log_file_id, variable_string_command_output);
    end
    output = variable_string_command + newline + variable_string_command_output;
end

