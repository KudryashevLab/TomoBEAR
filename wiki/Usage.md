# TomoBEAR Configuration

If you followed the [installation instructions](https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup) thoroughly then you should have a working copy of the TomoBEAR. Now you need to generate a JSON file for your project to start to process your acquired cryo-ET data.

## Contents

- [Data entry](#data-entry)
- [Tilt stack alignment](#tilt-stack-alignment)
- [CTF estimation and correction](#ctf-estimation-and-correction)
- [Missing wedge reconstruction](#missing-wedge-reconstruction)
- [Particles picking](#particles-picking)
- [Particles generation](#particles-generation)
- [Live data processing](#live-data-processing)
- [Executing the workflow](#executing-the-workflow)

## Data entry

### Input Data File Formats

Generally, TomoBEAR supports the ```TIF(F)```, ```MRC``` and ```EER``` input data file formats. As well, for all of the formats TomoBEAR supports perception of the raw filenames for the data collected by different modes including:
- single-shot (conventional) - with a single-level TS numbering pattern;
- multi-shot (e.g. [PACEtomo](https://github.com/eisfabian/PACEtomo)) - with a two-level TS numbering pattern, including IDs of square and TS.

**Table: Example cases of available input filenames recognition schemes**

| Scenario  | File Naming Patterns and Examples |
| -------------  | ------------- |
| Single-shot (conventional) frames (**TIF[F]/MRC**) | ```<TS-PREFIX>_<TS-ID>{_<VIEW>}{_<ANGLE>}{_<DATE>_<TIME>}.<EXT>``` </br> with the parts denoted in ```{}``` being optional </br> e.g. [EMPIAR-10164](https://www.ebi.ac.uk/empiar/EMPIAR-10164/): ```TS_05_008_-12.0.mrc``` |
| Falcon4 frames (**EER**) | ```<TS-PREFIX>_<TS-ID>{_<VIEW>}[<ANGLE>].<EXT>``` </br> e.g. [EMPIAR-11306](https://www.ebi.ac.uk/empiar/EMPIAR-11306/): ```Position_02_001[-10.00]_EER.eer```|
| Multi-shot frames (**TIF[F]** by [PACEtomo](https://github.com/eisfabian/PACEtomo)) | ```Square<SQUARE-ID>_<TS-PREFIX>_<TS-ID>_<VIEW>_<ANGLE>{_<DATE>_<TIME>}.<EXT>``` </br> e.g. from our internal data: ```Square3_ts_001_000_Feb24_10.12.16.tif``` |
| Assembled stacks (**MRC**) | ```<TS-PREFIX-1>..._<TS-PREFIX-N>.<EXT>``` </br> e.g. [EMPIAR-10064](https://www.ebi.ac.uk/empiar/EMPIAR-10064/) with arbitrary unique names: ```CTEM_tomo2.mrc``` |

> **Warning**
> (ordering frames)
> <br/> Withing a tilt-serie the frames are ordered according to ```<DATE>_<TIME>``` marker. If that was not present, then ```<VIEW>``` marker is used. If the latest is not present as well, then filename [date/time]stamp is used. Be aware that while copying in parallel (e.g. using ```cp```) or opening data you could modify that original timestamp!

> **Warning**
> (multi-shot data)
> <br/> In the case of multi-shot (e.g. [PACEtomo](https://github.com/eisfabian/PACEtomo)) input data it is important to make sure your data has described in the table above file format with leading keyword ```Square``` followed by the corresponding square number w/o any separators.

The possible naming schemes for input data coming from SerialEM and defined above EER naming pattern should be all well-covered by our default regular expressions. Nevertheless, you may fine-tune your data perception by using the following parameters, if necessary:
- ```<KEY>_position``` where ```<KEY>``` could be ```prefix```, ```tomogram_number```, ```tilt_number```, ```angle```, ```date``` or ```time``` - this set of parameters directly controls recognition of the corresponding information by counting positions between underscores ```_``` in filenames and associating the extracted sub-strings with the corresponding keys;
- ```<KEY>_regex``` where ```<KEY>``` could be ```angle```, ```name```, ```number```, ```name_number``` or ```month_date``` - this set of parameters is more general and better tunable, it controls recognition of the corresponding information by regular expressions.

If you experience some problems with input data perception, take a look at the corresponding section on the [Troubleshooting page](https://github.com/KudryashevLab/TomoBEAR/wiki/Troubleshooting).

### Electron-Event Representation

In order to be able to input and process ```EER``` files you have to setup MotionCor2 parameters of ```EER``` data integration into frame movies to be motion-corrected and integrated again to tilt images. Below you can find beginning of an example JSON configuration file for TomoBEAR:
```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/prefix*.eer",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "reconstruction_thickness": xxxx,
        "rotation_tilt_axis": xx,
        "aligned_stack_binning": x,
        "pre_aligned_stack_binning": x,
        "binnings": [x, x, xx]
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
        "gain": "/path/to/gain/ref/EER_GainReference.gain",
        "eer_sampling": x,
        "eer_total_number_of_fractions": xxx,
        "eer_fraction_grouping": xx,
        "eer_exposure_per_fraction": x.x,
        "ft_bin": x
    },
    ...
}
```
where the parameters are the following:
* ```eer_sampling```: EER upsampling rate after fractions integration (1 - don't upsample, 2 - upsample x2, etc.);
* ```eer_total_number_of_fractions```: total number of fractions (data slices) present in raw EER data;
* ```eer_fraction_grouping```: number of fractions (data slices) to group and integrate into a frame;
* ```eer_exposure_per_fraction```: total electron dose accumulated per frame (group of fractions).
These parameters relate to the corresponding MotionCor2 parameters such as ```–EerSampling``` and three parameter values denoted in the file passed to ```–FmIntFile``` option, namely - total number of fractions (1st column), number of fractions in group (2nd column) and total accumulated dose per group (3rd column).

### Assembled tilt stacks

If you want to input already assembled tilt stacks with `TomoBEAR` you need to provide the tilt angles corresponding to the order of images in the input tilt stacks:

```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/prefix*.mrc",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "tilt_angles": [-60.0, -58.0, -56.0, -54.0, -52.0, -50.0, -48.0, -46.0, -44.0, -42.0, -40.0, -38.0, -36.0, -34.0, -32.0, -30.0, -28.0, -26.0, -24.0, -22.0, -20.0, -18.0, -16.0, -14.0, -12.0, -10.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 0, 24.0, 26. , 28.0, 30.0, 32.0, 34.0, 36.0, 38.0, 40.0, 42.0, 44.0, 46.0, 48.0, 50.0, 52.0, 54.0, 56.0],
        "apix": x.xx,
        "reconstruction_thickness": xxxx,
        "rotation_tilt_axis": xx,
        "aligned_stack_binning": x,
        "pre_aligned_stack_binning": x,
        "binnings": [x, x, xx]
    },
    "MetaData": {
    },
    "CreateStacks": {
    },
    ...
}
```

## Tilt stack alignment

There is a couple of options available in TomoBEAR to perform tilt stacks alignment according to the fiducials presence in the sample:
* **fiducials-based alignment** - Dynamo/IMOD for fiducials model estimation, IMOD for alignment;  
* **fiducials-free alignment** - IMOD for patches-based tracking and alignment or AreTomo for global or local ("smart grid") tracking and alignment.   

### Fiducials-based alignment

To align tilt stacks containing fiducials the suggested `TomoBEAR` pipeline includes the following steps:
1. Coarsely pre-align tilt stacks using IMOD BatchRunTomo;
2. Estimate fiducials model using Dynamo Tilt Series Alignment;
3. Fine-align tilt stack by IMOD BatchRunTomo using obtained fiducials model from previous step.   
To achieve that you need to use the configuration JSON file with the following structure:
```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "pre_aligned_stack_binning": x,
        "aligned_stack_binning": x,
        "binnings": [x, x, xx],
        "apix": x.xx
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
    },
    "CreateStacks": {
    },
    "DynamoTiltSeriesAlignment": {
    },
    "DynamoCleanStacks": {
    },
    "BatchRunTomo": {
        "skip_steps": [4],
        "ending_step": 6
    },
    "StopPipeline": {
    },
    "BatchRunTomo": {
        "starting_step": 8,
        "ending_step": 8
    },
    ...
}
```
If for some reason you want to use BatchRunTomo fiducials model estimation routines instead of Dynamo Tilt Series Alignment routines, feel free to remove from your configuration JSON file the following sections: `"DynamoTiltSeriesAlignment": {}` and `"DynamoCleanStacks": {}"`.

### Fiducials-free alignment

To process tomogrpahy data without fiducials (for example, focused ion-beam milling data) user have the following options for fiducials-free alignment:

**1. BatchRunTomo-based (IMOD) patch tracking and alignment.**

<details>
<summary><b> BatchRunTomo-based (IMOD) template of JSON file to process raw tomogrpahy data without fiducials (expand to see).</b></summary>

```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "pre_aligned_stack_binning": x,
        "aligned_stack_binning": x,
        "binnings": [x, x, xx],
        "apix": x.xx
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
    },
    "CreateStacks": {
    },
    "BatchRunTomo": {
      "ending_step": 6,
      "skip_steps": [5],
      "directives": {
          "comparam.xcorr_pt.tiltxcorr.SizeOfPatchesXandY": "500 500",
          "comparam.xcorr_pt.tiltxcorr.OverlapOfPatchesXandY": "0.33 0.33",
          "comparam.xcorr_pt.tiltxcorr.BordersInXandY": "102 102",
          "runtime.Fiducials.any.trackingMethod": 1,
          "runtime.AlignedStack.any.eraseGold": 0,
          "comparam.align.tiltalign.RotOption": -1,
          "comparam.align.tiltalign.MagOption": 0,
          "comparam.align.tiltalign.TiltOption": 0,
          "comparam.align.tiltalign.ProjectionStretch": 0
      }
    },
    "BatchRunTomo": {
      "starting_step": 8,
      "ending_step": 8
    },
...
}
```
except for base directives which you need to use in order to make patch-based alignment by BatchRunTomo we would advice to take a look at the following ones (for the usage please consult with the corresponding [IMOD documentation page](https://bio3d.colorado.edu/imod/doc/directives.html)):
```json
...
  "directives": {
    ...
    "comparam.xcorr.tiltxcorr.FilterRadius2": 0.07,
    "comparam.xcorr.tiltxcorr.FilterSigma1": 0.00,
    "comparam.xcorr.tiltxcorr.FilterSigma2": 0.02,
    "comparam.xcorr.tiltxcorr.CumulativeCorrelation": 1,
    "comparam.xcorr_pt.tiltxcorr.FilterRadius2": 0.07,
    "comparam.xcorr_pt.tiltxcorr.FilterSigma1": 0.00,
    "comparam.xcorr_pt.tiltxcorr.FilterSigma2": 0.02,
    "comparam.xcorr_pt.tiltxcorr.IterateCorrelations": 1,
    ...
  }
...
```
</details>
</br>

**2. AreTomo-based features tracking and alignment.**

For AreTomo usage case there is global and local alignment procedures implemented. In the future releases we are planning to enable as well AreTomo-based reconstructions.

For AreTomo **global alignment** you need just to keep in mind the adjusted parameters values which you need to use for CTF-correction of the AreTomo globally aligned stack as in the provided example of configuration file below:
```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "pre_aligned_stack_binning": x,
        "aligned_stack_binning": x,
        "binnings": [x, x, xx],
        "apix": x.xx
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
    },
    "CreateStacks": {
    },
    "AreTomo": {
    },
    "GCTFCtfphaseflipCTFCorrection": {
        "run_ctf_phase_flip": true,
        "use_aligned_stack": true
    },
    ...
}
```

For AreTomo **local alignment** you need to use the same way of CT-correction after using AreTomo section. Additionally, to speed up calculations and overcome artefacts we recommend to pre-bin data before AreTomo local alignment procedure.  
Below you can find the example of the corresponding configuration file:
```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "pre_aligned_stack_binning": x,
        "aligned_stack_binning": x,
        "binnings": [x, x, xx],
        "apix": x.xx
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
    },
    "CreateStacks": {
    },
    "BinStacks": {
        "binnings": [2],
        "use_ctf_corrected_aligned_stack": false,
        "use_aligned_stack": false
    },
    "AreTomo": {
        "input_stack_binning": 2,
        "patch": "5 5"
    },
    "GCTFCtfphaseflipCTFCorrection": {
        "run_ctf_phase_flip": true,
        "use_aligned_stack": true
    },
    ...
}
```

## CTF estimation and correction

For CTF-associated routines in TomoBEAR a number of popular in cryo-ET community options are available to correct CTF in tilt stacks and tomograms.

### CTF routines for tilt stacks

**CTF estimation**

To estimate CTF in tilt stacks you need to use the module called `"GCTFCtfphaseflipCTFCorrection"`, which you can run with either `GCTF` or `CTFFIND4`. To choose the tool you want to use, setup the following parameters values:
* file: `defaults.json` > section: `"general"` > parameter: `"ctf_correction_command": ""` - provide the filename/path of the corresponding executable, for example:
  * `"ctf_correction_command": "GCTF_v1.18_sm30-75_cu10.1"`
  * `"ctf_correction_command": "ctffind"`
* file: `input.json` (your project configuration) > section: `"GCTFCtfphaseflipCTFCorrection"` > parameter: `"ctf_estimation_method": ""` - setup the corresponding method of CTF estimation:
  * `"ctf_estimation_method": "gctf"`
  * `"ctf_estimation_method": "ctffind"`

You can inspect the quality of fitting by going into the folder `X_GCTFCtfphaseflipCTFCorrection_1` and typing `imod tomogram_xxx/slices/*.ctf` and making sure that the Thon rings match the estimation. If not - play with the parameters of the `GCTFCtfphaseflipCTFCorrection` module.

**CTF correction**

To correct CTF in tilt stacks in TomoBEAR we implemented Ctfphaseflip from IMOD which you may use:
* (e.g. before IMOD alignment) from `"BatchRunTomo"` by using step 11 of this module as the following
  ```json
    "BatchRunTomo": {
      "starting_step": 11,
      "ending_step": 11
    }
  ```
* (e.g. before AreTomo alignment) from `"GCTFCtfphaseflipCTFCorrection"` by setting up `"run_ctf_phaseflip": true`

### CTF routines for tomograms

For CTF correction in tomograms in TomoBEAR you can use CTF-deconvolution procedure available as `IsoNet` module pre-processing functionality. For that you need first to get non-CTF-corrected aligned stacks and the corresponding non-CTF-corrected tomograms by the following sequence of configuration sections:
```json
...
    "BinStacks": {
        "binnings": [x, x, x],
        "use_ctf_corrected_aligned_stack": false,
        "use_aligned_stack": true
    },
    "Reconstruct": {
        "binnings": [x, x, x],
        "use_ctf_corrected_stack": false
    },
...
```
and afterwards produce input STAR file and the target CTF-deconvolved tomograms by the following configuration section:
```json
...
  "IsoNet": {
    "isonet_env": "isonet-env",
    "repository_path": "/path/to/cloned/IsoNet",
    "steps_to_execute": {
        "prepare_star": {
            "tomograms_binning": x
        },
        "deconv": {
             "ncpu": x
        }
    }
  },
...
```

## Missing wedge reconstruction

In order to fulfill interests of *in situ* cellular tomogaphy part of cryo-ET community, `TomoBEAR` interfaces `IsoNet` - DL framework capable of tomograms missing wedge (MW) reconstruction and denoising. `TomoBEAR` interface includes such `IsoNet` routines as preprocessing (STAR file preparation, mask creation, CTF-deconvolution), training (refinement) and prediction.

### Pre-processing

Since `IsoNet` requires quite good contrast to be able to restore missing wedge, it is recommended to use CTF-deconvolution as a preprocessing routine available in `IsoNet`. For that you need to get non-CTF-corrected aligned stacks and non-CTF-corrected tomograms before starting `IsoNet` by the following sequence of `TomoBEAR` modules:
```json
...
    "BinStacks": {
        "binnings": [x, x, x],
        "use_ctf_corrected_aligned_stack": false,
        "use_aligned_stack": true
    },
    "Reconstruct": {
        "binnings": [x, x, x],
        "use_ctf_corrected_stack": false
    },
...
```

### Produce trained model and test it

In order to be able to produce trained `IsoNet` model, you need to:
1. select 4-5 tomograms (the more different background is, the better training would be)
2. prepare STAR file listing the selected tomograms
3. (optional) deconvolve the selected tomograms
4. (optional) produce binary masks to train only on the selected regions of interest
5. extract 400-500 subtomograms (100-150 per tomogram) for training
6. start training procedure

All of those steps could be covered just in one section of the corresponding `IsoNet` module as in the following example:
```json
...
    "IsoNet": {
       "isonet_env": "isonet-env",
       "repository_path": "/path/to/cloned/IsoNet",
       "tomograms_to_use": [x,xx,xx,xxx],
       "steps_to_execute": {
           "prepare_star": {
           },
           "deconv": {
           },
           "make_mask": {
           },
           "extract": {
           },
           "refine": {
               "iterations": 30,
               "noise_start_iter": [10,15,20,25],
               "noise_level": [0.05,0.1,0.15,0.2]
           }
       }
    },
...
```

In case you do not want/need to produce binary masks for training, just skip the corresponding subsection `"make_mask"` in the `"steps_to_execute"` section.

<details>
<summary><b> In case you do not want/need to use IsoNet deconvolved tomograms (expand to see).</b></summary>

Note that if for some reason you don't want to use `IsoNet` deconvolution procedure, you need to skip preprocessing procedure described in the previous subsection, skip `"deconv"` step in `"steps_to_execute"` section and set parameter `"use_ctf_corrected_tomograms": true` in the `"prepare_star"` subsection as shown in the example below:
```json
...
    "IsoNet": {
       "isonet_env": "isonet-env",
       "repository_path": "/path/to/cloned/IsoNet",
       "tomograms_to_use": [x,xx,xx,xxx],
       "steps_to_execute": {
           "prepare_star": {
              "use_ctf_corrected_tomograms": true
           },
           "make_mask": {
           },
           "extract": {
           },
           "refine": {
               "iterations": 30,
               "noise_start_iter": [10,15,20,25],
               "noise_level": [0.05,0.1,0.15,0.2]
           }
       }
    },
...
```
</details>
</br>

Once you produced trained `IsoNet` model, before starting prediction on all the tomograms you may want to test it first on the same tomograms which were used for training to asses training quiality and decide whether you need to repeat it with different parameters. In order to run MW prediction using trained model, you need the following module structure:
```json
...
    "IsoNet": {
        "isonet_env": "isonet-env",
        "repository_path": "/path/to/cloned/IsoNet",
        "tomograms_to_use": [x,xx,xx,xxx],
        "steps_to_execute": {
            "predict": {
                "star_file": "../XX_IsoNet_1/tomograms.star",
                "model": "../XX_IsoNet_1/results/model_iter30.h5"
            }
        }
     },
...
```
where in `"tomograms_to_use": []` parameter you have to put exactly the same tomograms as those used for training, since you are going to use the already prepared STAR file from the training step. If you want to test it on other tomograms, use instructions given in the next section for the general prediction procedure.

Other used parameters here are `"star_file": ""` and `"model": ""` where you have to put paths (relative to the current step folder or absolute) to the STAR file containing paths to deconvolved tomograms for prediction and to the trained `IsoNet` model.

### Predict MW-free tomograms

After coming up with suitable trained model, if you want to run prediction on all the data or the piece of data which differs from the one used for training, you need to prepare the corresponding STAR file and deconvolve it. You may achieve all of that by a the following configuration section:
```json
...
    "IsoNet": {
        "isonet_env": "isonet-env",
        "repository_path": "/path/to/cloned/IsoNet",
        "tomograms_to_use": [x,xx,xx,xxx],
        "steps_to_execute": {
            "prepare_star": {
            },
            "deconv": {
            },
            "predict": {
                "model": "../XX_IsoNet_1/results/model_iter30.h5"
            }
        }
    },
...
```
In case you want to use all the tomograms for prediction, simply leave empty list in the corresponding field: `"tomograms_to_use": []`.

## Particles picking

TomoBEAR gives users a couple of particles picking options:
* template matching procedure by modified Dynamo routines (coordinates + orientations);
* neural network-based particles picking by crYOLO (coordinates only);


as well, not properly integrated in TomoBEAR yet, but as a workaround user may try
* manual particles picking (coordinates only).

### Template matching

In order to perform Dynamo-based template matching you need to
1. Prepare template
  * by fetching a template directly from EMDB by ID, for example
  ```json
  ...
    "EMDTemplateGeneration": {
        "template_emd_number": "XXXX",
        "flip_handedness": true
    },
  ...
  ```
  * by providing the path to the custom template file:
  ```json
  ...
    "TemplateGenerationFromFile": {
        "template_path": "/path/to/template.mrc",
        "mask_path": "/path/to/mask.mrc",
        "template_apix": xx.x
    },
  ...
  ```
2. Run template matching search by cross-correlation (CC)
  ```json
  ...
    "DynamoTemplateMatching": {
          "cone_range": 360,
          "cone_sampling": 10,
          "in_plane_range": 360,
          "in_plane_sampling": 10,
          "size_of_chunk": [xxx, xxx, xxx]
    },
  ...
  ```
  > **Note**
  > <br/> At a high binning level (e.g. 8 or 16) using the whole volume as a single chunk is more optimal than doing several chunks, so it is important to set the corresponding parameter to the size of the binned tomogram used for template matching.

3. Post-process resulting CC map to get particles table (coordinates + orientations)
  ```json
    ...
      "TemplateMatchingPostProcessing": {
          "cc_std": 2.5
      },
    ...
  ```

By default particles will be also cropped on-the-fly by Dynamo. If you want particles to be reconstructed by SUSAN instead of cropping them by Dynamo, you have to add parameter value `"use_SUSAN": true` to the `"TemplateMatchingPostProcessing"` section. However, if you do not want particles to be cropped at all, you have to add parameter value `"crop_particles": false` to the `"TemplateMatchingPostProcessing"` section. For more detailed instructions on particles generation procedure please refer to the **"Particles generation"** section below.

### Neural network-based particles picking

Another way to pick particles using `TomoBEAR` workflow is to use `crYOLO` - DL framework for particles coordinates prediction. `TomoBEAR` interface includes such `crYOLO` routines as preprocessing (config file preparation, filtering), training and prediction.

#### Train data preparation

For the train data preparation we recommend you to follow the original `crYOLO` tutorial on data preparation for [tomographic data crYOLO predictions](https://cryolo.readthedocs.io/en/stable/tutorials/tutorial_overview.html#tutorial-5-pick-particles-in-tomograms) (follow **Step 1. Data preparation**).

#### Preprocessing and training

After you created the needed training set of tomograms and corresponding annotations, you need to create the input configuration file. As well, it is highly recommended to filter tomograms in order to increase contrast and remove high-resolution noise, although it is an optional step. Both configuration and filtering are set up in one configuration subblock `"config"` along with the following training subblock `"train"` of the `"crYOLO"` configuration block of the input JSON configuration file, like in the example provided below:

```json
...
    "crYOLO": {
        "tomograms_to_use": [x,xx,xxx],
        "cryolo_env": "cryolo",
        "steps_to_execute": {
            "config": {
                "target_boxsize": xx,
                "filter": "LOWPASS",
                "low_pass_cutoff": 0.3,
                "train_mode": true,
                "tomograms_binning": 8,
                "train_annot_folder": "/path/to/dir/with/train/boxfiles"
            },
            "train": {
                "num_cpu": 10
            }
        }
    },
...
```

First of all, note that the `"config"` section of the example crYOLO step configuration section above contains `"train_mode": true` which indicates that configuration file is prepared for the train dataset (default is `false`).

The `"target_boxsize"` parameter should be filled with the size of the box encapsulating target molecule in annotations prepared for training.

The `"filter"` parameter controls whether the train tomograms will be filtered and the name of the filter to be used. Following the [original crYOLO convention and tutorial](https://cryolo.readthedocs.io/en/stable/tutorials/tutorial_overview.html#configuration), there are three types of values for this parameter:
* **"NONE"** - do not use any of the available filters (described below);
* **"LOWPASS"** - use low-pass filter (additional parameter `"low_pass_cutoff"` regulates low-passing threshold);
* **"JANNI"** - use JANNI denoising network: [pre-trained general model](https://sphire.mpg.de/wiki/doku.php?id=janni#janni_general_model) (additional parameter `"janni_model_path"` is for path to the pre-trained general model).

In order to set the data to be used for training you may use the following parameters:
* `"train_annot_folder"` - path to the folder with annotation data for training (e.g. obtained via napari boxmanager plugin, as suggest by crYOLO authors)
* `"tomograms_binning"` - regulates binning of the tomograms to be used for training;

By default, crYOLO module in TomoBEAR uses CTF-corrected tomograms of the binning level, corresponding to the `"tomograms_binning"` parameter value. However, it is better to increase/enhance contrast of the training dataset, because in that case prediction of target objects is more stable against false-positive picking of contamination, gold and empty membranes for noisy datasets. That is why usage of filters above is highly recommended. However, if you want to use tomograms enhanced/pre-processed by other method (for example, deconvolved or MW-restored by IsoNet), you may use parameter `"train_tomograms_path"` to set up path to the corresponding pre-processed tomograms.

Section `"config"` is followed by section `"train"` to setup all the needed training parameters.

The basic training setup is done and at this point `TomoBEAR` can be launched to train `crYOLO` model overnight.

#### Predict particles positions

After you got or trained by yourself `crYOLO` model, you may proceed to the prediction phase configuration. The example configuration file to obtain crYOLO particle coordinates predictions you may find below:
```json
...
    "crYOLO": {
        "tomograms_to_use": [x,xx,xxx],
        "cryolo_env": "cryolo",
        "steps_to_execute": {
            "config": {
                "target_boxsize": xx,
                "filter": "LOWPASS",
                "low_pass_cutoff": 0.3
            },
            "predict": {
                "trained_model_filepath": "/path/to/trained/cryolo_model.h5",
                "tomograms_binning": 8,
                "num_cpu": 10
            }
        }
    },
...
```
The structure is similar to the training stage: you need to prepare the configuration file by `"config"` and then use configuration subsection `"predict"`, setting up `"trained_model_path"` parameter value to obtain the particles positions as COORD or CBOX files. By default, as in the training section, the CTF-corrected tomograms on the corresponding binning level will be used as test tomograms for predictions. However, if you have need to provide alternative tomograms location (e.g. if you used this alternative location for training), you may set up additinoal parameter for the `"predict"` subsection called `"test_tomograms_path"`.

Finally, to extract Dynamo-like particles table per each tomogram and for all tomograms together, you need to use the `"export_annotations"` subsection of the crYOLO module configuration as below:

```json
...
    "crYOLO": {
        "cryolo_env": "cryolo",
        "steps_to_execute": {
            "export_annotations": {
                "raw_prtcl_coords_dir": "/path/to/predict_annot/COORDS"
            }
        }
    },
...
```

### Manual particles picking

In case template matching or NN-based solution cannot be used in a particular project, you may want to try manual picking procedure.

Currently we do not directly integrate manual particles picking to TomoBEAR projects, but as a workaround user may use ``"StopPipeline"`` module after ``"Reconstruction"`` step to pause processing, pick particles manually, put or soft-link `Dynamo`-like table with picked particles coordinates and orientations in the `particles_table` folder in the project's processing folder and resume processing.

## Particles generation

In `TomoBEAR` particles could be generated by one of the following modules:
* directly using `"GenerateParticles"`
* automatically after template matching by the `"TemplateMatchingPostProcessing"`
* automatically between alignment/classification projects by the `"DynamoAlignmentProject"`

In each case for automated particles generation you may choose one of the following tools to be used:
- `Dynamo` - in this case particles will be cropped from CTF-corrected tomograms;
- `SUSAN` - in this case particles will be reconstructed from individually CTF-corrected sub-stacks which were cropped from aligned non-CTF-corrected tilt stacks.

By default `TomoBEAR` is using `Dynamo` for particles generation. In order to use `SUSAN`-base particles reconstruction add ``"use_SUSAN": true`` in particles-producing module of your choice (`"GenerateParticles"`, `"DynamoAlignmentProject"`, `"TemplateMatchingPostProcessing"`) in your input JSON file. As well, for those steps you may want to change the following `SUSAN` parameters default values:

```json
  "ctf_correction_method": "defocus_file",
  "susan_padding": 200,
  "per_particle_ctf_correction": "phase_flip",
  "padding_policy": "zero",
  "normalization": "zm"
```

Please, remember that `SUSAN` needs non-CTF-corrected aligned stacks to be generated using `"BinStacks"` before the corresponding particles-generating modules will be used:
```json
...
  "BinStacks": {
    "binnings": [2, 4, 8],
    "use_ctf_corrected_aligned_stack": false,
    "use_aligned_stack": true
  },
...
```

As well, you may divide particles into so-called boxes (`Dynamo` dboxes-like batches) using ``"as_boxes": true`` (which is default) in ``"general"`` section of your JSON file:
- `Dynamo`: batch size is permanent and equal to 1000 prtcs/batch;
- `SUSAN`: batch size can be set by changing ``"susan_particles_batch"`` parameter default value (1000 prts/batch) in ``"general"`` section of an input JSON file.

## Live data processing

**This is an experimental feature.**

You may try out our new feature of the live data processing as it comes from the microscope! The main goal is to screen sample quality, e.g. identify presence of your molecular target in the sample. Main prerequisite for live data processing using `TomoBEAR` is an availability for `TomoBEAR` to access the data folder where collected files are appearing.

Currently, we have implemented "live" data processing for single-shot data collection mode. In this mode tilt series are processed as they are collected in the sequential order. User needs to add two additional parameters to the input JSON file in the ``"general"`` section:
- `"minimum_files"` - number of files needed to consider tilt serie to be fully collected and subjected to processing (default: 15);
- `"listening_time_threshold_in_minutes"` - threshold for a period of time passed from the latest arrived file of a tilt serie upon which that tilt serie would be considered as a fully collected and subjected to processing irregarding of the number of collected files (default: 15 [min]).

To reduce processing time in the live mode we have additionally implemented option of a simple summation of dose-fractioned movie frames into corresponding tilt images instead of the full motion correction procedure. Corresponding example of the JSON file for live data processing setup is provided below:

```json
{
    "general": {
        "project_name": "your_project_name",
        "project_description": "your project name description",
        "data_path": "/path/to/live/data/folder/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "aligned_stack_binning": 8,
        "pre_aligned_stack_binning": 8,
        "reconstruction_thickness": xxxx,
        "as_boxes": false,
        "minimum_files": 41,
        "ft_bin": 2,
        "listening_time_threshold_in_minutes": 10
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
        "method": "SumOnly",
        "execution_method": "sequential"
    },
    "CreateStacks": {
    },
    "DynamoTiltSeriesAlignment": {
        "use_newstack_for_binning": true
    },
    "DynamoCleanStacks": {
    },
    "BatchRunTomo": {
        "skip_steps": [4, 7, 9],
        "ending_step": 13
    },
    "BinStacks": {
    },
    "Reconstruct": {
        "generate_exact_filtered_tomograms": true,
        "exact_filter_size": xxxx
    }
}
```
Since live data processing mainly serves for sample quality check, in order to additionally reduce processing times we would advice to use the following setup (as in the example provided above):
- set `"ft_bin"` to at least 2 to pre-bin views (summarized/motion-corrected dose-fractionated movies) of pre-processed stack for all subsequent modules;
- use high binning values for `"pre_aligned_stack_binning"` and `"aligned_stack_binning"` parameters (e.g. 8 as above) and enabling `"use_newstack_for_binning"`.

In order to improve contrast in reconstructions we would recommend to enable `"generate_exact_filtered_tomograms"` and setup `"exact_filter_size"` to define filter to be used to produce contrast-enhanced reconstructions.

If you start collection from zero-tilt, to avoid problems of files perception and sorting caused by `-0.0`/`+0.0` appearing as the angle for untilted views (due to small initial tilting offset being present) instead of expected `0.0` it is also recommended to add `"first_tilt_angle": 0` to `general` section of your input JSON file.

## Executing the workflow

After you have generated an appropriate JSON file for your project you may start the processing. There are several different execution strategies which are described further in the following chapters.

### Local Execution (Offline)

To execute the workflow, you need to start MATLAB from the TomoBEAR cloned code folder using

```shell
./run_matlab.sh
```

and then you need to type in the MATLAB command window:

```matlab
    runTomoBear("local", "/path/to/project/input.json", "/path/to/defaults.json")
```

To run a workflow using a standalone TomoBEAR version, you need to go into the TomoBEAR cloned code folder (which should also contain executable `TomoBEAR`) and to run in the shell the following command:

```shell
    ./TomoBEAR local /path/to/project/input.json /path/to/defaults.json
```

This action assumes you have already configured everything according to the section [[ Standalone (Installation and Setup) | https://github.com/KudryashevLab/TomoBEAR/wiki/Installation-and-Setup#standalone ]].

### Local Execution (Live)

**This is an experimental feature!**

To start `TomoBEAR` execution in live mode user need to type in the MATLAB command window:
```matlab
    runTomoBear("local_live", "/path/to/input.json", "/path/to/defaults.json")
```

### SLURM Execution

For the execution of the workflow on a cluster you need to adjust the
following keys in the general section:

Set the value for the key `"slurm_partition"` to decide on which cluster
partition the should run. Be sure to use a partition where the nodes
have GPUs installed.

-   `"slurm_partition": "partition"`

If you want to limit the processing to a set of specific nodes to be
nice to others so you leave some nodes for them for processing you need
to set the value for the key "slurm_node_list".

-   `"slurm_node_list": ["node1", "node2", "node3"]`

To execute the workflow you just need to type the following command in the shell if you are using the compiled version of tomoBEAR

```shell
    ./run_tomoBEAR.sh slurm /path/to/project.json /path/to/defaults.json
```

Or type the following command in the command window of MATLAB if you are using tomoBEAR from within MATLAB

```matlab
    runTomoBear("slurm", "/path/to/project.json", "/path/to/defaults.json");
```


### Cleanup
#### Since 24-Nov-2022

To delete intermediate files in the `TomoBEAR` project folder you may use one of the following clean-up modes:
- `cleanup` - in this case intermediate files will be deleted **only for those** processing steps where is used flag `"keep_intermediates": false`;
- `cleanup_all` - in this case intermediate files will be deleted **for all** processing steps **except for those** where is used flag `"keep_intermediates": true`.

If `"keep_intermediates": false` is used for some step, the corresponding files to be deleted are provided in the table below.

| Processing step   | Files to be deleted           |
|:------------------|:------------------------------|
|**MotionCor2**     |___\*.mrc___ from **SortFiles**<br>gain file(s) from **MotionCor2**|
|**CreateStacks**     |___\*.mrc___ from **MotionCor2**|
|**DynamoCleanStacks**     |___\*_norm.mrc___ from **CreateStacks**<br>___*.AWF/___ from **DynamoTiltSeriesAlignment**|
|**GCTFCtfphaseflipCtfCorrection**     |___slices/___ from **GCTFCtfphaseflipCtfCorrection**|

If user utilizes `cleanup_all` mode, deletion of all provided above files and folders may already save up to 30% of space initially occupied by the project folder.

##### Example 1
Let's consider you want to perform cleanup **only for** intermediate files associated with the step **MotionCor2** (i.e. delete files-folders listed in line 1 in the table above). Corresponding example of the JSON file for that cleanup setup is provided below:

```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/folder/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "aligned_stack_binning": 8,
        "pre_aligned_stack_binning": 8,
        "reconstruction_thickness": xxxx
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
        "keep_intermediates": false
    },
    "CreateStacks": {
    },
    "DynamoTiltSeriesAlignment": {
    },
    "DynamoCleanStacks": {
    },
    "BatchRunTomo": {
        "skip_steps": [4],
        "ending_step": 6
    },
    "StopPipeline": {
    },
    "BatchRunTomo": {
        "starting_step": 8,
        "ending_step": 8
    },
    "GCTFCtfphaseflipCTFCorrection": {
    },
    "BatchRunTomo": {
        "starting_step": 10,
        "ending_step": 13
    },
    "BinStacks": {
    },
    "Reconstruct": {
    }
}
```

which you have to run using the following command in the MATLAB command window:

```matlab
    runTomoBear("cleanup", "/path/to/project.json", "/path/to/defaults.json");
```

or in the shell using the following command:

```shell
    ./run_tomoBEAR.sh cleanup /path/to/project.json /path/to/defaults.json
```

##### Example 2
Let's consider you want to perform cleanup **for all** intermediate files **except for** those which are associated with the step **GCTFCtfphaseflipCTFCorrection** (i.e. delete files/folders listed in lines 1-3 in the table above). Corresponding example of the JSON file for that cleanup setup is provided below:


```json
{
    "general": {
        "project_name": "your project name",
        "project_description": "your project name description",
        "data_path": "/path/to/data/folder/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "Cx",
        "gold_bead_size_in_nm": xx,
        "rotation_tilt_axis": xx,
        "aligned_stack_binning": 8,
        "pre_aligned_stack_binning": 8,
        "reconstruction_thickness": xxxx
    },
    "MetaData": {
    },
    "SortFiles": {
    },
    "MotionCor2": {
    },
    "CreateStacks": {
    },
    "DynamoTiltSeriesAlignment": {
    },
    "DynamoCleanStacks": {
    },
    "BatchRunTomo": {
        "skip_steps": [4],
        "ending_step": 6
    },
    "StopPipeline": {
    },
    "BatchRunTomo": {
        "starting_step": 8,
        "ending_step": 8
    },
    "GCTFCtfphaseflipCTFCorrection": {
        "keep_intermediates": true
    },
    "BatchRunTomo": {
        "starting_step": 10,
        "ending_step": 13
    },
    "BinStacks": {
    },
    "Reconstruct": {
    }
}
```

which you have to run using the following command in the MATLAB command window:

```matlab
    runTomoBear("cleanup_all", "/path/to/project.json", "/path/to/defaults.json");
```

or in the shell using the following command:

```shell
    ./run_tomoBEAR.sh cleanup_all /path/to/project.json /path/to/defaults.json
```

#### Before 24-Nov-2022

If the later described **keep_intermediates** flag is set during the
processing of a project to true you can cleanup the not needed
intermediate data afterwards if you run the following command.

Files that are kept are

-   tilt stacks
-   binned tilt stacks
-   ctf corrected tilt stacks
-   ctf corrected binned tilt stacks
-   aligned tilt stacks
-   binned aligned tilt stacks
-   ctf corrected aligned tilt stacks
-   ctf corrected binned aligned tilt stacks
-   tomograms
-   binned tomograms
-   ctf corrected tomograms
-   ctf corrected binned tomograms
-   batchruntomo related files (\*.rawtlt, \*.tlt, \*.xf, \*.ali)
-   particles with different binnings
-   particles table
-   some small tomoBEAR related files

all other files are removed.

Here is the shell command which you need to run in this form from the command line if you use a compiled version

```shell
    ./run_tomoBEAR.sh cleanup /path/to/project.json /path/to/defaults.json
```

If you use MATLAB for the execution of `TomoBEAR` you need to type the following statement in the command window of MATLAB

```matlab
    runTomoBear("cleanup", "/path/to/project.json", "/path/to/defaults.json");
```
