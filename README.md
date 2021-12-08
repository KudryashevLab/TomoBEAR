# TomoBEAR
TomoBEAR is an configured automated full processing pipeline for tomographic cryo electron microscopy data in the field of CryoEM based on best practices in the scientific research group of [Misha Kudryashev](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR).

In the following picture you can see a flow chart which visualizes which steps TomoBEAR will and can do for you in an automated and parallel manner. TomoBEAR supports single nodes with GPUs as also copmuter clusters through a queue manager like SLURM or SGE (Sun Grid Engine) at the moment.

Note that it is not needed to start from raw data but you can also use already assembled tilt stacks if you provide the angular information.

![Schematic Pipeline Image Light Mode](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/pipeline_light_mode.svg#gh-light-mode-only)
![Schematic Pipeline Image Dark Mode](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/pipeline_dark_mode.svg#gh-dark-mode-only)
 
Orange processing steps in the flow chart are mandatory and must be executed by TomoBEAR. Yellow boxes are optional and can be activated if desired.

## Results

# Contacts

[Nikita Balyschew](mailto:nikita.balyschew@gmail.com?subject=[GitHub]%20TomoBEAR)
