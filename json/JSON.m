classdef JSON < handle
    % TODO: make static class
    properties
    end
    
    methods
        function obj = JSON()
        end
        
        function parsed_content = parse(obj, filePath)
            file_content = fileread(filePath);
            parsed_content = jsondecode(file_content);
        end
        
        % TODO: merge with method in class Configuration
        function parsed_content = getParsedContent(obj)
            if ~isempty(obj.parsed_content)
                parsed_content = fieldnames(obj.parsed_content)';
            else
                error("ERROR: No pipeline definition file was parsed!");
            end
        end
        
        function write(obj, file_path, content)
            encoded_content = jsonencode(content);
            file_id = fopen(file_path, 'w');
            fprintf(file_id, '%s', encoded_content);
            fclose(file_id);
        end
    end
end

