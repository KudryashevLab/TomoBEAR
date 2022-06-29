function output = executeCommand(command, ignore_errors, log_file_id, hide_output)
if nargin < 4
    hide_output = false;
end
printVariable(command);
[status, command_output] = system(command);

% Output of command called via system() can be truncated.
% See the bug #1400063 report in MathWorks Bug Reports:
% https://de.mathworks.com/support/bugreports/1400063
% This issue has been identified as a Linux kernel regression 
% which affects Linux kernels 3.12 through 4.6.
% Officially listed affected MATLAB releases are R2006[a/b]-R2016[a/b]. 
% Nevertheless bug was captured in R2021a under Linux kernel 3.10.
% Official MathWorks solution does not exist. 
% MATLAB society workaround
% https://de.mathworks.com/matlabcentral/answers/212823-matlab-system-command-bug-returns-partial-stdout
% involving < dev/null and preventing buffering to stdin is not desirable.
% Using the following workaround:
[~,command_output_remainder] = system('');
command_output = [command_output command_output_remainder];

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

