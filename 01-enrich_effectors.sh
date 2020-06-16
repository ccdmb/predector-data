#!/usr/bin/env bash

set -euo pipefail


EFFECTORS="raw/fungal_effectors.tsv"
UNIREF="raw/uniref90_fungal.fasta.gz"

OUT_TABFILE="processed/effector_homologues.tsv"
OUT_FASTAFILE="processed/effector_homologues.fasta"


TMPDIR="tmp$$"
mkdir -p "${TMPDIR}"
mkdir -p "$(dirname "${OUT_TABFILE}")"
mkdir -p "$(dirname "${OUT_FASTAFILE}")"

awk -F'\t' '$6 != "no" {print $5"\t"$20}' "${EFFECTORS}" \
| tail -n+2 \
| sed 's/\*[[:space:]]*$//' \
| bin/tsv_to_fasta.sh \
> "${TMPDIR}/effectors.fasta"

rm -rf -- "${TMPDIR}/query" "${TMPDIR}/target" "${TMPDIR}/results" "${TMPDIR}/tmp"
mkdir "${TMPDIR}/query" "${TMPDIR}/target" "${TMPDIR}/results" "${TMPDIR}/tmp"

mmseqs createdb "${TMPDIR}/effectors.fasta" "${TMPDIR}/query/db"
mmseqs createdb "${UNIREF}" "${TMPDIR}/target/db"
mmseqs createindex "${TMPDIR}/target/db" "${TMPDIR}/tmp"

mmseqs search \
  "${TMPDIR}/query/db" \
  "${TMPDIR}/target/db" \
  "${TMPDIR}/results/db" \
  "${TMPDIR}/tmp" \
  -e 0.00001 \
  --start-sens 3 \
  -s 7.0 \
  --sens-steps 3 \
  --cov-mode 0 \
  -c 0.7 \


mmseqs convertalis \
  "${TMPDIR}/query/db" \
  "${TMPDIR}/target/db" \
  "${TMPDIR}/results/db" \
  "${TMPDIR}/target_matches.tsv" \
  --format-output "query,target,evalue,pident,bits,qstart,qend,qlen,tstart,tend,tlen,theader"


cut -f2 "${TMPDIR}/target_matches.tsv" \
| uniq \
> "${TMPDIR}/target_matches_unique.tsv"

zcat "${UNIREF}" \
| bin/fasta_to_tsv.sh \
| grep -f "${TMPDIR}/target_matches_unique.tsv" -F \
| sort -k 1b,1 \
> "${TMPDIR}/target_match_sequences.tsv"

bin/tsv_to_fasta.sh "${TMPDIR}/target_match_sequences.tsv" > "${OUT_FASTAFILE}"

join -1 2 -2 1 -t '	' \
    <(sort -k 2b,2 "${TMPDIR}/target_matches.tsv") \
    "${TMPDIR}/target_match_sequences.tsv" \
> "${OUT_TABFILE}"


rm -rf -- "${TMPDIR}"
