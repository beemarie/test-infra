#!/bin/bash

# Copyright 2018 The Knative Authors
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

source $(dirname $0)/helper.sh
source $(dirname $0)/../../tools/cleanup/cleanup-functions.sh

readonly _FAKE_NIGHTLY_PROJECT_NAME="gcr.io/knative-nightly"
readonly _FAKE_BOSKOS_PROJECT_NAME="gcr.io/fake-boskos-project"
readonly _PROJECT_RESOURCE_YAML="ci/prow/boskos/resources.yaml"
readonly _RE_PROJECT_NAME="knative-boskos-[a-zA-Z0-9]+"

# Call "cleanup.sh" function with given paramters
# Parameters: $1..$n - parameters passed to "cleanup.sh" script
function cleanup_script() {
  "./tools/cleanup/cleanup.sh" $@
}

set -e

cd ${REPO_ROOT_DIR}

echo ">> Testing directly invoking cleanup script"

test_function ${FAILURE} "error: unknown option" cleanup_script "action-not-exist"
test_function ${FAILURE} "error: missing gcr" cleanup_script "delete-old-images-from-gcr"
test_function ${FAILURE} "error: missing resource" cleanup_script "delete-old-gcr-images"

test_function ${FAILURE} "error: expecting value following" cleanup_script "delete-old-gcr-images" --project-resource-yaml --dry-run
test_function ${FAILURE} "error: expecting value following" cleanup_script  "delete-old-gcr-images" --re-project-name --dry-run
test_function ${FAILURE} "error: expecting value following" cleanup_script "delete-old-gcr-images" --gcr-to-cleanup --dry-run
test_function ${FAILURE} "error: expecting value following" cleanup_script "delete-old-gcr-images" --days-to-keep --dry-run

test_function ${FAILURE} "error: days to keep" cleanup_script "delete-old-images-from-gcr" --days-to-keep "a" --dry-run
test_function ${FAILURE} "error: days to keep" cleanup_script "delete-old-gcr-images" --days-to-keep "a" --dry-run

# Test individual functions
echo ">> Testing deleting images from single project"

test_function ${FAILURE} "error: missing gcr" delete_old_images_from_gcr
test_function ${FAILURE} "error: missing days" delete_old_images_from_gcr ${_FAKE_BOSKOS_PROJECT_NAME}
test_function ${SUCCESS} "" mock_gcloud_function delete_old_images_from_gcr ${_FAKE_BOSKOS_PROJECT_NAME} 1

echo ">> Testing deleting images from multiple projects"

test_function ${FAILURE} "error: missing resource" delete_old_gcr_images
test_function ${FAILURE} "error: missing regex" delete_old_gcr_images "file"
test_function ${FAILURE} "error: missing days" delete_old_gcr_images "file" "regex"
test_function ${SUCCESS} "Start" mock_gcloud_function delete_old_gcr_images ${_PROJECT_RESOURCE_YAML} ${_RE_PROJECT_NAME} 99

echo ">> All tests passed"
