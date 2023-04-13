# TomoBEAR

> **Warning**
> <br/> We are mainly at the late development stage, but new features may still appear and refactoring may still take place between all current and future 0.x.y versions until 1.0.0 will be ready to be released.

**TomoBEAR** is a configurable and customizable modular pipeline for streamlined processing of cryo-electron tomographic data and preliminary subtomogram averaging based on best practices in the [scientific research groups of Dr. Misha Kudryashev](#affiliation-links).

Implementation details and benchmarks you can find in our preprint:
</br> Balyschew N, Yushkevich A, Mikirtumov V, Sanchez RM, Sprink T, Kudryashev M. Streamlined Structure Determination by Cryo-Electron Tomography and Subtomogram Averaging using TomoBEAR. **[Preprint]** 2023. bioRxiv doi: [10.1101/2023.01.10.523437](https://www.biorxiv.org/content/10.1101/2023.01.10.523437v1)

> **Note**
> <br/> **We are happy to support you to try out one of the latest available TomoBEAR versions from the [Releases page](https://github.com/KudryashevLab/TomoBEAR/releases). We are also would be happy to receive from you [any kind of feedback](#feedback)!**

![TomoBEAR Social Media Logo Image](https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/TomoBEAR_gitlogo.png)

## Contents

- [Documentation](#documentation)
- [Pipeline structure](#pipeline-structure)
- [Feedback](#feedback)
- [Changes](#changes)
- [License](#license)
- [Citation](#citation)
- [Acknowledgements](#acknowledgements)
- [Contacts](#contacts)

## Documentation

Information on the installation, setup and usage as well as tutorials and example results can be found in the corresponding [wiki](https://github.com/KudryashevLab/TomoBEAR/wiki).

## Pipeline structure

In the following picture you can see a flow chart of the main `TomoBEAR` processing steps. As the basic input data you can use raw frame movies or already assembled tilt stacks (in this case, along with the angular information). More on input formats you [can read here](https://github.com/KudryashevLab/TomoBEAR/wiki/Usage.md#input-data-file-formats).

![Schematic Pipeline Image](https://raw.githubusercontent.com/KudryashevLab/TomoBEAR/main/images/pipeline_simplified.png)

Blue boxes outline the steps that are performed fully automatically, green boxes may require human intervention. The steps encapsulated in the red frame represent the functionality of live data processing. More detailed diagram [is located on wiki](https://github.com/KudryashevLab/TomoBEAR/wiki).

> **Note**
> <br/> Full MATLAB (source code) version of `TomoBEAR` supports workstations and single interactive nodes with GPUs on the computing clusters at the moment. We are also working towards enabling the support of binaries on the mentioned systems as well as support of both source code and binary versions of the `TomoBEAR` on computer clusters through a queue manager like SLURM or SGE (Sun Grid Engine).

## Feedback

In case of any questions, issues or suggestions you may interact with us by one of the following ways:
* write an e-mail to [Misha Kudryashev](mailto:misha.kudryashev@gmail.com) or [Artsemi Yushkevich](mailto:Artsemi.Yushkevich@mdc-berlin.de);
* open an issue/bug report, feature request or post a question using [Issue Tracker](https://github.com/KudryashevLab/TomoBEAR/issues);
* start a discussion in [Discussions](https://github.com/KudryashevLab/TomoBEAR/discussions);

## Changes

The [CHANGELOG file](https://github.com/KudryashevLab/TomoBEAR/blob/main/CHANGELOG.md) contains all notable changes corresponding to the different `TomoBEAR` releases, which are available at the [Releases page](https://github.com/KudryashevLab/TomoBEAR/releases) along with the additional notes.

## License

Please, see the [LICENSE file](https://github.com/KudryashevLab/TomoBEAR/blob/main/LICENSE.md) for the information about how the content of this repository is licensed.

## Citation

If you use `TomoBEAR` in your research, please **cite both `TomoBEAR` and all the third-party software packages** which you have used via `TomoBEAR`. The `TomoBEAR` modules dependencies on third-party software are listed on the [Modules page](https://github.com/KudryashevLab/TomoBEAR/wiki/Modules.md) and the list of the corresponding references to cite is located on the [Additional Software Citation page](https://github.com/KudryashevLab/TomoBEAR/wiki/Additional-Software-Citation.md).

---
## Acknowledgements

We are grateful to the following organizations:
- Buchmann family and [BMLS (Buchmann Institute for Molecular Life Sciences)](https://www.bmls.de) for supporting this project with their starters stipendia for PhD students;
- [DFG (Deutsche Forschungsgesellschaft)](https://www.dfg.de) for funding the project.

As well we are grateful to the [structural biology scientific research group of Werner Kühlbrandt](https://www.biophys.mpg.de/2207989/werner_kuehlbrandt) at the [MPIBP (Max Planck Institute of Biophysics)](https://www.biophys.mpg.de) and the [MPIBP](https://www.biophys.mpg.de) in Frankfurt (Hesse), Germany for support.

## Contacts
* Prof. Dr. Misha Kudryashev[^1][^2] ([e-mail](mailto:misha.kudryashev@gmail.com?subject=[GitHub]%20TomoBEAR)) - `TomoBEAR` project leader, Principal Investigator;

* Nikita Balyschew[^2] ([e-mail](mailto:nikita.balyschew@gmail.com?subject=[GitHub]%20TomoBEAR)) - `TomoBEAR` core version developer, alumni Ph.D. student.

* Artsemi Yushkevich[^1] ([e-mail](mailto:Artsemi.Yushkevich@mdc-berlin.de?subject=[GitHub]%20TomoBEAR)) - `TomoBEAR` contributing developer, Ph.D. student.

* Vasilii Mikirtumov[^1] ([e-mail](mailto:mikivasia@gmail.com?subject=[GitHub]%20TomoBEAR)) - `TomoBEAR` application engineer, Ph.D. student.


[^1]: [In situ Structural Biology Group](https://www.mdc-berlin.de/kudryashev) at the [MDCMM (Max Delbrück Center of Molecular Medicine)](https://www.mdc-berlin.de) in Berlin, Germany.

[^2]: [Independent Research Group (Sofja Kovaleskaja)](https://www.biophys.mpg.de/2149775/members) at the Department of Structural Biology at [MPIBP (Max Planck Institute of Biophysics)](https://www.biophys.mpg.de/en) in Frankfurt (Hesse), Germany;
