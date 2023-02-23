# TomoBEAR

> **Warning**
> <br/> We are mainly at the stage of testing, debugging and maintenance work. However, new features may still appear and refactoring may still take place.

TomoBEAR is an automated, configurable and customizable full processing pipeline for tomographic cryo-electron microscopy data and subtomogram averaging in the broad field of Cryo-ET based on best practices in the scientific research groups of [Misha Kudryashev](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR):
- (previous one) [Independent Research Group (Sofja Kovaleskaja)](https://www.biophys.mpg.de/2149775/members) at the Department of Structural Biology at [MPIBP (Max Planck Institute of Biophysics)](https://www.biophys.mpg.de/en) in Frankfurt (Hesse), Germany;
- (current one) [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany.

> **Note**
> <br/> We will be happy, if you would try out one of the latest available versions from [Releases page](https://github.com/KudryashevLab/TomoBEAR/releases) and get back to us by one of the ways mentioned in [Feedback](#feedback).

![TomoBEAR Social Media Logo Image](https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/TomoBEAR_gitlogo.png)

## Contents

- [Documentation](#documentation)
- [Pipeline structure](#pipeline-structure)
- [Feedback](#feedback)
- [Acknowledgements](#acknowledgements)
- [Contacts](#contacts)

## Documentation

Information on the installation, setup and usage as well as tutorials and example results can be found in the corresponding [wiki](https://github.com/KudryashevLab/TomoBEAR/wiki).
</br> In the future we are planning to introduce wiki versioning as well, stay tuned!

## Pipeline structure

In the following picture you can see a flow chart which visualizes which steps `TomoBEAR` will and can do for you in an automated and parallel manner. `TomoBEAR` supports workstations and single interactive nodes with GPUs on the computing clusters at the moment. We are also working towards enabling the support of computer clusters through a queue manager like SLURM or SGE (Sun Grid Engine).

Note that it is not needed to start from raw data but you can also use already assembled tilt stacks if you provide the angular information.

![Schematic Pipeline Image](https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/pipeline_simplified.png)

A picture above represents the flow diagram of the data processing with TomoBEAR. Blue boxes outline the steps that are performed fully automatically, green boxes may require human intervention. The steps encapsulated in the red frame represent the functionality of live data processing. More detailed diagram is located on [wiki](https://github.com/KudryashevLab/TomoBEAR/wiki).

## Feedback

In case of any questions or errors you may interact with us by one of the following ways:
* write an e-mail to [Misha Kudryashev](mailto:misha.kudryashev@gmail.com) or [Artsemi Yushkevich](mailto:Artsemi.Yushkevich@mdc-berlin.de);
* open an issue/bug report, feature request or post a question using [Issue Tracker](https://github.com/KudryashevLab/TomoBEAR/issues);
* start a discussion in [Discussions](https://github.com/KudryashevLab/TomoBEAR/discussions);

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
