process FINAL_MASK {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/dfam/tetools:1.88.5' :
        'docker.io/dfam/tetools:1.88.5' }"

    input:
    tuple val(meta), path(masked)
    tuple val(meta), path(fa)

    output:
    tuple val(meta), path("*.masked.masked"), emit: masked_fasta
    tuple val(meta), path("*.tbl")          , emit: tbl
    tuple val(meta), path("*.out")          , emit: repeat_list
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    RepeatMasker \\
    -lib $fa \\
    -s \\
    -parallel $task.cpus \\
    -xsmall \\
    -alignments $masked

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        finalmask: \$(RepeatMasker --version )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.masked.masked

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        finalmask: \$(RepeatMasker --version )
    END_VERSIONS
    """
}
