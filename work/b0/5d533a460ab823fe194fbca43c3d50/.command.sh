#!/bin/bash -ue
esearch -db nucleotide -query "M21012" | efetch fasta > "M21012.fasta"
