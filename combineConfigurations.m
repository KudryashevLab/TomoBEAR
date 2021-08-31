function [first_configuration_out, second_configuration_out] = combineConfigurations(first_configurations_in, second_configurations_in)
if length(first_configurations_in) > 1
    for j = 1:length(first_configurations_in) - 1
        if j == 1
            %                         merged_configuration = obj.mergeConfigurations(merged_configurations{j}, merged_configurations{j+1}, 0, "dynamic");
            first_configuration_out = mergeConfigurations(first_configurations_in{j}, first_configurations_in{j + 1}, 0, "dynamic");
            if nargin == 3
                second_configuration_out = mergeConfigurations(second_configurations_in{j}, second_configurations_in{j + 1}, 0, "dynamic");
            end
        else
            %                         merged_configuration = obj.mergeConfigurations(merged_configuration, merged_configurations{j+1}, 0, "dynamic");
            first_configuration_out = mergeConfigurations(first_configuration_out, first_configurations_in{j + 1}, 0, "dynamic");
            if nargin == 3
                second_configuration_out = mergeConfigurations(second_configuration_out, second_configurations_in{j + 1}, 0, "dynamic");
            end
        end
    end
elseif length(first_configurations_in) == 1
    %                 merged_configuration = merged_configurations{1};
    first_configuration_out = first_configurations_in{1};
    if nargin == 3
        second_configuration_out = second_configurations_in{1};
    end
else
    
    error("ERROR: no configurations to combine!");
end
end