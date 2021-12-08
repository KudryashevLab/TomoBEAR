# TomoBEAR
TomoBEAR is an configured automated full processing pipeline for tomographic cryo electron microscopy data in the field of CryoEM based on best practices in the scientific research group of [Misha Kudryashev](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR).

In the following picture you can see a flow chart which visualizes which steps TomoBEAR will and can do for you in an automated and parallel manner. TomoBEAR supports single nodes with GPUs and also copmuter clusters through a queue manager like Slurm or SGE (Sun Grid Engine) at the moment.

Note that it is not needed to start from raw data but you can also use already assembled tilt stacks if you provide the angular information.

![Schematic Pipeline Image Light Mode](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/pipeline_light_mode.svg#gh-light-mode-only)
![Schematic Pipeline Image Dark Mode](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/pipeline_dark_mode.svg#gh-dark-mode-only)
 
Orange processing steps in the flow chart are mandatory and must be executed by TomoBEAR. Yellow boxes are optional and can be activated if desired.

# Results (preliminray)

All results shown here have been achieved in an automated manner. The only manual task which needed to be done is chosing the classes for further processing in between the transition of different binning levels.

## EMPIAR-10064

On the EMPIAR-10064 dataset TomoBEAR achieved 11.52 Angstrom as can be seen below.

![Ribosome EMPIAR-10064 Map](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/ribosome_empiar_10064_map.png)
![Ribosome EMPIAR-10064 FSC](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/ribosome_empiar_10064_fsc.png)

## EMPIAR-10164

On the EMPIAR-10164 dataset TomoBEAR achieved 4.47 Angstrom as can be seen below.

![HIV EMPIAR-10064 Map 1](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/hiv_empiar_10164_map_1.png)
![HIV EMPIAR-10064 Map 2](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/hiv_empiar_10164_map_2.png)
![HIV EMPIAR-10064 FSC](https://github.com/KudryashevLab/TomoBEAR/blob/main/images/hiv_empiar_10164_fsc.png)

# Acknowledgements

Many thanks to [Misha Kudryashev](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR) for giving the opportunity to work in such an interesting field.

Many thanks to [Vaisli Mikirtumov](mailto:mikivasia@gmail.com?subject=[GitHub]%20TomoBEAR) for untired testing, reporting of bugs and improvement suggestions.

Many thanks to the Buchmann family and [BMLS (Buchmann Institute for Molecular Life Sciences)](https://www.bmls.de) for supporting this project with their starters stipendia for PhD students.

Many thanks to the [DFG (Deutsche Forschungsgesellschaft)](https://www.dfg.de) for funding the project.

Many thanks to the [Max Planck Institute of Biophysics](https://www.biophys.mpg.de) in Hesse in Frankfurt for support.

Many thanks to the Kudryashev scientific research group established in 2021 at the [MDC (Max-Delbrück-Center for Molecular Medicine)](https://www.biophys.mpg.de) in Berlin for testing and reporting of bugs.

# Contacts
[Misha Kudryashev (Principal Investigator)](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR)

[Nikita Balyschew (Developer)](mailto:nikita.balyschew@gmail.com?subject=[GitHub]%20TomoBEAR)

[Vaisli Mikirtumov (Application Engineer)](mailto:mikivasia@gmail.com?subject=[GitHub]%20TomoBEAR)
