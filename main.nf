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
    esearch -db nucleotide -query "${id}" | efetch -format fasta > "${id}.fasta"
    """
}

// --------- Process: Concatenate all FASTA files ---------
process merge_fasta {
    
    publishDir "${params.output}", mode: 'copy'
    
    input:
    path all_fastas

    output:
    path "${params.combined}"

    script:
    """
    cat ${all_fastas.join(' ')} > ${params.combined}
    """
}

// --------- Process: Align using MAFFT ---------
process run_mafft {
    conda 'conda-forge::mafft=7.526'

    input:
    path input_fasta

    output:
    path "${params.aligned}"

    script:
    """
    mafft --auto --thread -1 ${input_fasta} > ${params.aligned}
    """
}

// --------- Process: Trim alignment with TrimAl ---------
process trim_alignment {
    conda 'bioconda::trimal=1.5.0'

    publishDir "${params.output}", mode: 'copy'

    input:
    path aligned_fasta

    output:
    path "${params.trimmed}"
    path "${params.report}"

    script:
    """
    trimal -in ${aligned_fasta} -out ${params.trimmed} -automated1 -htmlout ${params.report}
    """
}

// --------- Workflow Definition ---------
workflow {
    ref_fasta_ch = download_fasta(params.query)
    local_fastas_ch = Channel.fromPath("${params.raw_dir}/*.fasta")
    all_fastas_ch = ref_fasta_ch.mix(local_fastas_ch).collect()

    merge_fasta(all_fastas_ch)
    run_mafft(merge_fasta.out)
    trim_alignment(run_mafft.out)
}