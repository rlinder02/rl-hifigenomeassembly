include { HIFIASM                        } from '../../modules/nf-core/hifiasm/main'
include { ASSEMBLY_STATS2 as TO_FASTA    } from '../../modules/local/assemblystats2'
include { FCS_FCSADAPTOR                 } from '../../modules/nf-core/fcs/fcsadaptor/main'  
include { RAGTAG                         } from '../../modules/local/ragtag'

workflow GENOME_ASSEMBLY {

    take:
    
    ch_samplesheet // channel: [ val(meta), path(fastq.gz), path(ref.fasta) ]

    main:

    ch_fastq = ch_samplesheet.map { meta, file, fasta -> [meta, file] }
    ch_ref = ch_samplesheet.map { meta, file, fasta -> [fasta] }
    ch_versions = Channel.empty()

    HIFIASM ( ch_fastq )
    ch_versions = ch_versions.mix(HIFIASM.out.versions.first())

    TO_FASTA ( HIFIASM.out.processed_contigs )
    ch_versions = ch_versions.mix(TO_FASTA.out.versions.first())

    FCS_FCSADAPTOR ( TO_FASTA.out.fasta )
    ch_versions = ch_versions.mix(FCS_FCSADAPTOR.out.versions.first())

    RAGTAG ( FCS_FCSADAPTOR.out.cleaned_assembly,
             ch_ref 
    )
    ch_versions = ch_versions.mix(RAGTAG.out.versions.first())


    emit:
    scaffold              = RAGTAG.out.fasta                           // channel: [ val(meta), path(fasta) ]
    assembly              = FCS_FCSADAPTOR.out.cleaned_assembly        // channel: [ val(meta), path(fa.gz) ]
    versions              = ch_versions                                // channel: path(versions.yml)
}

