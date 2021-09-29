function imod_version = getIMODVersion()
output = executeCommand("3dmod -h", true, -1, true);
output_lines = textscan(output,"%s","Delimiter","","endofline","\n");
output_lines = output_lines{1}{2};
imod_version = regexp(output_lines, "\d+\.\d+\.\d+", "match");
% TODO:NOTE everywhere available but what if folder is not named by version
if string(getenv("IMOD_DIR")) ~= "" && length(imod_version) > 1 || isempty(imod_version)
    imod_version = regexp(string(getenv("IMOD_DIR")), "[\d]+\.[\d]+\.[\d]+", "match");
end
imod_version = string(imod_version);
end

