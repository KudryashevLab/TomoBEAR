function configuration = fillSetUpStructIteration(configuration, j, previous_tomogram_status)
configuration.set_up.j = j;
configuration.set_up.cumulative_tomogram_status = cumsum(previous_tomogram_status);
if isscalar(configuration.gpu) && configuration.gpu == -1
    configuration.set_up.gpu_sequence = mod(configuration.set_up.cumulative_tomogram_status - 1, configuration.environment_properties.gpu_count) + 1;
elseif isscalar(configuration.gpu) && configuration.gpu >= 0
    configuration.set_up.gpu_sequence = repmat(configuration.gpu, [1 length(previous_tomogram_status)]);
elseif ~isscalar(configuration.gpu)
    configuration.set_up.gpu_sequence = mod(configuration.set_up.cumulative_tomogram_status - 1, length(configuration.gpu)) + 1;
    configuration.set_up.gpu_sequence = configuration.gpu(configuration.set_up.gpu_sequence)';
end
configuration.set_up.gpu = configuration.set_up.gpu_sequence(j);
configuration.set_up.adjusted_j = configuration.set_up.cumulative_tomogram_status(j);
end
