process COV_TABLE_PLOT {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::r-cowplot=1.1.3 conda-forge::r-data.table=1.15.2 conda-forge::r-reshape2=1.4.4 conda-forge::r-tidyverse=2.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-cowplot_r-data.table_r-reshape2_r-tidyverse:8059a2929cba6bae' :
        'community.wave.seqera.io/library/r-cowplot_r-data.table_r-reshape2_r-tidyverse:8059a2929cba6bae' }"

    input:
    tuple val(meta), path(cov_table), path(assembly_size)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.type}"
    """
    assembly_size=\$(cat $assembly_size)
    cat $cov_table | sort -k3rV -t "," | awk -F "," -v len=\$assembly_size -v type=contig 'OFS=","{ print \$1,\$2,type,(sum+0)/len; sum+=\$3 }' > ${prefix}_contig_lengths_table.csv

    plot_contig_length_distribution.R "${prefix}_contig_lengths_table.csv" ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version) | head -1 | sed 's/R version //g'
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version) | head -1 | sed 's/R version //g'
    END_VERSIONS
    """
}
