function configuration = generateSetUpStruct(configuration, previous_tomogram_status, i ,j)
configuration.set_up = struct;
configuration.set_up.i = i;
configuration.set_up.j = j;
cumulative_tomogram_status = cumsum(previous_tomogram_status);
configuration.set_up.adjusted_j = cumulative_tomogram_status(j);
end
