# Welcome to the TomoBEAR wiki!

![TomoBEAR Social Media Logo Image](/images/TomoBEAR_gitlogo.png)

<u>**B**</u>asics for cryo-<u>**E**</u>lectron <u>**tomo**</u>graphy and <u>**A**</u>utomated <u>**R**</u>econstruction (**TomoBEAR**) is a configurable and customizable open-source MATLAB software package developed for automated large-scale parallelized cryo-electron tomography (cryo-ET) data processing.

> **Note**
> <br/> Implementation details and benchmarks you can find in our preprint:
</br> Balyschew N, Yushkevich A, Mikirtumov V, Sanchez RM, Sprink T, Kudryashev M. Streamlined Structure Determination by Cryo-Electron Tomography and Subtomogram Averaging using TomoBEAR. **[Preprint]** 2023. bioRxiv doi: [10.1101/2023.01.10.523437](https://www.biorxiv.org/content/10.1101/2023.01.10.523437v1)

## Contents

- [General description of the pipeline](#general-description) 
- [Installation and setup notes](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup)
- [Frequently Asked Questions](https://github.com/KudryashevLab/TomoBEAR/wiki/Frequently-Asked-Questions)
- [Tutorials on TomoBEAR setup and usage](https://github.com/KudryashevLab/TomoBEAR/wiki/Tutorials)
- [Available modules description, their parameters and default values](https://github.com/KudryashevLab/TomoBEAR/wiki/Modules)
- [Usage cases and tips](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage)


## Gerenal description

**TomoBEAR** can assist you in large-scale processing of the tomographic data acquired on the electron microscope starting from the raw tilt series, possibly dose fractionated, or already assembled tilt stacks up to sample volume 3D reconstruction and even to biological structure of interest. More on input formats you [can read here](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage.md#input-data-file-formats).

**TomoBEAR** is designed to operate in automated manner minimizing user intervention where that is possible. The pipeline wraps popular cryo-ET tools (such as IMOD, Dynamo, MotionCor2, GCTF/CTFFIN4, etc.). Since number of TomoBEAR parameters is huge,to help users cope with that we have carefully designed a predefined set of defaults which were chosen based on several different cryo-ET datasets.

> **Note**
> <br/> `TomoBEAR` supports workstations and single interactive nodes with GPUs on the comuting clusters at the moment. We are also working towards enabling the support of computer clusters through a queue manager like SLURM or SGE (Sun Grid Engine).

<details><summary><b>List of reasons to use TomoBEAR</b></summary>
<p>

* Uses default presets which work on a variety of tested datasets
* Standalone and MATLAB versions are available
* Parallel execution is possible
* Computing resources are configurable
* Standardized folder structure
* Can deal with
  * misnumbered tilt images due to SerialEM crashes, based on timestamps
  * different naming conventions
  * EERs, MRCs and TIFs from K2, K3, Falcon4
  * duplicated projections due to tracking issues (first, last, keep)
* Restarting / resuming is possible (e.g. in case of errors, wrong configuration)
  * Checkpoints are created after every processing step of a tilt series or tomogram
* Based on JSON configuration files which can be easily shared between others so that they can validate or improve your results
* Developed and tested on standard benchmarking datasets (such as EMPIAR-10064) to achieve same or better results as with manual processing
* You are able to look at the intermediates optimize parameters and rerun the steps to achieve optimal results
* You are never locked to the TomoBEAR processing pipeline and can easily breakout at various steps to other software tools you prefer
* Uses links where possible
* Clean up functionality to save storage
* Tomograms to be processed can be limited to a subset
* Uses Dynamo tilt-series alignment but injects the fiducial positions to IMOD for projection estimation
* Alignment parameters for tilt series can be (optionally) manually refined
* Routines for particle identification: template matching or geometry-assisted particle picking (with Dynamo)
* Improved Dynamo template matching functionality
  * 10x - 14x speedup leveraging the GPU compared to 28 CPUs achieving 18x speedup
* Sub-stacking analysis (by SUSAN) is integrated (work in progress)
* TemplateMatchingPostprocessing
  * Extraction of particles and conversion to dboxes to speed up file system access speed
* DynamoAlignmentProject
  * Classification by multi-reference alignment (MRA)
    * Generation of initial templates with with true structures and "noise traps"
  * Extraction of particles with SUSAN and conversion to dboxes now possible
  * Forcing of using SUSAN is also possible
    * BinStacks module with appropriate binning levels should be run upfront
  * Modification of particles box size is possible, as input can be used a factor, the absolute box size can be used as input
* Introduced presorting for single numbered tilt series data (as in Wenbo’s case of published Ryanodine receptor data)
* Automated exclusion of bad tilts in reconstructions based on refined fiducial file from BatchRunTomo module

</p>
</details>

## Pipeline structure
In the following picture you can see a flow chart which visualizes pipeline steps which `TomoBEAR` can execute in an automated and parallel manner. 

![Schematic Pipeline Image](/images/pipeline_light_mode.svg)

Orange processing steps in the flow chart are mandatory and must be executed by TomoBEAR. Yellow boxes are optional and can be activated if desired.
