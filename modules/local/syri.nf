process SYRI {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::plotsr=1.1.1 bioconda::syri=1.6.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/plotsr_syri:5cffccf51a051df6' :
        'community.wave.seqera.io/library/plotsr_syri:5cffccf51a051df6' }"

    input:
    tuple val(meta), path(sam)
    path(ref)
    tuple val(meta), path(scaffold)

    output:
    tuple val(meta), path("*.png"), emit: png
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    syri \\
        $args \\
        -c $sam \\
        -r $ref \\
        -q $scaffold \\
        -k -F S \\
        --nc $task.cpus
    echo "#file\tname\ttags" > genomes.txt
    echo "$ref\tReference\tlw:1.5" >> genomes.txt
    echo "$scaffold\tQuery\tlw:1.5" >> genomes.txt
    plotsr --sr syri.out --genomes genomes.txt -H 8 -W 5 -o ${prefix}.synteny.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        syri: \$(syri --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.synteny.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        syri: \$(syri --version)
    END_VERSIONS
    """
}
