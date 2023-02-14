Here you can find frequently asked questions which appear from time to time when you process data with `TomoBEAR`:

1. What can I do if `TomoBEAR` outputs `out of memory` error during execution of the module `DynamoTiltSeriesAlignment`?
* If you are running the module in parallel execution mode set the parameter `"execution_method"` in the `DynamoTiltSeriesAlignment` block to `"sequential"`. Then the execution will be slower because only one tilt stack will be processed at a time but the memory consumption will be less.

2. What can I do if `TomoBEAR` outputs `out of memory` error during execution of the module `DynamoAlignmentProject`?
* This usually happens at low binning values (e.g., bin2 or bin1). You may put additional parameter `"dt_crop_in_memory": 0` to the corresponding `DynamoAlignmentProject` sections in order to prevent keeping the whole tomogram in the memory during processing. This will slow down processing because `Dynamo` will read tomogram volume several times but the memory consumption will be less.

3. What can I do if `TomoBEAR` sorting files wrong for data collected using dose-symmetric scheme starting from 0-deg-tilt because my raw data files contain both `0.0` and `-0.0` tilts? For example, `TS_001_0.0_Sep07_19.38.12.tif` and `TS_002_-0.0_Sep07_19.52.42.tif`.
* This happens because physically zero angles are not ideally equal to zero, they are just very small (e.g., -0.0049795). To make sorting right in the described case you may add `"first_tilt_angle": 0` to `general` section of your input JSON file. 
