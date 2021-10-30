function saveJSON(path, variable)
fid_json = fopen(path, "wt" );
variable_json = jsonencode(variable, "ConvertInfAndNaN", false);
variable_json = strrep(variable_json, ",", sprintf("," + newline));
variable_json = strrep(variable_json, "[{", sprintf("[" + newline + "{" + newline));
variable_json = strrep(variable_json, "}]", sprintf( newline + "}" + newline + "]"));
fprintf(fid_json, "%s", variable_json);
fclose(fid_json);
end

