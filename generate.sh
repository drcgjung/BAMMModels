#! /bin/sh
#
# Copyright (c) 2021 Robert Bosch Manufacturing Solutions GmbH
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# REMARKS:
# ========
# This script generates a set of artifacts for a given BAMM model in a ttl-file.
# Preconditiions:
# -internet connection to download CLI or specifiied BAMM CLI provided in $BAMMCLI folder
# The BAMM CLI can be downloaded at $BAMMCLIURL
#
# Usage:
# Apply script to a single file
# ./generate.sh com.catenax/0.0.1/ProductUsage.ttl
# Apply script to a set of files
# For file in ./com.catenax/0.0.1/*; do ./generate.sh $file



# Adjust if BAMM CLI version changes
JARNAME=bamm-cli-1.0.2.jar
BAMMFOLDER=.BAMMCLI/
BAMMCLI=$BAMMFOLDER$JARNAME
# Adjust if BAMM CLI version changes
BAMMCLIURL=https://github.com/OpenManufacturingPlatform/sds-sdk/releases/download/v1.0.2/bamm-cli-1.0.2.jar

CATENAXCSS=$BAMMFOLDER/catena-template.css
CATENAXCUSTOMCSSURL=https://raw.githubusercontent.com/catenax/tractusx/main/semantics/src/main/resources/catena-template.css

echo "Check availability of BAMM CLI"
if [ ! -f "$BAMMCLI" ]; then
  echo "$BAMMCLI does not exist. Will download"
  mkdir $BAMMFOLDER

  cd $BAMMFOLDER && { curl -LJO $BAMMCLIURL ; cd -; }
fi

if [ ! -f "$CATENAXCSS" ]; then
  echo "$CATENAXCSS does not exist. Will download"
  mkdir $BAMMFOLDER

  cd $BAMMFOLDER && { curl -LJO $CATENAXCUSTOMCSSURL ; cd -; }
fi

echo "Generate artifacts for $1"
MODELNAME="$(basename $1 .ttl)"
ARTIFACTSDIR=$MODELNAME-artifacts

echo "Create subfolder to store generated artifacts $ARTIFACTSDIR"
mkdir $ARTIFACTSDIR

for value in png html json schema oapi-json oapi-yaml java
do
    echo "generate $value"
    java -jar $BAMMCLI -i "$1" -d "$ARTIFACTSDIR" -"$value" -base-url catenax.net -hccf $CATENAXCSS

done

cp $1 $ARTIFACTSDIR