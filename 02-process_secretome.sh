#!/usr/bin/env bash

set -euo pipefail

OUTFILE="processed/localised.tsv"
TMPDIR="tmp$$"

mkdir -p "$(dirname "${OUTFILE}")"


zcat raw/uniprot/uniprot_fungal_secreted.fasta.gz \
| bin/fasta_to_tsv.sh \
| awk '{print "secreted\t"$0}' \
| sort -u \
> "${OUTFILE}"

zcat raw/uniprot/{uniprot_fungal_non_secreted.fasta.gz,uniprot_fungal_membrane.fasta.gz,uniprot_fungal_er.fasta.gz,uniprot_fungal_golgi.fasta.gz,/uniprot_fungal_gpi.fasta.gz} \
| bin/fasta_to_tsv.sh \
| sort -u \
| awk '{print "non_secreted\t"$0}' \
>> "${OUTFILE}"



exit 0








EFFECTORS="$1"


# Homology reduce secreted
awk -F'\t' '$3 != "no" {print $9"\t"$16}' data/fungal_effectors.tsv \
| tail -n+2 \
| sed 's/\*[[:space:]]*$//' \
| bin/tsv_to_fasta.sh \
> secreted.fasta

zcat data/uniprot_fungal_secreted.fasta.gz >> secreted.fasta

bin/reduce_homologous.sh reduced_secreted.fasta secreted.fasta


# Homology reduce non-secreted
zcat data/uniprot_fungal_non_secreted.fasta.gz data/uniprot_fungal_membrane.fasta.gz \
     data/uniprot_fungal_er.fasta.gz data/uniprot_fungal_golgi.fasta.gz \
     data/uniprot_fungal_gpi.fasta.gz \
| bin/fasta_to_tsv.sh \
| sort -u \
| bin/tsv_to_fasta.sh \
> non_secreted.fasta

bin/reduce_homologous_remote.sh reduced_non_secreted.fasta non_secreted.fasta

# Remove any remaining secreted from non-secreted
bin/subset_by_search.sh subset_non_secreted.fasta reduced_non_secreted.fasta secreted.fasta


# Generate secreted train_test_split

awk -F'\t' '$3 != "no" && $1 == "test" {print $9}' data/fungal_effectors.tsv > test_targets.txt
awk -F'\t' '$3 != "no" && $1 == "train" {print $9}' data/fungal_effectors.tsv > train_targets.txt

grep -f test_targets.txt -F reduced_secreted.fasta.tsv | awk '{print $1}' > test_effector.txt

grep -f train_targets.txt -vF reduced_secreted.fasta.tsv \
| awk '{print $1}' \
| shuf -n 100 \
> test_non_effector.txt

bin/fasta_to_tsv.sh reduced_secreted.fasta \
| grep -F -f <(cat test_effector.txt test_non_effector.txt) \
| bin/tsv_to_fasta.sh \
> secreted_test.fasta

bin/fasta_to_tsv.sh reduced_secreted.fasta \
| grep -vF -f <(cat test_effector.txt test_non_effector.txt) \
| bin/tsv_to_fasta.sh \
> secreted_train.fasta

rm -f test_effector.txt test_non_effector.txt train_targets.txt test_targets.txt


# Generate nonsecreted train test split
bin/fasta_to_tsv.sh subset_non_secreted.fasta \
| shuf -n 1000 \
> non_secreted_test.tsv

bin/tsv_to_fasta.sh non_secreted_test.tsv > non_secreted_test.fasta


bin/fasta_to_tsv.sh reduced_non_secreted.fasta \
| grep -vF -f <(awk -F '\t' '{ print $1 }' non_secreted_test.tsv) \
| bin/tsv_to_fasta.sh \
> non_secreted_train.fasta

rm -f non_secreted_train.tsv non_secreted_test.tsv
rm -f secreted.fasta non_secreted.fasta reduced_non_secreted.fasta* reduced_secreted.fasta*
rm -f subset_non_secreted.fasta
