include { BIOAWK as READ_LEN     } from '../../modules/nf-core/bioawk/main'
include { ASSEMBLY_STATS         } from '../../modules/local/assemblystats'
include { PLOT_READ_LEN          } from '../../modules/local/plotreadlen'


workflow HIFI_QC {

    take:

    ch_samplesheet // channel: [ val(meta), path(fastq.gz), path(ref.fasta) ]

    main:

    ch_fastq = ch_samplesheet.map { meta, file, fasta -> [meta, file] }
    ch_versions = Channel.empty()
    ch_optional_input = Channel.of("/")
    ch_fastq_empty = ch_fastq.combine(ch_optional_input)

    READ_LEN ( ch_fastq_empty )
    ch_versions = ch_versions.mix(READ_LEN.out.versions.first())

    ASSEMBLY_STATS ( ch_fastq )
    ch_versions = ch_versions.mix(ASSEMBLY_STATS.out.versions.first())

    PLOT_READ_LEN ( READ_LEN.out.csv )


    emit:
    n50                = ASSEMBLY_STATS.out.txt        // channel: [ val(meta), path(txt) ]
    read_len_plot      = PLOT_READ_LEN.out.pdf         // channel: [ val(meta), path(pdf) ]
    versions           = ch_versions                   // channel: path(versions.yml)
}

