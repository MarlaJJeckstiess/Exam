#!/bin/bash -ue
esearch -db nucleotide -query "M21012" | efetch -format fasta > "M21012.fasta"
