%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


classdef ConfigurationParser < handle
    properties (Access = private)
        file_path string;
        configuration struct;
        % TODO: decide if needed here
        pipeline_definition cell;
    end
    
    methods
        function obj = ConfigurationParser(file_path)
            if nargin == 1
                obj.parse(file_path)
            end
        end
        
        function [configuration, pipeline_definition] = parse(obj, file_path)
            obj.file_path = file_path;
            json = JSON();
            configuration = json.parse(file_path);
            field_name_count = length(fieldnames(configuration));
            field_names = fieldnames(configuration);
            for i = 1:length(field_names)
                field_name = field_names{i};
                if isstruct(configuration.(field_name))
                    configuration.(field_name) = obj.convertDataTypes(configuration.(field_name));
                end
            end
            % TODO: decide if needed here
            pipeline_definition = obj.getPipelineDefinition(configuration);
        end
        
        function configuration = getConfiguration(obj)
            configuration = obj.configuration;
        end
        
        % TODO: decide if needed here
        function pipeline_definition = getPipelineDefinition(obj, configuration)
            if ~isempty(configuration)
                pipeline_definition = fieldnames(configuration)';
                for i = 1:length(pipeline_definition)
                    % TODO: perhaps better definition regex is needed
                    if ~isempty(regexp(pipeline_definition{i}, "_\d+", "match"))
                        pipeline_step_string_splitted = strsplit(pipeline_definition{i}, "_");
                        pipeline_step_definition = strjoin(pipeline_step_string_splitted(1:end - 1),"_");
                        pipeline_definition{i} = pipeline_step_definition;
                    end
                end
            else
                error("ERROR: No configuration was parsed!");
            end
        end
        
        function configuration = convertDataTypes(obj, configuration)
            field_names = fieldnames(configuration);
            for i = 1:length(field_names)
                field_name = field_names{i};
                if ischar(configuration.(field_name))
                    configuration.(field_name) = string(configuration.(field_name));
                end
                if isstruct(configuration.(field_name))
                    configuration.(field_name) = obj.convertDataTypes(configuration.(field_name));
                end
            end
        end
    end
end

