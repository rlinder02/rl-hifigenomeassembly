process ASSEMBLY_STATS {
    tag "$meta.id"
    label 'process_low'
    debug true

    conda "bioconda::assembly-stats=1.0.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats:1.0.1--5635199ce6ee4b22' :
        'community.wave.seqera.io/library/assembly-stats:1.0.1--5635199ce6ee4b22' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.txt"), emit: txt
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat $input > ${meta.id}.fastq
    assembly-stats -t ${meta.id}.fastq > ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        assemblystats: \$(assembly-stats -v)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        assemblystats: \$(assembly-stats -v)
    END_VERSIONS
    """
}
