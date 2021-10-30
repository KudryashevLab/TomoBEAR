function path = addFileSeparator(path)
if path == ""
    return;
end
last_character = extractBetween(path, strlength(path), strlength(path));
if last_character ~= string(filesep)
    path = string(path + string(filesep));
else
    path = string(path);
end
end

