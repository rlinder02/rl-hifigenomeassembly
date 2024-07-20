process RAGTAG {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::ragtag=2.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ragtag:2.1.0--0ad61b661719a8ae' :
        'community.wave.seqera.io/library/ragtag:2.1.0--0ad61b661719a8ae' }"

    input:
    tuple val(meta), path(assembly)
    path(ref)

    output:
    tuple val(meta), path("*_ragtag_output/*.ragtag.scaffold.stats")    , emit: stats 
    tuple val(meta), path("*_ragtag_output/*.ragtag.scaffold.fasta")    , emit: fasta 
    tuple val(meta), path("*_ragtag_output/*.ragtag.scaffold.agp")      , emit: agp 
    tuple val(meta), path("*_ragtag_output")                          , emit: ragtag_dir
    path "versions.yml"                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    name=\$(basename $assembly .cleaned.fasta)
    ragtag.py \\
        scaffold \\
        $args \\
        -t $task.cpus \\
        -o \${name}_ragtag_output \\
        -u \\
        $ref \\
        $assembly
    cd \${name}_ragtag_output
    mv ragtag.scaffold.stats \${name}.ragtag.scaffold.stats
    mv ragtag.scaffold.fasta \${name}.ragtag.scaffold.fasta
    mv ragtag.scaffold.agp \${name}.ragtag.scaffold.agp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ragtag: \$(ragtag.py --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ragtag: \$(ragtag.py --version)
    END_VERSIONS
    """
}
