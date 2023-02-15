# TomoBEAR
TomoBEAR is an automated, configurable and customizable full processing pipeline for tomographic cryo-electron microscopy data and subtomogram averaging in the broad field of Cryo-ET based on best practices in the scientific research groups of [Misha Kudryashev](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR):
- (previous one) [Independent Research Group (Sofja Kovaleskaja)](https://www.biophys.mpg.de/2149775/members) at the Department of Structural Biology at [MPIBP (Max Planck Institute of Biophysics)](https://www.biophys.mpg.de/en) in Frankfurt (Hesse), Germany;
- (current one) [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany.

## Documentation
Information on the installation, setup and usage and can be found in the corresponding [wiki](https://github.com/KudryashevLab/TomoBEAR/wiki).

## Repository structure
Branches:
- `main` - more or less stable version (*in a normal case use this one, please!*);
- `develop` - non-stable development version (*use this one only if you know what you are doing!*);
- other branches - new features, bug-fixes, etc (*those branches are under development, do not use them!*).

Time to time updates from `develop` are introduced in `main`, then the documentation (wiki) updates correspondingly! The list of major updates in `main` with corresponding dates is provided in the ["Updates" section on wiki](https://github.com/KudryashevLab/TomoBEAR/wiki/Updates).

In the future we are planning to introduce wiki versioning as well, stay tuned!

## Pipeline structure
In the following picture you can see a flow chart which visualizes which steps `TomoBEAR` will and can do for you in an automated and parallel manner. `TomoBEAR` supports single nodes with GPUs and also copmuter clusters through a queue manager like SLURM or SGE (Sun Grid Engine) at the moment.

Note that it is not needed to start from raw data but you can also use already assembled tilt stacks if you provide the angular information.

![Schematic Pipeline Image Light Mode](https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/pipeline_light_mode.svg#gh-light-mode-only)
![Schematic Pipeline Image Dark Mode](https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/pipeline_dark_mode.svg#gh-dark-mode-only)

Orange processing steps in the flow chart are mandatory and must be executed by TomoBEAR. Yellow boxes are optional and can be activated if desired.

## Feedback

In case of any questions or errors do not hesitate to contact one of the provided persons mentioned in the `Contacts` section below. Alternatively, for bug reports or feature suggestions you may use our [Issue Tracker](https://github.com/KudryashevLab/TomoBEAR/issues). Please, be polite and precise!

## Results example (the tutorial case)

The result shown here have been achieved in an automated manner. The only manual task which needed to be done is the choice of the classes for further processing in between the transition of different binning levels.

### EMPIAR-10064

On the EMPIAR-10064 dataset `TomoBEAR` achieved 11.25 Angstrom (with ~4k particles) as can be seen below on the FSC curve plot:
<p align="center">
<img src="https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/ribosome_empiar_10064_fsc.jpg" alt="Ribosome EMPIAR-10064 FSC"/>
</p>

As well, below is provided ribosome final map view:

<p align="center">
<img src="https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/ribosome_empiar_10064_map.png" alt="Ribosome EMPIAR-10064 Map"/>
</p>

# Acknowledgements

We are grateful to the following organizations:
- Buchmann family and [BMLS (Buchmann Institute for Molecular Life Sciences)](https://www.bmls.de) for supporting this project with their starters stipendia for PhD students;
- [DFG (Deutsche Forschungsgesellschaft)](https://www.dfg.de) for funding the project.

As well we are grateful to the [structural biology scientific research group of Werner Kühlbrandt](https://www.biophys.mpg.de/2207989/werner_kuehlbrandt) at the [MPIBP (Max Planck Institute of Biophysics)](https://www.biophys.mpg.de) and the [MPIBP](https://www.biophys.mpg.de) in Frankfurt (Hesse), Germany for support.

# Contacts
[Prof. Dr. Misha Kudryashev (Project Leader)](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR) - Principal Investigator, head of the [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany.

[Nikita Balyschew (Developer)](mailto:nikita.balyschew@gmail.com?subject=[GitHub]%20TomoBEAR) - Guest Scientist in the [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany; alumni Ph.D. student in the [Independent Research Group (Sofja Kovaleskaja)](https://www.biophys.mpg.de/2149775/members) at the Department of Structural Biology at [MPIBP (Max Planck Institute of Biophysics)](https://www.biophys.mpg.de/en) in Frankfurt (Hesse), Germany.

[Artsemi Yushkevich (Contributing Developer)](mailto:Artsemi.Yushkevich@mdc-berlin.de?subject=[GitHub]%20TomoBEAR) - Ph.D. student in the [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany.

[Vasili Mikirtumov (Application Engineer)](mailto:mikivasia@gmail.com?subject=[GitHub]%20TomoBEAR) - Ph.D. student in the [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany.
