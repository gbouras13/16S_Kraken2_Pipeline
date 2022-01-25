# 16S_Kraken2_Pipeline
Snakemake Pipeline to Taxonomically Classify Nanopore Long Read 16S Datasets

This is a Work in Progress.

The only inputs required are:
1. Basecalled fastqs placed in separate folders in the fastqs directory, with subdirectories for each sample;
2. All samples (matching the subdirectories in the fastqs folder) listed in the sample column of the metadata.csv file.
* In the example data, the samples are barcode01, barcode02 and barcode03

# Usage

1. Create and Activate the qc conda environment

```console
conda create -n nanopore_qc_env
conda activate nanopore_qc_env
conda env update -f qc_environment.yaml
```

2. Run the qc.smk pipeline

```console
snakemake -s qc.smk -c {cores}
```
With 16 cores:
```console
snakemake -s qc.smk -c 16
```

* This will output fastqs in the fastqs/porechopped directory named for each sample. The fastqs have been filtered using filtlong (https://github.com/rrwick/Filtlong#acknowledgements) and had adapters and barcodes removed with porechop (https://github.com/rrwick/Porechop).
* It will also output summary qc plots and statistics in the Nanoplot directory.

3. Create and Activate the kraken conda environment

```console
conda deactivate
conda create -n kraken2_env
conda activate kraken2_env
conda env update -f kraken2_environment.yaml
```

4. Create and Specify the kraken2 database

There are multiple ways to get the 16S database from the NCBI. The easiest is from the following link https://www.ncbi.nlm.nih.gov/nuccore?term=33175%5BBioProject%5D+OR+33317%5BBioProject%5D. Alternatively, you can ftp the BLAST database and then extract the fasta files (see GenoMax comment https://www.biostars.org/p/194800/).

I have included the fasta file as of 25-01-22 as "16S.fasta."

Following that, cd to your desired directory to store the database and run the following commands (change the number of threads if required):

```console
kraken2-build --download-taxonomy --db 16S
kraken2-build --add-to-library 16S.fasta --db $DBNAME
kraken2-build --build --db --threads 8
```

5. Download Kraken_Tools

Kraken_Tools needs to be downloaded from https://github.com/jenniferlu717/KrakenTools to your preferred local directory

```console
git clone https://github.com/jenniferlu717/KrakenTools
```

If you are having trouble running the scripts, use the following to make the required script executable:

```console
chmod +x kreport2krona.py
```

6. Update the directories in kraken.smk ** TO DO - should be in a separate config **

Change the Following to:

KRAKEN_DB = "{Your_Kraken_DB_Dir}/16S"
KRAKEN_TOOLS_DIR = "{Your_Kraken_Tools_Dir}"

7.  Run the kraken.smk pipeline

```console
snakemake -s kraken.smk -c {cores}
```
With 16 cores:
```console
snakemake -s kraken.smk -c 16
```

* This will run kraken2 and bracken on each sample, and output various bracken reports to the species level "{sample}_report_bracken_species.txt" (in the bracken directory).
* The script will also create Krona plots for each sample in the krona directory, and a combined biom file in the json format that can be read into R and made into a phyloseq object for downstream processing.
