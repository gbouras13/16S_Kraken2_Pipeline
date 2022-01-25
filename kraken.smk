### mamba activate kraken2_env
### snakemake --dag | dot -Tpng > dag.png
### mamba env update -f kraken2_environment.yaml
## snakemake -s kraken.smk -c 16

import pandas as pd
import os

SAMPLES = pd.read_csv("metadata.csv").set_index("samples", drop=False)
KRAKEN_DB = "/Users/a1667917/Documents/Kraken2_DB/16S"
KRAKEN_TOOLS_DIR = "/Users/a1667917/Misc_Programs/KrakenTools/"

rule all:
    input:
        kraken_reports = expand('kraken/{sample}_report.txt', sample = SAMPLES.index),
        bracken_species = expand('bracken/{sample}_report_bracken_species.txt', sample = SAMPLES.index),
        total_out_species = expand('bracken/{sample}_species_total.txt', sample = SAMPLES.index),
        krona_html = expand('krona/{sample}_krona.html', sample = SAMPLES.index)

rule kraken:
    input:
        'fastqs/porechopped/{sample}.fastq.gz'
    params:
        kraken_db = KRAKEN_DB
    output:
        total = 'kraken/{sample}_total.txt',
        report = 'kraken/{sample}_report.txt'
    shell:
        '''
        kraken2 -db {params.kraken_db} {input} --output {output.total} --report {output.report}
        '''

rule bracken:
    input:
        total = 'kraken/{sample}_total.txt',
        report = 'kraken/{sample}_report.txt'
    params:
        kraken_db = KRAKEN_DB
    output:
        bracken_out = 'kraken/{sample}_report_bracken_species.txt',
        bracken_species = 'bracken/{sample}_report_bracken_species.txt',
        total_out_species = 'bracken/{sample}_species_total.txt'
    shell:
        '''
        bracken -d {params.kraken_db} -i {input.report} -o {input.total} -r 1450 -l S
        cp {output.bracken_out} {output.bracken_species}
        cp {input.report} {output.total_out_species}
        '''

rule krona:
    input:
        bracken_species = 'bracken/{sample}_report_bracken_species.txt'
    params:
        kraken_tools_dir = KRAKEN_TOOLS_DIR
    output:
        krona_out = 'krona/{sample}.krona',
        krona_html = 'krona/{sample}_krona.html'
    shell:
        '''
        {params.kraken_tools_dir}/kreport2krona.py -r {input.bracken_species} -o {output.krona_out}
        ktImportText {output.krona_out} -o {output.krona_html}
        '''

rule biom:
    input:
        bracken_species = expand('bracken/{sample}_species_total.txt', sample = SAMPLES.index)
    output:
        biom = 'biom/bracken_species.biom'
    shell:
        '''
        kraken-biom {input.bracken_species} -o {output.biom} --fmt json
        '''

#/Users/a1667917/Misc_Programs/KrakenTools/kreport2krona.py  -r barcode01_report_bracken_species.txt -o test.krona

# combine_bracken_outputs.py --files kraken/*total.txt -o bracken_species_all
# kraken-biom bracken/*_report_bracken_species.txt -o bracken_species.biom --fmt json

# combine_bracken_outputs.py --files *_genuses_total.txt -o bracken_genera_all
# kraken-biom *_genuses_total.txt  -o bracken_genera.biom --fmt json



#/Users/a1667917/Misc_Programs/KrakenTools/kreport2krona.py  -r barcode01_report_bracken_species.txt -o test.krona

#ktImportText test.krona -o test.krona.html
