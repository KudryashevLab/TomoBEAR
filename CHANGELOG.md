# Changelog

All notable changes will be documented in this file.

## v0.4.0 - 2023-08-07

### :rocket: New Features
* ```crYOLO``` - module wrapping [crYOLO](https://cryolo.readthedocs.io/en/stable/index.html) - DL tool, based on **You Only Look Once (YOLO)** object detection system for predicting particle coordinates (basically picking them) in cryo-electron tomograms

### :arrow_up: Improvements
* ```IsoNet```: added possibility to post-process IsoNet-corrected tomograms using NAD filtering
* ```DynamoTemplateMatching```: enabled usage of the tomograms from the custom user-provided path
* ```AreTomo```:
  * enabled direct usage of AreTomo alignment parameters from previously executed AreTomo step
  * enabled parameters: tilt axis offset (pre-tilt) and temporary reconstruction thickness (VolZ)

### :bug: Important fixes
* ```DynamoTemplateMatching```: fixed bug preventing GPU-enabled speedup

### :exclamation: Important updates
* **changed license** of the core code base from [`AGPLv3`](https://www.gnu.org/licenses/agpl-3.0.en.html) to [`GPLv3`](https://www.gnu.org/licenses/gpl-3.0.en.html) - changed license to a bit more permissive version in order to allow software maintainers and other TomoBEAR contributors more flexibility in terms of TomoBEAR modifications, needed to provide a TomoBEAR operation over local networks (like institutional intranets and/or shared filesystems);
* **updated documentation**:
  * recorded a [set of short 8-12 min video-tutorials](https://www.youtube.com/watch?v=2uizkE616tE&list=PLdMU06ILLrYKjI-Z0qezcNheEtpVulMao&pp=iAQB) on TomoBEAR installation and 80S ribosome (EMPIAR-10064) tutorial;
  * added [contribution guidelines and tips](https://github.com/KudryashevLab/TomoBEAR/blob/main/CONTRIBUTING.md)
  * extended ["Usage"](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage) and reviewed ["Installation and Setup"](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup) sections;
  * added ["External Software"](https://github.com/KudryashevLab/TomoBEAR/wiki/External-Software) section for dependencies installation/citation description.

---
## v0.3.0 - 2023-05-22

### :rocket: New Features
* ```local_live``` data processing mode - new mode allows to make on-the-fly pre-processing and reconstructions during data collection to check the sample quality. *Currently only single-shot collected data is supported for this feature.*
* ```EER``` (*Electron Event Representation*) support: input files format perception along with ```.gain``` gain file format support are now enabled in ```MotionCor2``` module
* ```GenerateParticles``` - new module which allows to generate particles using either Dynamo (by cropping) or SUSAN (by subtomogram reconstructions)
* ```IsoNet``` - module wrapping [IsoNet](https://github.com/IsoNet-cryoET/IsoNet) - CNN for denoising and missing wedge reconstruction

### :arrow_up: Improvements
* ```BinStacks```: added possibility to bin non-aligned stacks
* ```AreTomo```:
  - enabled binned stack input
  - enabled local patch-based alignment
* ```BatchRunTomo```: enabled IMOD-based patch-tracking
* ```Reconstruct```: enabled [*nonlinear anisotropic diffusion* (NAD)](https://www.sciencedirect.com/science/article/pii/S1047847701944065?via%3Dihub) filter for tomograms post-filtering
* ```GCTFCtfphaseflipCTFCorrection```: added possibility to use [CTFFIND4](https://www.sciencedirect.com/science/article/pii/S1047847715300460)

### :bug: Major fixes
* input files perception - fixed duplicated file extension ( issue #16 )

---
## v0.2.0 - 2023-02-23

### :rocket: New Features
* `GridEdgeEraser`: a new module which allows to identify position of the grid edge and mask it out.
  * *Currently only gold grids data is supported for this feature.*

### :arrow_up: Improvements
* `AreTomo`:
  * enabled IMOD-compatible files output
  * enabled tilt axis offset parameter

### :bug: Fixes
* `EMDTemplateGeneration`: fixed EMDB URL
* `BatchRunTomo`: fixed bug which prevented running TomoBEAR project for a single tilt serie
* `GCTFCtfphaseflipCTFCorrection`:
    * fixed AreTomo-aligned data usage
    * fixed aligned stack usage
    * fixed Ctfphaseflip usage
* `Reconstruct`: fixed reconstruction based on AreTomo-aligned data

---
## v0.1.2 - 2023-01-20

### :bug: Fixes
* `AreTomo` module: fixed parallelization and usage
