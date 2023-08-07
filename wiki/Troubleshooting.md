# Troubleshooting

Here you can find troubleshooting tips and workarounds for `TomoBEAR`.

### SUCESS and FAILURE control files

After processing each module `TomoBEAR` puts processing control files `SUCCESS` or `FAILURE` depending on the outcome of the whole processing step. Additionally, for the modules which process tomograms independently of each other in parallel manner (like `CreateStacks`, `MotionCor2`, `BatchRunTomo`, etc.), inside each tomogram's folder there will be as well `SUCCESS` or `FAILURE` depending on the outcome of the particular tomogram processing.

> **SUCCESS files contents**
> <br/>
The file `SUCCESS` contains bit (0/1) vector of the number of tomograms length with 0s or 1s meaning failure or success of processing for the corresponding tomogram so that successful ones will be used on the further processing steps. This might be useful to know when you need workaround if something is not working.  

If you want to reprocess some particular step(s) or even particular tomogram(s) on certain steps, you need to delete the corresponding `SUCCESS`/`FAILURE` files, before restarting `TomoBEAR`.

If for some reason you don't want to process further a certain tomogram, feel free to put in that tomogram's folder `FAILURE` file.

Finally, if you put "tomogram_indices" in `"general"` section of the input JSON file and `TomoBEAR` still processing all of the tomograms for steps where they are processed independently, you might try to delete `SUCCESS` files for couple of previous step folders (but not in tomograms folders and not for steps which don't have tomogram folders, otherwise they would be reprocessed), so that `TomoBEAR` will just update its metadata properly.

### Input Data Perception Issues

- **In case your input data was collected using dose-symmetric scheme starting from 0-deg-tilt**

If that is the case, the raw data files contain both `0.0` and `-0.0` tilts, for example, `TS_001_0.0_Sep07_19.38.12.tif` and `TS_002_-0.0_Sep07_19.52.42.tif`. This happens because physically zero angles are not ideally equal to zero, they are just very small (e.g., -0.0049795). To make sorting right in the described case you may add `"first_tilt_angle": 0` to `general` section of your input JSON file.

- **In case your input data have more than one TS prefix** (separated by an underscore '_')

We would recommend you to make symbolic links to the original raw data with a single TS prefix.
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

### ERROR `out of memory` (`DynamoTiltSeriesAlignment`):

If you are running the module in parallel execution mode set the parameter `"execution_method"` in the `DynamoTiltSeriesAlignment` block to `"sequential"`. Then the execution will be slower because only one tilt stack will be processed at a time but the memory consumption will be less.

### ERROR `out of memory` (`DynamoAlignmentProject`):

This usually happens at low binning values (e.g., bin2 or bin1). You may put additional parameter `"dt_crop_in_memory": 0` to the corresponding `DynamoAlignmentProject` sections in order to prevent keeping the whole tomogram in the memory during processing. This will slow down processing because `Dynamo` will read tomogram volume several times but the memory consumption will be less.
