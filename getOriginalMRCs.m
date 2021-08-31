function original_mrcs = getOriginalMRCs(configuration)

if isfield(configuration, "tomogram_input_prefix") && configuration.tomogram_input_prefix ~= ""
    mrc_path = configuration.data_path + string(filesep)...
        + configuration.tomogram_input_prefix + "*.mrc";
else
    mrc_path = configuration.data_path + string(filesep) + "*.mrc";
end
original_mrcs = dir(mrc_path);

% if isempty(original_mrcs)
%      error("ERROR: No micrographs found at location " + mrc_path);
% end
end

