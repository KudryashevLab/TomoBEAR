# Welcome to the TomoBEAR wiki!

![TomoBEAR Social Media Logo Image](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/TomoBEAR_gitlogo.png)

<u>**B**</u>asics for cryo-<u>**E**</u>lectron <u>**tomo**</u>graphy and <u>**A**</u>utomated <u>**R**</u>econstruction (**TomoBEAR**) is a configurable and customizable open-source MATLAB software package developed for automated large-scale parallelized cryo-electron tomography (cryo-ET) data processing.

> **Note**
> <br/> Implementation details and benchmarks you can find in our preprint:
</br> Balyschew N, Yushkevich A, Mikirtumov V, Sanchez RM, Sprink T, Kudryashev M. Streamlined Structure Determination by Cryo-Electron Tomography and Subtomogram Averaging using TomoBEAR. **[Preprint]** 2023. bioRxiv doi: [10.1101/2023.01.10.523437](https://www.biorxiv.org/content/10.1101/2023.01.10.523437v1)

## Wiki contents

- [General description of the pipeline](#general-description)
- [Installation and setup notes](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup)
- [Tutorials on TomoBEAR setup and usage](https://github.com/KudryashevLab/TomoBEAR/wiki/Tutorials)
- [Available modules description, their parameters and default values](https://github.com/KudryashevLab/TomoBEAR/wiki/Modules)
- [Usage cases and tips](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage)
- [Troubleshooting tips](https://github.com/KudryashevLab/TomoBEAR/wiki/Troubleshooting)
- [External software (installation, configuration, citation)](https://github.com/KudryashevLab/TomoBEAR/wiki/External-Software)

## Gerenal description

**TomoBEAR** can assist you in large-scale processing of the tomographic data acquired on the electron microscope starting from the raw tilt series, possibly dose fractionated, or already assembled tilt stacks up to sample volume 3D reconstruction and even to biological structure of interest. More on input formats you [can read here](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage.md#input-data-file-formats).

**TomoBEAR** is designed to operate in automated manner minimizing user intervention where that is possible. The pipeline consists of modules, which wrap popular cryo-ET tools (such as IMOD, Dynamo, MotionCor2, GCTF/CTFFIN4, etc.) as well as developed in our laboratory StA framework called [SUSAN](https://github.com/rkms86/SUSAN).

Since number of **TomoBEAR** parameters is huge, to help users cope with that we have carefully designed a predefined set of defaults which were chosen based on several different cryo-ET datasets. Description of all modules and corresponding default values is given on the [Modules page](https://github.com/KudryashevLab/TomoBEAR/wiki/Modules).

> **Note**
> <br/> `TomoBEAR` supports workstations and single interactive nodes with GPUs on the comuting clusters at the moment. We are also working towards enabling the support of computer clusters through a queue manager like SLURM or SGE (Sun Grid Engine).

<details><summary><b>List of reasons to use TomoBEAR</b></summary>
<p>

* Standalone and MATLAB versions
* Sequential and parallel execution with CPU- and GPU-enabled parallelization
* Standardized files and folders structure
* Can deal with
  * misnumbered tilt images due to SerialEM crashes, based on timestamps
  * different naming conventions
  * EERs, MRCs and TIFs from K2, K3, Falcon4
  * duplicated projections due to tracking issues (first, last, keep)
* Restarting / resuming is possible (e.g. in case of errors, wrong configuration)
  * Checkpoints are created at the every processing step for the whole step and per tomogram
* Based on JSON configuration files (for sharing and reproducibility)
* Carefully designed preset of default parameter values
* Developed and tested on set of benchmarking datasets (EMPIAR-10064, EMPIAR-10452, EMPIAR-11543, EMPIAR-11306)
* Integration with IMOD and Dynamo projects
* Clean up functionality to save storage
* Tomograms to be processed can be limited to a subset
* Uses Dynamo tilt-series alignment but injects the fiducial positions to IMOD for projection estimation
* Routines for particles picking: template matching (modified Dynamo) or neural network based picking (crYOLO)
* Improved Dynamo template matching functionality
  * 10x speedup leveraging the GPU compared to 28 CPUs achieving 18x speedup
  * Sub-stacks analysis (SUSAN) framework is integrated
* Particles extraction using Dynamo-based subtomogram cropping or SUSAN-based subtomogram reconstruction
* DynamoAlignmentProject
  * Generation of initial templates with with true structures and "noise traps"
  * Classification by multi-reference alignment (MRA)
* Automated exclusion of bad tilts in reconstructions based on refined fiducial file from BatchRunTomo module

</p>
</details>

## Pipeline structure
In the following picture you can see a flow chart which visualizes pipeline steps which `TomoBEAR` can execute in an automated and parallel manner.

![Schematic Pipeline Image](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/pipeline_light_mode.svg)

Orange processing steps in the flow chart are mandatory and must be executed by TomoBEAR. Yellow boxes are optional and can be activated if desired.
