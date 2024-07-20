process ALIGN_FOR_SYNTENY {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/minimap2_samtools:7e38c0cfb1291cfb' :
        'community.wave.seqera.io/library/minimap2_samtools:7e38c0cfb1291cfb' }"

    input:
    tuple val(meta), path(scaffold)
    path(ref)

    output:
    tuple val(meta), path("*.sam"), emit: sam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    minimap2 \\
        $args \\
        -a \\
        -x asm5 \\
        --eqx \\
        -t $task.cpus \\
        -o ${prefix}.syri.sam \\
        $ref \\
        $scaffold

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alignforsynteny: \$(minimap2 --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.syri.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alignforsynteny: \$(minimap2 --version)
    END_VERSIONS
    """
}
