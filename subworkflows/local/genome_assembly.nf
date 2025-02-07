include { HIFIASM                        } from '../../modules/nf-core/hifiasm/main'
include { ASSEMBLY_STATS2 as TO_FASTA    } from '../../modules/local/assemblystats2'
include { FCS_FCSADAPTOR                 } from '../../modules/nf-core/fcs/fcsadaptor/main'
include { FCSGX                          } from '../../modules/local/fcsgx'
include { RAGTAG                         } from '../../modules/local/ragtag'
include { PREP_FASTAS                    } from '../../modules/local/prepfastas'

workflow GENOME_ASSEMBLY {

    take:
    
    ch_samplesheet // channel: [ val(meta), path(fastq.gz), path(ref.fasta) ]

    main:

    ch_fastq = ch_samplesheet.map { meta, file, fasta -> [meta, file] }
    ch_ref = ch_samplesheet.map { meta, file, fasta -> [meta, fasta] }
    ch_chr_names = params.chr_names
    ch_versions = Channel.empty()

    HIFIASM ( ch_fastq,
              params.primary_only 
            )
    ch_versions = ch_versions.mix(HIFIASM.out.versions.first())

    ch_hap_primary = HIFIASM.out.processed_contigs.map { meta, path ->  
                                        meta = meta + [type:'primary']
                                        [meta, path]
                                        }
    ch_ref_primary = ch_ref.map { meta, path ->
                                meta = meta + [type:'primary']
                                [meta,path]
                                }

    if (params.primary_only) {
        ch_haps = ch_hap_primary
        ch_refs = ch_ref_primary
    } else {
        ch_hap1 = HIFIASM.out.haplotype1.map { meta, path ->  
                                        meta = meta + [type:'hap1']
                                        [meta, path]
                                        }
        ch_ref_hap1 = ch_ref.map { meta, path ->
                                    meta = meta + [type:'hap1']
                                    [meta,path]
                                    }
        ch_hap2 = HIFIASM.out.haplotype2.map { meta, path ->  
                                            meta = meta + [type:'hap2']
                                            [meta, path]
                                            }
        ch_ref_hap2 = ch_ref.map { meta, path ->
                                    meta = meta + [type:'hap2']
                                    [meta,path]
                                    }
        ch_both_haps = ch_hap1.mix(ch_hap2)
        ch_both_refs = ch_ref_hap1.mix(ch_ref_hap2)
        ch_haps = ch_both_haps
        ch_refs = ch_both_refs
        //ch_haps.view()
        ch_refs.view()
    }

    TO_FASTA ( ch_haps )

    ch_versions = ch_versions.mix(TO_FASTA.out.versions.first())

    FCS_FCSADAPTOR ( TO_FASTA.out.fasta )
    ch_versions = ch_versions.mix(FCS_FCSADAPTOR.out.versions.first())
    
    FCSGX ( FCS_FCSADAPTOR.out.cleaned_assembly,
            params.gxdb,
            params.tax_id
    )
    
    ch_assembly_ref = FCSGX.out.cleaned_assembly.combine(ch_refs,by:0)
    RAGTAG ( ch_assembly_ref  )
    ch_versions = ch_versions.mix(RAGTAG.out.versions.first())

    ch_ragtag_ref = RAGTAG.out.fasta.combine(ch_refs,by:0)

    PREP_FASTAS ( ch_ragtag_ref,
                  ch_chr_names 
    )
    ch_versions = ch_versions.mix(PREP_FASTAS.out.versions.first())

    emit:
    corrected_scaffold    = PREP_FASTAS.out.scaffold_modified          // channel: [ val(meta), path(fasta) ]
    assembly              = FCSGX.out.cleaned_assembly                 // channel: [ val(meta), path(fa.gz) ]
    corrected_ref         = PREP_FASTAS.out.ref_modified               // channel: [ val(meta), path(fasta))]
    versions              = ch_versions                                // channel: path(versions.yml)
}

