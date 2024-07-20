process BIOAWK {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--h5bf99c6_6':
        'biocontainers/bioawk:1.0--h5bf99c6_6' }"

    input:
    tuple val(meta), path(input), path(optional_file)

    output:
    tuple val(meta), path("*.{csv,fasta}")  , emit: csv
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: '' // args is used for the main arguments of the tool
    prefix = task.ext.prefix ?: "${meta.id}"

    def VERSION = '1.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    if [[ $input =~ ".scaffolded.fasta" ]]; then
        name=\$(basename $input .scaffolded.fasta)
        bioawk \\
            $args \\
            $input \\
            > \${name}.${prefix}
    else
        bioawk \\
            $args \\
            $input \\
            > ${prefix}
    fi
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioawk: $VERSION
    END_VERSIONS
    """
}
