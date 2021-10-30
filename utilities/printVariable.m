% NOTE: works only for named variables
function printVariable(variable, debug)
if nargin == 1
debug = false;
end
if debug == true
    disp("INFO:VARIABLE:" + inputname(1) + ": ");
    % NOTE: because disp is overloaded for different types it is called for the
    % variable separately
    disp(variable);
end
end

