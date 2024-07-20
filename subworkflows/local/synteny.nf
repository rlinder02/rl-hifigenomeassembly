include { ALIGN_FOR_SYNTENY      } from '../../modules/local/alignforsynteny'
include { SYRI                   } from '../../modules/local/syri'

workflow SYNTENY {

    take:

    ch_samplesheet
    ch_assembly_scaffold // channel: [ val(meta), path(scaffold_fasta) ]
    ch_corrected_ref     // channel: [ path(fasta) ]

    main:
    ch_versions = Channel.empty()

    ALIGN_FOR_SYNTENY ( ch_assembly_scaffold,
                        ch_corrected_ref
    )
    ch_versions = ch_versions.mix(ALIGN_FOR_SYNTENY.out.versions.first())

    SYRI ( ALIGN_FOR_SYNTENY.out.sam,
           ch_corrected_ref,
           ch_assembly_scaffold
     )
    ch_versions = ch_versions.mix(SYRI.out.versions.first())

    emit:
    synteny_plot      = SYRI.out.png           // channel: [ val(meta), path(png) ]
    versions          = ch_versions            // channel: [ versions.yml ]
}

