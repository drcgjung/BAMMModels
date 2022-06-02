# Sychronization Action
This action expects arrays which contain added, modified, renamded and delted files from the last commit. Based on this information, the action synchronizes the changes in the Git repository to a Semantic Hub instance. 

The actual deployment is done through the execution of the deploy.sh script which can also be used outside of this action to end requests to a Semantic Hub. 


## Test Cases
For future developments, we propose the following test cases to be evaluated:

### main branch

| Model | metadata.json | expected deployed model status |
----| ---- | ----- |
add model | add with status RELEASED | RELEASED
add model | none | RELEASED
existing model | add metadata.json with status DEPRECATED | DEPRECATED
add model | existing metadata.json with status DEPRECATED | DEPRECATED
add two models to same namespace | add with status RELEASED | one model RELEASED and warning
add two models to same namespace | none | one model RELEASED (no warning yet)
delete model with status DEPRECATED  | not relevant | model is deleted in Semantic Hub 
delete model with status RELEASED | not relevant | model is still and Semantic Hub and log error response from Semantic Hub that model cannot be deleted
modify model | no addition or modification | log warning and no update of model in Semantic Hub

### other branch
On any other branch besides the main-branch the metadata.json should be ignored. This results in the following test cases: 

| Model | metadata.json | expected deployed model status |
----| ---- | ----- |
add model | none | DRAFT
add model | add metadata.json with status DEPRECATED | DRAFT
existing model | add metadata.json with status RELEASED | DRAFT
delete model | not relevant | delete model from Semantic Hub



