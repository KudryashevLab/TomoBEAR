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
            %coder.varsize("field_name", [1 50]);

            coder.extrinsic("length");

            obj.file_path = file_path;
            json = JSON(); % TODO: remove this comment if argument "file_path" is not needed any more
            %obj.configuration = json.parsed_content;
            %obj.configuration = json.parse(file_path);
            configuration = json.parse(file_path);
            field_name_count = length(fieldnames(configuration));
            field_names = cell([field_name_count 1]);
            i_start = 1;
            
            for i = i_start:field_name_count
                field_names{i} = "";
            end
            field_names = fieldnames(configuration);
            %i_end = 0;
            %i_start = 0;
            %i_end = length(field_names);
            %i_indices = zeros(1,i_end);
            %i = zeros(1,i_end);
            
            %i_indices = i_start:i_end;
            %field_name = "                                     ";
            for i = i_start:field_name_count
                field_name = field_names{i};
%                 if isfield(configuration.(field_name), "data_path")
%                     % NOTE: convert to string
%                     configuration.(field_name).data_path = string(configuration.(field_name).data_path);
%                 end
%                 if isfield(configuration.(field_name), "processing_path")
%                     % NOTE: convert to string
%                     configuration.(field_name).processing_path = string(configuration.(field_name).processing_path);
%                 end
                
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
            % TODO: indroduce assertion here for less verbose error
            % handling
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
%                 if isfield(configuration.(field_name), "data_path")
%                     % NOTE: convert to string
%                     configuration.(field_name).data_path = string(configuration.(field_name).data_path);
%                 end
%                 if isfield(configuration.(field_name), "processing_path")
%                     % NOTE: convert to string
%                     configuration.(field_name).processing_path = string(configuration.(field_name).processing_path);
%                 end
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

