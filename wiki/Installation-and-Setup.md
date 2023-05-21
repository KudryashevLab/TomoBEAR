> **Note**
> <br/> We are happy to support you to try out one of the latest available TomoBEAR versions from the [Releases page](https://github.com/KudryashevLab/TomoBEAR/releases).
> </br> We are glad to
> * receive your opinion on [Discussions page](https://github.com/KudryashevLab/TomoBEAR/discussions)
> * respond to your feedback on bugs, execution issues and configuration complications by using our [Issue Tracker](https://github.com/KudryashevLab/TomoBEAR/issues)
> * have a discussion with you via e-mail:
>   * Artsemi Yushkevich - contributing developer: Artsemi.Yushkevich@mdc-berlin.de
>   * Misha Kudryashev - project lead: misha.kudryashev@gmail.com.

# Prerequisites

This software was developed and tested on machines with the following properties:

-   Operating System (OS): CentOS 7 / Ubuntu 21.04

Other Linux-based OSs should also be possible as long as MATLAB and all the other needed tools are runnable.

-   Graphics Processing Unit (GPU): at least one GPU with a minimum of 8GB of Video Random Access Memory (VRAM)

It is better to have more GPUs with possibly greater amount of VRAM. With more GPUs you can process more data units in parallel. With more VRAM you can fit bigger tilt stacks or tomograms in memory especially in template matching.

-   Random Access Memory (RAM): at least 16GB of RAM

The more RAM you have the better. With more RAM you can run more parallel processes to process to process your data faster. This depends on the execution method of the modules.

-   Hard Disk Drive (HDD) / Solid State Disk (SSD): depends on size of data

You need enough storage to store your data and all the intermediate data and results. Although it is possible to clean up the intermediate data during processing you will still need temporarily enough storage to store it until it can be deleted. The amount of needed storage is larger when you have more processes running in parallel.

# Setup

There are two ways to operate TomoBEAR.

* The first way is to [[ use it directly from MATLAB | https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#matlab ]]
* The second way is to [[ use a standalone executable which is available precompiled | https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#standalone ]]

For both methods of operation, you will need to [[ get TomoBEAR source code | https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#get-source-code-and-binary ]] and to get and install its dependencies.
You have to install essential TomoBEAR dependencies (CUDA, Dynamo, and IMOD) and may additionally install optional ones (MotionCor2, GCTF, etc.). The corresponding links you may find in the section [[ Additional software | https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#additional-software ]].

## Get source code and binary

### Clone the latest version

To get the latest ```TomoBEAR``` version you can simply clone *main* branch by:
```bash
 git clone https://github.com/KudryashevLab/TomoBEAR.git
```

### Clone specific version

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

## Initialize TomoBEAR

### MATLAB

If you want to run on a local machine then it is advised to run TomoBEAR from within MATLAB. This way you also don't need to download and install the MATLAB Compiled Runtime (MCR) if it is not already installed in your facility.

It is adviced to use the following MATLAB release under which the software was tested: MATLAB R2021a.

Further you need to install TomoBEAR's dependencies, at least all mandatory ones: CUDA, Dynamo and IMOD. For the corresponding links and some instructions on that refer to the section [Additional Software](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#additional-software).

Afterwards you need to configure and initialize TomoBEAR with the corresponding paths to the dependencies. Instructions on that part you may find below in the subsection [Configure installed software](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#configure-installed-software)

Finally, start MATLAB with the command

* `./run_matlab.sh`

To be able to run that MATLAB should be in your system's `PATH` variable.
The first time you start TomoBEAR after cloning it, initialization of necessary paths will be automatically performed, which could take a couple of minutes. But no worries, this is happening only once per the TomoBEAR clone you have fetched.

### Standalone

TomoBEAR can also be used as a standalone application. For that you will need to run the [installation script (see section above)](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#get-source-code-and-binary).
The available releases can be found on the [Releases page](https://github.com/KudryashevLab/TomoBEAR/releases).

As well, you will need to install and setup the external software which is [mentioned below](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#additional-software).

Additionally you will need the MCR (MATLAB Compiled Runtime) from [here](https://www.mathworks.com/products/compiler/matlab-runtime.html). There you need to get the newest **MCR 2021a** to be able to run TomoBEAR. When the download of the MCR is finished you will need to give it execution rights.
For that change to the folder where the file was downloaded to and execute the following command

* `chmod u+x MATLAB_Runtime_R2021a_Update_4_glnxa64.zip`

Alternatively you can change to some folder and execute the following command before you execute the previous one

* `wget https://ssd.mathworks.com/supportfiles/downloads/R2021a/Release/4/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021a_Update_4_glnxa64.zip`

Afterwards you need to extract the archive either with a command or through your file explorer

* `unzip MATLAB_Runtime_R2021a_Update_4_glnxa64.zip`

Change to the directory where the files were extracted and run the installation with the following command and follow the wizard which is displayed on screen

* `./install`

When the installation is finished, remember to include to the enviromental variable `LD_LIBRARY_PATH` the following paths of the installed MCR libraries:

```bash
/usr/local/MATLAB/MATLAB_Runtime/v910/runtime/glnxa64
/usr/local/MATLAB/MATLAB_Runtime/v910/bin/glnxa64
/usr/local/MATLAB/MATLAB_Runtime/v910/sys/os/glnxa64
/usr/local/MATLAB/MATLAB_Runtime/v910/extern/bin/glnxa64
```

Further you need to install TomoBEAR's dependencies, at least all mandatory ones: CUDA, Dynamo and IMOD. For the corresponding links and some instructions on that refer to the section [Additional Software](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#additional-software).

Afterwards you need to configure and initialize TomoBEAR with the corresponding paths to the dependencies. Instructions on that part you may find below in the subsection [Configure installed software](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#configure-installed-software)

Finally, initialize the current TomoBEAR standalone by running (from TomoBEAR code directory)

* `./TomoBEAR init`

which will perform the initialization of necessary paths automatically, which could take a couple of minutes. But this you should do only once per the TomoBEAR clone you have fetched.

#### Configure installed software

Please, follow the setup instructions for all the software packages you downloaded. At the best, you will find the paths to the executables of the downloaded software in your `PATH` variable of your Linux system.

If this is not the case you need to adjust the paths to the executables in the
`configurations/defaults.json` file. The keys where the values need to be adjusted can be found in the section `general` of the `defaults.json` file and are the following ones:
* mandatory:
  - `"pipeline_location": ""` - location of the cloned TomoBEAR source code
  - `"dynamo_path": ""` - path to your Dynamo folder
* semi-mandatory (if you need motion/CTF-correction routines):
  - `"motion_correction_command": ""` - executable name of MotionCor2 or the full executable filepath
  - `"ctf_correction_command": ""` - executable name of Gctf/CTFFIND4 or the full executable filepath
* optional:
  - `"aretomo_command": ""` - executable name of AreTomo or the full executable filepath
  - `"SUSAN_path": ""` - location of the cloned SUSAN source code
  - `"conda_path": ""` - location of the anaconda/miniconda

Additionaly, to be able to use IsoNet, you need fill in the following variables in the section `IsoNet`:
*  `"isonet_env": ""` - name of the environment created and configured for IsoNet (following the [IsoNet setup instructions](https://github.com/IsoNet-cryoET/IsoNet) )
*  `"repository_path": ""` - location of the cloned IsoNet source code

> **Warning**
> <br/> Be sure to use a version that supports your current CUDA installation.

> **Note**
> <br/> Sometimes software which depends on the newer CUDA libraries can handle versions compiled with older CUDA libraries.

If you install IMOD the normal way then IMOD should be already in your `PATH` variable and therefore callable from everywhere. This is the only way of IMOD configuration supported by TomoBEAR.

If you use the Linux module system please insert the module names which need to be loaded to make all the necessary software available and working in the following variable in the general section

* `"modules": ["IMOD_module", "Gctf_module", "MotionCor2_module", "CUDA_module_1", "CUDA_module_2"]`

## Additional Software

As TomoBEAR is wrapping standardized tools to fulfill some of the processing steps these need to be installed and executable.

### Module System

If you are working in a cryo electron microscopy facility and employ a cluster with a module system where all the needed software is already deployed as modules it is fairly easy to setup TomoBEAR. If not all the software packages are available as modules you have two possibilities.

1. The first and probably the easiest possibility for inexperienced users is to ask the administrator or some responsible person for the module system to introduce the needed software as modules

2. The second and probably faster possibility is to install the software on your own in your home folder if you don't have root permissions and put it your PATH variable or adjust the defaults.json so that the variables to tools contain the full path.

If all the software is available as modules you need to head to the `defults.json` file and find the entry `"modules": []` just replace it with `"modules": ["IMOD_module", "Gctf_module", "MotionCor2_module", "CUDA_module_1", "CUDA_module_2"]`. Be aware that these module names are just placeholders for your real module names. you can find them out with the command `module available` or the shortcut `module avail`.

As for the other software packages you can add the required CUDA versions also to the field modules.

### Manual Installation

The easiest way for the manual installation is to add the repositories with CUDA to your specific OS package manager. That is yum in CentOS and apt or apt-get in Ubuntu. The other way is a manual installation from the executables which are available from the [NVIDIA homepage](https://developer.nvidia.com/cuda-toolkit-archive).

##### CUDA

For all the additional software packages the proper CUDA toolkits with the newest driver for your graphics card need to be installed.

To install CUDA you can use the package manager of your OS install it manually or just use the module system of your facility if you employ one.

##### CentOS 7

A description of how to install a specific CUDA version for CentOS 7 is available [here](https://linuxconfig.org/how-to-install-nvidia-cuda-toolkit-on-centos-7-linux). Please follow the instructions there. To get other CUDA versions you will need to replace the rpm `cuda-repo-rhel7-10.0.130-1.x86_64.rpm` with a suitable rpm from [here](https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/).

You need to repeat the steps multiple times until you have all the needed CUDA versions in ypur system installed to be able to run all the tools which are mentioned below.

##### Ubuntu 21.04

To get the newest CUDA on an Ubuntu system the easiest way is to install it via graphical interface using *Software & Updates* (see tab *Additional Drivers*).

#### Dynamo

For the non standalone version of TomoBEAR you need a Dynamo version with tilt stack alignment capabilities. The newest version can be [downloaded from here](https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Downloads).

To minimize the dependencies on different CUDA versions it is advised to recompile the CUDA kernel for averaging with the newest CUDA version which is at best already available on your machine. If not please revise the chapter CUDA on this page.

To recompile the kernel you just need to the location where dynamo was extracted and access the folder ```cuda``` inside. There you will find a file called ```makefile``` which you need to open and modify the second line containing the variable ```CUDA_ROOT=```. Please put in there the path to your most recent CUDA release available on the system.

To recompile just execute the following two commands:

* `make clean`
* `make all`

#### MotionCor2

Head to the
[MotionCor2](https://docs.google.com/forms/d/e/1FAIpQLSfAQm5MA81qTx90W9JL6ClzSrM77tytsvyyHh1ZZWrFByhmfQ/viewform)
download page. There you need to register and download MotionCor2. A
MotionCor2 version greater than 1.4.0 is desired.

-   Alternative download [link](https://emcore.ucsf.edu/ucsf-software).

#### AreTomo

Head to the
[AreTomo](https://drive.google.com/drive/folders/1Z7pKVEdgMoNaUmd_cOFhlt-QCcfcwF3_)
download page. There you can find different AreTomo versions along with the documentation.

#### Gctf

You can download and try one of the following GCTF versions:
-   [Gctf v1.06](https://www2.mrc-lmb.cam.ac.uk/download/gctf_v1-06-and-examples/) - the main version, tested to be working under TomoBEAR;
-   [Gctf v1.18](https://www2.mrc-lmb.cam.ac.uk/download/special-version-for-phase-plate-gctf_v1-18/) - special version for phase plate data;
-   [Gctf Gautomatch cu10.1](https://www2.mrc-lmb.cam.ac.uk/download/gctf_gautomatch_cu10-1-tar-gz/) - version for CUDA-10 (should work under TomoBEAR, but was not tested).

#### CTFFIND4

Head to the [CTFFIND4](https://grigoriefflab.umassmed.edu/ctf_estimation_ctffind_ctftilt) or [cisTEM](https://cistem.org/) download page. There you can find CTFFIND4/cisTEM source code and/or binaries.

> **Note**
> <br/> In the following releases we are also planning to include CTFFIND4 updated version with tilted images support from the development version of the cisTEM package (https://cistem.org/development).

#### IMOD

Head to the
[IMOD](https://bio3d.colorado.edu/ftp/latestIMOD/RHEL7-64_CUDA8.0)
download page and get the IMOD version 4.10.42 or earlier.

#### SUSAN

To install and use SUSAN follow the instructions in the [SUSAN](https://github.com/rkms86/SUSAN) code repository.

#### Anaconda

TomoBEAR can use various python based techniques to extend its functionality like using a neural net-based picker, denoising or missing wedge reconstruction algorithm. For that, it assumes you have Anaconda or Miniconda installed. For that either use your OS-included package manager or install it from the [Anaconda](https://www.anaconda.com/products/individual) web page. You can also take the miniconda installation to save on space and inodes.

#### IsoNet

IsoNet is a DL framework based on convolutional neural nets (CNNs) and the U-net architecture which can learn both to denoise and reconstruct missing wedge on cryo-elecrtron microscopy images. With TomoBEAR it is possible to perform those operations on tomograms using IsoNet. For that please clone the [IsoNet](https://github.com/IsoNet-cryoET/IsoNet) and follow the instructions on their page to setup Python environment.

The original IsoNet version has limited missing wedge angular range of -60...+60, however there is an extended IsoNet version which allows for arbitrary parametrized missing wedge angular range on the ```mw_angle``` branch of the IsoNet original repository. TomoBEAR supports this version as well, so if you want to use it, you need to clone this branch by:
```bash
git clone --branch mw_angle https://github.com/IsoNet-cryoET/IsoNet.git IsoNet_mw
```
where ```IsoNet_mw``` is the folder name where this IsoNet version will be cloned so that original IsoNet version is not overwritten if you already got one.
