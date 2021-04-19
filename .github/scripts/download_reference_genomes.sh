#!/bin/bash

set -eo pipefail

echo "Download Reference Genomes..." >> artifacts/test_artifact.log

mkdir -p $PWD/.github/data/ref_genomes

pushd $PWD/.github/data/ref_genomes

while read -r accession; do
    ncbi-acc-download --format fasta ${accession}
    sleep 5
done < ../ref_genome_list.txt

popd