#!/usr/bin/env bash

set -eu

OUTFILE="$1"
SEQS="$2"

rm -rf -- seqs clusters representative tmp

mkdir seqs clusters representative tmp
mmseqs createdb "${SEQS}" seqs/db

mmseqs cluster \
  seqs/db \
  clusters/db \
  tmp \
  --cov-mode 0 \
  -c 0.8 \
  --min-seq-id 0.8 \
  --cluster-mode 0

mmseqs createtsv seqs/db seqs/db clusters/db "${OUTFILE}.tsv"

mmseqs createsubdb clusters/db seqs/db representative/db
mmseqs convert2fasta representative/db "${OUTFILE}"

rm -rf -- seqs clusters representative tmp
