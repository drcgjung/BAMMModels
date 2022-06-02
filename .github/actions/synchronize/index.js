var cp = require('child_process')
var path = require('path')
var fs = require('fs')

const mainBranch = 'refs/heads/main';

try {
    const added = JSON.parse(getInput('ADDED'))
    const modified = JSON.parse(getInput('MODIFIED'))
    const removed = JSON.parse(getInput('REMOVED'))
    const renamed = JSON.parse(getInput('RENAMED'))
    const branch = getInput('BRANCH')
    if (branch === mainBranch) {
        deployAddedFilesOnMain(added)
        deployModifiedFilesOnMain(modified);
        deleteAspects(removed);
    } else {
        console.log("The synchronization sets the the changed models to the status 'DRAFT' and does not consider potential metadata.json files because it runs on a branch which is not the main-branch.")
        deployAspects(added);
        deployAspects(modified);
        deleteAspects(removed);
    }
    

} catch (error) {
    console.log(error.message)
}

function deployAddedFilesOnMain(files) {
    files.forEach((file) => {
        if (path.basename(file) === 'metadata.json') {
            console.log("Found added metadata file: " + file);
            const metadata = JSON.parse(fs.readFileSync(file, 'utf8'));
            console.log("The new status is: " + metadata.status);
            if (metadata.status !== "draft" ) {
                baseDir = path.dirname(file)
                const filesInDirectory = fs.readdirSync(baseDir, 'utf8', true).map((file) => { return baseDir + "/" + file });
                modelFilesInDirectory = filesInDirectory.filter(isModelFile)
                if (modelFilesInDirectory.length === 0) {
                    console.log("Warning: Did not find any model file corresponding to metadata in: " + file)
                } else if (modelFilesInDirectory.length > 1) {
                    console.log("Warning: Did find more than one model file corresponding to one metadata file. The Semantic Hub currently only supports the addition of a single model file for each versioned namespace")
                    console.log("Metadata: " + file + ", Models in Directory: " + modelFilesInDirectory)
                }
                /*
                Do not handle invalid status entries here (e.g., that are not part of the status state-machine) since they will be ignored in the deploy.sh script.
                */
                deployAspects(modelFilesInDirectory, metadata.status)
            } else {
                console.log("Ignoring Aspect with metadata " + file + " because it is in status 'DRAFT' which is not a valid state on the main branch")
            }    
        }
        if (isModelFile(file)) {
            let status = "release"
            const metaDataPath = path.dirname(file) + "/metadata.json";
            console.log("Metadata Path: " + metaDataPath)
            /*
            Do not need to add the model here if the metadata.json is part of the added
            files too, because the model will be already added once the metadata.json for the model is found. 
            */
            if (!files.includes(metaDataPath)) {
                try {
                    const metadata = JSON.parse(fs.readFileSync(metaDataPath));
                    status = metadata.status;
                } catch (err) {
                    console.log("Unable to load valid metadata for the model file " + file + " Assuming the status RELEASED now.")
                } 
                deploySingleAspect(file, status)
            }
        }
    })
}

function isModelFile(file) {
    return path.extname(file) === ".ttl";
}

function deployModifiedFilesOnMain(files) {
    files.forEach((file) => {
        if (isModelFile(file)) {
            console.log("Warning: Detected a modification on main-branch for the model: " + file + " . Models on the main-branch should only change the status and not the content. Because of that, the model will be ignored for the synchronization.")
        }
        /*
        Only synchronize changes to the status found in the metdata.json since all other (model) files on the main branch are in state RELEASED or later and thus not supposed to change unless there is a state change. Thus these model deployment would be rejected by the Semantic Hub.
        There is the edge case that a model is changed while its status is changed too, for example, from 'RELEASED' to 'DEPRECATED'. This should be handled in the semantic hub.
        */
        if (path.basename(file) === 'metadata.json') {
            console.log("Modified metadata file: " + file);
            const metadata = JSON.parse(fs.readFileSync(file, 'utf8'));
            console.log("Modified new status: " + metadata.status);
            baseDir = path.dirname(file)
            const filesInDirectory = fs.readdirSync(baseDir, 'utf8', true).map((file) => { return baseDir + "/" + file });
            console.log(filesInDirectory)
            deployAspects(filesInDirectory, metadata.status)
        }
    })
}


function deployAspects(files) {
    deployAspects(files, "draft")
}

//TODO delay creation of single Aspects to prevent the Semantic Hub from overload.
/*Postponing this TODO because we do not expect that this action will trigger for commits with a larger number of change requests for the Semantic Hub instance.*/
function deploySingleAspect(file, status) {
    if (isModelFile(file)) {
        console.log("Starting deployment with deploy.sh for model file: " + file)
        cp.exec('.github/deploy.sh -' +  status + ' ' + file, (error, stdout, stderr) => {
            if (error) {
                console.log('Error deploying files', error);
            }
            if (stderr) {
                console.log('Output in stderr for deploy', stderr);
                return;
            }
            console.log(stdout);
        });
    } else {
        console.log("Did not deploy file, because it is not a model file: " + file) 
    }
}

function deployAspects(files, status) {
    files.forEach((file) => {
        deploySingleAspect(file, status)    
    });
}

/*
    When working on the main-branch, some of the deletion might fail because models in state RELEASED cannot be deleted from the Semantic Hub. However, when deleting a model in Git, most likeley the corresponding metadata.json will be deleted too. 
    So to retrieve the status of the model before the deletion in Git one could 
    request the state of the model from the Semantic Hub which is an additional HTTP call compared to directly sending the deletion request. There is also no good 
    recovery solution if the model cannot be deleted from the Semantic Hub, because 
    it would be not intuitive to restore the model in Git then. As a consequence, the 
    current synchronization simply tries to delete the model without further logic. 
    The outlined to issues thus need to be prevented as part of the governance process. 

    Another edge case is the deletion of the a metadata.json file while the model file remains in the Git repository.
    The current design decision is to ignore this deletion and keep the latest set status for the model and not change the status back to RELEASED which would be the default status for a model without a metadata.json file. The underlying assumption
    is that the metadata.json should not be deleted in the first place and that hence the deletion should not be used as indicator for a status change of the model. However, this may lead to a confusing situation where a model without a metadata.json is not in status "RELEASED" which can be resolved by re-adding a metadata.json file.
*/
function deleteAspects(files) {
    files.forEach((file) =>  {
        if (isModelFile(file)) {
            console.log("Deleting model with deploy.sh: " + file)
            cp.exec('.github/deploy.sh -delete ' + file, (error, stdout, stderr) => {
                if (error) {
                    console.log('Error deleting files, error', error);
                }
                if (stderr) {
                    console.log('Output in stderr for delete', stderr);
                    return;
                }
                console.log(stdout)
            });
        }
    });
}

function getInput(name) {
    const val = process.env[`INPUT_${name.replace(/ /g, '_').toUpperCase()}`] || '';
    return val.trim();
}