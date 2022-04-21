<img src="https://raw.githubusercontent.com/catenax/tractusx/main/portal/code/tractus-x-portal/public/Catena-X_Logo_mit_Zusatz_2021.svg" width="400">

# Aspect Model Repository for Catena-X Project
The repository contains the aspect models based on [BAMM](https://openmanufacturingplatform.github.io/sds-documentation/bamm-specification/snapshot/index.html) for the Catena-X project.
They are also available in the Catena-X Semantic Hub, available [here](https://catenaxintaksportal.germanywestcentral.cloudapp.azure.com/home/semantichub). The hub is a great place to browse existing models, and receive rendered views (diagrams, and human readable documentation) on them.


# How to contribute
If you plan to add another model or apply changes to existing ones please create a new branch and file a pull request so the the changes can be reviewed.


# Using the models
The models can locally be processed with the [BAMM CLI](https://openmanufacturingplatform.github.io/sds-documentation/sds-documentation/index.html).
It allows you to generate different artifacts (diagrams, example payload, java class files) out of it.

to generate the usual set of artifacts this repository also contains a script, `generate.sh` which automates some steps, and might be useful for your task.
The repository also contains a script, `generate.sh`, which you can use to generate a set of artifacts out of the models.

Example call for the Material.ttl aspect
```
./generate.sh Material/0.1.0/Material.ttl

```
You will find a folder Material-artifacts in the root folder of the repository, which contains the generated artifacts.

Limitations of the script: You need an internet connection to allow the script to download the BAMM-CLI and the catenaX style for the documentation. 
Currently the script uses version 1.0.0 of the BAMM-CLI, which doesn't work properly on the Mac (graphics will not generate images [issue](https://github.com/OpenManufacturingPlatform/sds-sdk/issues/38)). 

# Governance Development

The project realizes the governance process using GitHub Actions. If the governance process needs an update you can 
test your changes to the GitHub Workflow scripts by creating a branch called `governance-development`. The GitHub workflow
runs any changes made to the branch `governance-development` against the SemanticHub dev instance `https://catenaxdev042aksportal.germanywestcentral.cloudapp.azure.com/home/semantichub`.