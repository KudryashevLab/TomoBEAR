function combineConfigurationsAndSaveHistory(configuration_path, default_configuration_path, ending_step)
% if nargin == 2
%     strating_tomogram = -1;
%     ending_tomogram = -1;
%     step = -1;
% end
    if nargin < 2
        error("ERROR: not enough input arguments!");
    elseif nargin >= 2
        pipeline = LocalPipeline(configuration_path, default_configuration_path);
    end

    if nargin > 3
    	disp("WARNING: Too many input arguments!");
    end

    pipeline.print();
    pipeline.combineConfigurationsAndSaveHistory(str2double(ending_step));
end

