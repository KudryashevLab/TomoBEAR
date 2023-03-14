function xf_file_path = getXfOrAlnFilePaths(configuration, output_path, tomogram_name)
xf_file_path = getFilesFromLastModuleRun(configuration,"AreTomo","xf","last");
if ~isempty(xf_file_path)
    xf_file_path = xf_file_path{1};
else
    xf_file_path = getFilesFromLastModuleRun(configuration,"AreTomo","aln","last");
    if isempty(xf_file_path)
        xf_file_path = getFilePathsFromLastBatchruntomoRun(configuration, "xf");
        xf_file_path = xf_file_path{1};
    else
        fid_in = fopen(xf_file_path{1});
        lines_in_cells = textscan(fid_in, "%s","Delimiter","\n");
        fclose(fid_in);
        fid_out = fopen(output_path + filesep + tomogram_name + ".xf", "w+");
        for j = 4:length(lines_in_cells{1})
            numbers_in_line = textscan(lines_in_cells{1}{j}, "%f %f %f %f %f %f %f %f %f %f");
            rotation_matrix = rotz(numbers_in_line{2});
            fprintf(fid_out, "%f %f %f %f %f %f\n", rotation_matrix(1,1), rotation_matrix(1,2), rotation_matrix(2,1), rotation_matrix(2,2), numbers_in_line{4}, numbers_in_line{5});
        end
        fclose(fid_out);
        xf_file_path = output_path + filesep + tomogram_name + ".xf";
    end
end
end

