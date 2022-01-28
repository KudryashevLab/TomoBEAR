function initializeEnvironment(default_configuration_path)
if ~isdeployed()
    addpath("configuration");
    addpath("json");
    
    if nargin == 0
        default_configuration_path = "./configurations/defaults.json";
    end
end
configuration_parser = ConfigurationParser();
[default_configuration, ~] = configuration_parser.parse(default_configuration_path);

environment = struct();
environment.matlab_version = string(version());
environment.matlab_release = string(version('-release'));
environment.matlab_release_date = string(version('-date'));
environment.matlab_release_description = string(version('-description'));
environment.java_version = string(version('-java'));
environment.matlab_toolboxes = ver();

if ~verLessThan('matlab', '9.2')
    environment.matlab_toolboxes_string = string(evalc("ver()"));
else
    environment.matlab_toolboxes_string = string(evalc('ver()'));
end

emClarity_path = default_configuration.general.em_clarity_path;
dynamo_path = default_configuration.general.dynamo_path;

if isunix()
    environment.system = "unix";
    [status, host_name] = unix("hostname | tail -1");
    host_name = string(host_name(1:end-1));
elseif ismac()
    environment.system = "mac";
    [status, host_name] = unix("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
elseif ispc()
    environment.system = "windows";
    [status, host_name] = system("hostname");
    % TODO: check if needed
    host_name = string(host_name(1:end-1));
else
    error("Platform not supported!");
end

if isfield(default_configuration.general, "pipeline_location") && default_configuration.general.pipeline_location ~= ""
    project_path = default_configuration.general.pipeline_location;
else
    project_path = string(pwd);
end

disp("HOSTNAME = " + host_name);

% NOTE: imod specific code, chose old naming style for imod projects
% disp("INFO:ENV_GET:ETOMO_NAMING_STYLE: " + getenv("ETOMO_NAMING_STYLE"));
% setenv("ETOMO_NAMING_STYLE","0");
% disp("INFO:ENV_SET:ETOMO_NAMING_STYLE: " + getenv("ETOMO_NAMING_STYLE"));

% TODO: make it work on cluster (os installation without display)
environment.imod_version = getIMODVersion();

environment.gpu_count = gpuDeviceCount;

% NOTE: doesn't work with double quotes, tested in MATLAB R2018b
environment.cpu_count_physical = feature('numcores');
if ~verLessThan('matlab', '9.2')
    core_info = evalc("feature('numcores')");
    environment.system_architecture = computer("arch");
else
    core_info = evalc('feature(''numcores'')');
    environment.system_architecture = computer('arch');
end

matching_results = regexp(core_info, "\d+", "match");
environment.cpu_count_logical = str2double(matching_results{2});

[environment.computer_type, environment.max_array_size, environment.endianness] = computer();

environment.host_name = host_name;
environment.project_path = project_path;

if ~isdeployed()
    environment.dynamo_path = default_configuration.general.dynamo_path;
    environment.emClarity_path = default_configuration.general.em_clarity_path;
end

environment.debug = false;

if ~isdeployed
    if default_configuration.general.astra_path ~= ""
        astra_path = default_configuration.general.astra_path;
        astra_sub_paths = {"algorithms", {"DART", {"examples", "tools"}, "plot_geom"}, "mex", "tools"};
        concatAndAddPathsRecursive(astra_path, astra_sub_paths);
        pyversion(default_configuration.general.python_path);
        pyversion();
        if isfield(default_configuration.general, "conv_net_path") && default_configuration.general.conv_net_path ~= ""
            run(default_configuration.general.conv_net_path + filesep + "vl_setupnn");
        end
    end
    
    if isfield(default_configuration.general, "dip_image_path") && default_configuration.general.dip_image_path ~= ""
        addpath(default_configuration.general.dip_image_path);
        addpath(default_configuration.general.dip_image_path + filesep + "common");
        addpath(default_configuration.general.dip_image_path + filesep + "common/dipimage");
        addpath(default_configuration.general.dip_image_path + filesep + "common/dipimage/demos");
        if isfield(default_configuration.general, "dip_image_images_path") && default_configuration.general.dip_image_images_path ~= ""
            dipsetpref('imagefilepath',char(default_configuration.general.dip_image_images_path));
        end
        dip_initialise;
    end
    
    project_sub_paths = {"dynamo", {"matlab", {"mbtools", {"src"}, "src", {"shorthands"}}, "mex", {"bin"}}, "utilities", "configuration", "json", "modules", "pipeline"}; %, "helper", {"gpu"}, "extern", {"semaphore"}, "imod", "offxca", "database", "nn", "playground", {"matlab", {"astra"}}, "extern", {"av3", {"utils"}, "bol_scripts", "tom", {"Filtrans", "Geom"}, "irt", "flatten", "window2"}
    concatAndAddPathsRecursive(project_path, project_sub_paths, string(filesep));
    
    if ~fileExists("DYNAMO_INITIALIZED")
        createDynamoLinks(default_configuration.general.dynamo_path)
        fid = fopen("DYNAMO_INITIALIZED", "w+");
        fclose(fid);
    end
    addpath(default_configuration.general.SUSAN_path);
end
if ~fileExists(default_configuration.general.pipeline_executable) || default_configuration.general.regenerate_load_modules_file == true
    fid = fopen(default_configuration.general.pipeline_executable, "w+");
    fprintf(fid, "%s\n", "#!/bin/bash");
    fprintf(fid, "%s\n", "#https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself");
    fprintf(fid, "%s\n", "if [ ""$#"" -ne 9 ]; then");
    fprintf(fid, "\t%s\n", "SCRIPTPATH=""$( cd -- ""$(dirname ""$0"")"" >/dev/null 2>&1 ; pwd -P )""");
    fprintf(fid, "%s\n", "else");
    fprintf(fid, "\t%s\n", "SCRIPTPATH=""$8""");
    fprintf(fid, "%s\n", "fi");
    fprintf(fid, "%s\n", "export PATH=$SCRIPTPATH/dynamo/cuda/bin:$PATH");
    if  isfield(default_configuration.general, "SUSAN_path") && default_configuration.general.SUSAN_path ~= ""
        fprintf(fid, "%s\n", "export PATH=/home/risanche/Projects/SUSAN/devel/+SUSAN/bin:$PATH");
    end
    if fileExists("./load_modules.sh")
        fprintf(fid, "%s\n", "source $SCRIPTPATH/load_modules.sh");
    end
    fprintf(fid, "%s\n", "if [ ""$#"" -eq 2 ]; then");
        fprintf(fid, "%s\n", "$SCRIPTPATH/" + default_configuration.general.project_name + "/for_redistribution_files_only/run_" + default_configuration.general.project_name + ".sh " + default_configuration.general.mcr_location + " $1 $2 configurations/defaults.json -1 -1 -1 -2");
    fprintf(fid, "%s\n", "elif [ ""$#"" -ne 9 ]; then");
        fprintf(fid, "%s\n", "$SCRIPTPATH/" + default_configuration.general.project_name + "/for_redistribution_files_only/run_" + default_configuration.general.project_name + ".sh " + default_configuration.general.mcr_location + " $1 $2 $3 -1 -1 -1 -2");
    fprintf(fid, "%s\n", "else");
        fprintf(fid, "%s\n", "$SCRIPTPATH/" + default_configuration.general.project_name + "/for_redistribution_files_only/run_" + default_configuration.general.project_name + ".sh " + default_configuration.general.mcr_location + " $1 $2 $3 $4 $5 $6 $7");
    fprintf(fid, "%s\n", "fi");
    fclose(fid);
    % TODO: add parameter to decide for whom to allow execution
    system("chmod ug+x " + default_configuration.general.pipeline_executable);
    
    if exist(default_configuration.general.project_name, "dir") && ~fileExists(default_configuration.general.project_name + filesep + "BUILD_INITIALIZED")
        compileTomoBEAR
        fid = fopen(default_configuration.general.project_name + filesep + "BUILD_INITIALIZED", "w+");
        fclose(fid);
    end
end


% TODO: add parameter to decide for whom to allow execution
system("chmod ug+x " + default_configuration.general.qsub_wrapper);
system("chmod ug+x " + default_configuration.general.sbatch_wrapper);


if ~isdeployed()
    fid = fopen("./TomoBEAR.prj", "w+");
    fprintf(fid, "<deployment-project plugin=""plugin.ezdeploy"" plugin-version=""1.0"">");
  fprintf(fid, "<configuration build-checksum=""2813730637"" file=""${PROJECT_ROOT}/TomoBEAR.prj"" location=""${PROJECT_ROOT}"" name=""TomoBEAR"" preferred-package-location=""${PROJECT_ROOT}/TomoBEAR/for_redistribution"" preferred-package-type=""package.type.install"" target=""target.ezdeploy.standalone"" target-name=""Application Compiler"">");
    fprintf(fid, "<param.appname>TomoBEAR</param.appname>");
    fprintf(fid, "<param.icon />");
    fprintf(fid, "<param.icons />");
    fprintf(fid, "<param.version>0.90</param.version>");
    fprintf(fid, "<param.authnamewatermark>Nikita Balyschew</param.authnamewatermark>");
    fprintf(fid, "<param.email>nikita.balyschew@googlemail.com</param.email>");
    fprintf(fid, "<param.company>Max Planck Institute of Biophysics</param.company>");
    fprintf(fid, "<param.summary />");
    fprintf(fid, "<param.description />");
    fprintf(fid, "<param.screenshot />");
    fprintf(fid, "<param.guid />");
    fprintf(fid, "<param.installpath.string>/Max_Planck_Institute_of_Biophysics/TomoBEAR/</param.installpath.string>");
    fprintf(fid, "<param.installpath.combo>option.installpath.userlocal</param.installpath.combo>");
    fprintf(fid, "<param.logo />");
    fprintf(fid, "<param.install.notes />");
    fprintf(fid, "<param.target.install.notes>In the following directions, replace MR/v911 by the directory on the target machine where MATLAB is installed, or MR by the directory where the MATLAB Runtime is installed.");
fprintf(fid, "(1) Set the environment variable XAPPLRESDIR to this value:");
fprintf(fid, "MR/v911/X11/app-defaults");
fprintf(fid, "(2) If the environment variable LD_LIBRARY_PATH is undefined, set it to the following:");
fprintf(fid, "MR/v911/runtime/glnxa64:MR/v911/bin/glnxa64:MR/v911/sys/os/glnxa64:MR/v911/sys/opengl/lib/glnxa64");
fprintf(fid, "If it is defined, set it to the following:");
fprintf(fid, "${LD_LIBRARY_PATH}:MR/v911/runtime/glnxa64:MR/v911/bin/glnxa64:MR/v911/sys/os/glnxa64:MR/v911/sys/opengl/lib/glnxa64</param.target.install.notes>");
    fprintf(fid, "<param.intermediate>${PROJECT_ROOT}/TomoBEAR/for_testing</param.intermediate>");
    fprintf(fid, "<param.files.only>${PROJECT_ROOT}/TomoBEAR/for_redistribution_files_only</param.files.only>");
    fprintf(fid, "<param.output>${PROJECT_ROOT}/TomoBEAR/for_redistribution</param.output>");
    fprintf(fid, "<param.logdir>${PROJECT_ROOT}/TomoBEAR</param.logdir>");
    fprintf(fid, "<param.enable.clean.build>false</param.enable.clean.build>");
    fprintf(fid, "<param.user.defined.mcr.options />");
    fprintf(fid, "<param.target.type>subtarget.standalone</param.target.type>");
    fprintf(fid, "<param.support.packages />");
    fprintf(fid, "<param.web.mcr>true</param.web.mcr>");
    fprintf(fid, "<param.package.mcr>false</param.package.mcr>");
    fprintf(fid, "<param.no.mcr>false</param.no.mcr>");
    fprintf(fid, "<param.web.mcr.name>TomoBEAR_web_installer</param.web.mcr.name>");
    fprintf(fid, "<param.package.mcr.name>TomoBEAR_mcr_included</param.package.mcr.name>");
    fprintf(fid, "<param.no.mcr.name>MyAppInstaller_app</param.no.mcr.name>");
    fprintf(fid, "<param.windows.command.prompt>false</param.windows.command.prompt>");
    fprintf(fid, "<param.create.log>true</param.create.log>");
    fprintf(fid, "<param.log.file>pipeline_distribution.log</param.log.file>");
    fprintf(fid, "<param.native.matlab>false</param.native.matlab>");
    fprintf(fid, "<param.checkbox>false</param.checkbox>");
    fprintf(fid, "<param.example />");
    fprintf(fid, "<param.help.text>Syntax ");
	 fprintf(fid, "runPipeline -? ");
	 fprintf(fid, "runPipeline compute_environment configuration_path default_configuration_path starting_tomogram ending_tomogram step gpu ");
 fprintf(fid, "Input Arguments ");
	 fprintf(fid, "-?  print help on how to use the application ");
	 fprintf(fid, "compute_environment configuration_path default_configuration_path starting_tomogram ending_tomogram step gpu  input arguments</param.help.text>");
    fprintf(fid, "<unset>");
      fprintf(fid, "<param.icon />");
      fprintf(fid, "<param.icons />");
      fprintf(fid, "<param.summary />");
      fprintf(fid, "<param.description />");
      fprintf(fid, "<param.screenshot />");
      fprintf(fid, "<param.guid />");
      fprintf(fid, "<param.installpath.string />");
      fprintf(fid, "<param.logo />");
      fprintf(fid, "<param.install.notes />");
      fprintf(fid, "<param.intermediate />");
      fprintf(fid, "<param.files.only />");
      fprintf(fid, "<param.output />");
      fprintf(fid, "<param.logdir />");
      fprintf(fid, "<param.enable.clean.build />");
      fprintf(fid, "<param.user.defined.mcr.options />");
      fprintf(fid, "<param.target.type />");
      fprintf(fid, "<param.support.packages />");
      fprintf(fid, "<param.web.mcr />");
      fprintf(fid, "<param.package.mcr />");
      fprintf(fid, "<param.no.mcr />");
      fprintf(fid, "<param.no.mcr.name />");
      fprintf(fid, "<param.windows.command.prompt />");
      fprintf(fid, "<param.native.matlab />");
      fprintf(fid, "<param.checkbox />");
      fprintf(fid, "<param.example />");
    fprintf(fid, "</unset>");
    fprintf(fid, "<fileset.main>");
      fprintf(fid, "<file>${PROJECT_ROOT}/pipeline/runPipeline.m</file>");
   fprintf(fid, "</fileset.main>");
    fprintf(fid, "<fileset.resources>");
      fprintf(fid, "<file>${PROJECT_ROOT}/dynamo</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/helper</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/modules</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/utilities</file>");
      if isfield(default_configuration.general, "SUSAN_path") && default_configuration.general.SUSAN_path ~= ""
        fprintf(fid, "<file>" + default_configuration.general.SUSAN_path + "/+SUSAN</file>");
      end
    fprintf(fid, "</fileset.resources>");
    fprintf(fid, "<fileset.package />");
    fprintf(fid, "<fileset.depfun>");
      fprintf(fid, "<file>${PROJECT_ROOT}/configuration/ConfigurationParser.m</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/json/JSON.m</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/pipeline/GridEnginePipeline.m</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/pipeline/LocalPipeline.m</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/pipeline/Pipeline.m</file>");
      fprintf(fid, "<file>${PROJECT_ROOT}/pipeline/SlurmPipeline.m</file>");
    fprintf(fid, "</fileset.depfun>");
    fprintf(fid, "<build-deliverables>");
      fprintf(fid, "<file location=""${PROJECT_ROOT}/TomoBEAR/for_testing"" name=""splash.png"" optional=""false"">${PROJECT_ROOT}/TomoBEAR/for_testing/splash.png</file>");
      fprintf(fid, "<file location=""${PROJECT_ROOT}/TomoBEAR/for_testing"" name=""run_TomoBEAR.sh"" optional=""false"">${PROJECT_ROOT}/TomoBEAR/for_testing/run_TomoBEAR.sh</file>");
      fprintf(fid, "<file location=""${PROJECT_ROOT}/TomoBEAR/for_testing"" name=""TomoBEAR"" optional=""false"">${PROJECT_ROOT}/TomoBEAR/for_testing/TomoBEAR</file>");
      fprintf(fid, "<file location=""${PROJECT_ROOT}/TomoBEAR/for_testing"" name=""readme.txt"" optional=""true"">${PROJECT_ROOT}/TomoBEAR/for_testing/readme.txt</file>");
    fprintf(fid, "</build-deliverables>");
    fprintf(fid, "<workflow />");
    fprintf(fid, "<matlab>");
      fprintf(fid, "<root>/opt/local/MATLAB/R2021b</root>");
      fprintf(fid, "<toolboxes>");
        fprintf(fid, "<toolbox name=""matlabcoder"" />");
        fprintf(fid, "<toolbox name=""embeddedcoder"" />");
        fprintf(fid, "<toolbox name=""gpucoder"" />");
        fprintf(fid, "<toolbox name=""fixedpoint"" />");
        fprintf(fid, "<toolbox name=""matlabhdlcoder"" />");
        fprintf(fid, "<toolbox name=""neuralnetwork"" />");
      fprintf(fid, "</toolboxes>");
      fprintf(fid, "<toolbox>");
        fprintf(fid, "<matlabcoder>");
          fprintf(fid, "<enabled>true</enabled>");
        fprintf(fid, "</matlabcoder>");
      fprintf(fid, "</toolbox>");
      fprintf(fid, "<toolbox>");
        fprintf(fid, "<embeddedcoder>");
          fprintf(fid, "<enabled>true</enabled>");
        fprintf(fid, "</embeddedcoder>");
      fprintf(fid, "</toolbox>");
      fprintf(fid, "<toolbox>");
        fprintf(fid, "<gpucoder>");
          fprintf(fid, "<enabled>true</enabled>");
        fprintf(fid, "</gpucoder>");
      fprintf(fid, "</toolbox>");
      fprintf(fid, "<toolbox>");
        fprintf(fid, "<fixedpoint>");
          fprintf(fid, "<enabled>true</enabled>");
        fprintf(fid, "</fixedpoint>");
      fprintf(fid, "</toolbox>");
      fprintf(fid, "<toolbox>");
        fprintf(fid, "<matlabhdlcoder>");
          fprintf(fid, "<enabled>true</enabled>");
        fprintf(fid, "</matlabhdlcoder>");
      fprintf(fid, "</toolbox>");
      fprintf(fid, "<toolbox>");
        fprintf(fid, "<neuralnetwork>");
          fprintf(fid, "<enabled>true</enabled>");
        fprintf(fid, "</neuralnetwork>");
      fprintf(fid, "</toolbox>");
    fprintf(fid, "</matlab>");
    fprintf(fid, "<platform>");

    if isunix()
      fprintf(fid, "<unix>true</unix>");
      fprintf(fid, "<linux>true</linux>");
      fprintf(fid, "<solaris>false</solaris>");
      fprintf(fid, "<osver>" + system("hostnamectl | grep ""Kernel: Linux"" | awk -F' ' '{print $3}'") + "</osver>");

    else
      fprintf(fid, "<unix>false</unix>"); 
      fprintf(fid, "<linux>false</linux>");
      fprintf(fid, "<solaris>false</solaris>");
      % TODO: implement for other os
      fprintf(fid, "<osver>!!!TODO!!!</osver>");
    end
    
    if ismac()
        fprintf(fid, "<mac>true</mac>");
    else
      fprintf(fid, "<mac>false</mac>");
    end
    if ispc()
        fprintf(fid, "<windows>true</windows>");
   
      fprintf(fid, "<win2k>false</win2k>");
      fprintf(fid, "<winxp>false</winxp>");
      fprintf(fid, "<vista>true</vista>");
    else
      fprintf(fid, "<windows>false</windows>");
   
      fprintf(fid, "<win2k>false</win2k>");
      fprintf(fid, "<winxp>false</winxp>");
      fprintf(fid, "<vista>false</vista>");
    end
      if string(extractBetween(computer,length(computer)-1, length(computer))) == "64"
        fprintf(fid, "<os32>false</os32>");
        fprintf(fid, "<os64>true</os64>");
      else
        fprintf(fid, "<os32>true</os32>");
        fprintf(fid, "<os64>false</os64>");
      end
      fprintf(fid, "<arch>" + string(computer("arch")) + "</arch>");
      fprintf(fid, "<matlab>true</matlab>");
    fprintf(fid, "</platform>");
  fprintf(fid, "</configuration>");
fprintf(fid, "</deployment-project>");
end

end

