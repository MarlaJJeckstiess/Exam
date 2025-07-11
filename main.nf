#!/usr/bin/env nextflow

// --------- Parameters ---------
params.query = "M21012"
params.raw_dir = "hepatitis_data"
params.output = "results"
params.combined = "all_sequences.fasta"
params.aligned = "aligned_seqs.fasta"
params.trimmed = "aligned_trimmed.fasta"
params.report = "trim_summary.html"

// --------- Process: Download sequence ---------
process download_fasta {
    conda 'bioconda::entrez-direct=24.0'

    input:
    val id

    output:
    path "${id}.fasta"

    script:
    """
    esearch -db nucleotide -query "${id}" | efetch fasta > "${id}.fasta"
    """
}

// --------- Process: Concatenate all FASTA files ---------
process merge_fasta {
    
    input:
    path fasta_folder

    output:
    path "${params.combined}"

    script:
    """
    cat ${fasta_folder}/*.fasta > ${params.combined}
    """
}

// --------- Process: Align using MAFFT ---------
process run_mafft {
    conda 'conda-forge::mafft=7.526'

    input:
    path multi_fasta

    output:
    path "${params.aligned}"

    script:
    """
    mafft --auto --thread -1 ${multi_fasta} > ${params.aligned}
    """
}

// --------- Process: Trim alignment with TrimAl ---------
process trim_alignment {
    conda 'bioconda::trimal=1.5.0'

    publishDir "${params.output}/trimmed", mode: 'copy', pattern: '*'

    input:
    path mafft_output

    output:
    path "${params.trimmed}"
    path "${params.report}"

    script:
    """
    trimal -in ${mafft_output} -out ${params.trimmed} -automated1 -htmlout ${params.report}
    """
}

// --------- Workflow Definition ---------
workflow {
    download_fasta(params.query)

    def fasta_dir = Channel.fromPath(params.raw_dir, type: 'dir')
    merge_fasta(fasta_dir)

    run_mafft(merge_fasta.out)

    trim_alignment(run_mafft.out)
}