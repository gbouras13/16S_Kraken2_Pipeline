### mamba activate nanopore_qc_env
### snakemake --dag | dot -Tpng > dag.png
### mamba env update -f qc_environment.yaml
## snakemake -s qc.smk -c 16

import pandas as pd
import os

SAMPLES = pd.read_csv("metadata.csv").set_index("samples", drop=False)

# filtlong params
MIN_LENGTH = 1400
MAX_LENGTH = 1700
KEEP_PERCENT = 99

def getFastqGzFilesForConcat(wildcards):
    fastqs = list()
    # Beware no other files than fastqs should be there
    for s in os.listdir("fastqs/"+wildcards.sample):
        if s.endswith('.gz'):
            fastqs.append(os.path.join("fastqs",wildcards.sample,s))
    return fastqs

rule all:
    input:
        porechops = expand('fastqs/porechopped/{sample}.fastq.gz', sample = SAMPLES.index),
        nanoplots = expand("nanoplot/{sample}", sample = SAMPLES.index),

rule concatenate_fastqs:
    input:
        fastq_files = getFastqGzFilesForConcat
    output:
        'fastqs/filtlong_fastqs/{sample}_conc.fastq'
    shell:
        'gzcat {input.fastq_files} > {output}'

rule filtlong:
    input:
        'fastqs/filtlong_fastqs/{sample}_conc.fastq'
    params:
        min_read_size = MIN_LENGTH,
        max_read_size = MAX_LENGTH,
        keep_percent = KEEP_PERCENT
    output:
        'fastqs/filtlong_fastqs/{sample}.fastq.gz'
    shell:
        '''
        filtlong --min_length {params.min_read_size} --max_length {params.max_read_size} --keep_percent {params.keep_percent} {input} | gzip > {output}
        rm {input}
        '''

rule porechop:
    input:
        'fastqs/filtlong_fastqs/{sample}.fastq.gz'
    output:
        'fastqs/porechopped/{sample}.fastq.gz'
    threads:
        16
    shell:
        '''
        porechop -i {input} -o {output} --threads {threads}
        rm {input}
        '''

rule nanoplot:
    input:
        'fastqs/porechopped/{sample}.fastq.gz'
    output:
        dir = directory("nanoplot/{sample}")
    threads:
        16
    shell:
        'NanoPlot --prefix pass --fastq {input} -t {threads} -o {output.dir}'
