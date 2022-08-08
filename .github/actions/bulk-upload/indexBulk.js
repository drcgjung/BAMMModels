var cp = require('child_process')

var path = require('path')
var fs = require('fs');
const { syncBuiltinESMExports } = require('module');

const mainBranch = 'refs/heads/main';
const timeout = 2000

try {
    files = getModelFilesFromDirectory('.');
    filesFlat = [].concat.apply([], files);
    filesFlatFlat = [].concat.apply([], filesFlat);
    console.log(filesFlatFlat)

    const branch = getInput('BRANCH')

    if (branch == mainBranch) {
        deployAspectsWithStatus(filesFlatFlat)
    } else {
        deployAspectsDraft(filesFlatFlat);
    }

} catch (error) {
    console.log(error.message)
}

function getModelFilesFromDirectory(directoryPath) {
    const filesInDirectory = fs.readdirSync(directoryPath, 'utf8', true);
    const files = filesInDirectory.map((file) => {
        const filePath = path.join(directoryPath, file);
        const stats = fs.statSync(filePath);

        if (stats.isDirectory()) {
            return getModelFilesFromDirectory(filePath);
        } else {
            if (path.extname(filePath) === '.ttl') {
                return filePath;
            } else {
                return ""
            }
        }
    });
    //return files with empty arrays removed
    return files.filter((file) => file.length);
};




function deployAspectsDraft (files) {
    console.log("Deploy Aspect from non-main-branch with status DRAFT")
    var n = 1
    files.forEach((file) => {
        if (path.extname(file) === '.ttl') {
            setTimeout(()=> {
                cp.exec('.github/deploy.sh -draft ' + file, (error, stdout, stderr) => {
                    if (error) {
                        console.log('Error deploying files', error);
                    }
                    if (stderr) {
                        console.log('Output in stderr for deploy', stderr);
                        return;
                    }
                    console.log('Result of deploy', stdout);
                }
                );
            }, n * timeout)
            n = n + 1
        }
    });
}

function deployAspectsWithStatus (files) {
    console.log("Deploy Aspects from main-branch with Status main")
    var n = 1
    files.forEach((file) => {
        if (path.extname(file) === '.ttl') {
            const status = findStatus(file)
            setTimeout(()=> {
                cp.exec('.github/deploy.sh -' + status + ' ' + file, (error, stdout, stderr) => {
                    if (error) {
                        console.log('Error deploying files', error);
                    }
                    if (stderr) {
                        console.log('Output in stderr for deploy', stderr);
                        return;
                    }
                    console.log('Result of deploy', stdout);
                }
                );
            }, n * timeout)
            n = n + 1
        }
    });
}

function findStatus(modelFile) {
    console.log("Finding status for model file: " + modelFile)
    let status = "release"
    try {
        const dirName = path.dirname(modelFile);
        const statusFile = dirName + '/metadata.json';
        const metadata = JSON.parse(fs.readFileSync(statusFile, 'utf8'));
        console.log("Model: " + modelFile + " Status: " + metadata.status)
        if (metadata.status === "deprecate") {
            status = "deprecate"
        }
    } catch (error) {
        console.log(`Unable to load valid metadata for the model file ${modelFile} due to ${error}. Assuming the status RELEASED now.`)
    } 
    return status
}

function getInput(name) {
    const val = process.env[`INPUT_${name.replace(/ /g, '_').toUpperCase()}`] || '';
    return val.trim();
}