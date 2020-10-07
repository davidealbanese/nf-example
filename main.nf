#!/usr/bin/env nextflow

/* 
 * The example executes for each input file a BLAST query in a parallel manner.
 * Then, all the sequences for the top hits are collected in the output direcory.
 */

db_name = file(params.db).name
db_dir = file(params.db).parent
 
/*
 * Given the query parameter creates a channel emitting the query fasta file(s)
 */
Channel
    .fromPath(params.query)
    .map { file -> tuple(file.baseName, file) }
    .set { fasta_ch }
 
/*
 * Executes a BLAST job for each file emitted by the 'fasta_ch' channel
 * and creates as output a channel named 'top_hits' emitting the resulting
 * BLAST matches 
 */
process blast {
    input:
    tuple val(id), path(query) from fasta_ch
    path db from db_dir
 
    output:
    tuple val(id), path('top_hits') into hits_ch
 
    """
    blastp -db $db/$db_name -query $query -outfmt 6 > blast_result
    cat blast_result | head -n 10 | cut -f 2 > top_hits
    """
}
 
/*
 * Each time a file emitted by the 'top_hits' channel an extract job is executed
 * producing a file containing the matching sequences
 */
process extract {

    publishDir "${params.outdir}"

    input:
    tuple val(id), path('top_hits') from hits_ch
    path db from db_dir
 
    output:
    file 'sequences_*' into sequences_ch
 
    """
    blastdbcmd -db $db/$db_name -entry_batch top_hits | head -n 10 > sequences_${id}
    """
}
