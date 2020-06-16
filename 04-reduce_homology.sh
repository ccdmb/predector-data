#!/usr/bin/env bash

set -euo pipefail

TMPDIR="tmp$$"

EFFECTORS="raw/fungal_effectors.tsv"
LOCALIZED="processed/localised.tsv"
PROTEOMES="processed/proteomes.tsv"
HOMOLOGS="processed/effector_homologues.fasta"

OUTCLUSTERS="processed/clusters.tsv"

mkdir -p "${TMPDIR}"
mkdir -p "$(dirname "${OUTCLUSTERS}")"

awk -F'\t' '{print $5"\t"$20}' "${EFFECTORS}" \
| tail -n+2 \
| sed 's/\*[[:space:]]*$//' \
| bin/tsv_to_fasta.sh \
> "${TMPDIR}/combined.fasta"

awk -F'\t' 'BEGIN {OFS="\t"} {print $2, $3}' "${LOCALIZED}" | bin/tsv_to_fasta.sh >> "${TMPDIR}/combined.fasta"
awk -F'\t' 'BEGIN {OFS="\t"} {print $2, $3}' "${PROTEOMES}" | bin/tsv_to_fasta.sh >> "${TMPDIR}/combined.fasta"

cat "${HOMOLOGS}" >> "${TMPDIR}/combined.fasta"

rm -rf -- "${TMPDIR}/seqs" "${TMPDIR}/clu" "${TMPDIR}/tmp"
mkdir -p "${TMPDIR}/seqs" "${TMPDIR}/clu" "${TMPDIR}/tmp"

mmseqs createdb "${TMPDIR}/combined.fasta" "${TMPDIR}/seqs/db"

mmseqs cluster \
  "${TMPDIR}/seqs/db" \
  "${TMPDIR}/clu/db" \
  "${TMPDIR}/tmp" \
  --min-seq-id 0.3 \
  --cov-mode 0 \
  -c 0.7 \
  --cluster-mode 0

mmseqs createtsv \
  "${TMPDIR}/seqs/db" \
  "${TMPDIR}/seqs/db" \
  "${TMPDIR}/clu/db" \
  "${OUTCLUSTERS}"
