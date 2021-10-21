classdef JSON < handle
    properties
    end
    
    methods
        function obj = JSON()%filePath
            % TODO: convert to string if needed
            %obj.file_path = filePath;

            % TODO: convert parsed contents from char to string
            %obj.parse(filePath);
            % NOTE: Alternative, more verbose error handling
            %if fileExists(filePath)
            %    % TODO: convert parsed contents from char to string
            %    obj.parse(filePath);
            %else
            %    error("Specified file does not exist!");
            %end
        end
        
        function parsed_content = parse(obj, filePath)
            assert(fileExists(filePath), "Specified file does not exist!")

            % NOTE: not compatible with matlab coder
            file_content = fileread(filePath);
            %obj.file_content = file_content;
            
            %obj.file_content = string(file_content);
            
            %obj.parsed_content = jsondecode(obj.file_content);
            %obj.parsed_content = jsondecode(file_content);
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

