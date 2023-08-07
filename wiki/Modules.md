# Modules
In this section you can find descriptions of the implemented modules, their functionality
and their parameters which can be setup in the JSON configuration file in their
corresponding blocks.

## Contents
- [Modules dependency table](#modules-dependency-table)
- [Global parameters configuration](#global-parameters-configuration)
- [Pipeline behavior control modules](#pipeline-behavior-control-modules)
- [CryoET data processing modules](#cryoet-data-processing-modules)
- [Particles picking-associated modules](#particles-picking-associated-modules)
- [Subtomogram Averaging modules](#subtomogram-averaging-modules)

## Modules dependency table

Here we provide a table of modules dependencies on the external software.

| Module \ Tool  | IMOD | Dynamo | MotionCor2 | AreTomo | Gctf / CTFIND4 | IsoNet | crYOLO | SUSAN | Anaconda |
| :------------- | :--- | :---- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MetaData       | | | | | | | | | |
| SortFiles      | | | | | | | | | |
| MotionCor2     | :white_check_mark: | | :white_check_mark: | | | | | | |
| GridEdgeEraser | | :white_check_mark: | | | | | | | |
| CreateStacks   | :white_check_mark: | :white_check_mark: | | | | | | |
| DynamoTiltSeriesAlignment | | :white_check_mark: | | | | | | | |
| DynamoCleanStacks | :white_check_mark: | :white_check_mark: | | | | | | |
| AreTomo        | :white_check_mark: | | | :white_check_mark: | | | | | |
| BatchRunTomo   | :white_check_mark: | | | | | | | | | |
| GCTFCtfphaseflipCTFCorrection | :white_check_mark: | | | | :white_check_mark: | | | | |
| BinStacks      | :white_check_mark: | | | | | | | | |
| Reconstruct    | :white_check_mark: | | | | | | | | |
| IsoNet         | (:white_check_mark:) | | | | | :white_check_mark: | | | :white_check_mark: |
| DynamoImportTomograms | | :white_check_mark: | | | | | | | |
| EMDTemplateGeneration | | :white_check_mark: | | | | | | | |
| TemplateGenerationFromFile | | :white_check_mark: | | | | | | | |
| DynamoTemplateMatching | | :white_check_mark: | | | | | | | |
| TemplateMatchingPostProcessing | | :white_check_mark: | | | | | | (:white_check_mark:) | |
| crYOLO         | | (:white_check_mark:) | | | | | :white_check_mark: | | :white_check_mark: |
| GenerateParticles | | :white_check_mark: | | | | | | (:white_check_mark:) | |
| DynamoAlignmentProject | | :white_check_mark: | | | | | | (:white_check_mark:) | |

Legend:
* :white_check_mark: - mandatory dependency
* (:white_check_mark:) - optional dependency
* empty square - not a dependency / tool is not used in the corresponding module

## Global parameters configuration

### general
**Description**
</br>
The general section is not a module but a configuration section where all the general
parameters regarding the processing and the environment can be found.

**Parameters**
</br>
> **Note**
> <br/> Parameters which are input in this section are visible to all
modules during the execution. If parameters with the same key are found
in a modules block then they override parameters from the "general"
section.

<details>
<summary> Parameters table <i> (click to expand) </i> </summary>

| Key                                                  | Default Value                                                                                 | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Examples           |
|------------------------------------------------------|-----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------|
| gpu                                                  | -1                                                                                            | defines the GPUs to use, -1 means take all GPUs, positive number takes one GPU, a combination of positive numbers in square brackets defines multiple GPUs to be used, 0 means no GPUs                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | -1, 2, \[1, 2, 3\] |
| jobs_per_node                                        | 1                                                                                             | controls how many jobs should be executed per node, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| gpus_per_node                                        | 2                                                                                             | controls how many gpus are per node available, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| nodes                                                | ""                                                                                            | controls which nodes should be used for processing, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| slurm_execute                                        | ""                                                                                            | controls if jobs should be executed on SLURM or if just the commands should be output to the terminal, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| slurm_node_list                                      | ""                                                                                            | controls which nodes should be used for processing, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| slurm_nodes                                          | 0                                                                                             | controls how many nodes should be used for processing, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| slurm_nice                                           | 0                                                                                             | controls the nice level which should be used for cluster jobs, higher nice level means lower priority, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| slurm_partition                                      | ""                                                                                            | controls the cluster partition which should be used for cluster jobs, choose a partition which has GPUs installed, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| slurm_gres                                           | ""                                                                                            | controls the slurm generic resources (gres) argument so that SLURM can choose appropriate nodes for processing, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| slurm_qos                                            | ""                                                                                            | controls the quality of service (qos) argument which is used by SLURM for cluster jobs to choose appropriate nodes, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| slurm_constraint                                     | ""                                                                                            | controls the constraint argument which is used by SLURM for cluster jobs to choose appropriate nodes, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| slurm_time                                           | ""                                                                                            | controls the time argument which is used by SLURM for cluster jobs to cancel processing after the specified time is reached, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |                    |
| slurm_exclusive                                      | true                                                                                          | controls if a node should be allocated exclusively, this is advised to do so as the jobs will crash if they are scheduled on the same GPU, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |                    |
| slurm_flags                                          | ""                                                                                            | you can add additional SLURM flags here, these get appended to the end of the command, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| slurm_gpus                                           | 0                                                                                             | controls how many GPUs should be allocated through the SLURM cluster manager, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| slurm_mem_per_gpu_in_gb                              | 0                                                                                             | controls how much GPU memory should be allocated by the SLURM cluster manager, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| slurm_gpus_per_task                                  | 0                                                                                             | controls how many GPUs should be allocated per task by the SLURM cluster manager, **affects only processing on a SLURM cluster**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| slurm                                                | false                                                                                         | **note** flag is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| gpu_worker_multiplier                                | 1                                                                                             | controls how many tasks per GPU should be allocated, be careful jobs can crash if you allocate to many tasks per GPU, set to 2 or higher if you have more than 20GB of memory                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| pipeline_location                                    | ""                                                                                            | this variable is needed if you are using SLURM cluster manager and the pipeline executable is not found in the PATH system variable or the pipeline is executed from its containing folder                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |
| pipeline_executable                                  | "run_tomoBEAR.sh"                                                                             | this variable contains the name of the executable for tomoBEAR, this is needed for the execution of tasks through SLURM cluster manager                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |                    |
| sbatch_wrapper                                       | "sbatch.sh"                                                                                   | this variable contains the name of the sbatch wrapper which outputs only the job id which is needed to define the execution order and dependencies of the tasks which should be run by the SLURM cluster manager                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| cuda_forward_compatibility                           | true                                                                                          | controls the forward compatibility of GPU related functions, for further information visit this [link](https://www.mathworks.com/help/parallel-computing/gpu-support-by-release.html)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| random_number_generator_seed                         | 0                                                                                             | sets the seed which is used to parametrise the pseudo random number generator, for further information visit this [link](https://www.mathworks.com/help/matlab/math/generate-random-numbers-that-are-repeatable.html?searchHighlight=random%20number%20generator%20seed&s_tid=srchtitle)                                                                                                                                                                                                                                                                                                                                                                                                                                                                |                    |
| tomogram_output_prefix                               | "tomogram"                                                                                    | sets the prefix which is used to prepend the names of raw mrcs, tilt stacks and tomograms, if this variable is set to "" then the variable **tomogram_input_prefix** is used to prepend the resulting data, be careful to set **tomogram_input_prefix** then to a non empty string                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| tomogram_input_prefix                                | ""                                                                                            | see description for **tomogram_output_prefix**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| data_path                                            | ""                                                                                            | **mandatory** sets the path where the data to be processed can be found                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |                    |
| processing_path                                      | ""                                                                                            | **mandatory** sets the path where the results for the data to be processed should be stored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |                    |
| debug                                                | false                                                                                         | controls if the output and scratch folders should be removed when tomoBEAR is restarted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |                    |
| project_name                                         | "pipeline"                                                                                    | **optional** use this variable to give your project a name for documentary reasons                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| project_description                                  | "new_project description"                                                                     | **optional** use this variable to describe your project for documentary reasons                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |                    |
| wipe_cache                                           | false                                                                                         | **note** flag is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| motion_correction_command                            | "MotionCor2_1.4.0_Cuda102"                                                                    | controls the executable of MotionCor2 which should be used, if the executable is not found in your system's PATH variable then you need to set the full path here, be careful to use an executable with a proper CUDA version                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| ctf_correction_command                               | "Gctf-v1.06_sm_30_cu8.0_x86_64"                                                               | controls the executable of Gctf (only Gctf is supported) which should be used, if the executable is not found in your system's PATH variable then you need to set the full path here, be careful to use an executable with a proper CUDA version                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| double_numbering                                     | true                                                                                          | **note** flag is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| prefix_position                                      | 0                                                                                             | if you use serialEM you should not modify these variables as everything can be detected automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| tomogram_number_position                             | -1                                                                                            | if you use serialEM you should not modify these variables as everything can be detected automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| tilt_number_position                                 | -1                                                                                            | if you use serialEM you should not modify these variables as everything can be detected automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| angle_position                                       | -1                                                                                            | if you use serialEM you should not modify these variables as everything can be detected automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| date_position                                        | -1                                                                                            | if you use serialEM you should not modify these variables as everything can be detected automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| time_position                                        | -1                                                                                            | if you use serialEM you should not modify these variables as everything can be detected automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| output_folder                                        | "output"                                                                                      | sets the name of the output folder which is created under the processing path                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| scratch_folder                                       | "scratch"                                                                                     | sets the name of the scratch folder which is created under the processing path, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |
| remove_folders                                       | false                                                                                         | **note** flag is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| tilt_scheme                                          | "dose_symmetric"                                                                              | **note** variable is not used and can be deleted, set instead **zero_tilt** if your tilt stacks doesn't start from 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | "bi_directional"   |
| tilting_step                                         | 3                                                                                             | **note** variable is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| gold_bead_size_in_nm                                 | 10                                                                                            | variable sets the expected gold bead size in nm                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |                    |
| rotation_tilt_axis                                   | 85                                                                                            | variable sets the rotation of the tilt axis so that it results vertical or parallel to the y axis after alignment                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| pid_wait_time                                        | 5                                                                                             | sets the time to wait before catching the pid for modules which allow interactive inspection of tilt stacks, this can only used if concerned modules are run with **execution_method** sequential as one viewer is then opened at a time                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |                    |
| raw_files_folder                                     | "raw_files"                                                                                   | sets the name of the folder for raw files, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| fid_files_folder                                     | "fiducial_models"                                                                             | sets the name of the folder for fiducial models, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                    |
| motion_corrected_files_folder                        | "motion_corrected_mrcs"                                                                       | sets the name of the folder for motion corrected files, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |
| aligned_tilt_stacks_folder                           | "aligned_tilt_stacks"                                                                         | sets the name of the folder for aligned tilt stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |                    |
| ctf_corrected_aligned_tilt_stacks_folder             | "ctf_corrected_aligned_tilt_stacks"                                                           | sets the name of the folder for ctf corrected aligned tilt stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| tilt_stacks_folder                                   | "tilt_stacks"                                                                                 | sets the name of the folder for tilt stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |                    |
| binned_tilt_stacks_folder                            | "binned_tilt_stacks"                                                                          | sets the name of the folder for binned tilt stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |                    |
| binned_aligned_tilt_stacks_folder                    | "binned_aligned_tilt_stacks"                                                                  | sets the name of the folder for binned aligned tilt stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| ctf_corrected_binned_aligned_tilt_stacks_folder      | "ctf_corrected_binned_aligned_tilt_stacks"                                                    | sets the name of the folder for ctf corrected binned aligned tilt stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| tomograms_folder                                     | "tomograms"                                                                                   | sets the name of the folder for tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| ctf_corrected_tomograms_folder                       | "ctf_corrected_tomograms"                                                                     | sets the name of the folder for ctf corrected tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |                    |
| exact_filtered_tomograms_folder                      | "exact_filtered_tomograms"                                                                    | sets the name of the folder for exact filtered tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| binned_tomograms_folder                              | "binned_tomograms"                                                                            | sets the name of the folder for binned tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| ctf_corrected_binned_tomograms_folder                | "ctf_corrected_binned_tomograms"                                                              | sets the name of the folder for ctf corrected binned tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| exact_filtered_ctf_corrected_binned_tomograms_folder | "exact_filtered_ctf_corrected_binned_tomograms"                                               | sets the name of the folder for exact filtered ctf corrected binned tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| binned_exact_filtered_tomograms_folder               | "binned_exact_filtered_tomograms"                                                             | sets the name of the folder for binned exact filtered tomograms, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                    |
| particles_folder                                     | "particles"                                                                                   | sets the name of the folder for particles, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| particles_table_folder                               | "particles_table"                                                                             | sets the name of the folder for particles table, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                    |
| particles_susan_info_folder                               | "particles_susan_info"                                                                             | sets the name of the folder for SUSAN-based data to reconstruct particles, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                    |
| meta_data_folder                                     | "meta_data"                                                                                   | sets the name of the folder for metadata, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| dynamo_folder                                        | "dynamo"                                                                                      | sets the name of the folder for dynamo catalogue, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| templates_folder                                     | "templates"                                                                                   | sets the name of the folder for templates, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| gain_correction_folder                               | "gain_correction"                                                                             | sets the name of the folder for the a posteriori gain correction which is generated by the GainCorrection module, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| binarized_stacks_folder                              | "binarized_stacks"                                                                            | sets the name of the folder for binarized stacks, normally you should not touch this, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| ctf_corrected_stack_suffix                           | "ctfc"                                                                                        | sets the suffix for ctf corrected stacks, normally you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |                    |
| ignore_success_files                                 | false                                                                                         | if flag is set to true on every restart the modules are rerun ignoring the success files if there are any                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |                    |
| keV                                                  | 300                                                                                           | sets the keV e.g. for MotionCor2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| spherical_aberation                                  | 2.7                                                                                           | sets the spherical aberration e.g. for MotionCor2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| skip_n\_first_projections                            | 3                                                                                             | **note** variable is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| nominal_defocus_in_nm                                | 4                                                                                             | sets the nominal defocus in nm                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| link_files_threshold_in_mb                           | 1                                                                                             | sets the threshold in MB (mega bytes) to link files from previous module runs if size is exceeded instead of copying                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| tilt_type                                            | "single"                                                                                      | this variable is used when generating a dynamo catalogue for documentary reasons only                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | "double"           |
| minimum_files                                        | 15                                                                                            | sets the threshold which defines the minimum amount of projections needed to keep a tilt stack for processing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                    |
| increase_folder_numbers                              | false                                                                                         | **note** feature is not implemented fully, could be removed if not needed, you should not touch this                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| cpu_fraction                                         | 0.25                                                                                          | controls the fraction of CPUs to be used if a parallel pool needs to be started for parallel processing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |                    |
| tomogram_indices                                     | \[\]                                                                                          | controls the tomograms which should be processed, can be set initially or later if you want only to process some of the tomograms or tilt stacks, has precedence over the combination of **tomogram_begin**, **tomogram_end** and **tomogram_step**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                    |
| tomogram_begin                                       | 0                                                                                             | defines the tomogram or tilt stack to start with processing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |                    |
| tomogram_end                                         | 0                                                                                             | defines the tomogram or tilt stack to end with processing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |                    |
| tomogram_step                                        | 1                                                                                             | defines the step which is used to chose tomograms or tilt stacks between **tomogram_begin** and **tomogram_end** for processing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |                    |
| aligned_stack_binning                                | 1                                                                                             | defines the binning to generate the aligned stack with, **note** if the binning is too low it affects drastically the computational time                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |                    |
| pre_aligned_stack_binning                            | 4                                                                                             | defines the binning to generate the pre aligned stack with, this is used for the module BatchRunTomo and DynamoTiltSeriesAlignment e.g. to detect the fiducial model **note** if the binning is too low it affects drastically the computational time                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| template_matching_binning                            | 4                                                                                             | defines the binning to use for template matching, **note** if the binning is too low it affects drastically the computational time, at best choose a binning where a tomogram can be fit in GPU memory e.g. 16 super resolution mode or 8 for counted mode, this is a rule of thumb it depends also on your protein's size                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |
| reconstruction_thickness                             | 2000                                                                                          | defines the thickness for the tomogram to be reconstructed, this can not be determined reliably so you need to choose an appropriate thickness for your tomograms to cover the information in all of the tomograms even if some or many of them are thinner                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |                    |
| binnings                                             | \[2, 4\]                                                                                      | defines the binnings to be generated, **note** you need to be careful to cover the template matching binning and all the binnings you want to process later your particles with the module DynamoAlignmentProject as they are not generated on the fly, however you can skip the binning level from the aligned stack as this is generated by BatchRunTomo and not by BinStacks, if you provide it BinStacks will skip it anyway, your aligned stack binning also defines the lowest binning level where particles are cropped from the tomograms in the DynamoAlignmentProject module if you go to a lower binning than that particles are cropped directly from the stacks with the SUSAN approach and are ctf corrected based on particles positions |                    |
| ignore_file_system_time_stamps                       | true                                                                                          | if data was copied from somewhere in a parallel manner like cp or scp does it you can not rely on file system timestamps to sort the data chronologically so this flag should be set to true else to false, data generated by serialEM contains the metadata in their names needed to sort files which is achieved if during data collection all necessary boxes are ticked for proper naming                                                                                                                                                                                                                                                                                                                                                           |                    |
| automatic_filename_parts_recognition                 | true                                                                                          | if data is collected with serialEM and data generated by serialEM contains the metadata in their names needed to sort files you can leave this options as it is as everything can be detected reliable automatically                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                    |
| angle_regex                                          | "\_(\[+-\]\*\[{\\\\d}2\]\*\[.\]+\\\\d)\[\_.\]"                                                | this variable contains the regular expression to detect the angle                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| name_regex                                           | "(\[A-Za-z\\\\d\_\]+\[A-Za-z\]+)"                                                             | this variable contains the regular expression to detect the name                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| number_regex                                         | "\[\_\]\*(\[\\\\d\]+\[\_\[\\\\d\]\*\]\*)\_"                                                   | this variable contains the regular expression to detect the number of the tomogram and projection                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| name_number_regex                                    | "(\[A-Za-z\\\\d\_\]+\[A-Za-z\]+)\[\_\]\*(\[\\\\d\]+\[\_\[\\\\d\]\*\]\*)"                      | this variable contains the regular expression to detect the combination of name and number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |
| name_number_regex_backup                             | "(\[A-Za-z\\\\d\_\]+\[A-Za-z\]+)\[\_\]\*(\[\\\\d\]+\[\_\[\\\\d\]\*\]\*)\_"                    | this variable contains the previous used regular expression for documentary reasons to detect the combination of name and number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| month_date_time_regex                                | "\[\_\]+(\[{A-Z}1\]\[{a-z}2\]+\[\\\\d\]+)\_(\[{\\\\d}2\]+.\[{\\\\d}2\]+.\[{\\\\d}2\]+)\[.\]+" | this variable contains the regular expression to detect the month, date and time                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                    |
| tomogram_acquisition_time_in_minutes                 | 70                                                                                            | this variable contains the regular expression to detect the combination of name and number, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |                    |
| keep_intermediates                                   | true                                                                                          | if this flag is set to true intermediate files will be kept else they will be deleted during execution, if you are not sure keep it as it is and use later the clean up functionality to get rid of unnecessary files in the specified project folder                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                    |
| reconstruct                                          | "binned"                                                                                      | this variable controls if binned or unbinned tomograms should be reconstructed, if "binned" option is used                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | "unbinned"         |
| em_clarity_path                                      | ""                                                                                            | this variable contains the path to emClarity, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |                    |
| dynamo_path                                          | "/sbdata/EM/projects/nibalysc/programs/dynamo-v-1.1.509_MCR-9.6.0_GLNXA64_withMCR"            | this variable contains the path to dynamo **note** this variable is not needed anymore as essential dynamo functionality which is used by tomoBEAR is integrated into the pipeline and also overrides some functionality for better performance, nevertheless it could be used to load Dynamo automatically into the workspace when matlab is loaded, this is not implemented                                                                                                                                                                                                                                                                                                                                                                           |                    |
| astra_path                                           | ""                                                                                            | this variable contains the path to astra a tomographic reconstruction framework, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |                    |
| modules                                              | \["IMOD", "cuda-10.2", "Gctf-v1.06", "MotionCor2"\]                                           | this array contains the module names to be loaded during startup, **note** functionality is not fully implemented and tested, modules should be loaded either manually or in system related bash file which is run on every start of a terminal like .bashrc in CentOS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |                    |
| duplicated_tilts                                     | "last"                                                                                        | this variable controls what should happen to duplicated projections which is an option in SerialEM where duplicated projections arise if some tracking errors occur where the are to be projected exceeds a threshold for image shifts compared to the previous projection                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |
| ft_bin                                               | 1                                                                                             | this variable sets the binning for MotionCor2 output, **note** functionality is not fully implemented because this option is not taken into account for later absolute binning calculations, please leave it as it is if you want to process also data with the resolution of the raw files, if you don't need this resolution you can bin the data already in MotionCor2 with this option                                                                                                                                                                                                                                                                                                                                                              |                    |
| as_boxes                                              | true                                                                                          | this flag controls if the cropped/reconstructed particles needed to be packaged in boxes (Dynamo-like); can be used with both Dynamo (1000 prts/box) and SUSAN (prts/box is defined by parameter "susan_particle_batch") particles                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| susan_particle_batch                                              | 1000                                                                                          | this variable sets the number of reconstructed by SUSAN particles per box                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| expected_symmetrie                                   | "C1"                                                                                          | this variable sets the expected symmetrie, if you don't use SUSAN you can use all symmetries which are available in Dynamo else you can only use the Cn symmetrie                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |                    |
| checkpoint_module                                    | false                                                                                         | this flag controls if a module is a checkpoint module, this means if it is not the module's output folder is emptied on execution when there is no SUCCESS file else the module needs to handle checkpoint like behaviour and recover and proceed with processing where it stopped                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                    |
| propagate_failed_stacks                              | true                                                                                          | this flag controls if failed stacks should be further propagated for processing, the default is set to true because BatchRunTomo should try to fit the fiducial model if the module DynamoTiltSeriesAlignment fails                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                    |
| first_tilt_angle                                     | ""                                                                                            | this variable controls at which tilt angle the first projection is taken, if the value is "" it is deduced from the data else you need to set it to some integer value when your files do not contain angular information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |                    |
| execute                                              | true                                                                                          | this flag controls if the process function of an module is executed, this is set automatically to false for the cleanup functionality, normally you should not touch this flag                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                    |
| citation                                             | ""                                                                                            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                    |

</details>
</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "general": {
        "gpu": -1,
        "jobs_per_node": 1,
        "gpus_per_node": 2,
        "nodes": [],
        "slurm_execute": true,
        "slurm_node_list": "",
        "slurm_nodes": 0,
        "slurm_nice": 0,
        "slurm_partition": "",
        "slurm_gres": "",
        "slurm_qos": "",
        "slurm_constraint": "",
        "slurm_time": "",
        "slurm_exclusive": true,
        "slurm_flags": "",
        "slurm_gpus": 0,
        "slurm_mem_per_gpu_in_gb": 0,
        "slurm_gpus_per_task": 0,
        "slurm": false,
        "gpu_worker_multiplier": 1,
        "pipeline_location": "",
        "pipeline_executable": "run_tomoBEAR.sh",
        "sbatch_wrapper": "sbatch.sh",
        "cuda_forward_compatibility": true,
        "random_number_generator_seed": 0,
        "tomogram_output_prefix": "tomogram",
        "tomogram_input_prefix": "",
        "data_path": "",
        "processing_path": "",
        "debug": false,
        "project_name": "pipeline",
        "project_description": "new_project description",
        "wipe_cache": false,
        "motion_correction_command": "MotionCor2_1.4.0_Cuda102",
        "ctf_correction_command": "Gctf-v1.06_sm_30_cu8.0_x86_64",
        "double_numbering": true,
        "prefix_position": 0,
        "tomogram_number_position": -1,
        "tilt_number_position": -1,
        "angle_position": -1,
        "date_position": -1,
        "time_position": -1,
        "output_folder": "output",
        "scratch_folder": "scratch",
        "remove_folders": false,
        "tilt_scheme": "dose_symmetric",
        "tilting_step": 3,
        "gold_bead_size_in_nm": 10,
        "rotation_tilt_axis": 85,
        "pid_wait_time": 5,
        "raw_files_folder": "raw_files",
        "fid_files_folder": "fiducial_models",
        "motion_corrected_files_folder": "motion_corrected_mrcs",
        "aligned_tilt_stacks_folder": "aligned_tilt_stacks",
        "ctf_corrected_aligned_tilt_stacks_folder": "ctf_corrected_aligned_tilt_stacks",
        "tilt_stacks_folder": "tilt_stacks",
        "binned_tilt_stacks_folder": "binned_tilt_stacks",
        "binned_aligned_tilt_stacks_folder": "binned_aligned_tilt_stacks",
        "ctf_corrected_binned_aligned_tilt_stacks_folder": "ctf_corrected_binned_aligned_tilt_stacks",
        "tomograms_folder": "tomograms",
        "ctf_corrected_tomograms_folder": "ctf_corrected_tomograms",
        "exact_filtered_tomograms_folder": "exact_filtered_tomograms",
        "binned_tomograms_folder": "binned_tomograms",
        "ctf_corrected_binned_tomograms_folder": "ctf_corrected_binned_tomograms",
        "exact_filtered_ctf_corrected_binned_tomograms_folder": "exact_filtered_ctf_corrected_binned_tomograms",
        "binned_exact_filtered_tomograms_folder": "binned_exact_filtered_tomograms",
        "particles_folder": "particles",
        "particles_table_folder": "particles_table",
        "particles_susan_info_folder": "particles_susan_info",
        "meta_data_folder": "meta_data",
        "dynamo_folder": "dynamo",
        "templates_folder": "templates",
        "gain_correction_folder": "gain_correction",
        "binarized_stacks_folder": "binarized_stacks",
        "ctf_corrected_stack_suffix": "ctfc",
        "ignore_success_files": false,
        "keV": 300,
        "spherical_aberation": 2.7,
        "skip_n_first_projections": 3,
        "nominal_defocus_in_nm": 4,
        "link_files_threshold_in_mb": 1,
        "tilt_type": "single",
        "minimum_files": 15,
        "increase_folder_numbers": false,
        "cpu_fraction": 0.25,
        "tomogram_indices": [],
        "tomogram_begin": 0,
        "tomogram_end": 0,
        "tomogram_step": 1,
        "aligned_stack_binning":1,
        "pre_aligned_stack_binning": 4,
        "template_matching_binning": 4,
        "reconstruction_thickness": 2000,
        "binnings": [2, 4],
        "ignore_file_system_time_stamps": true,
        "automatic_filename_parts_recognition": true,
        "angle_regex": "_([+-]*[{\\d}2]*[.]+\\d)[_.]",
        "name_regex": "([A-Za-z\\d_]+[A-Za-z]+)",
        "number_regex": "[_]*([\\d]+[_[\\d]*]*)_",
        "name_number_regex": "([A-Za-z\\d_]+[A-Za-z]+)[_]*([\\d]+[_[\\d]*]*)",
        "name_number_regex_backup": "([A-Za-z\\d_]+[A-Za-z]+)[_]*([\\d]+[_[\\d]*]*)_",
        "month_date_time_regex": "[_]+([{A-Z}1][{a-z}2]+[\\d]+)_([{\\d}2]+.[{\\d}2]+.[{\\d}2]+)[.]+",
        "tomogram_acquisition_time_in_minutes": 70,
        "keep_intermediates": true,
        "reconstruct": "binned",
        "em_clarity_path": "",
        "dynamo_path": "/sbdata/EM/projects/nibalysc/programs/dynamo-v-1.1.509_MCR-9.6.0_GLNXA64_withMCR",
        "astra_path": "",
        "modules": ["IMOD", "cuda-10.2", "Gctf-v1.06", "MotionCor2"],
        "duplicated_tilts": "last",
        "ft_bin": 1,
        "as_boxes": true,
        "susan_particle_batch": 1000,
        "expected_symmetrie": "C1",
        "checkpoint_module": false,
        "propagate_failed_stacks": true,
        "first_tilt_angle": 0,
        "execute": true,
        "citation": ""
    }
```
</details>

## Pipeline behavior control modules

### StopPipeline
**Description**
</br>

The StopPipeline module is a module which controls the behavior of
tomoBEAR. It allows to stop tomoBEAR after some processing step to
inspect the output and not waste computational resources if parameters
need to be optimized.

**Parameters**
</br>

| Key              | Default Value | Description                                                                                                   | Examples |
|------------------|---------------|---------------------------------------------------------------------------------------------------------------|----------|
| execution_method | "control"     | this variable defines the execution method for the module, **note** for this module it needs to be left as is |          |

```json
    "StopPipeline": {
        "execution_method": "control"
    }
```

## CryoET data processing modules
### MetaData

**Description**
</br>
The MetaData module collects descriptive statistics such as min, max,
mean, std from the raw data.

**Dependencies**
</br>
This module does not depend on any external packages.

**Parameters**
</br>

| Key                | Default Value | Description                                                                                                                                                                                                                                                                                     | Examples |
|--------------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method   | "control"     | this variable defines the execution method for the module, **note** for this module it needs to be left as is                                                                                                                                                                                   |          |
| parallel_execution | true          | this flag defines if the collection of the descriptive statistics should be done in parallel or not, **note** parallel execution may result in out of memory errors if you use it with the flag for **parallel_execution**, better to turn it off if you don't have sufficient amount of memory |          |
| do_statistics      | false         | this flag defines if descriptive statistics should be collected at all, **note** if this is not needed better turn it off because it will consume a substantial amount of processing time, especially for lage raw files with a lot of frames                                                   |          |
| apix               | 0             | if this variable is set to 0 the pixel size will be determined from the header else you can override it here                                                                                                                                                                                    |          |
| skip               | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                   |          |
| citation           | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                      |          |

```json
    "MetaData":{
        "execution_method": "once",
        "parallel_execution": true,
        "do_statistics": false,
        "apix": 0,
        "skip": false,
        "citation": ""
    }
```

### SortFiles

**Description**
</br>
The SortFiles module sorts the raw files on a tomogram basis and links
them to their corresponding folders for further processing.

**Dependencies**
</br>
This module does not depend on any external packages.

**Parameters**
</br>

| Key               | Default Value | Description                                                                                                                                                                                                                                           | Examples |
|-------------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method  | "parallel"    | this variable defines the execution method for the module, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops |          |
| starting_tomogram | 1             | this variable defines the start of the numbering of tomograms and tilt stacks, **note** leave it as it is because it can't be predicted if it affects indexing behaviour of tomoBEAR                                                                  |          |
| use_link          | true          | this flag defines if links or real copies should be used for the raw files, **note** only set it to true if you want an explicit copy of the data in your project folder                                                                              |          |
| fixed_number      | 0             | **note** this variable is not used anymore and can be deleted                                                                                                                                                                                         |          |
| skip              | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                         |          |
| citation          | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                            |          |

```json
    "SortFiles": {
        "execution_method": "parallel",
        "starting_tomogram": 1,
        "use_link": true,
        "fixed_number": 0,
        "skip": false,
        "citation": ""
      }
```

### MotionCor2

**Description**
</br>

This module uses MotionCor2 to correct for the sample movement in a given projection can be a dose-fractionated movie or EER sequence.

For some of the options it is advised to look also into the original manual of MotionCor2 provided along with the source code as there are some more detailed descriptions.

**Dependencies**
</br>
- MotionCor2
- IMOD
- CUDA (compatible with chosen MotionCor2 version, if GPU parallelization is needed)

**Parameters**
</br>
<details>
<summary> Parameters table <i> (click to expand) </i> </summary>
| Key                                           | Default Value | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Examples |
|-----------------------------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| method                                        | "MotionCor2"  | this variable defines the method to be used for frame based motion correction, **note** for this module it needs to be left as is, only MotionCor2 is supported at the moment                                                                                                                                                                                                                                                                                                                                                                                                                                                         |          |
| execution_method                              | "in_order"    | this variable defines the execution method for the module, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops                                                                                                                                                                                                                                                                                                                                                                                 |          |
| output_postfix                                | "motioncor2"  | this variable defines the postfix which is appended to motion corrected files                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |          |
| iterations                                    | 50            | this variable defines the termination criterion for motion correction, if this amount of iterations is reached the execution is terminated, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                              |          |
| tolerance                                     | 0.5           | this variable defines the termination criterion for motion correction, if the value of pixel error for alignment is lower than that threshold the execution is terminated, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                               |          |
| gpu_memory                                    | 0.5           | this variable defines the amount of memory to be used for motion correction, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |          |
| patch                                         | "7 5 15"      | this variable defines the amount of patches to be used for the motion correction, the format is "horizontal_patches vertical_patches overlap_in_percent", **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                | "4 3 20" |
| group                                         | 2             | this flag defines the number of frames to be grouped for better SNR for the process of motion correction , **note** try your setting first on a subset of the data as for some numbers the resulting projections can contain patches which are completely misaligned                                                                                                                                                                                                                                                                                                                                                                  |          |
| outstack                                      | 0             | if this flag is set to 1 the non averaged aligned stacks are output, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| gain                                          | ""            | this variable can contain the full path to the gain reference, either in mrc or dm4 format, if the GainCorrection module was used before to generate an aposteriori gain refeerence leave it as it as the gain reference will be input automatically, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                    |          |
| defect                                        | ""            | this variable defines the path to the defect file for the used imaging sensor, it can either be in txt format or mrc or dm4, if mrc or dm4 is used it will automatically be transformed to the required txt file, the txt file specify fixed regions of defects, it is composed of multiple lines of which each contains four space separated integers, x, y, w, and h that define a rectangular region of defects, x and y are the pixel coordinates of the lower left corner of such a region where w and h denote the width and height, respectively, **note** please consult the MotionCor2 documentation for further information |          |
| dark                                          | ""            | this variable can contain the full path to the dark reference, either in mrc or dm4 format, if dm4 is used it will be converted to mrc, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                  |          |
| b_factor                                      | \[500, 150\]  | this array defines the B factors to be used for global and local alignment respectively, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |          |
| in_fm_motion                                  | 1             | if this variable is set to 1 MotionCor2 takes into account of motion induced blurring of each frame, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| apply_dose_weighting                          | false         | if this flag is set to true dose weighted motion corrected images are generated, for this to work the **keV**, **apix** and **fm_dose** need to be set which they normally are, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                          |          |
| fm_dose                                       | 0.3           | this variable defines the dose per frame, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |          |
| tilt                                          | ""            | **note** this variable can be deleted as this is not supported by MotionCor2 anymore or never was implemented to the end as the developer said                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |          |
| magnification_anisotropy_major_scale          | 1             | this variable defines the major scale axis of magnification anisotropy, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | 1.16     |
| magnification_anisotropy_minor_scale          | 1             | this variable defines the major scale axis of magnification anisotropy, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | 1.1      |
| magnification_anisotropy_major_axis_angle     | 360           | this variable defines the angle of major scale magnification anisotropy axis, 360 means skip corrcetion of magnification anisotropy, the same can be achieved if minor and major axis is set to 1.0, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                     |          |
| magnification_anisotropy_major_scale_tmp      | 1             | **note** this variable is not used, only for documentary reasons, can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |          |
| magnification_anisotropy_minor_scale_tmp      | 1             | **note** this variable is not used, only for documentary reasons, can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |          |
| magnification_anisotropy_major_axis_angle_tmp | 360           | **note** this variable is not used, only for documentary reasons, can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |          |
| split_sum                                     | false         | if this flag is set to true even and odd sums are generated that are the partial sums of even and odd frames, respectively, the corresponding MRC files are appended with "EVN" and "ODD", respectively, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                 |          |
| out_aln                                       | ""            | here you can specify the path to the directory where the alignment file will be saved, the alignment file is a text file that stores the program setting and measured global and local motion, this file can be reloaded next time into MotionCor2 that will bypass the alignment process, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                               |          |
| initial_dose                                  | ""            | this variable defines the initial dose received before stack is acquired, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |          |
| align                                         | "1"           | this variable defines if an aligned sum "1" or simple sum "0" should be generated, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |          |
| throw                                         | "0"           | this variable defines the initial number of frames to throw away, default is 0, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |          |
| trunc                                         | "0"           | this vraiable defines the number of last frames to be truncated, default is 0, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |          |
| sum_range                                     | \[0, 0\]      | sum frames whose accumulated doses fall in the specified range, the first number is the minimum dose and the second is the maximum dose, default range is \[3, 25\] electrons per square angstrom, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                                                                                                       |          |
| fm_ref                                        | ""            | this variable specifies a frame in the input movie stack to be the reference to which all other frames are aligned, the reference is 1-based index in the input movie stack regardless how many frames will be thrown away, by default the reference is set to be the last frame, **note** please consult the MotionCor2 documentation for further information                                                                                                                                                                                                                                                                        |          |
| skip                                          | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |          |
| citation                                      | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |          |
| citation_link                                 | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |          |
| doi                                           | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |          |
</details>
</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "MotionCor2": {
        "method": "MotionCor2",
        "execution_method": "in_order",
        "output_postfix": "motioncor2",
        "iterations": 50,
        "tolerance": 0.5,
        "gpu_memory": 0.5,
        "patch": "7 5 15",
        "group": 2,
        "outstack": 0,
        "gain": "",
        "defect": "",
        "dark": "",
        "b_factor": [500, 150],
        "in_fm_motion": 1,
        "apply_dose_weighting": false,
        "fm_dose": 0.3,
        "tilt": "",
        "magnification_anisotropy_major_scale": 1,
        "magnification_anisotropy_minor_scale": 1,
        "magnification_anisotropy_major_axis_angle": 360,
        "magnification_anisotropy_major_scale_tmp": 1,
        "magnification_anisotropy_minor_scale_tmp": 1,
        "magnification_anisotropy_major_axis_angle_tmp": 360,
        "split_sum": "false",
        "out_aln": "",
        "initial_dose": "",
        "align": "1",
        "throw": "0",
        "trunc": "0",
        "sum_range": [0, 150],
        "fm_ref": "",
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```
</details>

### GridEdgeEraser
**Description**
</br>
This module performs grid edge identification and erases it for Au grids data.

**Dependencies**
</br>
- Dynamo

**Parameters**
</br>
```json
    "GridEdgeEraser": {
        "execution_method": "in_order",
        "detection_binning": 4,
        "grid_hole_diameter_in_um": 2,
        "output_shift_user": [0, 0],
        "output_shift_kernel_factor": [0, 0],
        "binarize_threshold_in_std": 3,
        "grid_detection_threshold_in_std": 3,
        "smooth_mask_border": true,
        "smooth_to_mean": true,
        "smoothing_exp_decay": -40,
        "cleaned_postfix": "gef",
        "relink_as_previous_output": false
    }
```

### CreateStacks

**Description**
</br>

The CreateStacks module creates the stacks and normalizes them. There
are two options for normalization. The default normalization scheme is
to divide the projections by their frame count. TomoBEAR detects
automatically if you are using high-dose images from hybrid StA approach and divides them by
their corresponding frame count in contrast to low-dose images where the
frame-count is different.

**Dependencies**
</br>
- Dynamo
- IMOD

**Parameters**
</br>

| Key                                | Default Value | Description                                                                                                                                                                                                                                                                                                                              | Examples |
|------------------------------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method                   | "in_order"    | this variable defines the execution method for the module, if set to parallel out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops |          |
| slice_suffix                       | "view"        | this variable defines the suffix which is prepended to the extracted projections (called slices here) from a stack which was output by serialEM with already aligned and averaged frames, projections need to be separated and normalized here because serialEM doesn't know high dose images which contain a higher electron dose       |          |
| normalization_method               | "frames"      | this variable defines the method for normalization, if frames is set then the projections are normalized by the frame count, if "mean_std" is set then the projections are normalized to mean value of 0 and standard deviation of 1                                                                                                     |          |
| normalized_postfix                 | "norm"        | this variable defines the postfix which is appended to the normalized projections                                                                                                                                                                                                                                                        |          |
| stack_name                         | "tiltstack"   | **note** this variable is not used anymore and can be deleted                                                                                                                                                                                                                                                                            |          |
| pixel_intensity_average            | 128           | this variable defines the average pixel intensity for the **method** "mean_std"                                                                                                                                                                                                                                                          |          |
| pixel_intensity_standard_deviation | 4             | this variable defines the standard deviation of high dose images for the **method** "mean_std"                                                                                                                                                                                                                                           |          |
| border_pixels                      | 75            | this variable defines the amount of soft border pixels to add to the projections to generate reconstructions with less reconstruction artifacts                                                                                                                                                                                          |          |
| skip                               | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                            |          |
| citation                           | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                               |          |
| citation_link                      | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                               |          |
| doi                                | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                               |          |

```json
    "CreateStacks": {
        "execution_method": "in_order",
        "slice_suffix": "view",
        "normalization_method": "frames",
        "normalized_postfix": "norm",
        "stack_name": "tiltstack",
        "pixel_intensity_average": 128,
        "pixel_intensity_standard_deviation": 4,
        "border_pixels": 75,
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```

### DynamoTiltSeriesAlignment

**Description**
</br>

The DynamoTiltSeriesAlignment module is using the tilt stacks alignment
algorithm from dynamo which is the state of the art available algorithm for fiducial-based alignment. As default, reasonable parameters for many cryo-ET projects are set. Some of them are dynamically derived. The option to
override non-dynamically derived parameters is available via the JSON configuration file. For troubleshooting and optimization of parameters it is possible to go to the processing folder and [use the Dynamo tools as in the Dynamo tutorial](https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Walkthrough_on_GUI_based_tilt_series_alignment).

**Dependencies**
</br>
- Dynamo

**Parameters**
</br>

<details>
<summary> Parameters table <i> (click to expand) </i> </summary>

| Key                                       | Default Value               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Examples |
|-------------------------------------------|-----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method                          | "parallel"                  | this variable defines the execution method for the module, if set to parallel out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops                                                                                                                                                                                                                |          |
| checkpoint_module                         | true                        | this flag controls if a module is a checkpoint module, this means if it is not the module's output folder is emptied on execution when there is no SUCCESS file else the module needs to handle checkpoint like behaviour and recover and proceed with processing where it stopped                                                                                                                                                                                                                                                                      |          |
| method                                    | "rms"                       | this variable defines the method for chosing a fiducial model, "rms" means chosing the model with lowest root mean squred error, "markers" means taking the model with most full paths of markers or fiducials ans "observations" means taking the model with most observations of markers, the chosen model is taken later for additional tracking and refinement in IMOD with the BatchRunTomo Module, it is advised to put the StopPipeline module after BatchRunTomo is done with fiducial tracking for inspection and additional manual refinement |          |
| generate_fiducial_files                   | true                        | if this flag is set to true fiducial model files ".fid" are generated for injecting into IMOD or BatchRunTomo module                                                                                                                                                                                                                                                                                                                                                                                                                                    |          |
| dynamo_tilt_stack_alignment_template_file | "configurations/global.doc" | this variable contains the path to the configuration file for the dynamo tilt series alignment algorithm it is merged with the values which can be found under the key **original_parameters**                                                                                                                                                                                                                                                                                                                                                          |          |
| config_file_name                          | "config.doc"                | this variable defines the name of the final config file which is generated to be input into the instantiation of the dynamo tilt series alignment algorithm                                                                                                                                                                                                                                                                                                                                                                                             |          |
| skip_ctf_estimation                       | true                        | this flag defines if the ctf estimation through dynamo tilt series alignment should be skipped, **note** this is the normal behaviour and should be left like that because the stacks generated by IMOD are used because of their better appearence for further processing like ctf correction and reconstruction                                                                                                                                                                                                                                       |          |
| mask_radius_factor                        | 1.5                         | this variable defines the factor to calculate the radius for the mask for fiducials, **note** normally you can leave this parameter as is                                                                                                                                                                                                                                                                                                                                                                                                               |          |
| template_side_length_factor               | 4                           | this variable defines the factor to calculate the side length of the template for fiducial detection, **note** normally you can leave this parameter as is                                                                                                                                                                                                                                                                                                                                                                                              |          |
| max_shift_ratio                           | 0.25                        | this variable defines the maximum shift for projections to keep, it is based on the smaller side length of a projection, **note** normally you can leave this parameter as is                                                                                                                                                                                                                                                                                                                                                                           |          |
| gold_bead_size_in_nm_testing_range        | 1                           | this variable defines gold bead size range for testing of fiducial detection, 1 means it will test **gold_bead_size_in_nm** + 1 and **gold_bead_size_in_nm** - 1, **note** this approach results in larger processing times but can yield more aligned tilt stacks                                                                                                                                                                                                                                                                                      |          |
| test_range                                | true                        | this flag controls if the range should be at all tested, if not then only **gold_bead_size_in_nm** will be used for fiducial detection else the range is tested until a run succeeds, this run defines then fiducial model **note** this approach results in larger processing times but can yield more aligned tilt stacks                                                                                                                                                                                                                             |          |
| test_whole_range                          | false                       | this flag controls if the whole range defined with **gold_bead_size_in_nm_testing_range** and **gold_bead_size_in_nm** should tested, if not then the first succeeded run of the fitting will be used for fiducial detection, **note** this approach results in larger processing times but can yield even more aligned tilt stacks                                                                                                                                                                                                                     |          |
| take_defaults                             | true                        | this flag defines if the defaults from Dynamo should be used as this sometimes yields on some data sets the best results                                                                                                                                                                                                                                                                                                                                                                                                                                |          |
| detection_binning_factor                  | 2                           | this variable defines the binning factor for detection of fiducials in the first steps of the Dynamo tilt series alignment algorithm                                                                                                                                                                                                                                                                                                                                                                                                                    |          |
| original_parameters                       | {...}                       | **note** please consult the [Dynamo page](https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Main_Page) [here](https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Walkthrough_on_command_line_based_tilt_series_alignment) and [here](https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Walkthrough_on_GUI_based_tilt_series_alignment) for the description of original parameters                                                                                                                                                               |          |
| skip                                      | false                       | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                                                                                                                                                                                                                                           |          |
| citation                                  | ""                          | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                              |          |
| citation_link                             | ""                          | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                              |          |
| doi                                       | ""                          | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                              |          |

</details>
</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "DynamoTiltSeriesAlignment": {
        "execution_method": "parallel",
        "checkpoint_module": true,
        "method": "rms",
        "generate_fiducial_files": true,
        "dynamo_tilt_stack_alignment_template_file": "configurations/global.doc",
        "config_file_name": "config.doc",
        "skip_ctf_estimation": true,
        "mask_radius_factor": 1.5,
        "template_side_length_factor": 4,
        "max_shift_ratio": 0.25,
        "gold_bead_size_in_nm_testing_range": 1,
        "test_range": true,
        "test_whole_range": false,
        "take_defaults": true,
        "detection_binning_factor": 2,
        "original_parameters": {
            "settings.computing.cpus": "10",
            "settings.computing.gpuSet": 1,
            "settings.computing.gpuUse": 1,
            "settings.computing.parallelCPUUse": 1,
            "settings.general.amplitudeContrast": 0.9,
            "settings.general.apix": 1.701,
            "settings.general.nominalDefocus": -2.5,
            "settings.general.sphericalAberration": 2.7,
            "settings.general.voltage": 300,
            "steps.alignWorkingStack.alignmentBinLevel": 8,
            "steps.binnedReconstruction.reconstructBinnedSIRT": 0,
            "steps.binnedReconstruction.reconstructBinnedWBP": 0,
            "steps.binnedReconstruction.reconstructBinnedWBPCTF": 0,
            "steps.binnedReconstruction.reconstructionBinnedHeight": 500,
            "steps.binner.workingBinningFactor": 4,
            "steps.chainSelector.minimumMarkerDistance": 100,
            "steps.chainSelector.minimumMarkersPerTilt": 3,
            "steps.chainSelector.minimumOccupancy": 15,
            "steps.chainSelector.relaxedMinimumOccupancy": 5,
            "steps.chainSelector.skipMarkedIndices": 1,
            "steps.correctCTF.imodPhaseFlipExecutable": "ctfphaseflip",
            "steps.correctCTF.phaseflipDefocusTolerance": 250,
            "steps.correctCTF.phaseflipInterpolationWidth": 4,
            "steps.correctCTF.phaseflipMaximumStripWidth": 1024,
            "steps.correctCTF.useImodPhaseFlip": 1,
            "steps.detectPeaks.beadRadius": 30,
            "steps.detectPeaks.detectionBinningFactor": 2,
            "steps.detectPeaks.maskRadius": 36,
            "steps.detectPeaks.templateSidelength": 72,
            "steps.estimateCTF.ctffind4": "ctffind",
            "steps.estimateCTF.ctffind4Card": "$DYNAMO_ROOT/examples/ctffind4Card.doc",
            "steps.estimateCTF.ctffind4Use": 0,
            "steps.estimateCTF.ctffind4UseCard": 0,
            "steps.finalSelection.maximalResidualPerObservation": "Inf",
            "steps.finalSelection.maximalResidualPerTrace": "Inf",
            "steps.finalSelection.minimumAmountOfMarkersPerMicrograph": 2,
            "steps.fittingModel.psi": "single",
            "steps.fittingModel.psiRange": 2,
            "steps.fixAlignmentMarkers.stackZshift": 0,
            "steps.fullReconstruction.centerBinnedCoordinatesValue": [0, 0, 0],
            "steps.fullReconstruction.reconstructFullSIRT": 0,
            "steps.fullReconstruction.reconstructFullWBP": 0,
            "steps.fullReconstruction.reconstructFullWBPCTF": 0,
            "steps.fullReconstruction.reconstructionFullSize": [400, 400, 400],
            "steps.fullReconstruction.reconstructionShiftCenter": [0, 0, 0],
            "steps.fullReconstruction.useCenterOnbinnedCoordinates": 0,
            "steps.independentMarkerRefinement.gaussfiltOutlierDetectionCC": 1,
            "steps.independentMarkerRefinement.iterationsRefineAverages": 1,
            "steps.independentMarkerRefinement.recenterAverages": 1,
            "steps.peakFeatures.symmetryOrder": 9,
            "steps.peakSelector.useSobelForSelection": 1,
            "steps.peakSelector.useSymmetryOrderForSelection": 1,
            "steps.reindexer.excludeMultipleMatches": 1,
            "steps.reindexer.exclusionRadiusMultipleMatches": 30,
            "steps.reindexer.minimumOccupancy": 10,
            "steps.reindexer.proximityThreshold3DThinning": 20,
            "steps.reindexer.proximityThresholdReprojection": 10,
            "steps.shifter.maximalHysteresis": 20,
            "steps.shifter.maximalShift": 1000,
            "steps.shifter.shiftInterval": 20,
            "steps.shifter.skipManualDiscardsInShifts": 1,
            "steps.tiltExtensor.knotGridSeparation": 20,
            "steps.tiltExtensor.maximumOverlapProjections": 50,
            "steps.tiltExtensor.minimalKnotContributions": 15,
            "steps.tiltExtensor.rerunIterativeReindexingInExtensor": 1,
            "steps.tiltExtensor.rerunTiltGapFillingInExtensor": 1,
            "steps.tiltExtensor.separationYStripe": 20,
            "steps.tiltExtensor.thresholdKnotDistance": 40,
            "steps.tiltExtensor.widthYStripe": 40,
            "steps.tiltGapFiller.estimateResidualsThreshold": 0,
            "steps.tiltGapFiller.increaseDistanceThreshold": 10,
            "steps.tiltGapFiller.initialDistanceThreshold": 10,
            "steps.tiltGapFiller.maximalDistanceThreshold": 40,
            "steps.tiltGapFiller.maximumMarkersDefiningGap": 4,
            "steps.tiltGapFiller.minimumMarkersTargeted": 4,
            "steps.tiltGapFiller.minimumOccupancyContributingChain": 4,
            "steps.tiltGapFiller.residualsThreshold": 5,
            "steps.tiltGapFiller.targetedOccupancyContributingChain": 10,
            "steps.traceGapFiller.exclusionRadius": 30,
            "steps.traceGapFiller.fastCC": 1,
            "steps.traceGapFiller.maximalDeviationFromReprojection": 5,
            "steps.trimMarkers.maximalMedianResidualMarker": 10,
            "steps.trimMarkers.maximalResidualObservation": 5,
            "steps.trimMarkers.minimumOccupancy": 15,
            "steps.trimMarkers.proximityDeletionThreshold": 80,
            "steps.trimMarkers.proximityFusionThreshold": 10
        },
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```
</details>

### DynamoCleanStacks

**Description**
</br>
The DynamoCleanStacks module can be run after the
DynamoTiltSeriesAlignment to automatically clean up the tilt stacks and to remove the projections where DynamoTiltSerieAlignment has not found gold beads. For
that **DynamoCleanStacks** uses the output from dynamo tilt stacks
alignment which states on which projections the fiducials could be fit.
The others are then removed from the tilt stacks for further processing.

**Dependencies**
</br>
- Dynamo
- IMOD

**Parameters**
</br>

| Key                   | Default Value | Description                                                                                                                                                                                                                                                                                                                                | Examples |
|-----------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method      | "parallel"    | this variable defines the execution method for the module, if set to "parallel" out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops |          |
| show_truncated_stacks | false         | this flag controls if the truncated tilt stacks should be shown to the user, this is only advisable if you run the module in serial mode with **execution_method** "sequential"                                                                                                                                                            |          |
| skip                  | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                              |          |
| citation              | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |
| citation_link         | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |
| doi                   | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |

```json
    "DynamoCleanStacks": {
        "execution_method": "parallel",
        "show_truncated_stacks": false,
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```

### AreTomo
**Description**
</br>
The AreTomo module uses AreTomo to perform global or local fiducial-free alignment of the tilt stack. In order to optimize alignment parameters, please consult with the corresponding AreTomo documentation.

**Dependencies**
</br>
- AreTomo
- IMOD
- CUDA (compatible with AreTomo)

**Parameters**
</br>

```json
    "AreTomo": {
        "execution_method": "in_order",
        "input_stack_binning": 1,
        "reconstruction": false,
        "weighted_back_projection": true,
        "tilt_axis_refine_flag": 1,
        "correct_tilt_axis_offset": 0,
        "apply_given_tilt_axis_offset": false,
        "tilt_axis_offset": 0,
        "align_height_ratio": 0.75,
        "apply_dose_weighting": false,
        "sart": "20 5",
        "roi": "0 0",
        "roi_file": "",
        "patch": "0 0",
        "flip_volume": 1,
        "flip_intensity": 0,
        "use_previous_alignment": false,
        "citation": ""
    }
```

### BatchRunTomo

**Description**
</br>

The BatchRunTomo is a versatile module performing IMOD operations. The detailed description can be found here: Tomography Guide for [IMOD Version 4.11](https://bio3d.colorado.edu/imod/doc/tomoguide.html). TomoBEAR can runs steps of batchruntomo:

-   0: Setup
-   1: Preprocessing
-   2: Cross-correlation alignment
-   3: Pre Aligned stack
-   4: Patch tracking, auto seeding, or RAPTOR
-   5: Bead tracking
-   6: Alignment
-   7: Positioning
-   8: Aligned stack generation
-   9: CTF plotting
-   10: 3D gold detection
-   11: CTF correction
-   12: Gold erasing after transforming fiducial model or projecting 3D
    model
-   13: 2D filtering
-   14: Reconstruction
-   14.5: Postprocessing on a/b axis reconstruction
-   15: Combine setup
-   16: Solvematch
-   17: Initial matchvol;
-   18: Autopatchfit
-   19: Volcombine
-   20: Post Processing with Trimvol
-   21: NAD (Nonlinear anisotropic diffusion)

**Dependencies**
</br>
- IMOD

**Parameters**
</br>

<details>
<summary> Parameters table <i> (click to expand) </i> </summary>
| Key                                                | Default Value                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                     | Examples |
|----------------------------------------------------|---------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method                                   | "parallel"                                  | this variable defines the execution method for the module, if set to "parallel" out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops                                                                                      |          |
| take_fiducials_from_dynamo                         | true                                        | this flag controls if the fiducial model determined with the module **DynamoTiltSeriesAlignment** should be injected into **BatchRunTomo**, **note** this is the normal behaviour and should not be changed because **DynamoTiltSeriesAlignment** does most of the time a better job and if that fails and only if the fiducial model is determined by running batchruntomo automatic seeding with seed tracking for that stack |          |
| generate_seed_model_with_all_fiducials_from_dynamo | true                                        | this flag controls if the fiducial model should be generated from seeds only from the central projection, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                            |          |
| reconstruct_binned_stacks                          | false                                       | this flag controls if binned stacks should be reconstructed, please use for that the **BinStacks** module, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                           |          |
| gold_erasing_extra_diameter                        | 30                                          | this variable controls the extra diameter in pixels added to the gold bead size for erasing the gold beads                                                                                                                                                                                                                                                                                                                      |          |
| maximum_strip_width                                | 1000                                        | this variable controls the maximum strip width for ctf correction, sometimes it results in gpu memory error if this parameter is not set, that is why it was introduced                                                                                                                                                                                                                                                         |          |
| cpu_machine_list                                   | ""                                          | this variable holds the cpu machine list file for parallel processing, this is not needed because parallel processing is achieved with other methods                                                                                                                                                                                                                                                                            |          |
| template_file                                      | "configurations/batchruntomo-template.adoc" | this variable holds the path to the batchruntomo template configuration file which is later merged with the values which can be found under the key **directives**                                                                                                                                                                                                                                                              |          |
| directive_file_name                                | "DirectiveFile"                             | this variable holds the name of the directive file which is generated by merging **template_file** and values under the key **directives** and afterwards fed into batchruntomo                                                                                                                                                                                                                                                 |          |
| starting_step                                      | 0                                           | this variable controls the starting step from which this module should be run, to start from a later step a previous run up to some step before should exist in the json file, then it will continue from the previous instantiation of this module, except if you start from step 0, the steps are the ones you can find as the bullet list in the beginning of this paragraph                                                 |          |
| ending_step                                        | 21                                          | this variable controls the ending step, obviously the ending step must be a higher number than the **starting_step**                                                                                                                                                                                                                                                                                                            |          |
| skip_steps                                         | \[\]                                        | this variable controls the steps to be skipped, obviously the **ending_step** must be a higher number than the **starting_step** and higher than all steps entered in **skipt_steps** and **starting_step** must be lower than **ending_step** and all steps entered in **skip_steps**                                                                                                                                          |          |
| exit_on_error                                      | true                                        | sets the batchruntomo flag "-ExitOnError" to the corresponding value, **note** please consult the IMOD documentation for batchruntomo for further information                                                                                                                                                                                                                                                                   |          |
| batchruntomo_description                           | "..."                                       | this flag controls if the truncated tilt stacks should be shown to the user, this is only advisable if you run the module in serial mode with **execution_method** "sequential"                                                                                                                                                                                                                                                 |          |
| directives_description                             | {...}                                       | this vriable just hold the path to a description file of the parameters under the key **directives** and a link to a page describing the parameters under the key **directives**                                                                                                                                                                                                                                                |          |
| directives                                         | {...}                                       | this variable holds all the parameters which can be setup for batchruntomo, **note** please consult the IMOD documentation for batchruntomo directives for further information                                                                                                                                                                                                                                                  |          |
| skip                                               | false                                       | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                                                                                                                   |          |
| citation                                           | ""                                          | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                      |          |
| citation_link                                      | ""                                          | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                      |          |
| doi                                                | ""                                          | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                      |          |

The value "<REPLACE>" means it will be automatically replaced by
tomoBEAR and should not be replaced or changed by the user.
</details>
</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "BatchRunTomo": {
        "execution_method": "parallel",
        "take_fiducials_from_dynamo": true,
        "generate_seed_model_with_all_fiducials_from_dynamo": true,
        "reconstruct_binned_stacks": false,
        "gold_erasing_extra_diameter": 30,
        "maximum_strip_width": 1000,
        "cpu_machine_list": "",
        "template_file": "configurations/batchruntomo-template.adoc",
        "directive_file_name": "DirectiveFile",
        "starting_step": 0,
        "ending_step": 21,
        "exit_on_error": true,
        "batchruntomo_description": "0: Setup
                 1: Preprocessing
                 2: Cross-correlation alignment
                 3: Prealigned stack
                 4: Patch tracking, autoseeding, or RAPTOR
                 5: Bead tracking
                 6: Alignment
                 7: Positioning
                 8: Aligned stack generation
                 9: CTF plotting
                 10: 3D gold detection
                 11: CTF correction
                 12: Gold erasing after transforming fiducial model or
                     projecting 3D model
                 13: 2D filtering
                 14: Reconstruction
                 14.5: Postprocessing on a/b axis reconstruction
                 15: Combine setup
                 16: Solvematch
                 17: Initial matchvol;
                 18: Autopatchfit
                 19: Volcombine
                 20: Postprocessing with Trimvol
                 21: NAD (Nonlinear anistropic diffusion)",
        "directives_description": {
            "path": "/home/local/imod_4.10.9/com/directives.csv"
        },
        "directives": {
            "setupset.copyarg.focus": 0,
            "setupset.copyarg.bfocus": 0,
            "setupset.copyarg.dual": 0,
            "setupset.copyarg.montage": 0,
            "runtime.Preprocessing.any.archiveOriginal": 0,
            "setupset.copyarg.pixel": "`<REPLACE>`",
            "setupset.copyarg.gold": "`<REPLACE>`",
            "setupset.copyarg.rotation": "`<REPLACE>`",
            "setupset.copyarg.userawtlt": 1,
            "setupset.copyarg.extract": 0,
            "setupset.copyarg.voltage": "`<REPLACE>`",
            "setupset.copyarg.Cs": "`<REPLACE>`",
            "setupset.copyarg.defocus": "`<REPLACE>`",
            "runtime.Preprocessing.any.removeXrays": 1,
            "comparam.eraser.ccderaser.LineObjects": 2,
            "comparam.eraser.ccderaser.BoundaryObjects": 3,
            "comparam.eraser.ccderaser.AllSectionObjects": "1-3",
            "comparam.prenewst.newstack.BinByFactor": "`<REPLACE>`",
            "runtime.RAPTOR.any.useAlignedStack": 1,
            "runtime.RAPTOR.any.numberOfMarkers": 50,
            "runtime.Fiducials.any.trackingMethod": 0,
            "runtime.Fiducials.any.seedingMethod": 1,
            "comparam.track.beadtrack.LightBeads": 0,
            "comparam.track.beadtrack.RoundsOfTracking": 5,
            "runtime.BeadTracking.any.numberOfRuns": 2,
            "comparam.track.beadtrack.SobelFilterCentering": 1,
            "comparam.track.beadtrack.KernelSigmaForSobel": 1.5,
            "comparam.autofidseed.autofidseed.TwoSurfaces": 0,
            "comparam.autofidseed.autofidseed.TargetNumberOfBeads": 20,
            "comparam.autofidseed.autofidseed.AdjustSizes": 1,
            "comparam.align.tiltalign.MagOption": 0,
            "comparam.align.tiltalign.TiltOption": 0,
            "comparam.align.tiltalign.RotOption": "-1",
            "comparam.align.tiltalign.XTiltOption": 0,
            "comparam.align.tiltalign.BeamTiltOption": 0,
            "comparam.newst.newstack.AntialiasFilter": -1,
            "runtime.AlignedStack.any.binByFactor": "`<REPLACE>`",
            "runtime.AlignedStack.any.correctCTF": 1,
            "runtime.AlignedStack.any.eraseGold": 2,
            "comparam.align.tiltalign.RobustFitting": 1,
            "comparam.tilt.tilt.THICKNESS": "`<REPLACE>`",
            "runtime.Reconstruction.any.useSirt": 0,
            "runtime.Reconstruction.any.doBackprojAlso": 1,
            "runtime.Postprocess.any.doTrimvol": 1,
            "runtime.Trimvol.any.reorient": 2,
            "runtime.Preprocessing.any.removeExcludedViews": 0,
            "setupset.copyarg.twodir": 0,
            "setupset.scanHeader": 0,
            "comparam.tilt.tilt.LOG": "",
            "comparam.tilt.tilt.SCALE": "0.0 1.0",
            "comparam.tilt.tilt.RADIAL": "0.5 0.0",
            "comparam.tilt.tilt.XAXISTILT": "0.0",
            "comparam.tilt.tilt.AdjustOrigin": 0,
            "comparam.align.tiltalign.AngleOffset": "0.0",
            "comparam.align.tiltalign.SeparateGroup": "`<REPLACE>`",
            "comparam.align.tiltalign.SurfacesToAnalyze": 1,
            "runtime.Positioning.any.centerOnGold": 1,
            "runtime.Positioning.any.sampleType": 0,
            "runtime.Positioning.any.wholeTomogram": 0,
            "runtime.Positioning.any.hasGoldBeads": 1,
            "comparam.xcorr.tiltxcorr.SearchMagChanges": 0,
            "comparam.align.tiltalign.LocalAlignments": 0,
            "runtime.GoldErasing.any.extraDiameter": "`<REPLACE>`",
            "runtime.GoldErasing.any.thickness": "`<REPLACE>`"
        },
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```
</details>

### GCTFCtfphaseflipCTFCorrection

**Description**
</br>
The GCTFCtfphaseflipCTFCorrection module is detecting the defocus using Gctf or CTFIND4 on the tilt series which will be further CTF-corrected and used to reconstruct tomograms for template matching or particles generation. The results can be examined in the processing folders. As well, the module can be used for CTF-correction using ctfphaseflip from IMOD.

**Dependencies**
</br>
- IMOD
- GCTF/CTFFIND4
- CUDA (compatible with GCTF/CTFFIND4)

**Parameters**
</br>

<details>
<summary> Parameters table <i> (click to expand) </i> </summary>

| Key                               | Default Value        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Examples |
|-----------------------------------|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method                  | "parallel"           | this variable defines the execution method for the module, if set to "parallel" out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| defocus_limit_factor              | 2                    | this variable sets the factor for the definition of the lower and upper bound of the defocus value, the defocus value will be divided and multiplied by this factor to set the lower and upper bound, respectively                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |          |
| slice_suffix                      | "view"               | this variable holds the suffix to be appended to the extracted slices                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |          |
| slice_folder                      | "slices"             | this variable holds the name of the folder to be created for storing the slices                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |          |
| gctf_correction_log_file          | "gctf.log"           | this variable holds the name for the log file to be generated by gctf, **note** variable is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |          |
| ctf_correction_log_file           | "ctf_correction.log" | this variable holds the name for the log file to be generated by gctf, **note** variable is not used and can be deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |          |
| exact_filter_suffix               | "ef"                 | this variable holds the suffix to be appended to the name for tomograms reconstructed with the exact filter                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |          |
| tomogram_suffix                   | "full"               | this variable holds the suffix to be appended to the name of tomograms                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |          |
| rotated_tomogram_suffix           | "rotx"               | this variable holds the suffix to be appended to the name of tomograms which are rotated to be conform with IMOD's 3dmod                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |          |
| generate_exact_filtered_tomograms | true                 | this flag controls if exact filtered tomograms should be generated                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |          |
| exact_filter_size                 | 1500                 | this variable holds the filter size of the exact filter                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |          |
| reconstruction_thickness          | 2000                 | this variable holds the reconstruction thickness in voxels for the tomograms to be reconstructed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |          |
| use_aligned_stack                 | false                | this flag controls if aligned or raw stacks should be used for tomogram reconstruction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |          |
| do_phase_flip                     | false                | this flag controls if phase flipping should be done by Gctf                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |          |
| run_ctf_phase_flip                | false                | this flag controls if phase flipping should be done by external application ctfphaseflip from IMOD package                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| reconstruct_tomograms             | false                | this flag controls if tomograms should be reconstructed at all                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |          |
| defocus_tolerance                 | 20                   | this variable sets the "-defTol" argument from ctfphaseflip from the IMOD package: Defocus tolerance in nanometers, which is one factor that governs the width of the strips. The actual strip width is based on the width of this region and several other factors: a fixed minimum width of 128, a minimum width required to achieve sufficient resolution in the Fourier transform, governed by the the 0zero option, and the dynamic adjustment of maximum width described above.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |          |
| iWidth                            | 2                    | this variable sets the "-iWidth" argument from ctfphaseflip from the IMOD package: The distance in pixels between the center lines of two consecutive strips. A pixel inside the region between those two center lines resides in both strips. As the two strips are corrected separately, that pixel will have 2 corrected values. The final value for that pixel is a linear interpolation of the 2 corrected values. If a value of 1 is entered, there is no such interpolation. For a value greater than one, the entered value will be used whenever the strip width computed from the defocus tolerance is less than 256 (i.e., at high tilt), and the value will be scaled proportional to the strip width for widths above 256. This scaling keeps the computational time down and is reasonable because the defocus difference between adjacent wide strips at wider intervals is still less than that between the narrower strips at high tilt. However, strips at constant spacing can still be obtained by entering the negative of the desired spacing, which disables the scaling of the spacing |          |
| ampContrast                       | 0.1                  | this variable sets the "-ampContrast" argument from ctfphaseflip from the IMOD package: The fraction of amplitude contrast. For Cryo-EM, it should be between 0.07 and 0.14. The value should be the same as was used when detecting the defocus.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          |
| defocus_file_version              | 3                    | this variable choses the version of the defocus file to be generated                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |          |
| defocus_file_version_3\_flag      | 1                    | this variable holds the flag which should be insert into the headerof the 3rd version of the defocus file when it is chosen to be generated                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |          |
| use_rawtlt                        | true                 | this flag controls if the rawtlt or tlt file should be chosen for reconstruction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |          |
| skip                              | false                | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |          |
| citation                          | ""                   | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| citation_link                     | ""                   | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| doi                               | ""                   | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |

</details>

</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "GCTFCtfphaseflipCTFCorrection": {
        "execution_method": "parallel",
        "defocus_limit_factor": 2,
        "slice_suffix": "view",
        "slice_folder": "slices",
        "gctf_correction_log_file": "gctf.log",
        "ctf_correction_log_file": "ctf_correction.log",
        "exact_filter_suffix": "ef",
        "tomogram_suffix": "full",
        "rotated_tomogram_suffix": "rotx",
        "generate_exact_filtered_tomograms": true,
        "exact_filter_size": 1500,
        "reconstruction_thickness": 2000,
        "use_aligned_stack": false,
        "do_phase_flip": false,
        "run_ctf_phase_flip": false,
        "reconstruct_tomograms": false,
        "defocus_tolerance": 20,
        "iWidth": 2,
        "ampContrast": 0.1,
        "defocus_file_version": 3,
        "defocus_file_version_3_flag": 1,
        "use_rawtlt": true,
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```
</details>

### BinStacks
**Description**
</br>
The BinStacks module is used to bin tilt series stacks to be able to reconstruct them with the Reconstruct module. Stacks with selected binning levels will be produced.

**Dependencies**
</br>
- IMOD

**Parameters**
</br>

| Key                             | Default Value | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Examples |
|---------------------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method                | "parallel"    | this variable defines the execution method for the module, if set to "parallel" out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| use_ctf_corrected_aligned_stack | true          | this flag controls if ctf corrected aligned stacks or raw stacks should be used for tomogram reconstruction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |          |
| antialias_filter                | 6             | type of antialiasing filter to use when shrinking images, the available types of filters are: 1: Box - equivalent to binning, 2: Blackman - fast but not as good at antialiasing as slower filters, 3: Triangle - fast but smooths more than Blackman, 4: Mitchell - good at antialiasing smooths a bit, 5: Lanczos 2 lobes - good at antialiasing less smoothing than Mitchell, 6: Lanczos 3 lobes - slower, even less smoothing but more risk of ringing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| defocus_tolerance               | 20            | this variable sets the "-defTol" argument from ctfphaseflip from the IMOD package: Defocus tolerance in nanometers, which is one factor that governs the width of the strips. The actual strip width is based on the width of this region and several other factors: a fixed minimum width of 128, a minimum width required to achieve sufficient resolution in the Fourier transform, governed by the the 0zero option, and the dynamic adjustment of maximum width described above.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |          |
| iWidth                          | 2             | this variable sets the "-iWidth" argument from ctfphaseflip from the IMOD package: The distance in pixels between the center lines of two consecutive strips. A pixel inside the region between those two center lines resides in both strips. As the two strips are corrected separately, that pixel will have 2 corrected values. The final value for that pixel is a linear interpolation of the 2 corrected values. If a value of 1 is entered, there is no such interpolation. For a value greater than one, the entered value will be used whenever the strip width computed from the defocus tolerance is less than 256 (i.e., at high tilt), and the value will be scaled proportional to the strip width for widths above 256. This scaling keeps the computational time down and is reasonable because the defocus difference between adjacent wide strips at wider intervals is still less than that between the narrower strips at high tilt. However, strips at constant spacing can still be obtained by entering the negative of the desired spacing, which disables the scaling of the spacing |          |
| ampContrast                     | 0.1           | this variable sets the "-ampContrast" argument from ctfphaseflip from the IMOD package: The fraction of amplitude contrast. For Cryo-EM, it should be between 0.07 and 0.14. The value should be the same as was used when detecting the defocus.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          |
| run_ctf_phaseflip               | false         | this flag controls if phase flipping should be done by external application ctfphaseflip from IMOD package                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| ctf_corrected_stack_suffix      | "ctfc"        | this variable holds the suffix to be appended to the name of ctf corrceted stacks                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |          |
| skip                            | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |          |
| citation                        | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| citation_link                   | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| doi                             | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |          |

```json
    "BinStacks":{
        "execution_method": "parallel",
        "use_ctf_corrected_aligned_stack": true,
        "use_aligned_stack": false,
        "antialias_filter": 6,
        "defocus_tolerance": 20,
        "iWidth": 2,
        "ampContrast": 0.1,
        "run_ctf_phaseflip": false,
        "ctf_corrected_stack_suffix": "ctfc",
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```

### Reconstruct

**Description**
</br>

The Reconstruct module is used for tomogram reconstruction from aligned tilt stacks. The module is set up by default to reconstruct CTF-corrected binned stacks. If you otherwise want to reconstruct unbinned stacks or non-CTF-corrected stacks (for example, for further 3D CTF-deconvolution by IsoNet) you need to set up the Reconstruct module properly.

**Dependencies**
</br>
- IMOD

**Parameters**
</br>

| Key                               | Default Value | Description                                                                                                                                                                                                                                                                                                                                | Examples |
|-----------------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method                  | "parallel"    | this variable defines the execution method for the module, if set to "parallel" out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops |          |
| use_ctf_corrected_stack           | true          | this flag controls if ctf corrected aligned stacks or just aligned stacks should be used for tomogram reconstruction                                                                                                                                                                                                                       |          |
| generate_exact_filtered_tomograms | false         | this flag controls if exact filtered tomograms should be generated                                                                                                                                                                                                                                                                         |          |
| exact_filter_size                 | 1500          | this variable holds the filter size of the exact filter                                                                                                                                                                                                                                                                                    |          |
| use_rawtlt                        | true          | this flag controls if the rawtlt file should be used instead of a possibly by batchruntomo modified tlt file                                                                                                                                                                                                                               |          |
| correct_angles                    | "center"      | the method to be applied to correct the angles if rawtlt is not used, this means if **use_rawtlt** is set to false                                                                                                                                                                                                                         |          |
| skip                              | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                              |          |
| citation                          | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |
| citation_link                     | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |
| doi                               | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |

```json
    "Reconstruct": {
        "execution_method": "in_order",
        "use_ctf_corrected_stack": true,
        "generate_exact_filtered_tomograms": false,
        "exact_filter_size": 1500,
        "generate_nad_filtered_tomograms": false,
        "nad_filter_output_iterations_list": [3],
        "nad_filter_number_of_iterations": -1,
        "nad_filter_sigma_for_smoothing": -1,
        "nad_filter_threshold_for_gradients": -1,
        "use_rawtlt": true,
        "correct_angles": "center",
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```

### IsoNet

**Description**
</br>
The IsoNet module provides functionality of the deep learning framework IsoNet used for reconstruction of the missing wedge (MW) region in tomograms. Besides, IsoNet provides an interface for denoising and 3D CTF-deconvolution. TomoBEAR interface includes such IsoNet routines as pre-processing (STAR file preparation, mask creation, CTF-deconvolution), training (refinement) and prediction.

**Dependencies**
</br>
- Anaconda
- IsoNet (and its Python dependencies)
- CUDA

</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
  "IsoNet": {
        "execution_method": "once",
        "isonet_env": "",
        "repository_path": "",
        "tomograms_to_use": [],
        "steps_to_execute": {},
        "steps_to_execute_defaults": {
            "prepare_star": {
                "use_ctf_corrected_tomograms": false,
                "add_defocus_to_star": true,
                "tomograms_binning": -1,
                "folder_name": "tomograms",
                "output_star": "tomograms.star",
                "number_subtomos": -1
            },
            "deconv": {
                "star_file": "tomograms.star",
                "deconv_folder": "deconv",
                "snrfalloff": 0.7,
                "deconvstrength": -1,
                "highpassnyquist": -1,
                "chunk_size": -1,
                "overlap_rate": -1,
                "ncpu": -1
            },
            "make_mask": {
                "star_file": "tomograms.star",
                "mask_folder": "mask",
                "patch_size": -1,
                "mask_boundary": "",
                "density_percentage": 50,
                "std_percentage": 50,
                "z_crop": -1,
                "use_deconv_tomo": true
            },
            "extract": {
                "star_file": "tomograms.star",
                "subtomo_folder": "subtomo",
                "subtomo_star": "subtomo.star",
                "cube_size": -1,
                "crop_size": -1,
                "use_deconv_tomo": true
            },
            "refine": {
                "subtomo_star": "subtomo.star",
                "iterations": 30,
                "data_dir": "",
                "pretrained_model": "",
                "result_dir": "results",
                "preprocessing_ncpus": -1,
                "continue_from": "",
                "epochs": -1,
                "batch_size": -1,
                "steps_per_epoch": -1,
                "noise_level": [0.05,0.1,0.15,0.2],
                "noise_start_iter": [10,15,20,25],
                "noise_mode": "",
                "noise_dir": "",
                "learning_rate": -1,
                "drop_out": -1,
                "convs_per_depth": -1,
                "kernel": [],
                "unet_depth": -1,
                "filter_base": -1,
                "batch_normalization": -1,
                "normalize_percentile": -1
            },
            "predict": {
                "star_file": "tomograms.star",
                "model": "results/model_iter30.h5",
                "output_dir": "corrected_tomos",
                "cube_size": -1,
                "crop_size": -1,
                "batch_size": -1,
                "normalize_percentile": -1
            }
        }
    }
```
</details>


## Particles picking-associated modules

### DynamoImportTomograms

**Description**
</br>
The DynamoImportTomograms module generates a Dynamo Catalogue for user
and inputs the tomograms to that catalog. After that you can call the
Dynamo Catalogue Manager (dcm) to generate the models for the tomograms
or pick particles in them using the functionality of Dynamo Catalogue.

**Dependencies**
</br>
- Dynamo

**Parameters**
</br>

| Key              | Default Value | Description                                                                                                                                                                                                                                                                                                                                | Examples |
|------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| execution_method | "parallel"    | this variable defines the execution method for the module, if set to "parallel" out of memory errors can occur if you don't have enough memory, **note** for this module it needs to be left as is, except for debugging reasons you need to set it to "sequential" because MATLAB does only allow debugging of code in non parallel loops |          |
| import_tomograms | "both"        | this variable controls if binned and/or unbinned tomograms are imported into a catalogue, other options are "binned" and "unbinned"                                                                                                                                                                                                        |          |
| skip             | false         | this flag if the execution of this processing step should be skipped at all, **note** normally you should not touch this if you don't know what you are doing                                                                                                                                                                              |          |
| citation         | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |
| citation_link    | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |
| doi              | ""            | this variable holds the information for automatically generating the citations, **note** functionality is not fully implemented and tested                                                                                                                                                                                                 |          |

```json
    "DynamoImportTomograms": {
        "execution_method": "once",
        "import_tomograms": "both",
        "skip": false,
        "citation": "",
        "citation_link": "",
        "doi": ""
    }
```

### EMDTemplateGeneration

**Description**
</br>
The EMDTemplateGeneration module is used to automatically download a
EMDB template which is further down-scaled to match the requested template
matching binning level. Besides that an automated routine to generate the mask is also implemented. Either this module or the module TemplateGenerationFromFile needs to be run before template matching is executed by the DynamoTemplateMatching module.


**Dependencies**
</br>
- Dynamo

**Parameters**
</br>

```json
    "EMDTemplateGeneration": {
        "execution_method": "once",
        "template_emd_number": "",
        "mask_bandpass": [0, 2, 2],
        "template_bandpass_cut_on_fourier_pixel": 2,
        "template_bandpass_cut_off_resolution_in_angstrom": 20,
        "template_bandpass_smoothing_pixels": 3,
        "ratio_mask_pixels_based_on_unbinned_pixels": 0.05,
        "use_half_template_size": false,
        "mask_cut_off": 0.05,
        "template_cut_off": 0.75,
        "type": "dynamo",
        "use_bandpassed_template": true,
        "use_smoothed_mask": true,
        "dark_density": true,
        "skip": false,
        "citation": ""
    }
```

### TemplateGenerationFromFile

**Description**
</br>
The TemplateGenerationFromFile module imports a map into the TomoBEAR workflow given by a path and scales it properly if the map header contains the correct pixel size; else the pixel size can be input as a parameter through the JSON-based configuration file. Either this module or the module EMDTemplateGeneration needs to be run before template matching is executed by the DynamoTemplateMatching module.


**Dependencies**
</br>
- Dynamo

**Parameters**
</br>

```json
    "TemplateGenerationFromFile": {
        "execution_method": "once",
        "template_path": "",
        "mask_path": "",
        "use_ellipsoid": true,
        "radii_ratio": [0.33, 0.33, 0.5],
        "ellipsoid_smoothing_ratio": 0.16,
        "mask_bandpass": [0, 2, 2],
        "template_bandpass_cut_on_fourier_pixel": 2,
        "template_bandpass_cut_off_resolution_in_angstrom": 20,
        "template_bandpass_smoothing_pixels": 3,
        "use_bandpassed_template": true,
        "use_smoothed_mask": true,
        "invert_density": true,
        "skip": false,
        "citation": ""
    }
```

### DynamoTemplateMatching

**Description**
</br>
The DynamoTemplateMatching module re-implements the template
matching functionality from the Dynamo package, but distributes calculations on the GPU. The GPU-distributed version executes up to 12-15 times faster than the conventional CPU-distributed template matching
implementation available in Dynamo. In some multi-GPU systems the speed-up may be even non-linear relative to the number of GPUs used.

**Dependencies**
</br>
- Dynamo

**Parameters**
</br>

<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "DynamoTemplateMatching": {
        "execution_method": "in_order",
        "use_ctf_corrected_tomograms": true,
        "show_table": false,
        "show_cross_correlations": false,
        "show_generated_template": false,
        "randomize_angles": false,
        "size_of_chunk": [512, 720, 500],
        "auto_detect_sampling": false,
        "auto_detect_sampling_multiplication_factor": 5,
        "cone_range": 360,
        "cone_sampling": 15,
        "matlab_workers": 1,
        "symmetry_opearator": 19,
        "template_transform": "none",
        "in_plane_range": 360,
        "in_plane_sampling": 7.5,
        "sampling": 0,
        "threshold_standard_deviation": 3,
        "ellipsoid_smoothing_pixels": 5,
        "skip": false,
        "citation": ""
    }
```
</details>

### TemplateMatchingPostProcessing
**Description**
</br>
The TemplateMatchingPostProcessing module takes the cross-correlation volumes generated by the DynamoTemplateMatching module and extracts the coordinates from the peaks found in them until a given threshold is reached. This threshold is set by default to a value of 2.5 standard deviations. As well this module could extract the corresponding subtomograms by cropping them from the reconstructed tomograms using Dynamo or reconstruct them directly from the aligned stacks using SUSAN.

**Dependencies**
</br>
- Dynamo
- SUSAN (if you chose it as the particles generation method)

**Parameters**
</br>

<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "TemplateMatchingPostProcessing": {
        "execution_method": "once",
        "parallel_execution": false,
        "checkpoint_module": true,
        "all_in_one_folder": true,
        "particle_count": 0,
        "cc_std": 3,
        "crop_particles": false,
        "bandpass_cc_volume": false,
        "bandpass_cc_high_pass": 0,
        "bandpass_cc_low_pass": 0,
        "bandpass_cc_smoothing": 0,
        "keep_binned": true,
        "keep_unbinned": true,
        "mask_gaussian_fall_off": false,
        "precision": 4,
        "cross_correlation_mask": false,
        "remove_large_correlation_clusters": false,
        "use_mask_for_cluster_removal": false,
        "cluster_std":2,
        "mask_non_zero_voxels_ratio": 1.5,
        "non_zero_voxels_threshold": 0.05,
        "exclusion_radius_box_size_ratio": 0.5,
        "box_size": 1,
        "keep_binned": false,
        "keep_unbinned": true,
        "use_denoised_tomograms": false,
        "use_SUSAN": false,
        "ctf_correction_method": "defocus_file",
        "susan_padding": 200,
        "per_particle_ctf_correction": "phase_flip",
        "padding_policy": "zero",
        "normalization": "zm",
        "skip": false,
        "citation": ""
    }
```
</details>

### crYOLO

**Description**
</br>
The crYOLO module provides functionality of the deep learning framework crYOLO used for particle coordinate prediction. TomoBEAR interface includes such crYOLO routines as pre-processing (configuration file preparation, filtering), training and prediction. To optimize parameters of the training and prediction please use the corresponding crYOLO documentation (https://cryolo.readthedocs.io/en/stable/index.html).

**Dependencies**
</br>
- Anaconda
- crYOLO (and its Python dependencies)
- CUDA

</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "crYOLO": {
        "execution_method": "once",
        "cryolo_env": "",
        "tomograms_to_use": [],
        "steps_to_execute": {},
        "steps_to_execute_defaults": {
            "config": {
                "cryolo_command": "cryolo_gui.py config",
                "target_boxsize": 220,
                "config_json_filepath": "config_cryolo.json",
                "filter": "LOWPASS",
                "low_pass_cutoff": 0.1,
                "janni_model_path": "",
                "train_mode": false,
                "train_tomograms_folder": "train_tomograms",
                "train_tomograms_path": "",
                "tomograms_binning": -1,
                "train_annot_folder": "train_annot",
                "input_size": -1
            },
            "train": {
                "cryolo_command": "cryolo_train.py",
                "config_json_filepath": "config_cryolo.json",
                "num_cpu": -1,
                "early": 15,
                "warmup": 5
            },
            "predict": {
                "cryolo_command": "cryolo_predict.py",
                "config_json_filepath": "config_cryolo.json",
                "trained_model_filepath": "cryolo_model.h5",
                "threshold": 0.1,
                "test_tomograms_folder": "test_tomograms",
                "test_tomograms_path": "",
                "tomograms_binning": -1,
                "predict_annot_folder": "predict_annot",
                "num_cpu": -1,
                "tracing_search_range": -1,
                "tracing_memory": -1,
                "tracing_min_length": -1
            },
            "export_annotations": {
                "raw_prtcl_coords_dir": "predict_annot/COORDS",
                "per_table_particle_count": -1,
                "total_particle_count": -1
            }
        }
    }
```
</details>

### GenerateParticles
**Description**
</br>
The GenerateParticles module uses Dynamo-like particles tables to extract particles in one of the following ways:
* crop sub-tomograms from the reconstructed tomograms using Dynamo;
* reconstruct sub-tomograms from sub-stacks cropped directly from aligned tilt stacks using SUSAN.

**Dependencies**
</br>
- Dynamo
- SUSAN (if you chose it as the particles generation method)

**Parameters**
</br>

<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
  "GenerateParticles": {
     "execution_method": "once",
     "generate_particles_method": "",
     "particles_table_path": "",
     "box_size": 1.0,
     "particles_binning": -1,
     "use_SUSAN": false,
     "ctf_correction_method": "defocus_file",
     "susan_padding": 200,
     "per_particle_ctf_correction": "phase_flip",
     "padding_policy": "zero",
     "normalization": "zm"
   }
```
</details>

## Subtomogram Averaging modules

### DynamoAlignmentProject

**Description**
</br>
The DynamoAlignmentProject module can be set up to generate the two common Dynamo subtomogram averaging projects: multiple reference alignment (MRA) project and an independent half-set based refinement project. For classification we find it useful to have one or two classes with the correct reference that was used e.g. for template matching and some classes containing only noise (“noise traps”) which will attract suboptimal particles into classes for removal.

**Dependencies**
</br>
- Dynamo
- SUSAN (if you chose it as the classification method)

**Parameters**
</br>
<details>
<summary> Default parameters values <i> (click to expand) </i> </summary>

```json
    "DynamoAlignmentProject": {
        "randomize_angles": false,
        "bf": 4,
        "split_by_y": true,
        "atand_factor": 2,
        "use_SUSAN": false,
        "cone_flip": 0,
        "checkpoint_module": true,
        "noise": 1,
        "noise_scaling_factor": 0.7,
        "use_noise_classes": true,
        "susan_lowpass": 65,
        "dynamo_lowpass_factor": 0.5,
        "threshold_mode": 5,
        "threshold": 0.5,
        "area_search_mode": 1,
        "susan_padding": 200,
        "per_particle_ctf_correction": "phase_flip",
        "ssnr": [],
        "padding_policy": "zero",
        "normalization": "zm",
        "use_symmetrie": true,
        "execution_method": "once",
        "reference": "average",
        "iterations": 0,
        "swap_particles": true,
        "refine_factor": 2,
        "show_results": false,
        "last_classification_binning":4,
        "projects_per_binning": 2,
        "alignment_method": "mra",
        "parallel_execution": true,
        "use_elliptic_mask": true,
        "radii_ratio": [0.5, 0.5, 0.5],
        "ellipsoid_smoothing_ratio": 0.16,
        "shift_limit_factor": 0.1,
        "discretization_bias": 0.33,
        "project_name": "mraProject",
        "destination": "matlab_gpu",
        "classes": 0,
        "selected_classes": [],
        "sampling": 0,
        "ite_r1": 0,
        "nref_r1": 0,
        "cone_range_r1": 0,
        "cone_sampling_r1": 0,
        "cone_flip_r1": 0,
        "cone_check_peak_r1": 0,
        "cone_freeze_reference_r1": 0,
        "inplane_range_r1": 0,
        "inplane_sampling_r1": 0,
        "inplane_flip_r1": 0,
        "inplane_check_peak_r1": 0,
        "inplane_freeze_reference_r1": 0,
        "refine_r1": 0,
        "refine_factor_r1": 0,
        "high_r1": 0,
        "low_r1": 0,
        "sym_r1": 0,
        "dim_r1": 0,
        "area_search_r1": 0,
        "area_search_modus_r1": 0,
        "separation_in_tomogram_r1": 0,
        "limit_xy_check_peak_r1": 0,
        "limit_z_check_peak_r1": 0,
        "use_CC_r1": 0,
        "localnc_r1": 0,
        "mra_r1": 0,
        "threshold_r1": 0,
        "threshold_modus_r1": 0,
        "threshold2_r1": 0,
        "threshold2_modus_r1": 0,
        "ccmatrix_r1": 0,
        "ccmatrix_type_r1": 0,
        "ccmatrix_batch_r1": 0,
        "Xmatrix_r1": 0,
        "Xmatrix_maxMb_r1": 0,
        "PCA_r1": 0,
        "PCA_neigs_r1": 0,
        "kmeans_r1": "",
        "kmeans_ncluster_r1": 0,
        "kmeans_ncoefficients_r1": 0,
        "nclass_r1": 0,
        "plugin_align_r1": 0,
        "plugin_post_r1": 0,
        "plugin_iter_r1": 0,
        "plugin_align_order_r1": 0,
        "plugin_post_order_r1": 0,
        "plugin_iter_order_r1": 0,
        "flags_r1": 0,
        "convergence_type_r1": 0,
        "convergence_r1": 0,
        "rings_r1": 0,
        "rings_random_r1": 0,
        "dynamic_mask_r1": 0,
        "mask_path": "",
        "mask_apix": 1,
        "SUSAN_defocus_min": 10000,
        "SUSAN_defocus_max": 50000,
        "SUSAN_ctf_box_size":400,
        "SUSAN_binning": 0,
        "ctf_correction_method": "defocus_file",
        "bandpass_method": "angles",
        "exclude_projections": 0,
        "citation": ""
    }
```
</details>
