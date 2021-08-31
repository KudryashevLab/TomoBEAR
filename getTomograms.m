function tomograms = getTomograms(configuration, flatten)
if nargin == 1
    flatten = false;
end

tomograms = getTomogramsFromStandardFolder(configuration, flatten);
if isempty(tomograms)
    tomograms = getTomogramsFromPreviousPipelineStepFolders(configuration, flatten);
end

if isempty(tomograms)
    error("ERROR: No tomograms found!");
end
end

