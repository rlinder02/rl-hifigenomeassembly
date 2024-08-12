process RAGTAG {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::ragtag=2.1.0 bioconda::samtools=1.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/minimap2_ragtag:9b89ec13b3b443c1 ' :
        'community.wave.seqera.io/library/minimap2_ragtag:9b89ec13b3b443c1 ' }"

    input:
    tuple val(meta), path(assembly), path(ref)

    output:
    //tuple val(meta), path("*_ragtag_output/ragtag.scaffold.stats")    , emit: stats 
    tuple val(meta), path("*_ragtag_output/ragtag.scaffold.fasta")    , emit: fasta // change to ragtag.scaffold.fasta if scaffolding is final step
    tuple val(meta), path("*_ragtag_output/ragtag.scaffold.agp")      , emit: agp // hange to ragtag.scaffold.agp if scaffolding is final step
    tuple val(meta), path("*_ragtag_output")                          , emit: ragtag_dir
    path "versions.yml"                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ragtag.py \\
        correct \\
        $args \\
        -t $task.cpus \\
        -o ${meta.id}.${meta.type}_ragtag_output \\
        $ref \\
        $assembly

    ragtag.py \\
        scaffold \\
        $args \\
        -r \\
        -t $task.cpus \\
        -o ${meta.id}.${meta.type}_ragtag_output \\
        $ref \\
        ${meta.id}.${meta.type}_ragtag_output/ragtag.correct.fasta

    ragtag.py \\
        patch \\
        $args \\
        --aligner minimap2 \\
        --fill-only \\
        -t $task.cpus \\
        -o ${meta.id}.${meta.type}_ragtag_output \\
        ${meta.id}.${meta.type}_ragtag_output/ragtag.scaffold.fasta \\
        $ref
	
    ragtag.py \\
        scaffold \\
        $args \\
        -r \\
        -w \\
        -t $task.cpus \\
        -o ${meta.id}.${meta.type}_ragtag_output \\
        $ref \\
        ${meta.id}.${meta.type}_ragtag_output/ragtag.patch.fasta

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
