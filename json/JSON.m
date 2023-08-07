%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021,2022,2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published
% by the Free Software Foundation, either version 3 of the License,
% or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef JSON < handle
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

