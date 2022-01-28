function runPipeline(compute_environment, configuration_path, default_configuration_path, starting_tomogram, ending_tomogram, step, gpu)
if nargin <= 3
    starting_tomogram = -1;
    ending_tomogram = -1;
    step = -1;
    gpu = -2;
end

if (fileExists("CONFIGURATION") && ~exist("default_configuration_path", "var")) || (fileExists("CONFIGURATION") && exist("default_configuration_path", "var") && default_configuration_path == "")
    default_configuration_path = string(fread(fopen("CONFIGURATION"), "*char")');
end

if string(compute_environment) == "initialize" || string(compute_environment) == "init"
    if nargin == 1
        pipeline = LocalPipeline();
    elseif nargin == 2
        pipeline = LocalPipeline(configuration_path);
    elseif nargin >= 3
        pipeline = LocalPipeline(configuration_path, default_configuration_path);
    end
    is_initialized = true;
    if ~isdeployed
        if pipeline.default_configuration.general.dynamo_path == ""
            disp("ERROR: Please provide the path to a dynamo installtion in defaults.json!");
            is_initialized = is_initialized && false;
        elseif pipeline.default_configuration.general.dynamo_path ~= "" && ~isempty(dir(pipeline.default_configuration.general.dynamo_path + filesep + "dynamo_activate.m"))
            disp("INFO: Dynamo path is properly configured!");
            is_initialized = is_initialized && true;
        else
            disp("ERROR: Please check your dynamo path in defaults.json!");
            is_initialized = is_initialized && false;
        end
    end
    [status, result] = system(pipeline.default_configuration.general.motion_correction_command + " --version");
    if pipeline.default_configuration.general.motion_correction_command == ""
    	disp("WARNING: Please provide the path to MotionCor2 if you want to use the motion correction module!");
        is_initialized = is_initialized && false;
    elseif status == 0
        disp("INFO: MotionCor2 command is properly configured!");
        is_initialized = is_initialized && true;
    else
        disp("ERROR: Please check your MotionCor2 command in defaults.json!");
        is_initialized = is_initialized && false;
    end

    [status, result] = system(pipeline.default_configuration.general.ctf_correction_command);
    if pipeline.default_configuration.general.ctf_correction_command == ""
        disp("WARNING: Please provide the path to Gctf if you want to use the gctf ctf correction module!");
        is_initialized = is_initialized && false;
    elseif status == 0
    	disp("INFO: Gctf command is properly configured!");
        is_initialized = is_initialized && true;
    else
        disp("ERROR: Please check your Gctf command in defaults.json!");
        is_initialized = is_initialized && false;
    end
    
    [status, result] = system(pipeline.default_configuration.general.conda_path + filesep + "bin" + filesep + "conda");
    if pipeline.default_configuration.general.conda_path == ""
    	disp("WARNING: Please provide the path to a conda installtion if you want to use advanced features like various neural net based modules or post processing modules!");
        is_initialized = is_initialized && false;
    elseif status == 0
        disp("INFO: Conda path is properly configured!");
        is_initialized = is_initialized && true;
    else
        disp("ERROR: Please check your conda path in defaults.json!");
        is_initialized = is_initialized && false;
    end
    
    if is_initialized == true
        disp("INFO: TomoBEAR is now completely initialized!");
    else
        disp("WARNING: TomoBEAR is only partly initialized!");
    end
elseif string(compute_environment) == "local"
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
    
    
%     if nargin > 7
%         disp("WARNING: Too many input arguments.");
%     end
    
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
    
    
%     if nargin > 7
%         disp("WARNING: Too many input arguments.");
%     end
    
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
        gpu = -2;
    else    
        starting_tomogram = str2double(starting_tomogram);
        ending_tomogram = str2double(ending_tomogram);
        step = str2double(step);
        gpu = str2double(gpu);
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
%         if nargin > 3
%             disp("WARNING: Too many input arguments.");
%         end
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
elseif string(compute_environment) == "grid"
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
        pipeline = GridEnginePipeline();
    elseif nargin == 2
        pipeline = GridEnginePipeline(configuration_path);
    elseif nargin >= 3
%         if nargin > 3
%             disp("WARNING: Too many input arguments.");
%         end
        pipeline = GridEnginePipeline(configuration_path, default_configuration_path);
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
elseif string(compute_environment) == "clone"
    [status, output] = system("cp -as " + configuration_path + " " + default_configuration_path);
else
    error("ERROR: unknown compute environment!");
end
end

