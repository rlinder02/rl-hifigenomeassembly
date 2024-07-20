process FIND_REPEATS {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/dfam/tetools:1.88.5' :
        'docker.io/dfam/tetools:1.88.5' }"

    input:
    tuple val(meta), path(scaffold)

    output:
    tuple val(meta), path("*.fa") , emit: fa
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    BuildDatabase \\
    -name ${prefix} \\
    $scaffold
    
    RepeatModeler \\
    -database ${prefix} \\
    -threads $task.cpus \\
    -LTRStruct

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        findrepeats: \$(RepeatModeler --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        findrepeats: \$(RepeatModeler --version)
    END_VERSIONS
    """
}
