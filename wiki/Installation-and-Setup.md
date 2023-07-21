# Installation and setup

> **Note**
> <br/> If you experience problems with TomoBEAR installation, do not hestitate to communicate with us by one of mentioned ways in [Feedback and Contribution](https://github.com/KudryashevLab/TomoBEAR#feedback-and-contribution) section.

## Contents

- [Prerequisites](#prerequisities)
- [Setup process overview](#setup-overview)
- [Video-tutorial link](#video-tutorial)
- [Step-by-step instructions](#detailed-instructions)

## Prerequisites

### Hardware

1. **Graphics Processing Unit (GPU)**: at least one GPU with a minimum of 8GB of Video Random Access Memory (VRAM)

It is better to have more GPUs with possibly greater amount of VRAM. With more GPUs you can process more data units in parallel. With more VRAM you can fit bigger tilt stacks or tomograms in memory especially in template matching.

2. **Random Access Memory (RAM)**: at least 16GB of RAM

The more RAM you have the better. With more RAM you can run more parallel processes to process to process your data faster. This depends on the execution method of the modules.

3. **Hard Disk Drive (HDD) / Solid State Disk (SSD)**: depends on size of the data being processed

You need enough storage to store your data and all the intermediate data and results. Although it is possible to clean up the intermediate data during processing you will still need temporarily enough storage to store it until it can be deleted. The amount of needed storage is larger when you have more processes running in parallel.

### Operating system

The TomoBEAR was tested under the following Operating Systems (OS): **CentOS 7** / **Ubuntu 21.04**.

In general, any Linux-based OS's are suitable as long as MATLAB, CUDA and all the other needed for your processing external tools are installable and executable.

### Middleware and software

#### MATLAB

The TomoBEAR was tested under the following MATLAB releases: **MATLAB R2021a**.

There are two ways to operate TomoBEAR:

* **(main) use it directly from MATLAB interactive session** - *currently it is better supported option*

In this case you need to install the full version of MATLAB and obtain the required MATLAB license. Afterwards, the corresponding MATLAB executable should be added to your system's `PATH` variable.

If you don't have administrator rights on your system, ask responsible person (laboratory technician or cluster/workstation administrator) to install it (recommended), otherwise you may try the next (in dev.) approach.

* **(in dev.) use the standalone executable** provided along with some of the [source code releases](https://github.com/KudryashevLab/TomoBEAR/releases)

If you would like to try TomoBEAR standalone version or don't have MATLAB license, you will need to use the **MATLAB Compiled Runtime (MRC)** libraries to be able to run compiled MATLAB binary. To configure it use the following instructions:

1. In order to run TomoBEAR on the tested setup you need to get the newest available version of **MCR 2021a** [available here](https://www.mathworks.com/products/compiler/matlab-runtime.html). For example, you may get it directly to the selected folder using `wget` as the following:

  `wget https://ssd.mathworks.com/supportfiles/downloads/R2021a/Release/8/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021a_Update_8_glnxa64.zip`

2. Further you need to give execution rights to the downloaded file using `chmod`. For that change to the folder where the file was downloaded to and execute the following command:

  `chmod u+x MATLAB_Runtime_R2021a_Update_8_glnxa64.zip`

3. As the next step you need to extract the archive either with a command or through your file explorer, for example:

  `unzip MATLAB_Runtime_R2021a_Update_8_glnxa64.zip`

4. Afterwards, you need change to the directory where the files were extracted, run the installation file and follow the installation wizard using GUI displayed on screen via

  `./install`

5. Finally, when the installation is finished, remember to include the following paths of the installed MCR libraries to the environmental variable `LD_LIBRARY_PATH`:

  ```bash
  /usr/local/MATLAB/MATLAB_Runtime/v910/runtime/glnxa64
  /usr/local/MATLAB/MATLAB_Runtime/v910/bin/glnxa64
  /usr/local/MATLAB/MATLAB_Runtime/v910/sys/os/glnxa64
  /usr/local/MATLAB/MATLAB_Runtime/v910/extern/bin/glnxa64
  ```

#### CUDA

To benefit from GPU-enabled parallelization of some of the external software packages, the proper CUDA toolkits with the newest driver for your graphics card need to be installed. You need to get all the needed CUDA versions in your system installed to be able to run all the external tools which you need.

> **Tipp**
> </br> Sometimes software which depends on the newer CUDA libraries can handle versions compiled with older CUDA libraries. Currently we recommend to install/use the **CUDA-11.5** as the most suitable version which complies with at least one of the available executables for each external tool using CUDA.

To install CUDA you can use the package manager of your OS and install it manually or just use the module system of your facility/cluster/workstation if one is already employed.

Alternatively, you may install CUDA manually. The easiest way for the manual installation is to add the repositories with CUDA to your specific OS package manager, otherwise may you download and run the corresponding to your OS executable available from the [NVIDIA homepage](https://developer.nvidia.com/cuda-toolkit-archive).

The OS-specific tips:

- **CentOS 7**

The package manager is called `yum`.
A description of how to install a specific CUDA version for **CentOS 7** is [available here](https://linuxconfig.org/how-to-install-nvidia-cuda-toolkit-on-centos-7-linux). To get other CUDA versions you will need to replace the rpm `cuda-repo-rhel7-10.0.130-1.x86_64.rpm` with [other suitable rpm](https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/).

- **Ubuntu 21.04 (or any other version)**

To get the newest CUDA on an **Ubuntu** system the easiest way is to install it via graphical interface using *Software & Updates* (see tab *Additional Drivers*). Otherwise you may want to add CUDA repositories to the `apt` package manager.

## Setup overview

As it was mentioned above, there are two ways to operate TomoBEAR.

* (main) use it directly from MATLAB interactive session - *currently it is better supported option*
* (in dev.) use the standalone executable provided along with some of the [source code releases](https://github.com/KudryashevLab/TomoBEAR/releases)

For both methods of operation, to setup TomoBEAR you need to do the following:

  0. Check prepresiquities.
  1. Get TomoBEAR source code (along with binary if needed).
  2. Get, install and configure all the mandatory and optional (if needed) dependencies.
  3. Configure and initialize TomoBEAR instance.

Further on this page you may find the corresponding [video-tutorial](#video-tutorial) and [detailed step-wise instructions](#detailed-instructions).

## Video-tutorial

We have prepared a small video-tutorial explaining the most basic `TomoBEAR` setup, which is needed for our [80S ribosome data processing tutorial](https://github.com/KudryashevLab/TomoBEAR/wiki/Tutorials):
* [Video-tutorial](https://youtu.be/2uizkE616tE) explaining how to get the latest ```TomoBEAR``` version and configure ```TomoBEAR``` and its dependencies.

## Detailed instructions

### Step 0. Check prerequisites

Make sure that you comply with hardware and OS prerequisites, as well as that you have installed, accessible and executable middleware and software prerequisites before proceeding further. The corresponding instructions see in the [Prerequisites section](#prerequisites).

### Step 1. Get source code and binary

#### Clone the latest version

To get the latest ```TomoBEAR``` version you can simply clone *main* branch by:
```bash
 git clone https://github.com/KudryashevLab/TomoBEAR.git
```

#### Clone specific version

To get a specific version of the ```TomoBEAR``` you need to create the following ```install_TomoBEAR.sh``` installation bash script:

```bash
VER=${1}
INSTALL_DIR=$(readlink -f ./${2})
echo "Installing TomoBEAR-v"${VER} "in the directory " ${INSTALL_DIR}

echo "Fetching and unpacking source code from GitHub..."
mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}
wget https://github.com/KudryashevLab/TomoBEAR/archive/refs/tags/v${VER}.tar.gz
tar zxvf v${VER}.tar.gz
ln -s TomoBEAR-${VER} ${VER}
```

If binary was also applied to the release which you want to get, you need to add as well the following lines to the ```install_TomoBEAR.sh```:
```
echo "Fetching and activating binary..."
cd ${VER}
wget https://github.com/KudryashevLab/TomoBEAR/releases/download/v${VER}/TomoBEAR-${VER}
chmod +x TomoBEAR-${VER}
ln -s TomoBEAR-${VER} TomoBEAR
rm -f ../v${VER}.tar.gz
```
To use it, activate it by
```bash
chmod +x install_TomoBEAR.sh
```
and execute as the following
```bash
./install_TomoBEAR.sh X.Y.Z /path/to/dir
```
where ```X.Y.Z``` is the version of the release (e.g., 0.3.0) and ```/path/to/dir``` is the path to the folder where to put the TomoBEAR source code.

The list of available releases can be found on the [Releases page](https://github.com/KudryashevLab/TomoBEAR/releases).

> **Note**
> </br> We are grateful to Wolfgang Lugmayr (CSSB, Hamburg) for the installation script idea.

### Step 2. Install and setup external software

As TomoBEAR is wrapping standardized tools to fulfill some of the processing steps these need to be installed, executable and properly initialized in TomoBEAR.

You have to install essential TomoBEAR dependencies: **Dynamo** and **IMOD**. As well, you may additionally install optional external tools which you plan to use in TomoBEAR (**MotionCor2**, **GCTF**, etc.).

Generally, you have two installation/configuration options:

1. Easier possibility for less experienced users: ask responsible for your cluster/workstation maintenance person to install the needed software and introduce that as modules.

2. Faster possibility for more experienced users: install the needed software on your own (use ```/home/username``` folder if you don't have root permissions) and configure it according to the corresponding instructions.

It is recommended to add the paths to the executables of the downloaded software in your `PATH` variable of your Linux system, except for **Dynamo** which must not be in the `PATH`.

> **Warning**
> </br>
Since we have introduced a number of modifications to the original `Dynamo` code, which are distributed along with the `TomoBEAR`, you should not have original `Dynamo` codebase folder on your `PATH`, otherwise it will lead to the errors appearing during `Dynamo`-dependent modules execution.

The corresponding software versions, download links, installation notes and citation references you may find on the page [[ External software | https://github.com/KudryashevLab/TomoBEAR/wiki/External-Software ]].

### Step 3. Configure TomoBEAR defaults

In this section you will configure TomoBEAR with the corresponding paths to the external tools available either as executables or via module system.

Further you need to adjust the paths to the executables in the
`configurations/defaults.json` file. The keys where the values need to be adjusted can be found in the section `general` of the `defaults.json` file and are the following ones:
* mandatory:
  - `"pipeline_location": ""` - location of the cloned TomoBEAR source code
  - `"dynamo_path": ""` - path to your Dynamo folder
* semi-mandatory (motion/CTF-correction), when available as executables:
  - `"motion_correction_command": ""` - executable name of MotionCor2 or the full executable filepath
  - `"ctf_correction_command": ""` - executable name of Gctf/CTFFIND4 or the full executable filepath
* optional, when available as executables:
  - `"aretomo_command": ""` - executable name of AreTomo or the full executable filepath
  - `"SUSAN_path": ""` - location of the cloned SUSAN source code
  - `"conda_path": ""` - location of the anaconda/miniconda
* optional, when available as modules:
  - `"modules": ["IMOD_module", "Gctf_module", "MotionCor2_module", "CUDA_module_1", "CUDA_module_2"]` - insert the corresponding module names (will be loaded automatically by TomoBEAR). As for the other software packages you can add the required CUDA versions also to the field modules.

Additionaly, to be able to use IsoNet/crYOLO, you need fill in the following variables in the section `IsoNet`/`crYOLO`:
*  `"isonet_env": ""` or `"cryolo_env": ""` - name of the environment created and configured for IsoNet/crYOLO
*  `"repository_path": ""` - location of the cloned IsoNet/crYOLO source code

> **Warning**
> <br/> Be sure to use software versions that supports your current CUDA installation. However, sometimes software which depends on the newer CUDA libraries can handle versions compiled with older CUDA libraries.

If you install IMOD the normal way then IMOD should be already in your `PATH` variable and therefore callable from everywhere. This is the only way of IMOD configuration supported by TomoBEAR.

### Step 4. Initialize TomoBEAR

#### MATLAB (interactive session)

After you have installed the full licensed MATLAB version, go to the folder with cloned TomoBEAR source code and start MATLAB using the command

`./run_matlab.sh`

> **Warning**
> </br> MATLAB should be in your system's `PATH` variable to be able to run the command above.

The first time you start TomoBEAR after cloning it, initialization of necessary paths will be automatically performed, which could take a couple of minutes. You need to initialize TomoBEAR this way only once per the TomoBEAR clone you have obtained.

#### Standalone (binary)

Initialize the current TomoBEAR standalone by running (from TomoBEAR code directory)

`./TomoBEAR init`

which will perform the initialization of necessary paths automatically, which could take a couple of minutes. You need to initialize TomoBEAR this way only once per the TomoBEAR clone you have obtained.

## What is the next?

Upon completion of those setup steps you may proceed to [Tutorials page](https://github.com/KudryashevLab/TomoBEAR/wiki/Tutorials) to get idea of how to create input configuration files for your project and how to start TomoBEAR execution.
