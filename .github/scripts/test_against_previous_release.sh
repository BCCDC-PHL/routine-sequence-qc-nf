#!/bin/bash

set -eo pipefail

export PATH=/opt/miniconda3/bin:$PATH
export PATH=/opt/nextflow/bin:$PATH

# write test log as github Action artifact
echo "Nextflow run current PR..." >> artifacts/test_artifact.log
NXF_VER=20.10.0 nextflow -C ${PWD}/.github/config/nextflow.config -quiet run ./main.nf \
       -profile conda \
       --cache ${HOME}/.conda/envs \
       --kraken2_db ${PWD}/.github/data/kraken2_db \
       --bracken_db ${PWD}/.github/data/kraken2_db \
       --run_dir ${PWD}/.github/data/mock_runs/210101_M00000_0000_000000000-A1B2C \
       --outdir results

cp .nextflow.log artifacts/pull_request.nextflow.log
cp -r results artifacts/pull_request_results

# run tests against previous previous_release to compare outputs 
git clone https://github.com/BCCDC-PHL/routine-sequence-qc.git previous_release 
pushd previous_release
git checkout 1a4197efd32cd03983a64c439cfe56ea09258fff -b previous-release

echo "Nextflow run previous release..." >> ../artifacts/test_artifact.log
NXF_VER=20.10.0 nextflow -C ${PWD}/../.github/config/nextflow.config -quiet run ./main.nf \
       -profile conda \
       --cache ${HOME}/.conda/envs \
       --kraken2_db ${PWD}/../.github/data/kraken2_db \
       --bracken_db ${PWD}/../.github/data/kraken2_db \
       --run_dir ${PWD}/../.github/data/mock_runs/210101_M00000_0000_000000000-A1B2C \
       --outdir results

cp .nextflow.log ../artifacts/previous_release.nextflow.log
cp -r results ../artifacts/previous_release_results

popd

# exclude files from comparison
# and list differences
echo "Compare ouputs of current PR vs those of previous release.." >> artifacts/test_artifact.log
find results ./previous_release/results \
     -name "multiqc.log" \
     -o -name "multiqc_sources.txt" \
     -o -name "multiqc_data.json" \
     -o -name "multiqc_report.html" \
     -o -name "pipeline_complete.json" \
    | xargs rm -rf

if ! git diff --stat --no-index results ./previous_release/results > diffs.txt ; then
  echo "test failed: differences found between PR and previous release" >> artifacts/test_artifact.log
  echo "see diffs.txt" >> artifacts/test_artifact.log 
  cp diffs.txt artifacts/  
  exit 1
else
  echo "no differences found between PR and previous release" >> artifacts/test_artifact.log
fi

# clean-up for following tests
rm -rf previous_release && rm -rf results && rm -rf work && rm -rf .nextflow*
