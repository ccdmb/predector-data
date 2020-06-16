#!/usr/bin/env bash

# Subtract matches to target from query

OUTFILE="$1"
QUERY="$2"
# Target should be gzipped
TARGET="$3"

rm -rf -- query target results tmp
mkdir query target results tmp

mmseqs createdb "${QUERY}" query/db
mmseqs createdb "${TARGET}" target/db
mmseqs createindex target/db tmp

mmseqs search \
  query/db \
  target/db \
  results/db \
  tmp \
  -e 0.00001 \
  --start-sens 3 \
  -s 7.0 \
  --sens-steps 3 \
  --slice-search \
  --cov-mode 0 \
  -c 0.7 \


mmseqs convertalis \
  query/db \
  target/db \
  results/db \
  target_matches.tsv \
  --format-output "query,target,evalue,pident,bits,qstart,qend,qlen,tstart,tend,tlen,theader"


cut -f12 target_matches.tsv | sed 's/\([^[:space:]]*\).*/\1/' | uniq > target_matches_unique.tsv

zcat "${TARGET}" \
| bin/fasta_to_tsv.sh \
| grep -f target_matches_unique.tsv -F \
| bin/tsv_to_fasta.sh \
> "${OUTFILE}"

# rm -rf -- query target results tmp target_matches_unique.tsv target_matches.tsv
