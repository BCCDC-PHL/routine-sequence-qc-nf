#!/bin/bash

set -eo pipefail

echo "Install NCBI Genome Download tool using conda.." >> artifacts/test_artifact.log

conda create --yes --name ncbi-acc-download --prefix /opt/miniconda3/envs/ncbi-acc-download
