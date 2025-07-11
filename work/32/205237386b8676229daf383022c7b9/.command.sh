#!/bin/bash -ue
mafft --auto --thread -1 all_sequences.fasta > aligned_seqs.fasta
