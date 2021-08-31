% NOTE: works only for named variables
function printVariable(variable)
% global environmentProperties;
% if environmentProperties.debug == true
    disp("INFO:VARIABLE:" + inputname(1) + ": ");
    % NOTE: because disp is overloaded for different types it is called for the
    % variable separately
    disp(variable);
% end
end

