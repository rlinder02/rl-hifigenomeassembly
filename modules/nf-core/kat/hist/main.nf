process KAT_HIST {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kat:2.4.2--py38hfc5f9d8_2':
        'biocontainers/kat:2.4.2--py38hfc5f9d8_2' }"

    input:
    tuple val(meta), path(assembly)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.png")                    , emit: png          
    tuple val(meta), path("*.pdf")                    , emit: pdf          , optional: true
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_kat"
    """
    kat comp \\
        --threads $task.cpus \\
        --output_prefix ${prefix} \\
        $args \\
        $reads \\
        $assembly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kat: \$( kat comp --version | sed 's/kat //' )
    END_VERSIONS
    """
}
