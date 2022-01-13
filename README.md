<img src="https://raw.githubusercontent.com/catenax/tractusx/main/portal/code/tractus-x-portal/public/Catena-X_Logo_mit_Zusatz_2021.svg" width="400">

# Aspect Model Repository for Catena-X Project
The repository contains the aspect models based on [BAMM](https://openmanufacturingplatform.github.io/sds-documentation/bamm-specification/snapshot/index.html) for the Catena-X project.


# How to contribute
If you plan to add another model or apply changes to existing ones please create a new branch and file a pull request so the the changes can be reviewed.


# Using the models
The repository also contains a script, `generate.sh`, which you can use to generate a set of artifacts out of the models.

Example call for the Material.ttl aspect
```
./generate.sh Material/0.1.0/Material.ttl

```
You will find a folder Material-artifacts in the root folder of the repository, which contains the generated artifacts.

Limitations of the script: You need an internet connection to allow the script to download the BAMM-CLI and the catenaX style for the documentation. 
Currently the script uses version 1.0.0 of the BAMM-CLI, which doesn't work properly on the Mac (graphics will not generate images [issue](https://github.com/OpenManufacturingPlatform/sds-sdk/issues/38)). 
