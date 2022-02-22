function runTomoBear(compute_environment, configuration_path, default_configuration_path, starting_tomogram, ending_tomogram, step, gpu)
if nargin <= 2
    if fileExists("CONFIGURATION")
        default_configuration_path = string(fread(fopen("CONFIGURATION"), "*char")');
    else
        default_configuration_path = "./configurations/defaults.json";
    end
end
if nargin <= 3
    starting_tomogram = -1;
    ending_tomogram = -1;
    step = -1;
    gpu = -2;
end
runPipeline(compute_environment, configuration_path, default_configuration_path, starting_tomogram, ending_tomogram, step, gpu);
end

