process REPEAT_MASK {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/dfam/tetools:1.88.5' :
        'docker.io/dfam/tetools:1.88.5' }"


    input:
    tuple val(meta), path(scaffold)
    val(species)

    output:
    tuple val(meta), path("*.fasta.masked"), emit: masked_fasta
    tuple val(meta), path("*.fasta.out")   , emit: repeat_list
    tuple val(meta), path("*.fasta.tbl")   , emit: repeat_tbl
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    RepeatMasker \\
    $args \\
    -species "${species}" \\
    -s \\
    -parallel $task.cpus \\
    -xsmall \\
    -alignments $scaffold

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmask: \$(RepeatMasker --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa.masked

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmask: \$(RepeatMasker --version)
    END_VERSIONS
    """
}
