<img src="https://raw.githubusercontent.com/catenax/tractusx/main/portal/code/tractus-x-portal/public/Catena-X_Logo_mit_Zusatz_2021.svg" width="400">

# Aspect Model Repository for Catena-X Project
The repository contains the aspect models based on [BAMM](https://openmanufacturingplatform.github.io/sds-documentation/bamm-specification/snapshot/index.html) for the Catena-X project.
They are also available in the Catena-X Semantic Hub, available [here](https://catenaxintaksportal.germanywestcentral.cloudapp.azure.com/home/semantichub). The hub is a great place to browse existing models, and receive rendered views (diagrams, and human readable documentation) on them.


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

# Status of model
Each model has its life cycle and can thus have a different status. The Semantic Hub stores this status together with the model. This information always corresponds to a specific version of the model. To indicate the state of the model version in Git, one creates a file with the name `metadata.json` and places it in the same directory as the corresponding model file. An example `metadata.json` looks like this:

```
{ "status" : "deprecate"} 
```

The following table lists the possible values for `status` and what they mean:

status | status in Semantic Hub | description
----| ---- | ---- |
draft | DRAFT | This version of the model is under development and can change at any time.
release | RELEASED | This version of the model is considered as stable and any modifications to the model trigger a new release and subsequentially a new version. 
deprecate | DEPRECATED | This content of this model version has reached its end-of-life and should not be used anymore because it will be deleted later. 

The ``metadata.json`` is only relevant for model files on the branch ``main`. All other branches are development branches, and the models from these branches are therefore implicitly in status "DRAFT". 

# How to contribute
We have a governance process for the joint development of new and updated models which we describe [in more details under this link](GOVERNANCE.md). 

## Summary of Governance Process
The governance process is **triggered by a domain expert** requesting a new model or model update. The **modeling team then reviews** the request to identify whether it is of interest for Catena-X and whether there is not already another model which can solve the raised issue (**Q1-Approval**). 

Once the request is accepted, **a modeling expert and the requesting domain expert create a solution**. The modeling expert then evaluates whether the new or updated model follows the modeling guidelines in Catena-X (**Q2-Approval**). In the last step, the **requesting use case and the modeling team approve** that the resulting model fulfills the initial requirement and can be adopted (**Q3-Approval**). As a result, the content of the new model version cannot change, and use cases are safe to use the model.

We do this process for each version of a model. So there can be multiple versions of the model with different content in different phases of the model life-cycle. 
See the following section for more details on the different approvals and the life cycle. 

If you plan to add another model or apply changes to existing ones please create a new issue and discuss your request with the modeling team. When requesting reviews and approvals for new model developments file a pull request.

# Governance Development

The project realizes the governance process using GitHub Actions. If the governance process needs an update you can 
test your changes to the GitHub Workflow scripts by creating a branch called `governance-development`. The GitHub workflow
runs any changes made to the branch `governance-development` against the SemanticHub dev instance `https://catenaxdev042aksportal.germanywestcentral.cloudapp.azure.com/home/semantichub`.