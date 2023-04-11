# Changelog

All notable changes will be documented in this file.

## v0.3.0 - 2023-04-:exclamation:**XX**:exclamation:

### :rocket: New Features
* ```local_live``` data processing mode - new mode allows to make on-the-fly pre-processing and reconstructions during data collection to check the sample quality. *Currently only single-shot collected data is supported for this feature.*
* ```EER``` (*Electron Event Representation*) support: input files format perception along with ```.gain``` gain file format support are now enabled in ```MotionCor2``` module
* ```GenerateParticles``` - new module which allows to generate particles using either Dynamo (by cropping) or SUSAN (by subtomogram reconstructions)

### :arrow_up: Improvements
* ```BinStacks```: added possibility to bin non-aligned stacks
* ```AreTomo```: enabled binned stack input
* ```Reconstruct```: enabled **nonlinear anisotropic diffusion** (NAD) filter for tomograms post-filtering
* ```GCTFCtfphaseflipCTFCorrection```: added possibility to use ```CTFFIND4```

### :bug: Fixes
* input files perception:
  * fixed duplicated file extension ( issue #16 )
  * fixed regular expression for date/time perception
  * fixed user-enforced input filenames parsing scheme changes (like [tilt_number/angle/date/time]_position)
* ```AreTomo```: fixed views exclusion for unbinned stack
* ```BatchRunTomo```: fixed bugs preventing patch-tracking

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
