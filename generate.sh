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
#
#
# This script generates a set of artifacts for a given BAMM model in a ttl-file.
# Preconditiions:
# bamm-cli-1.0.0.jar in same folder as this script
# The BAMM CLI can be downloaded or build based on the content in https://github.com/OpenManufacturingPlatform/sds-sdk/releases 
#
# Usage:
# For file in ./com.catenax/0.0.1/*; do ./generate.sh $file
#
# For example: 
# ./generate.sh com.catenax/0.0.1/ProductUsage.ttl
#
# 

echo "Generate artifacts for $1"
model_name="$(basename $1 .ttl)"
artifacts_dir=$model_name-artifacts
echo "$model_name created"


mkdir "$artifacts_dir"

for value in png html json schema oapi-json oapi-yaml java
do
    echo "generate $value"
    java -jar bamm-cli-1.0.0.jar -i "$1" -d "$model_name-artifacts" -"$value" -base-url catenax.net

done

cp $1 $artifacts_dir/$i


