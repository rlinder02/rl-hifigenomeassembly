process HIFIASM {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.19.8--h43eeafb_0' :
        'biocontainers/hifiasm:0.19.8--h43eeafb_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.r_utg.gfa")        , emit: raw_unitigs
    tuple val(meta), path("*.ec.bin")           , emit: corrected_reads
    tuple val(meta), path("*.ovlp.source.bin")  , emit: source_overlaps
    tuple val(meta), path("*.ovlp.reverse.bin") , emit: reverse_overlaps
    tuple val(meta), path("*.bp.hap1.p_ctg.gfa"), emit: haplotype1
    tuple val(meta), path("*.bp.hap2.p_ctg.gfa"), emit: haplotype2
    tuple val(meta), path("*.bp.p_ctg.gfa")     , emit: processed_contigs, optional: true
    tuple val(meta), path("*.asm.p_ctg.gfa")    , emit: primary_contigs  , optional: true
    tuple val(meta), path("*.log")              , emit: log
    path  "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    hifiasm \\
        $args \\
        -o ${prefix}.asm \\
        -t $task.cpus \\
        $reads \\
        2> >( tee ${prefix}.stderr.log >&2 )

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(hifiasm --version 2>&1)
    END_VERSIONS
    """
   
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.asm.r_utg.gfa
    touch ${prefix}.asm.ec.bin
    touch ${prefix}.asm.ovlp.source.bin
    touch ${prefix}.asm.ovlp.reverse.bin
    touch ${prefix}.asm.bp.p_ctg.gfa
    touch ${prefix}.asm.p_utg.gfa
    touch ${prefix}.asm.p_ctg.gfa
    touch ${prefix}.asm.a_ctg.gfa
    touch ${prefix}.asm.hap1.p_ctg.gfa
    touch ${prefix}.asm.hap2.p_ctg.gfa
    touch ${prefix}.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(hifiasm --version 2>&1)
    END_VERSIONS
    """
}
