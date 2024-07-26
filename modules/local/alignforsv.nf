process ALIGN_FOR_SV {
    tag "${meta.id}.${meta.type}"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/minimap2_samtools:7e38c0cfb1291cfb' :
        'community.wave.seqera.io/library/minimap2_samtools:7e38c0cfb1291cfb' }"

    input:
    tuple val(meta), path(scaffold), path(ref)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.type}"
    """
    minimap2 \\
        $args \\
        -a \\
        -x asm5 \\
        --cs \\
        -r2k \\
        -t $task.cpus \\
        $ref \\
        $scaffold \\
    | \\
    samtools \\
        sort \\
        $args \\
        -m4G \\
        -@ $task.cpus \\
        -O BAM \\
        -o ${prefix}_sv_alignment.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alignforsv: \$(minimap2 --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_sv_alignment.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alignforsv: \$(minimap2 --version)
    """
}
