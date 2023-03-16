# TomoBEAR Configuration

If you followed the instructions thoroughly then you should have a
working copy of the TomoBEAR. Now you need to generate a JSON file for your
project to start to process your acquired cryo-ET data.

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

### Overcoming Input Data Perception Issues

The possible naming schemes for input data coming from SerialEM and defined above EER naming pattern should be all well-covered by our default regular expressions. Nevertheless, you may fine-tune your data perception by using the following parameters, if necessary:
- ```<KEY>_position``` where ```<KEY>``` could be ```prefix```, ```tomogram_number```, ```tilt_number```, ```angle```, ```date``` or ```time``` - this set of parameters directly controls recognition of the corresponding information by counting positions between underscores ```_``` in filenames and associating the extracted sub-strings with the corresponding keys;
- ```<KEY>_regex``` where ```<KEY>``` could be ```angle```, ```name```, ```number```, ```name_number``` or ```month_date``` - this set of parameters is more general and better tunable, it controls recognition of the corresponding information by regular expressions.

**In case your input data have more than one TS prefix**, separated by an underscore '_', and you experience issues with TomoBEAR filenames perception, we would recommend you to make symbolic links to the original raw data with a single TS prefix.
An example bash script ```softlink_files.sh``` to change prefix for all files of a single tilt serie in ```TIF``` data format is provided below:
```bash
prefix_to_cut=${1}
prefix_to_put=${2}
dir_data_raw=$(readlink -f ./${3})
dir_data_links=$(readlink -f ./${4})

for file_tif_old in ${dir_data_raw}/${prefix_to_cut}*.tif ; do
        file_tif_trunc=${file_tif_old#*${prefix_to_cut}}
        file_mdoc_old=${file_tif_old}.mdoc
        file_tif_new=${dir_data_links}/${prefix_to_put}$file_tif_trunc
        file_mdoc_new=${file_tif_new}.mdoc
        echo 'Linking ' $file_tif_old ' to ' $file_tif_new
        ln -s $file_tif_old $file_tif_new
        echo 'Linking ' $file_mdoc_old ' to ' $file_mdoc_new
        ln -s $file_mdoc_old $file_mdoc_new
done
```
You may use the script above ```softlink_files.sh``` to rename input data as softlinks to original files as the following:
```bash
softlink_files.sh PREFIX1_PREFIX2_PREFIX3_ PREFIXNEW_ original/dir/path renamed/dir/path
```
where for each ```TIF``` file in the location ```original/dir/path``` a set of prefixes ```PREFIX1_PREFIX2_PREFIX3_``` will be substituted with a single prefix ```PREFIXNEW_``` and softlinks with the new filenames to the corresponding original files will be saved in the ```renamed/dir/path``` directory.  

## JSON Configuration Templates

### Raw Tomography Data with Fiducials

To process tomogrpahy data with fiducials the following template should
be used as configuration for the pipeline:
<details>
<summary><b> Example of full JSON file to process raw tomography data with fiducials (expand to see).</b></summary>

```json
    {
        "general": {
            "project_name": "your project name",
            "project_description": "your project name description",
            "data_path": "/path/to/data/prefix*.mrc",
            "processing_path": "/path/to/processing/folder",
            "expected_symmetrie": "Cx",
            "template_matching_binning": xx,
            "gold_bead_size_in_nm": xx,
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
            "reconstruct": "binned"
        },
        "DynamoImportTomograms": {
        },
        "EMDTemplateGeneration": {
            "template_emd_number": "xxxx",
            "template_bandpass_cut_off_resolution_in_angstrom": 20
        },
        "DynamoTemplateMatching": {
            "size_of_chunk": [512, 720, 500],
            "sampling": 15
        },
        "TemplateMatchingPostProcessing": {
            "parallel_execution": false,
            "cc_std": 2.5,
            "crop_particles": true
        }
    }
```
</details>
</br>

For some projects there are more sophisticted features available which can be switched on or fine tuned if needed.

### Raw Tomography Data without Fiducials

To process tomogrpahy data without fiducials (for example, focused ion-beam milling data) user have the following options for fiducial-free alignment:
- BatchRunTomo-based (IMOD) patch tracking and alignment;
- AreTomo-based features tracking and alignment.

<details>
<summary><b> BatchRunTomo-based (IMOD) template of JSON file to process raw tomogrpahy data without fiducials (expand to see).</b></summary>

```json
    {
        "general": {
            "project_name": "fibmil project",
            "project_description": "fibmil project description",
            "data_path": "/path/to/data/prefix*.tif",
            "processing_path": "/path/to/processing/folder",
            "gain": "/path/to/gain.mrc",
            "dark": "/path/to/dark.mrc",
            "expected_symmetrie": "Cx",
            "template_matching_binning": xx,
            "reconstruction_thickness": xxxx,
            "rotation_tilt_axis": xx,
            "aligned_stack_binning": x,
            "pre_aligned_stack_binning": x,
            "binnings": [x, x, xx],
            "tilt_scheme": "bi_directional",
            "tilt_angles": [-9, -6, -3, 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, -12, -15, -18, -21, -24, -27, -3033, -36, -39, -42, -45, -48, -51, -54, -57, -60]
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
            "starting_step": 0,
            "ending_step": 8,
            "directives": {
                "runtime.Fiducials.any.trackingMethod": 1,
                "comparam.xcorr_pt.tiltxcorr.SizeOfPatchesXandY": "512,512",
                "comparam.xcorr_pt.tiltxcorr.IterateCorrelations": 100,
                "runtime.PatchTracking.any.adjustTiltAngles": 0,
                "runtime.AlignedStack.any.eraseGold": 0,
                "runtime.Positioning.any.hasGoldBeads": 0,
                "comparam.xcorr_pt.tiltxcorr.FilterRadius2": 0.3,
                "comparam.xcorr_pt.tiltxcorr.FilterSigma2": 0.4,
                "comparam.xcorr_pt.tiltxcorr.OverlapOfPatchesXandY": "0.5,0.5"
            }
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
            "reconstruct": "binned"
        },
        "StopPipeline": {
        },
        "DynamoImportTomograms": {
        },
        "EMDTemplateGeneration": {
            "template_emd_number": "xxxx",
            "template_bandpass_cut_off_resolution_in_angstrom": 20
        },
        "DynamoTemplateMatching": {
            "sampling": 15
        },
        "TemplateMatchingPostProcessing": {
            "cc_std": 2.5,
            "crop_particles": true
        }
    }
```
</details>
</br>

For AreTomo usage case there is global alignment implemented in the pipeline as of ```TomoBEAR-v0.1.2```. In the future releases we are planning to enable as well local alignment procedure as well as AreTomo-based reconstructions.

<details>
<summary><b> AreTomo-based template of JSON file to process raw tomogrpahy data without fiducials (expand to see).</b></summary>

```json
  {
    "general": {
        "project_name": "fibmil project",
        "project_description": "fibmil project description",
        "data_path": "/path/to/data/prefix*.tif",
        "processing_path": "/path/to/processing/folder",
        "gain": "/path/to/gain.mrc",
        "dark": "/path/to/dark.mrc",
        "expected_symmetrie": "Cx",
        "template_matching_binning": xx,
        "reconstruction_thickness": xxxx,
        "rotation_tilt_axis": xx,
        "aligned_stack_binning": x,
        "binnings": [x, x, xx],
        "tilt_angles": [-9, -6, -3, 0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, -12, -15, -18, -21, -24, -27, -3033, -36, -39, -42, -45, -48, -51, -54, -57, -60]
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
    "StopPipeline": {
    },
    "GCTFCtfphaseflipCTFCorrection": {
        "run_ctf_phase_flip": true
    },
    "BinStacks": {
    },
    "Reconstruct": {
    }
  }
```
</details>

### Tilt Stacks with Fiducials

If you want to process already assembled tilt stacks with `TomoBEAR` you
need to provide the tilt angles in the order in which they apear in the
tilt stacks.
<details>
<summary><b> Example of full JSON file to process assembled tilt stacks with fiducials (expand to see).</b></summary>

```json
    {
        "general": {
            "project_name": "Ribosome",
            "project_description": "Ribosome Benchmark",
            "data_path": "/sbdata/PTMP/nibalysc/ribosome/data/*.mrc",
            "processing_path": "/sbdata/PTMP/nibalysc/ribosome",
            "expected_symmetrie": "C1",
            "tilt_scheme": "bi_directional",
            "apix": 2.62,
            "tilt_angles": [-60.0, -58.0, -56.0, -54.0, -52.0, -50.0, -48.0, -46.0, -44.0, -42.0, -40.0, -38.0, -36.0, -34.0, -32.0, -30.0, -28.0, -26.024.0, -22.0, -20.0, -18.0, -16.0, -14.0, -12.0, -10.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 0, 24.0, 26. , 28.0, 30.0, 32.0, 34.0, 36.0, 38.0, 40.0, 42.0, 44.0, 46.0, 48.0, 50.0, 52.0, 54.0, 56.0],
            "gold_bead_size_in_nm": 9

        },
        "MetaData": {
        },
        "CreateStacks": {
            "execution_method": "sequential"
        },
        "DynamoTiltSeriesAlignment": {
            "execution_method": "sequential"
        },
        "DynamoCleanStacks": {
        },
        "BatchRunTomo": {
            "skip_steps": [4],
            "ending_step": 6
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
        },
        "DynamoImportTomograms": {
        },
        "EMDTemplateGeneration": {
            "template_emd_number": "3420"
        },
        "DynamoTemplateMatching": {
        },
        "TemplateMatchingPostProcessing": {
        },
        "DynamoAlignmentProject": {
            "iterations": 3,
            "classes": 4,
            "use_symmetrie": false,
            "use_noise_classes": true
        },
        "DynamoAlignmentProject": {
            "iterations": 3,
            "classes": 4,
            "use_noise_classes": true,
            "use_symmetrie": false,
            "selected_classes": [1]
        },
        "DynamoAlignmentProject": {
            "iterations": 3,
            "classes": 4,
            "use_noise_classes": true,
            "use_symmetrie": false,
            "selected_classes": [1]
        },
        "BinStacks": {
            "use_ctf_corrected_aligned_stack": false,
            "binnings": [2, 4, 8]
        },
        "DynamoAlignmentProject": {
            "classes": 1,
            "iterations": 1,
            "use_noise_classes": false,
            "swap_particles": false,
            "use_symmetrie": false,
            "selected_classes": [1],
            "as_boxes": true,
            "use_SUSAN": true,
            "binning": 8,
            "threshold":0.75
        },
        "DynamoAlignmentProject": {
            "classes": 1,
            "iterations": 1,
            "use_noise_classes": false,
            "swap_particles": false,
            "use_symmetrie": false,
            "selected_classes": [1,2],
            "as_boxes": true,
            "use_SUSAN": true,
            "binning": 4,
            "threshold":0.75
        },
        "DynamoAlignmentProject": {
            "classes": 1,
            "iterations": 1,
            "use_noise_classes": false,
            "swap_particles": false,
            "use_symmetrie": false,
            "selected_classes": [1,2],
            "as_boxes": true,
            "use_SUSAN": true,
            "binning": 2,
            "threshold":0.75
        },
        "DynamoAlignmentProject": {
            "classes": 1,
            "iterations": 1,
            "use_noise_classes": false,
            "swap_particles": false,
            "use_symmetrie": false,
            "selected_classes": [1,2],
            "as_boxes": true,
            "use_SUSAN": true,
            "binning": 1,
            "threshold":0.75
        }
    }
```
</details>

## Particles generation options

In TomoBEAR particles are automatically generated either after template matching on the `"TemplateMatchingPostProcessing"` step and during alignment/classification projects on the `"DynamoAlignmentProject"` steps. As well, if template matching cannot be used in a particular project, user may use ``"StopPipeline"`` module after ``"Reconstruction"`` step to pause processing, pick particles manually, put `Dynamo`-like table with picked particles coordinates and orientations in the `particles_table` folder in project's processing folder and resume processing.

In `TomoBEAR` for automated particles generation you may choose one of the following tools to be used:
- `Dynamo` - in this case particles will be cropped from CTF-corrected tomograms;
- `SUSAN` - in this case particles will be reconstructed from individually CTF-corrected sub-stacks which were cropped from aligned non-CTF-corrected tilt stacks.

By default `TomoBEAR` is using `Dynamo` for particles generation. In order to use `SUSAN`-base particles reconstruction add ``"use_SUSAN": true`` in particles-producing steps (`"DynamoAlignmentProject"` and/or `"TemplateMatchingPostProcessing"`) of your input JSON file. As well, for those steps you may change the following `SUSAN` parameters default values:

```json
  "ctf_correction_method": "defocus_file",
  "susan_padding": 200,
  "per_particle_ctf_correction": "phase_flip",
  "padding_policy": "zero",
  "normalization": "zm"
```

Please, remember that `SUSAN` needs non-CTF-corrected aligned stacks to be generated using `"BinStacks"` before the corresponding particles-generating modules will be used:
```json
  "BinStacks": {
    "binnings": [2, 4, 8],
    "use_ctf_corrected_aligned_stack": false
  }
```

<details>
<summary><b> Example of full JSON file including SUSAN usage for particles generation for 80S ribosome dataset from tutorial (expand to see).</b></summary>

```json
{
    "general": {
        "project_name": "Ribosome",
        "project_description": "Ribosome EMPIAR 10064",
        "data_path": "/path/to/ribosome/data/*.mrc",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "C1",
        "apix": 2.62,
        "tilt_angles": [-60.0, -58.0, -56.0, -54.0, -52.0, -50.0, -48.0, -46.0, -44.0, -42.0, -40.0, -38.0, -36.0, -34.0, -32.0, -30.0, -28.0, -26.0, -24.0, -22.0, -20.0, -18.0, -16.0, -14.0, -12.0, -10.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 34.0, 36.0, 38.0, 40.0, 42.0, 44.0, 46.0, 48.0, 50.0, 52.0, 54.0, 56.0, 58.0, 60.0],
        "gold_bead_size_in_nm": 9,
        "template_matching_binning": 8,
        "reconstruction_thickness": 1400,
        "rotation_tilt_axis": -5,
        "as_boxes": false
    },
    "MetaData": {
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
    "StopPipeline": {
    },
    "BatchRunTomo": {
        "starting_step": 10,
        "ending_step": 13
    },
    "BinStacks": {
        "binnings": [8]
    },
    "Reconstruct": {
        "binnings": [8]
    },
    "DynamoImportTomograms": {
    },
    "EMDTemplateGeneration": {
        "template_emd_number": "3420",
        "flip_handedness": true
    },
    "DynamoTemplateMatching": {
    },
    "BinStacks": {
        "binnings": [2, 4, 8],
        "use_ctf_corrected_aligned_stack": false
    },
    "TemplateMatchingPostProcessing": {
        "cc_std": 2.5,
        "use_SUSAN": true,
        "susan_padding": 40
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_symmetrie": false,
        "use_noise_classes": true
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_symmetrie": false,
        "use_noise_classes": true,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 3,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1],
        "box_size": 1.10,
        "binning": 4,
        "use_SUSAN": true,
        "susan_padding": 40
    },
    "StopPipeline": {
    },
    "DynamoAlignmentProject": {
        "classes": 1,
        "iterations": 1,
        "use_noise_classes": false,
        "swap_particles": false,
        "use_symmetrie": false,
        "selected_classes": [1],
        "binning": 4,
        "threshold":0.8
    },
    "DynamoAlignmentProject": {
        "classes": 1,
        "iterations": 1,
        "use_noise_classes": false,
        "swap_particles": false,
        "use_symmetrie": false,
        "selected_classes": [1,2],
        "binning": 2,
        "threshold":0.9,
        "use_SUSAN": true,
        "susan_padding": 40
    },
    "BinStacks":{
        "binnings": [1],
        "use_ctf_corrected_aligned_stack": false
    },
    "DynamoAlignmentProject": {
        "classes": 1,
        "iterations": 1,
        "use_noise_classes": false,
        "swap_particles": false,
        "use_symmetrie": false,
        "selected_classes": [1,2],
        "binning": 1,
        "threshold": 1,
        "dt_crop_in_memory": 0,
        "dynamo_allow_padding": 0,
        "use_SUSAN": true,
        "susan_padding": 40
    }
}
```
</details>
</br>

As well, you may divide particles into so-called boxes (`Dynamo` dboxes-like batches) using ``"as_boxes": true`` (which is default) in ``"general"`` section of your JSON file:
- `Dynamo`: batch size is permanent and equal to 1000 prtcs/batch;
- `SUSAN`: batch size can be set by changing ``"susan_particles_batch"`` parameter default value (1000 prts/batch) in ``"general"`` section of an input JSON file.

<details>
<summary><b> Example of full JSON file including SUSAN usage for particles generation with packaging particles in Dynamo-like boxes for 80S ribosome dataset from tutorial (expand to see).</b></summary>

```json
{
    "general": {
        "project_name": "Ribosome",
        "project_description": "Ribosome EMPIAR 10064",
        "data_path": "/path/to/ribosome/data/*.mrc",
        "processing_path": "/path/to/processing/folder",
        "expected_symmetrie": "C1",
        "apix": 2.62,
        "tilt_angles": [-60.0, -58.0, -56.0, -54.0, -52.0, -50.0, -48.0, -46.0, -44.0, -42.0, -40.0, -38.0, -36.0, -34.0, -32.0, -30.0, -28.0, -26.0, -24.0, -22.0, -20.0, -18.0, -16.0, -14.0, -12.0, -10.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 34.0, 36.0, 38.0, 40.0, 42.0, 44.0, 46.0, 48.0, 50.0, 52.0, 54.0, 56.0, 58.0, 60.0],
        "gold_bead_size_in_nm": 9,
        "template_matching_binning": 8,
        "reconstruction_thickness": 1400,
        "rotation_tilt_axis": -5,
        "as_boxes": true,
        "susan_particle_batch": 2000
    },
    "MetaData": {
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
    "StopPipeline": {
    },
    "BatchRunTomo": {
        "starting_step": 10,
        "ending_step": 13
    },
    "BinStacks": {
        "binnings": [8]
    },
    "Reconstruct": {
        "binnings": [8]
    },
    "DynamoImportTomograms": {
    },
    "EMDTemplateGeneration": {
        "template_emd_number": "3420",
        "flip_handedness": true
    },
    "DynamoTemplateMatching": {
    },
    "BinStacks": {
        "binnings": [2, 4, 8],
        "use_ctf_corrected_aligned_stack": false
    },
    "TemplateMatchingPostProcessing": {
        "cc_std": 2.5,
        "use_SUSAN": true,
        "susan_padding": 40
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_symmetrie": false,
        "use_noise_classes": true
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_symmetrie": false,
        "use_noise_classes": true,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 4,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1]
    },
    "DynamoAlignmentProject": {
        "iterations": 3,
        "classes": 3,
        "use_noise_classes": true,
        "use_symmetrie": false,
        "selected_classes": [1],
        "box_size": 1.10,
        "binning": 4,
        "use_SUSAN": true,
        "susan_padding": 40
    },
    "StopPipeline": {
    },
    "DynamoAlignmentProject": {
        "classes": 1,
        "iterations": 1,
        "use_noise_classes": false,
        "swap_particles": false,
        "use_symmetrie": false,
        "selected_classes": [1],
        "binning": 4,
        "threshold":0.8
    },
    "DynamoAlignmentProject": {
        "classes": 1,
        "iterations": 1,
        "use_noise_classes": false,
        "swap_particles": false,
        "use_symmetrie": false,
        "selected_classes": [1,2],
        "binning": 2,
        "threshold":0.9,
        "use_SUSAN": true,
        "susan_padding": 40
    },
    "BinStacks":{
        "binnings": [1],
        "use_ctf_corrected_aligned_stack": false
    },
    "DynamoAlignmentProject": {
        "classes": 1,
        "iterations": 1,
        "use_noise_classes": false,
        "swap_particles": false,
        "use_symmetrie": false,
        "selected_classes": [1,2],
        "binning": 1,
        "threshold": 1,
        "dt_crop_in_memory": 0,
        "dynamo_allow_padding": 0,
        "use_SUSAN": true,
        "susan_padding": 40
    }
}
```
</details>

## Live data processing
**This is an experimental feature which is currently available only in development version under `develop_live` branch. Note that other `TomoBEAR` functionality in that brunch may differ from `main`.**

You may try out our new feature of the live data processing as it comes from the microscope! The main goal is to screen sample quality, e.g. identify presence of your molecular target in the sample. Main prerequisite for live data processing using `TomoBEAR` is an availability for `TomoBEAR` to access the data folder where collected files are appearing.

Currently, we have implemented "live" data processing for single-shot data collection mode. In this mode data is processed in "tilt serie by tilt serie" order. User needs to add two additional parameters to the input JSON file in the ``"general"`` section:
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

# Executing the Workflow

After you have generated an apropriate json file for your project you
may start the processing. There are several different execution strategies
which are described further in the following chapters.

## Local Execution (Offline)

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

## Local Execution (Live)
**This is an experimental feature which is currently available only in development version under `develop_live` branch. Note that other `TomoBEAR` functionality in that brunch may differ from `main`.**

To start `TomoBEAR` execution in live mode user need to type in the MATLAB command window:
```matlab
    runTomoBear("local_live", "/path/to/input.json", "/path/to/defaults.json")
```

## SLURM Execution

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


## Cleanup
### Since 24-Nov-2022

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

#### Example 1
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

#### Example 2
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

### Before 24-Nov-2022

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
