#!/usr/bin/env bash

set -euo pipefail

INDIR="raw/proteomes"
OUTFILE="processed/proteomes.tsv"
mkdir -p "$(dirname "${OUTFILE}")"

rm -f "${OUTFILE}"
touch "${OUTFILE}"

for f in "${INDIR}"/*.fasta
do
    ISOLATE="$(basename "${f%.fasta}")"
    sed "s/^>/>${ISOLATE}_/" "${f}" \
    | bin/fasta_to_tsv.sh \
    | awk -F'\t' '{print "proteome\t"$0}' \
    >> "${OUTFILE}" 
done
