process ASSEMBLY_STATS2 {
    tag "$meta.id"
    label 'process_low'
    debug true

    conda "bioconda::assembly-stats=1.0.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats:1.0.1--5635199ce6ee4b22' :
        'community.wave.seqera.io/library/assembly-stats:1.0.1--5635199ce6ee4b22' }"

    input:
    tuple val(meta), path(gfa)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    tuple val(meta), path("*.txt")  , emit: txt
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    file_name=\$(basename $gfa)
    output_name=\${file_name%.gfa}
    awk '/^S/{print ">"\$2;print \$3}' "\${file_name}" > \${output_name}.fasta
    assembly-stats -t \${output_name}.fasta > \${output_name}.txt

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
