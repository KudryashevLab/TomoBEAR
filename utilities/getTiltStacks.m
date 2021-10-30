function tilt_stacks = getTiltStacks(configuration, flatten)
if nargin == 1
    flatten = false;
end
tilt_stacks = getTiltStacksFromStandardFolder(configuration, flatten);
if isempty(tilt_stacks)
    tilt_stacks = getTiltStacksFromPreviousPipelineStepFolders(configuration, flatten);
end
if isempty(tilt_stacks)
    error("ERROR: No tiltstacks found!");
end
end

 