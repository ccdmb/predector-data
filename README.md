# Test and training data for predector

This repository contains all data and code used to train the predector pipeline.
We include in this set: known effectors, known secreted proteins, known non-secreted proteins, and unlabelled data from several well studied pathogens.

The final training/test fasta and tsv in placed in the `processed` folder as `test.fasta`, `train.fasta`, `representative.fasta`, and `representative.tsv`.
`representative.{fasta,tsv}` contains information about both training and test sequences.


## Effector

As a positive dataset for effector prediction we use a curated dataset available in `raw/fungal_effectors.tsv`.
This dataset includes all effectors in the EffectorP training datasets and several additional ones.
We also include some published homologous proteins of known effectors, which do not exist in UniProt/NCBI.
These homologues are labelled in the `validated` column as `no`.

## Effector homologues

To increase the size of our effector training set, we include a number of effector homologues for evaluation.
The effector spreadsheet includes some effector homologues, but we also find more homologues by searching the UniRef 90 (release 2020_01; downloaded 2020-06-01) database of fungal proteins obtained with the following query:

```
taxonomy:"Fungi [4751]" AND identity:0.9
```

Due to size constraints, we don't store this file in the repository, but it would ordinarily be saved as `raw/uniref90_fungal.fasta.gz`.


## Secretion prediction data

Known fungal secreted proteins were extracted from UniProtKB (release 2020_01; downloaded 2020-06-01) using the following queries.

fungal_secreted:

```
taxonomy:"Fungi [4751]" AND locations:(location:"Secreted [SL-0243]" evidence:manual) NOT (locations:(location:membrane) OR annotation:(type:transmem) OR annotation:(type:intramem))
```

fungal_non_secreted:
```
taxonomy:"Fungi [4751]" NOT (keyword:"Secreted [KW-0964]") AND reviewed:yes
```

fungal_membrane:
```
taxonomy:"Fungi [4751]" AND (locations:(location:membrane evidence:experimental) OR annotation:(type:transmem evidence:experimental) OR annotation:(type:intramem evidence:experimental))
```

fungal_er:
```
taxonomy:"Fungi [4751]" locations:(location:"Endoplasmic reticulum [SL-0095]" evidence:experimental)
```

fungal_golgi:
```
taxonomy:"Fungi [4751]" locations:(location:golgi evidence:experimental)
```

fungal_gpi:
```
taxonomy:"Fungi [4751]" locations:(location:"GPI-anchor [SL-9902]" evidence:experimental)
```

These sequences are stored in `raw/uniprot`.
We use fungal_secreted as a positive secreted set, and all others as a known non-secreted set.


## Proteome data

As an unlabelled dataset we use predicted proteomes from several well studied pathogens with known effectors. The proteomes used are described in the table `raw/proteomes.tsv`.

The proteomes are labelled as either train or test. The test set is in `raw/proteomes_test` and are used for evaluating the pipeline outside of the train-test split set.
The proteomes used in the training/test set are in `raw/proteomes`.


## Generating the training set

A number of scripts in this directory generate the training/test datasets.
Steps 1-4 are run without arguments, but scripts can be modified if the names don't match up.

- `01-enrich_effectors.sh` finds effector homologues in the uniref90 dataset using mmseqs2.
- `02-process_secretome.sh` combines the secreted and non-secreted sets.
- `03-process_proteomes.sh` combines the proteomes and prepends the isolate names to the protein sequence ids.
- `04-reduce_homology.sh` Combines all of the sequences, and clusters the proteins to remove redundancy using MMSeqs2. We cluster to a minimum sequence identity of 30% and requiring a reciprocal coverage of 70%. I.e. both the cluster centroid and the cluster member should be covered by the alignment at least 70% of their length.
- `05-label_data.ipynb` Generates a final combined dataset, selects cluster centroids by prioritising members in the following order known effector > known secreted > known non-secreted > proteome or effector homologue. It also completes the train-test split, retaining the same effector train-test split as EffectorP2 and setting 20% of the remaining proteins aside as a test set.
