classdef JSON < handle
    % TODO: make static class
    properties
        %file_path string;
        % NOTE: not compatible with matlab coder
        %file_content string;
        %parsed_content;
    end
    
    methods
        function obj = JSON()%filePath
            % TODO: convert to string if needed
            %assert(fileExists(filePath), "Specified file does not exist!")
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
            coder.extrinsic("fileread");
            coder.extrinsic("jsondecode");
            
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
            coder.extrinsic("jsonencode");
            encoded_content = jsonencode(content);
            file_id = fopen(file_path, 'w');
            fprintf(file_id, '%s', encoded_content);
            fclose(file_id);
        end
        
%         function file_content = getFileContent(obj)
%             if ~isempty(obj.parsed_content)
%                 file_content = obj.file_content;
%             else
%                 error("ERROR: No file content was read!");
%             end
%         end
    end
end

