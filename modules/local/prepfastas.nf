process PREP_FASTAS {
    tag "$meta.id"
    label 'process_low'
    debug true

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--h5bf99c6_6':
        'biocontainers/bioawk:1.0--h5bf99c6_6' }"

    input:

    tuple val(meta), path(scaffold)
    path(ref)
    path(chr_names)

    output:
    tuple val(meta), path("*.scaffolded.fasta"), emit: scaffold_modified
    path("*.ref.fasta")                        , emit: ref_modified

    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    name=\$(basename $scaffold .ragtag.scaffold.fasta)
    sed 's/_RagTag//' $scaffold > \${name}_renamed.scaffold.fasta
    echo \$(cat \${name}_renamed.scaffold.fasta | grep ">chr")
    ref_name=\$(basename $ref .fasta)
    chrs=\$(cat ${chr_names})
    echo \$chrs
    for i in \$chrs; do
        echo \$i
        cat $ref | bioawk -c fastx -v chr="\$i" \'\$name==chr{print ">"\$name; print \$seq}\' >> \${ref_name}.ref.fasta
        cat \${name}_renamed.scaffold.fasta | bioawk -c fastx -v chr="\$i" \'\$name==chr{print ">"\$name; print \$seq}\' >> \${name}.scaffolded.fasta
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioawk: $VERSION
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.scaffolded.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioawk: $VERSION
    END_VERSIONS
    """
}
