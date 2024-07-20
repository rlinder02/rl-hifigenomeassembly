/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { HIFI_QC                } from '../subworkflows/local/hifi_qc'
include { GENOME_ASSEMBLY        } from '../subworkflows/local/genome_assembly'
include { ASSEMBLY_QC            } from '../subworkflows/local/assembly_qc'
include { SYNTENY                } from '../subworkflows/local/synteny'
include { SV                     } from '../subworkflows/local/sv'
include { REPEATS                } from '../subworkflows/local/repeats'

include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_hifigenomeassembly_pipeline'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CREATE CHANNELS FOR ADDITIONAL INPUT NEEDED
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMBLE {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: Run QC on PacBio HiFi reads
    //
    HIFI_QC (
        ch_samplesheet  
    )

    ch_multiqc_files = ch_multiqc_files.mix(HIFI_QC.out.n50.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(HIFI_QC.out.read_len_plot.map {it[1]})
    ch_versions = ch_versions.mix(HIFI_QC.out.versions)

    //
    //SUBWORKFLOW: Assemble PacBio HiFi reads and scaffold using a reference genome
    //
    GENOME_ASSEMBLY (
        ch_samplesheet
    )

    ch_assembly_fasta = GENOME_ASSEMBLY.out.assembly
    ch_assembly_scaffold = GENOME_ASSEMBLY.out.corrected_scaffold
    ch_corrected_ref = GENOME_ASSEMBLY.out.corrected_ref
    ch_multiqc_files = ch_multiqc_files.mix(GENOME_ASSEMBLY.out.assembly.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(GENOME_ASSEMBLY.out.corrected_scaffold.map {it[1]})
    ch_versions = ch_versions.mix(GENOME_ASSEMBLY.out.versions)

    //
    //SUBWORKFLOW: QC the genome assembly (contigs and scaffolded assembly)
    //
    ASSEMBLY_QC (
        ch_assembly_fasta,              // path to genome assembly 
        ch_corrected_ref,
        ch_samplesheet
    )
    
    ch_multiqc_files = ch_multiqc_files.mix(ASSEMBLY_QC.out.cov_plot.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(ASSEMBLY_QC.out.busco_plot.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(ASSEMBLY_QC.out.quast_plots.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(ASSEMBLY_QC.out.kat_plots.map {it[1]})

    ch_versions = ch_versions.mix(ASSEMBLY_QC.out.versions.first())

    //
    // SUBWORKFLOW: Synteny analysis
    //
    SYNTENY (
        ch_samplesheet,
        ch_assembly_scaffold, // path to genome scaffold
        ch_corrected_ref      // path to reference genome 
    )
    ch_multiqc_files = ch_multiqc_files.mix(SYNTENY.out.synteny_plot.map {it[1]})
    ch_versions = ch_versions.mix(SYNTENY.out.versions.first())

    //
    // SUBWORKFLOW: SV analysis
    //
    SV (
        ch_assembly_scaffold, // path to genome scaffold
        ch_corrected_ref
    )
    ch_multiqc_files = ch_multiqc_files.mix(SV.out.sv_calls.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(SV.out.sv_plot.map {it[1]})
    ch_versions = ch_versions.mix(SV.out.versions.first())

    //
    // SUBWORKFLOW: Repeat masking
    //
    REPEATS (
        ch_assembly_scaffold // path to genome scaffold
    )
    ch_multiqc_files = ch_multiqc_files.mix(REPEATS.out.masked_fasta.map {it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(REPEATS.out.repeat_tbl.map {it[1]})
    ch_versions = ch_versions.mix(REPEATS.out.versions.first())

    //
    // Collate and save software versions
    //
//     softwareVersionsToYAML(ch_versions)
//         .collectFile(
//             storeDir: "${params.outdir}/pipeline_info",
//             name: 'nf_core_pipeline_software_mqc_versions.yml',
//             sort: true,
//             newLine: true
//         ).set { ch_collated_versions }

//     //
//     // MODULE: MultiQC
//     //
//     ch_multiqc_config        = Channel.fromPath(
//         "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
//     ch_multiqc_custom_config = params.multiqc_config ?
//         Channel.fromPath(params.multiqc_config, checkIfExists: true) :
//         Channel.empty()
//     ch_multiqc_logo          = params.multiqc_logo ?
//         Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
//         Channel.empty()

//     summary_params      = paramsSummaryMap(
//         workflow, parameters_schema: "nextflow_schema.json")
//     ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

//     ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
//         file(params.multiqc_methods_description, checkIfExists: true) :
//         file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
//     ch_methods_description                = Channel.value(
//         methodsDescriptionText(ch_multiqc_custom_methods_description))

//     ch_multiqc_files = ch_multiqc_files.mix(
//         ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
//     ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
//     ch_multiqc_files = ch_multiqc_files.mix(
//         ch_methods_description.collectFile(
//             name: 'methods_description_mqc.yaml',
//             sort: true
//         )
//     )

//     MULTIQC (
//         ch_multiqc_files.collect(),
//         ch_multiqc_config.toList(),
//         ch_multiqc_custom_config.toList(),
//         ch_multiqc_logo.toList()
//     )

//     emit:
//     multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
//     versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
