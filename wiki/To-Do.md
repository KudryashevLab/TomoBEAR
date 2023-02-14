This page contains a collection of useful ideas and improvements to further facilitate processing. Please send us your ideas to mikhail.kudryashev at mdc-berlin.de

# Mdoc-Files

Mdoc-Files which are created by SerialEM contain a bunch of useful information. Therefore it is a good idea to make the most useful information from mdoc-files in the global configuration structure at best at the tomogram level available. As the tomogram acquisition schemes get more and more sophisticated it is good idea to capture the frame-dose and the frame count e.g. to parametrize later the parameters of MotionCor2 to properly dose weight the projections.

There are two different formats of mdoc-files. The first format contains all the information for every projection in a single file whereas the other format contains all the information per project per file.

# CryoCARE

The CryoCARE module is a neural net based denoising framework. Beacuse it is a probabilistic

# Template Matching

Chose a binning level for template matching based on heuristics. If the GPU memory and performance grows further in the future it can be thought of incorporating this into the heuristics for chosing the proper binning level.

# Stack Binning

The process to generate binned stacks can be for some users confusing as you need to know when to generate them to save storage in the beginning of processing, at which binnings they need to be generated and what operations should be applied on them e.g. CTF correction or denoising.

# GUI

A web-based GUI will prove advantageous for workflow visualization and analysis of intermediate processing steps.