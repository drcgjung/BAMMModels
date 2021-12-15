#
# Copyright (c) 2021 T-Systems International GmbH (Catena-X Consortium)
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
# Syntax ./deploy.ssh (-delete|-draft|-deprecate|-release) PATH_TO_MODEL_FILE*
#            -delete delete the models associated to the given paths
#            -draft create or update the models described in the given paths with status DRAFT (default)
#            -release create or update the models described in the given paths with status RELEASED
#            -deprecate create or update the models described in the given paths with status DEPRECATED
#
# (Optional) Environment variables
#            - WORKSPACE the target environment (default: dev042)
#            - SEMANTIC_HUB the hub servie endpoint (default: catenax${WORKSPACE}akssrv.germanywestcentral.cloudapp.azure.com/semantics/api/v1/models)
#            - PUBLISHER the publisher of the models (default: Catena-X Consortium)

if [[ -z "${WORKSPACE}" ]]; then
   WORKSPACE=dev042
fi

if [[ -z "${SEMANTIC_HUB}" ]]; then
   SEMANTIC_HUB=catenax${WORKSPACE}akssrv.germanywestcentral.cloudapp.azure.com/semantics/api/v1/models
fi

if [[ -z "${PUBLISHER}" ]]; then
   PUBLISHER="Catena-X Consortium"
fi

REPLACE_ORG_NEWLINE='s/\\n/\\\\n/g'
REPLACE_QUOTE='s/"/\\"/g'
REPLACE_NEWLINE=':a;N;$!ba;s/\n/\\n/g'

SUCCESS="true"
DELETION="false"
MODEL_STATUS="DRAFT"

for model in "$@"
do
  if [[ "${model}" == "-delete" ]]; then
    DELETION="true"
  elif [[ "${model}" == "-draft" ]]; then
    DELETION="false"; MODEL_STATUS="DRAFT"
  elif [[ "${model}" == "-release" ]]; then
    DELETION="false"; MODEL_STATUS="RELEASED"
  elif [[ "${model}" == "-deprecate" ]]; then
    DELETION="false"; MODEL_STATUS="DEPRECATED"
  elif [[ "${model}" == *.ttl ]]; then
    if [[ "${DELETION}" == "false" ]]; then
        if [[ "${model}" == *deprecated* ]]; then
          CURRENT_MODEL_STATUS="DEPRECATED"
        else
          CURRENT_MODEL_STATUS=${MODEL_STATUS}
        fi
        echo "About to deploy ${model} to ${SEMANTIC_HUB} in status ${CURRENT_MODEL_STATUS}"
        MODEL_NAMESPACE=$(cat ${model} | grep -o -E '@prefix : <[^"]+#>.' |sed  -n 's/^@prefix : <\(.*\)#>.$/\1/p')
        MODEL_NAME=$(cat ${model} | grep -o -E ':[^"]+ a bamm:Aspect' |sed  -n 's/^:\(.*\) a bamm:Aspect$/\1/p')
        MODEL_ID="${MODEL_NAMESPACE}#${MODEL_NAME}"
        echo "Deduced model id ${MODEL_ID}"
        #cat ${model} | sed ${REPLACE_ORG_NEWLINE} | sed ${REPLACE_QUOTE}  | sed ${REPLACE_NEWLINE} > test.json
        STATUS=$(echo '{"private": false, "publisher":"'${PUBLISHER}'", "status":"'${CURRENT_MODEL_STATUS}'", "type": "BAMM", "model":"' $( cat ${model} | sed ${REPLACE_ORG_NEWLINE} | sed ${REPLACE_QUOTE}  | sed ${REPLACE_NEWLINE} ) '"}' | \
            curl -s --location --request POST 'https://'${SEMANTIC_HUB} \
                --header 'Content-Type: application/json' \
                -d @- -w '%{http_code}')
#    --header 'Authorization: Basic dXNlcjpwYXNzd29yZA=='
        echo "Got creation status ${STATUS}"
        if [[ "${STATUS}" == *200 ]]; then
            echo "Model ${MODEL_ID} was successfully created.";
        elif [[ "${STATUS}" == *400 ]]; then
            echo "Model ${MODEL_ID} already exists. Try to modify.";
            STATUS=$(echo '{ "private": false, "publisher":"'${PUBLISHER}'", "status":"'${CURRENT_MODEL_STATUS}'", "type": "BAMM", "model":"' $( cat ${model} | sed ${REPLACE_ORG_NEWLINE} | sed ${REPLACE_QUOTE}  | sed ${REPLACE_NEWLINE} ) '"}' | \
                curl -s --location --request PUT 'https://'${SEMANTIC_HUB} \
                --header 'Content-Type: application/json' \
                -d @- -w '%{http_code}')
#    --header 'Authorization: Basic dXNlcjpwYXNzd29yZA=='
            echo "Got modification status ${STATUS}"
            if [[ "${STATUS}" == *200 ]]; then
                echo "Model ${MODEL_ID} was successfully updated.";
            else 
                echo "Unknown modification status ${STATUS}. Marking deployment as failed";
                SUCCESS="false"
            fi
        else
            echo "Unknown creation status ${STATUS}. Marking deployment as failed."
            SUCCESS="false"
        fi
    else
        REGEX="(.*)/([0-9]+\.[0-9]+\.[0-9]+)/([^/]+).ttl"
        if [[ ${model} =~ ${REGEX} ]]; then
          MODEL_NAME=${BASH_REMATCH[3]}
          MODEL_VERSION=${BASH_REMATCH[2]}
          echo "About to delete ${model} in ${SEMANTIC_HUB}. Assuming MODEL_NAME ${MODEL_NAME} and version ${MODEL_VERSION}"
          JQ_QUERY=".[]|select(.id|endswith(\"${MODEL_VERSION}#${MODEL_NAME}\"))|.id"
          URL="https://${SEMANTIC_HUB}?nameFilter=${MODEL_NAME}&namespaceFilter=${MODEL_VERSION}"
          MODELS_TO_DELETE=($(curl -s --location --request GET ${URL} | jq -r $JQ_QUERY))
#    --header 'Authorization: Basic dXNlcjpwYXNzd29yZA=='
          for element in ${MODELS_TO_DELETE[@]}
          do
            echo $element
            MODEL_TO_DELETE=${element//[$'\t\r\n']} 
            URLENCODED_MODEL_TO_DELETE=${MODEL_TO_DELETE//#/%23}
            echo "About to delete ${URLENCODED_MODEL_TO_DELETE} in ${SEMANTIC_HUB}"
            URL="https://${SEMANTIC_HUB}/${URLENCODED_MODEL_TO_DELETE}"
            STATUS=$(curl -s --location --request DELETE ${URL} -w '%{http_code}')
#    --header 'Authorization: Basic dXNlcjpwYXNzd29yZA=='
            echo "Got deletion status ${STATUS}"
            if [[ "${STATUS}" == *204 ]]; then
              echo "Model ${URLENCODED_MODEL_TO_DELETE} was successfully deleted.";
            else 
              echo "Unknown deletion status ${STATUS}. Marking deployment as failed";
              SUCCESS="false"
            fi
          done
        else
          echo "Model path ${MODEL_NAME} does not conform to the MODEL_NAME/VERSION/MODEL_NAME.ttl standard. The model cannot be looked up/deleted."
        fi
    fi
  else
       echo "Ignoring file ${model} as it is no ttl file."
  fi
done


if [[ "$SUCCESS" == "true" ]]; then
  exit 0
else 
  exit 1
fi