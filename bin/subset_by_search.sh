#!/usr/bin/env bash

# Subtract matches to target from query

OUTFILE="$1"
QUERY="$2"
TARGET="$3"

rm -rf -- query target results tmp
mkdir query target results tmp

mmseqs createdb "${QUERY}" query/db
mmseqs createdb "${TARGET}" target/db

mmseqs search \
  query/db \
  target/db \
  results/db \
  tmp \
  -e 0.00001

mmseqs convertalis \
  query/db \
  target/db \
  results/db \
  query_matches.tsv \
  --format-output qheader

sed 's/\([^[:space:]]*\).*/\1/' query_matches.tsv | uniq > query_matches_unique.tsv
bin/fasta_to_tsv.sh "${QUERY}" \
| grep -f query_matches_unique.tsv -vF \
| bin/tsv_to_fasta.sh \
> "${OUTFILE}"

rm -rf -- query target results tmp query_matches_unique.tsv query_matches.tsv
