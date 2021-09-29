% NOTE: works only for named variables
function variable_string = printVariableToString(variable)
    if iscell(variable)
        variable_string = sprintf("INFO:VARIABLE:%s: %s", inputname(1), variable{:});
    else
        variable_string = sprintf("INFO:VARIABLE:%s: %s", inputname(1), variable);
    end
end

