# External Software

As ```TomoBEAR``` wraps different third-party software packages for different processing stages, here we provide the corresponding installation and citation notes.

Please remember that along with the ```TomoBEAR``` you **must cite all the used external packages as well**. Please, note as well that **by using these software packages it is assumed that you have read the corresponding license files and fully accept them**.

TomoBEAR modules dependencies on the external software are available on the [Modules page](https://github.com/KudryashevLab/TomoBEAR/wiki/Modules).

## Contents

- [Mandatory software](#mandatory-software)
- [Optional software](#optional-software)
- [Optional Python-based software](#optional-python-based-software)

## Mandatory software

### IMOD

**Installation**

Get the IMOD of version `4.11.24` from the [IMOD download page](https://bio3d.colorado.edu/imod/download.html).
As well, we have tested TomoBEAR under `IMOD-4.9.12` which you may find on the [IMOD package archive page](https://bio3d.colorado.edu/imod/download.html#Archive).

**Citation**

General usage:
- Mastronarde DN & Held SR (2017) Automated tilt series alignment and tomographic
reconstruction in IMOD. *J Struct Biol* 197: 102–113. DOI: [10.1016/j.jsb.2016.07.011](https://www.sciencedirect.com/science/article/pii/S1047847716301526?via%3Dihub)

Non-linear Anisotropic Diffusion filter:
- Frangakis A & Hegerl R (2001) Noise reduction in electron tomographic reconstructions using nonlinear anisotropic diffusion. *J Struct Biol* 135: 239-205. DOI: [10.1006/jsbi.2001.4406](https://www.sciencedirect.com/science/article/pii/S1047847701944065?via%3Dihub).

### Dynamo

**Installation**

For the non standalone version of TomoBEAR you need a Dynamo version with tilt stack alignment capabilities. The newest version can be [downloaded from here](https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Downloads). TomoBEAR was tested using the Dynamo of version `1.1.532` with `MCR-9.9.0` for `GLNXA64` system and GPU-dependent routines were compiled under `CUDA-11.5`.

To minimize the dependencies on different CUDA versions it is advised to recompile the CUDA kernel for averaging with the newest CUDA version which is at best already available on your machine. If not please revise the chapter CUDA on this page.

To recompile the kernel you just need to the location where dynamo was extracted and access the folder ```cuda``` inside. There you will find a file called ```makefile``` which you need to open and modify the second line containing the variable ```CUDA_ROOT=```. Please put in there the path to your most recent CUDA release available on the system.

To recompile just execute the following two commands:

* `make clean`
* `make all`

**Citation**

Main reference for its usage under TomoBEAR:
- Castaño-Díez D, Kudryashev M, Arheit M & Stahlberg H (2012) Dynamo: A flexible, user-friendly development tool for subtomogram averaging of cryo-EM data in high-performance computing environments. *J Struct Biol* 186:139-151. DOI: [10.1016/j.jsb.2011.12.017](https://www.sciencedirect.com/science/article/pii/S1047847711003650?via%3Dihub)

If you pick particles manually using Dynamo Catalogue as well, please cite also the following publication:
- Castaño-Díez D, Kudryashev M & Stahlberg H (2016) Dynamo Catalogue: Geometrical tools
and data management for particle picking in subtomogram averaging of cryo-electron
tomograms. *J Struct Biol* 197(2):135-144. DOI: [10.1016/j.jsb.2016.06.005](https://www.sciencedirect.com/science/article/pii/S1047847716301113?via%3Dihub)

## Optional software

### MotionCor2

**Installation**

Head to the
[MotionCor2](https://docs.google.com/forms/d/e/1FAIpQLSfAQm5MA81qTx90W9JL6ClzSrM77tytsvyyHh1ZZWrFByhmfQ/viewform)
download page. There you need to register and download MotionCor2. A MotionCor2 version greater than `1.4.0` is desired. [Alternative download link](https://emcore.ucsf.edu/ucsf-software).

**Citation**

- Zheng SQ, Palovcak E, Armache J-P, Verba KA, Cheng Y & Agard DA (2017) MotionCor2:
anisotropic correction of beam-induced motion for improved cryo-electron microscopy. *Nat Methods* 14: 331–332. DOI: [10.1038/nmeth.4193](https://www.nature.com/articles/nmeth.4193)

### AreTomo

**Installation**

Head to the [AreTomo download page](https://drive.google.com/drive/folders/1Z7pKVEdgMoNaUmd_cOFhlt-QCcfcwF3_). There you can find different AreTomo versions along with the documentation. TomoBEAR was tested using AreTomo of version `1.3.3` for `CUDA-11.5` (release date mark: 11212022).

**Citation**

- Zheng S, Wolff G, Greenan G, Chen Z, Faas FGA, Bárcena M, Koster AJ, Cheng Y & Agard DA
(2022) AreTomo: An integrated software package for automated marker-free,
motion-corrected cryo-electron tomographic alignment and reconstruction. *J Struct Biol X*
6: 100068. DOI: [10.1016/j.yjsbx.2022.100068](https://www.sciencedirect.com/science/article/pii/S2590152422000095?via%3Dihub)

### Gctf

**Installation**

You can download and try one of the following GCTF versions:
-   [Gctf v1.06](https://www2.mrc-lmb.cam.ac.uk/download/gctf_v1-06-and-examples/) - the version tested to be working under TomoBEAR;
-   [Gctf v1.18](https://www2.mrc-lmb.cam.ac.uk/download/special-version-for-phase-plate-gctf_v1-18/) - special version for phase plate data, as well tested to be working under TomoBEAR;
-   [Gctf Gautomatch cu10.1](https://www2.mrc-lmb.cam.ac.uk/download/gctf_gautomatch_cu10-1-tar-gz/) - version for CUDA-10 (should work under TomoBEAR, but was not tested).

**Citation**

For all three GCTF versions usage (v1.06/v1.18/Gautomatch cu10.1) please cite the following publication:
- Zhang K (2016) Gctf: Real-time CTF determination and correction. *J Struct Biol* 193: 1–12. DOI: [10.1016/j.jsb.2015.11.003](https://www.sciencedirect.com/science/article/pii/S1047847715301003?via%3Dihub)

### CTFFIND4

**Installation**

Head to the [CTFFIND4](https://grigoriefflab.umassmed.edu/ctf_estimation_ctffind_ctftilt) or [cisTEM](https://cistem.org/) download page. There you can find CTFFIND4/cisTEM source code and/or binaries. TomoBEAR was tested using CTFIND4 of `4.1.14` version released on May 8 2020.

> **Note**
> <br/> In the following releases we are also planning to include CTFFIND4 updated version with tilted images support from the development version of the cisTEM package (https://cistem.org/development).

**Citation**

CTFFIND4:
- Rohou A & Grigorieff N (2015) CTFFIND4: Fast and accurate defocus estimation from electron micrographs. *J Struct Biol* 192(2): 216-221. DOI: [10.1016/j.jsb.2015.08.008](https://www.sciencedirect.com/science/article/pii/S1047847715300460?via%3Dihub)

CTFFIND4 from cisTEM package:
- Grant T, Rohou A & Grigorieff N (2018) cisTEM, user-friendly software for single-particle image processing. *Elife* 7: e35383. DOI: [10.7554/eLife.35383](https://elifesciences.org/articles/35383)

### SUSAN

**Installation**

To install and use SUSAN follow the instructions in the [SUSAN](https://github.com/rkms86/SUSAN) code repository. TomoBEAR was tested with the SUSAN special release for TomoBEAR `v0.1-RC1-TomoBEAR`, posted on Zenodo (see citation link below). However, SUSAN uses rolling updates CI/CD model (as of July 2023) and hence no releases are currently issued, so we would encourage you to get the newer SUSAN version and try it with TomoBEAR, reporting us about any problems you faced with either TomoBEAR or SUSAN tools.

**Citation**

- Sánchez RM (2023) rkms86/SUSAN: Release for TomoBEAR (v0.1-RC1-TomoBEAR). *Zenodo*. DOI: [10.5281/zenodo.7950904](https://doi.org/10.5281/zenodo.7950904)

## Optional Python-based software

### Anaconda

TomoBEAR can use various python based techniques to extend its functionality like using a neural net-based picker (crYOLO), denoising (cryoCARE) or missing wedge reconstruction algorithm (IsoNet). For that, it assumes you have Anaconda or Miniconda installed. For that either use your OS-included package manager or install it from the [Anaconda web page](https://www.anaconda.com/products/individual). You can also take the miniconda installation to save on space and inodes.

### IsoNet

**Installation**

IsoNet is a DL framework based on convolutional neural nets (CNNs) and the U-net architecture which can be trained to both denoise and reconstruct missing wedge on cryo-elecrtron microscopy data. In order to use IsoNet under TomoBEAR, please clone the [IsoNet source code](https://github.com/IsoNet-cryoET/IsoNet) and follow the instructions on that page to setup the corresponding Python environment. TomoBEAR was tested using IsoNet of version `0.2` along with `CUDA-11.5` and the following versions of the main IsoNet dependencies: `python`=3.9, `cudatoolkit`=11.5, `cudnn`=8.3, `tensorflow-gpu`=2.11.

The original IsoNet version has limited missing wedge angular range of -60...+60, however there is an extended IsoNet version which allows for arbitrary parametrized missing wedge angular range on the ```mw_angle``` branch of the IsoNet original repository. TomoBEAR supports this version as well, so if you want to use it, you need to clone this branch by:
```bash
git clone --branch mw_angle https://github.com/IsoNet-cryoET/IsoNet.git IsoNet_mw
```
where ```IsoNet_mw``` is the folder name where this IsoNet version will be cloned so that original IsoNet version is not overwritten if you already got one.

**Citation**

- Liu YT, Zhang H, Wang H et al. (2022) Isotropic reconstruction for electron tomography with deep learning. *Nat Commun* 13: 6482. DOI: [10.1038/s41467-022-33957-8](https://www.nature.com/articles/s41467-022-33957-8)

### crYOLO

**Installation**

[crYOLO](https://cryolo.readthedocs.io/en/stable/index.html) is a DL framework based on convolutional neural nets (CNNs) which utilizes the popular **You Only Look Once (YOLO)** object detection system. crYOLO can be trained to pick particles XYZ positions from cryo-elecrtron microscopy data. If you want to try crYOLO under TomoBEAR, please follow the [crYOLO installation instructions](https://cryolo.readthedocs.io/en/stable/installation.html) to setup the corresponding Python (conda) environment. TomoBEAR was tested using crYOLO of version `1.9.3` along with `CUDA-11.5` and the following versions of the main crYOLO dependencies: `python`=3.8, `nvidia-cudnn-cu115`=8.3, `nvidia-tensorflow`=1.15.

**Citation**

- Wagner T, Merino F, Stabrin M et al. (2019). SPHIRE-crYOLO is a fast and accurate fully automated particle picker for cryo-EM. *Commun Biol* 2. DOI: [10.1038/s42003-019-0437-z](https://www.nature.com/articles/s42003-019-0437-z)
