#!/bin/bash
#
# Copyright (c) 2021 T-Systems International GmbH (Catena-X Consortium)
# Copyright (c) 2022 Robert Bosch Manufacturing Solutions GmbH
#
# See the AUTHORS file(s) distributed with this work for additional
# information regarding authorship.
#
# See the LICENSE file(s) distributed with this work for
# additional information regarding license terms.
#

#
# Shell script to perform a deployment of semantic models
#
# Syntax ./deploy.sh (-delete|-draft|-deprecate|-release|PATH_TO_MODEL_FILE)*
#            -delete delete the models associated to the following paths
#            -draft create or update the models described in the following paths with status DRAFT (default)
#            -release create or update the models described in the following paths with status RELEASED
#            -deprecate create or update the models described in the following paths with status DEPRECATED
#
# Note: In all non-delete modes (-draft|-release|-deprecate), the existance of the term "deprecated" in the path name of a follwing model will
# lead to its deployment under status DEPRECATED 
# Note: paths not ending with a turtle file (*.ttl) are ignored
#
# (Optional) Environment variables
#            - WORKSPACE the target environment (default: dev042)
#            - SEMANTIC_HUB the hub servie endpoint (default: catenax${WORKSPACE}akssrv.germanywestcentral.cloudapp.azure.com/semantics/api/v1/models)
#            - PUBLISHER the publisher of the models (default: Catena-X Consortium)
#            - ACCESS_TOKEN the access token needed to authenticate with the Semantic Hub API

echo "Called Deploy to Semantic Hub with arguments: '$@'"
if [[ -z "${WORKSPACE}" ]]; then
   WORKSPACE=dev042
fi

if [[ -z "${SEMANTIC_HUB}" ]]; then
   SEMANTIC_HUB=catenax${WORKSPACE}akssrv.germanywestcentral.cloudapp.azure.com/semantics/hub/api/v1/models
fi

if [[ -z "${PUBLISHER}" ]]; then
   PUBLISHER="Catena-X Consortium"
fi

if [[ -z "${ACCESS_TOKEN}" ]]; then
  echo "Access Token is missing"
  exit 1
fi

REPLACE_ORG_NEWLINE='s/\\n/\\\\n/g'
REPLACE_QUOTE='s/"/\\"/g'
REPLACE_NEWLINE=':a;N;$!ba;s/\n/\\n/g'

SUCCESS="true"
DELETION="false"
MODEL_STATUS="DRAFT"

for argument in "$@"
do
  #switch on delete mode
  if [[ "${argument}" == "-delete" ]]; then
    DELETION="true"

  # switch on draft mode
  elif [[ "${argument}" == "-draft" ]]; then
    DELETION="false"; MODEL_STATUS="DRAFT"
  
  # switch on release mode
  elif [[ "${argument}" == "-release" ]]; then
    DELETION="false"; MODEL_STATUS="RELEASED"
  
  # switch on deprecation mode
  elif [[ "${argument}" == "-deprecate" ]]; then
    DELETION="false"; MODEL_STATUS="DEPRECATED"
  
  # is the path a ttl file?
  elif [[ "${argument}" == *.ttl ]]; then

    # are we in delete or modify/create mode?
    if [[ "${DELETION}" == "false" ]]; then

        # should we apply auto-deprecation because of the (moved) path name
        if [[ "${argument}" == *deprecated* ]]; then
          CURRENT_MODEL_STATUS="DEPRECATED"
        else
          CURRENT_MODEL_STATUS=${MODEL_STATUS}
        fi

        # Perform a fresh create try
        echo "About to deploy ${argument} to ${SEMANTIC_HUB} in status ${CURRENT_MODEL_STATUS}"
        
        MODEL_NAMESPACE=$(cat ${argument} | grep -o -E '@prefix : <[^"]+#>.' |sed  -n 's/^@prefix : <\(.*\)#>.$/\1/p')
        MODEL_NAME=$(cat ${argument} | grep -o -E ':[^"]+ a bamm:Aspect' |sed  -n 's/^:\(.*\) a bamm:Aspect$/\1/p')
        MODEL_ID="${MODEL_NAMESPACE}#${MODEL_NAME}"
        
        echo "Deduced model id ${MODEL_ID}"
        
        #cat ${argument} | sed ${REPLACE_ORG_NEWLINE} | sed ${REPLACE_QUOTE}  | sed ${REPLACE_NEWLINE} > test.json
        STATUS=$(echo $( cat ${argument} ) | \
            curl -s --location --request POST "https://${SEMANTIC_HUB}?type=BAMM&status=${CURRENT_MODEL_STATUS}" \
                --header 'Content-Type: text/plain' \
                --header "Authorization: Bearer $ACCESS_TOKEN" \
                -d @- -w '%{http_code}')
#    --header 'Authorization: Basic dXNlcjpwYXNzd29yZA=='

        echo "Got creation status ${STATUS}"

        # Model already existed?
        if [[ "${STATUS}" == *200 ]]; then
            echo "Model ${MODEL_ID} was successfully created.";
        elif [[ "${STATUS}" == *400 ]]; then
            
            # Perform a scond modification try
            echo "Model ${MODEL_ID} already exists. Try to modify.";
            STATUS=$(echo $( cat ${argument} ) | \
                curl -s --location --request PUT "https://${SEMANTIC_HUB}?type=BAMM&status=${CURRENT_MODEL_STATUS}" \
                --header 'Content-Type: text/plain' \
                --header "Authorization: Bearer $ACCESS_TOKEN" \
                -d @- -w '%{http_code}')
#    --header 'Authorization: Basic dXNlcjpwYXNzd29yZA=='

            echo "Got modification status ${STATUS}"

            if [[ "${STATUS}" == *200 ]]; then
                echo "Model ${MODEL_ID} was successfully updated.";
            else

                # Failure conditition for modification call 
                echo "Unknown modification status ${STATUS}. Marking deployment as failed";
                SUCCESS="false"
            fi

        else
            # Failure condition for creation call
            echo "Unknown creation status ${STATUS}. Marking deployment as failed."
            SUCCESS="false"
        fi


    else

        # This is the delete mode, since the file does no exist anymore, we
        # need to derive all important information from the path name

        REGEX="(.*)/([0-9]+\.[0-9]+\.[0-9]+)/([^/]+).ttl"
        if [[ ${argument} =~ ${REGEX} ]]; then

          # Perform a list query on the relevant models
          MODEL_NAME=${BASH_REMATCH[3]}
          MODEL_VERSION=${BASH_REMATCH[2]}
          MODEL_NAMESPACE=${BASH_REMATCH[1]}
          echo "About to delete ${argument} in ${SEMANTIC_HUB}. Assuming version ${MODEL_VERSION} and namespace ${MODEL_NAMESPACE}"
          URL="https://${SEMANTIC_HUB}/urn:bamm:${MODEL_NAMESPACE}:${MODEL_VERSION}%23"
          echo "$URL"
          STATUS=$(curl -s --location --request DELETE ${URL} --header "Authorization: Bearer $ACCESS_TOKEN" -w '%{http_code}')
          echo "Got deletion status ${STATUS}"
            if [[ "${STATUS}" == *204 ]]; then
              echo "Namespace ${MODEL_NAMESPACE} was successfully deleted.";
            else 
              # Failure condition on deletion
              echo "Unknown deletion status ${STATUS}. Marking deployment as failed";
              SUCCESS="false"
            fi
        else
          # Ignore paths without proper naming
          echo "Model path ${MODEL_NAME} does not conform to the MODEL_NAME/VERSION/MODEL_NAME.ttl standard. The model cannot be looked up/deleted."
        fi
    fi
  else
       # Ignore paths without proper naming
       echo "Ignoring file ${argument} as it is no ttl file."
  fi
done

if [[ "$SUCCESS" == "true" ]]; then
  exit 0
else 
  exit 1
fi