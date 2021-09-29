function configuration = loadJSON(file_path)
fid = fopen(file_path);
text = fscanf(fid, "%s");
configuration = jsondecode(text);
fclose(fid);
end