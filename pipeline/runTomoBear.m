function runTomoBear(compute_environment, configuration_path, default_configuration_path, starting_tomogram, ending_tomogram, step, gpu)
if nargin <= 3
    starting_tomogram = -1;
    ending_tomogram = -1;
    step = -1;
    gpu = -2;
end
if string(compute_environment) == "local"
    %if isdeployed()
    % TODO: think of passing project_path to initializeEnvironment
    %global environmentProperties;
    %environmentProperties = initializeEnvironment(default_configuration_path);
    %end
    %% PIPELINE GENERATION
    if nargin == 1
        pipeline = LocalPipeline("meta_data/project.json");
    elseif nargin == 2
        pipeline = LocalPipeline(configuration_path);
    elseif nargin >= 3
        pipeline = LocalPipeline(configuration_path, default_configuration_path);
    end
    
    
    if nargin > 7
        disp("WARNING: Too many input arguments.");
    end
    
    %% PRINT GENERATED PIPELINE
    pipeline.print();
    %% PIPELINE EXECUTION
    % TODO: make a compatibility layer for different shells like ksh, zsh, csh,
    % tcsh, bash... perhaps better to write most of the stuff in matlab
    % language
    if nargin <= 3
        pipeline.execute()
    else
        if isdeployed() == true
            pipeline.execute(str2double(starting_tomogram), str2double(ending_tomogram), str2double(step), str2double(gpu));
        else
            pipeline.execute(starting_tomogram, ending_tomogram, step, gpu);
        end
    end
    %usejava('jvm') && ~feature('ShowFigureWindows')
    %java.lang.System.getProperty('java.awt.headless') == true
    %usejava('desktop') == false
    %screen_size = get(0, 'ScreenSize');
    %if screen_size(1) == 1 && screen_size(2) == 1 && screen_size(3) == 1 && screen_size(4) == 1
    %    exit;
    %end
    
    %% TEST CASES
    
    %% PIPELINE DEFINITION
    % pipelineDefintion = {"example_pipeline_1_step_1",...
    %     "example_pipeline_1_step_2",...
    %     "example_pipeline_1_step_3"};
    %
    % pipeline = Pipeline(pipelineDefintion);
    %
    % pipeline.execute();
    
    %% APPEND STEPS TO PIPELINE
    % pipeline = Pipeline();
    % pipeline + "test1";
    % pipeline.printPipeline();
    %
    % pipeline + 'test2';
    % pipeline.printPipeline();
    %
    % pipeline + {"test3", "test4"};
    % pipeline.printPipeline();
    %
    % pipeline + {'test5', 'test6'};
    % pipeline.printPipeline();
    %
    % pipeline + {"test7", 'test8'};
    % pipeline.printPipeline();
elseif string(compute_environment) == "cleanup"
        %if isdeployed()
    % TODO: think of passing project_path to initializeEnvironment
    %global environmentProperties;
    %environmentProperties = initializeEnvironment(default_configuration_path);
    %end
    %% PIPELINE GENERATION
    if nargin == 1
        pipeline = LocalPipeline();
    elseif nargin == 2
        pipeline = LocalPipeline(configuration_path);
    elseif nargin >= 3
        pipeline = LocalPipeline(configuration_path, default_configuration_path);
    end
    
    
    if nargin > 7
        disp("WARNING: Too many input arguments.");
    end
    
    %% PRINT GENERATED PIPELINE
    pipeline.print();
    %% PIPELINE EXECUTION
    pipeline.configuration.general.execute = false;
    pipeline.configuration.general.keep_intermediates = false;
    pipeline.configuration.general.ignore_success_files = true;
    pipeline.configuration.general.checkpoint_module = true;
    pipeline.configuration.general.skip_data_check = true;
    starting_tomogram = -1;
    ending_tomogram = -1;
    step = length(dir(pipeline.configuration.general.processing_path + filesep + pipeline.configuration.general.output_folder + filesep + "*_1"));
    gpu = -2;
    
    if isdeployed() == true
    	pipeline.execute(str2double(starting_tomogram), str2double(ending_tomogram), str2double(step), str2double(gpu));
    else
    	pipeline.execute(starting_tomogram, ending_tomogram, step, gpu);
	end

elseif string(compute_environment) == "slurm"
    if nargin == 3
        strating_tomogram = -1;
        ending_tomogram = -1;
        step = -1;
    end
    %if isdeployed()
    % TODO: think of passing project_path to initializeEnvironment
    %global environmentProperties;
    %environmentProperties = initializeEnvironment(default_configuration_path);
    %end
    %% PIPELINE GENERATION
    if nargin == 1
        pipeline = SlurmPipeline();
    elseif nargin == 2
        pipeline = SlurmPipeline(configuration_path);
    elseif nargin >= 3
        if nargin > 3
            disp("WARNING: Too many input arguments.");
        end
        pipeline = SlurmPipeline(configuration_path, default_configuration_path);
    end
    
    %% PRINT GENERATED PIPELINE
    pipeline.print();
    %% PIPELINE EXECUTION
    % TODO: make a compatibility layer for different shells like ksh, zsh, csh,
    % tcsh, bash... perhaps better to write most of the stuff in matlab
    % language
    if nargin <= 3
        pipeline.execute()
    else
        pipeline.execute(starting_tomogram, ending_tomogram, step);
    end
else
    error("ERROR: unknown compute environment!");
end
end

