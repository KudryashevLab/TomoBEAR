# Contributing guidelines

## Foreword

*Dear cryo-ET enthusiast,*
</br> we are happy that you are considering contribution to the `TomoBEAR` workflow, which is an [**open-source**](https://opensource.guide/) academic software. We do believe that community contribution and co-development efforts help to collect and bring in practice excellent ideas, overcome issues and initial design limitations thankfully to the broadness and diversity of the community experience and expertise as well as generally accelerate development in order to faster achieve software stabilization. That influences software life cycle outcomes and software lifetime expectancy, which in the end defines such important parameters for academic software as:
* re-usability
* utilization
* availability
* reproducibility
* transparency

Those principles comply with [**FAIR4RS Principles**](https://www.nature.com/articles/s41597-022-01710-x), which we are trying to follow in the `TomoBEAR` project too. We do hope that the open-source state of this project along with opened communication channels enable a possibility to engage cryo-ET community into collaborative development.
</br> *Sincerely yours,*
</br> *TomoBEAR team*

## Making your contribution

To our contributors we suggest the broadly used **fork-and-pull** model which consists of the following steps:
1. Fork this project to your repository.
2. Make local changes and push them to your fork.
3. Prepare pull request back to our repository along with description of the made changes.
4. Give us time to review and decide on the future of your pull request.

## General guidelines and principles

Whenever contributing to `TomoBEAR`, please, consider the following:
* **Divide and conquer.** Do not contribute unconnected things together! It makes much harder for us to review and accept your contribution then.
* **Test locally and globally.** Along with isolated testing of the module/function which you change/contribute to, please, try to predict and test effect of your changes on the whole pipeline or at least on the "neighboring" modules, which are supposed to be executed right before/after the module you are contributing to. We do not provide unit-tests or other kind of tests to run yet, but we ask at least to run your changes on the data from our [Ribosome tutorial](https://github.com/KudryashevLab/TomoBEAR/wiki/Tutorials) or any other **EMPIAR** data set (e.g. one of those we [used in our preprint](https://www.biorxiv.org/content/10.1101/2023.01.10.523437v1)) or, at the best, on one of your real data sets.    
* **Include license note.** If you add a new code file, include license note ([see example in Module.m](https://github.com/KudryashevLab/TomoBEAR/blob/develop/modules/Module.m)) at the top for [**GPLv3**](https://www.gnu.org/licenses/gpl-3.0.en.html) or any other **compatible with GPLv3** license.
* **Use proposed contribution model.** Use **fork-and-pull** model to bring changes for our review, please. This is the safest contribution mechanism for both contributors and reviewers.

## TomoBEAR design

If you are willing to contribute the bug-fix, a new feature/module or have an idea of how to re-design some part of the pipeline, there we provide some minimal developer/contributor notes regarding the `TomoBEAR` intermediate user-level and developer-level design which might be important to know.

### User-level design

Please, consider that good understanding of the user-level design of `TomoBEAR` is the entry-level requirement for reading these notes and contributing to `TomoBEAR`. For the details on basic user-level design you may refer to the corresponding sections of the [TomoBEAR wiki](https://github.com/KudryashevLab/TomoBEAR/wiki/Home) such as [Installation and Setup](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup), [Tutorials](https://github.com/KudryashevLab/TomoBEAR/wiki/Tutorials) and [Usage](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage). Here we provide some additional information for intermediate user-level design of the `TomoBEAR`:

* **Configuration files.** There are two types of configuration files, from which all the metadata about pipeline and for main (experimental and processed) data is assembled and used during execution. Those are:
  * `defaults.json` which contains all the global parameters and parameters for all the modules as well as their default values.
  * `input.json` or any other filename of user's input configuration file for the particular project, which holds user's pipeline structure, metadata for user's primary project pipeline, execution and processing parameters values.
  Data in the `input.json` (user's project file) has higher priority than data in the `defaults.json`. That means that if parameter field is absent in `input.json`, it will be taken from `defaults.json`, otherwise - from `input.json`.

* **Execution modes.** Here are several execution modes which define the TomoBEAR workflow behavior, namely:
  * `local` - (*stable*) data processing mode for offline (static) input data for sequential/parallel(CPU/GPU) processing locally or on the interactive cluster node;
  * `cleanup` - (*feature in test*) not a data processing mode for cleaning up some metadata and intermediate results to save up space
  * `local_live` - (*experimental feature*) data processing mode for online (live, on-the-fly) input data for sequential/parallel(CPU/GPU) processing locally or on the interactive cluster node;
  * `slurm` - (*refactoring is planned*) data processing mode for offline (static) input data for parallel(CPU/GPU) processing by distributing tasks over cluster nodes using SLURM scheduler system.

* **Pipeline execution checkpoint files.** There are execution checkpoint files, which `TomoBEAR` puts after each processing step in the corresponding folder:
    * `SUCCESS`\\`FAILURE` which indicate the outcome of the whole processing step or operation applied to the particular tilt serie or tomogram (for the modules which process tilt series or tomograms independently of each other like `CreateStacks`, `MotionCor2`, `BatchRunTomo`, etc.).
    > **SUCCESS files contents**
    > <br/> The file `SUCCESS` contains bit (0/1) vector of the number of tomograms length with 0's or 1's meaning failure or success of processing for the corresponding tilt serie or tomogram so that successful ones will be used on the further processing steps. This might be useful to know when you need workaround if something is not working.

    * `TIME` which contains the time in seconds that it took TomoBEAR to execute the certain step or process the particular tilt serie or tomogram.

### Developer-level design

**Project and code directories structure.**

![Project/code structure](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/TomoBEAR_file_structures.png)

`TomoBEAR` *project folder* is structured as presented on the image above with the following elements:
* `input.json` - the input configuration file which users should create themselves;
* `output/` - the main output folder which contains all the kinds of data (input, intermediate, output) and metadata (for data and pipeline) structured in the following way:
  * `XX_StepName_1/` - those are processing steps folders, containing in general step-related `data_files.*` and `data_folders/` (for example, individual tomogram/tilt serie folders `tomogram_*` for the modules like `CreateStacks`, `BinStacks`, `Reconstruct`), as well as step-related pipeline metadata files, like various JSON files (`input.json`, `output.json`, etc.), log file of the step execution `SteName.log`, pipeline checkpoint file `SUCCESS` or `FAILURE` (depending on processing outcome) and execution time log file `TIME`;
  * `pipeline.log` - general log file, tracking global pipeline execution messages (info/warnings/errors);
  * `data_folders/` and `metadata_folders/` - folders where the most important (meta)data is moved or linked to.
* `scratch/` - special folder which contains just folder tree of the `output/` folder reflecting workflow structure and serving as a reference during the pipeline execution.

`TomoBEAR` *source code* is structured as presented on the image above and consists of the following *three main parts*:
* **environment setup** scripts/functions (`run_matlab.sh`, `startup.m`, `environment/`)  - those are for configuring environmental and MATLAB Path variables
* **processing modules** (`modules/`) - those are interface modules for TomoBEAR steps, wrapping external software and/or our developments functionality
* **pipeline modules** (`pipeline/`) - those are pipeline execution modules for different computational environments

as well as
* **modified external routines** (`dynamo/`) - special folder to merge main `Dynamo` source code with our re-implemented `Dynamo` routines during `TomoBEAR` configuration to virtually produce updated functional version of `Dynamo`;   
* **auxilary functionality and files** (`utilities/`, `configuration/`, `configurations/` and `json/`) - variety of scripts/functions as well as templates and sets of defaults, used elsewhere in the briefly described above main parts;

and, finally
* **documentation** (`wiki/`, `images/`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `AUTHORS.md`, `CITATION.cff`, `LICENSE.md`, `LICENSES/`) - users-oriented files describing how to configure, install and use `TomoBEAR` as well as developers-oriented files containing general information about `TomoBEAR` as an open-source project like authors and contributors list, licensing and citation information, list of changes by releases, contribution guidelines, etc.   

Whenever you open interactive MATLAB session in TomoBEAR folder, the first file to start is `startup.m` which is MATLAB-specific way of setting up environment. Afterwards, when you use `runTomoBEAR` command to initialize or execute TomoBEAR workflow, this runs `pipeline/runPipeline.m` function, which basically performs a set of additional setups, heads to the selected *computational environment*, starts it in the chosen *execution mode* and runs it via the requested *execution method*. The details on the available *computational environments* you may find in the section **Pipeline modules** below, *execution modes* - is in the section **User-level design** above, and *execution methods* is described in the section **Additional developer-level design elements** below.

### Environment setup

**Environment setup** scripts/functions include:
* `run_matlab.sh` - a bash script for TomoBEAR configuration to be executable in interactive MATLAB session, which sets up some system environment variables and opens MATLAB session;
* `startup.m` - is the script for MATLAB-specific way of setting up MATLAB environment, which is auto-executed every time as you open MATLAB from TomoBEAR source code folder;
* contents of `environment/` - several additional scripts to e.g. enable recognition of external software commands and conda environment paths.

### Processing modules

**Processing modules** include contents of the `modules/` directory. Those are interface modules for TomoBEAR steps, wrapping external software and/or our developments functionality. All the processing modules are inherited from the only parent abstract module called **Module** (`modules/Module.m`), implementing the core of the processing module routines such as definition and initialization of module properties (e.g. computing environment information, global/local/temporal configurations, input/output/log paths), metadata creation, collection (e.g. execution time measurement), writing (log files), and some metadata cleanup functionality.

All the modules are quite different, but their contents depend on the own interface of the external programs/frameworks being wrapped. Thus, *processing modules* could be classified into groups
* **by domain knowledge** according to the cryo-ET/StA processing stage as the following:
  * Pipeline behavior control modules
  * Cryo-ET data processing modules (functionality from raw dose-fractionated movies up to and including tomographic reconstructions)
  * Particles picking-associated modules (functionality of particles picking and extraction)
  * Subtomogram Averaging modules (functionality of single-reference and multi-reference particles alignment and classification)
* **by interface type of the functionality** being wrapped as the following:
  * metadata/files/execution management (`MetaData`, `SortFiles` and `StopPipeline`)
  * standalone command line software (e.g. modules wrapping MotionCor2, CTFFIND4, GCTF, AreTomo, etc.)
  * frameworks/libraries/packages (e.g. Dynamo/SUSAN/IMOD-oriented modules)
  * original algorithms and data processing code pieces (e.g. `GridEdgeEraser`, `TemplateMatchingPostProcessing`, etc.)
  * Neural network-based Python tool sets, containing pre-processing, training, prediction and post-processing procedures (e.g. `IsoNet`, `crYOLO`, etc.)

Despite the plenty of possible ways to create a new module, depending on the original algorithm or external tool structure and execution features, we have prepared two mini-templates along with comments, which are located by the following relative paths:
* `modules/GeneralModuleTemplate` - a general-purpose processing module template;
* `modules/DLToolModuleTemplate` - a (Python-based) deep learning tool-oriented processing module template.

as well as
* `configurations/defaults_template.json` - a configuration file, containing templates of sections for the two module templates above.

We hope those mini-templates can help our future contributors to better understand structure of a typical `TomoBEAR` module in order to overcome initial contribution barrier.

### Pipeline modules

**Pipeline modules** include contents of the `pipeline/` directory. Those are pipeline execution modules for different *computational environments* defining the way how TomoBEAR runs/distributes processing modules execution over the available computational resources in the certain *computational environment*. All the pipeline modules are inherited from the abstract module **Pipeline** (`pipeline/Pipeline.m`).

The available computational environments are described in the table below.

| Title  | Pipeline module | Target system | Execution mode | State of development |
| :-------------  | :--- | :---- | :--- | :--- |
| **Local**       | `pipeline/LocalPipeline.m` | a local workstation or a single (interactive) HPC cluster node | `local`/`cleanup` | stable |
| **Local live**  | `pipeline/LocalLivePipeline.m` | a local workstation for live data processing | `local_live` | experimental |
| **SLURM**       | `pipeline/SlurmPipeline.m` | HPC cluster using SLURM scheduler | `slurm`| requires refactoring |
| **Grid Engine** | `pipeline/GridEnginePipeline.m` | HPC cluster using SGE scheduler | N/A | in early development |

### Additional developer-level design elements

* **Execution methods.** The *execution methods* are mostly definitions of the parallelisation schemes and a certain *execution method* can be used by setting up the corresponding `"execution_method"` parameter value in the certain section of the configuration file corresponding to the target module. In a bit of details about each of them:
  * `once` - a one-time execution of the module functional (e.g. used by metadata-collecting modules like `MetaData`, by data importing/exporting modules like `EMDTemplateGeneration`). However, be aware that this *execution method* is also used to execute modules with internal (in-module) parallelisation (e.g. when wrapped algorithm uses its own parallelisation scheme like modules `GenerateParticles`, `crYOLO` and `IsoNet` do).
  * `sequential` - a sequential multi-time independent execution of the module functional on the different data chunks like tilt series or tomograms, when parallelization is not desired. As well, this method is useful and the only possibility for debugging modules which by default use parallel *execution methods* like `parallel` or `in_order`.
  * `parallel` - a simultaneous multi-time independent execution of the module functional on the different data chunks like tilt series or tomograms, serves for functional **parallelized on CPU's** (e.g. modules `"SortFiles"`, `"DynamoCleanStacks"`, `"BinStacks"`);
  * `in_order` - a simultaneous multi-time independent execution of the module functional on the different data chunks like tilt series or tomograms, serves for functional **parallelized on GPU's** (e.g. modules `"MotionCor2"`, `"AreTomo"`, `"Reconstruct"`, `"DynamoTemplateMatching"`);
  * `control` - the special *execution method* reserved only for operation of the `"StopPipeline"` control module.

* **Configuration variables.** There are two main configuration fields which you need to know about when writing a module:
  * `obj.configuration` - this is a structure field which holds global (from `"general"` section) and local (from the corresponding module section) parameters and their values initialized with the higher priority to the value set in module-specific configuration section unless the latest is not set and the corresponding value from `"general"` section or value defined by the lowest-priority `configurations/defaults.json` is used;    
  * `obj.dynamic_configuration` - this is a "dynamic" structure field which is aimed at storing temporal or local parameters values for the currently executed module (processing step); the variables of the obj.configuration above at the next processing step are updated in accordance with this structure field `obj.dynamic_configuration`.  
