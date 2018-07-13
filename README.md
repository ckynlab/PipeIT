# PipeIT
Stand-alone Singularity Container for somatic variant calling on the Ion Torrent platform.

### Introduction
We present PipeIT, an accurate variant call bioinformatics pipeline specific for Ion Torrent sequencing data. The pipeline has been enclosed into a Singularity image to allow easy and high throughput analyses.

### Installation
PipeIT can be downloaded on our laboratory's website: http://oncogenomicslab.org/software-downloads/. No further installations are nrequired, all the dependencies needed to perform the whole analysis are already installed within the container.

### Running the pipeline
PipeIT can be executed by simply running this command: 
```bash
singularity run PipeIT.img -t path/to/tumor.bam -n path/to/normal.bam -e path/to/region.bed [-u path/to/unmerged.bed -f genome.fasta]
```
The only mandatory input files can be directly obtained from the Ion Torrent, the tumor and the normal BAM files and the BED files from the sequenced region. The user can specify his own unmerged BED and the Fasta for the reference genome. Wherever these two files are not manually specified PipeIT will simply build the unmerged BED on its own and use the hg19 human genome, standard for the Ion Torrent sequencing at the time of the writing.
***

### Workflow
- Step1: Torrent Variant Caller is performed with lenient parameters on the input submitted bam files.
- Step2: Multiallelic variants are split, left aligned, trimmed and merged once again with the Biallelic variants using BCFtools and GATK.
- Step3: Using GATK once again, all the variants are filtered by removing regions with less than 10 reads, mutations with less than 8 reads and with a tumor-normal allele frequency lower than 10:1.

### Software requirements
PipeIT only needs a working Singularity installation. Please visit the official website (https://singularity.lbl.gov/) for more information.


## Docker version
A Docker image has also been built for Docker users and can be found on the Docker Hub page: https://hub.docker.com/r/ckynlab/pipeit/.

### Running the pipeline
Just like for the Singularity image, the Docker version of PipeIT can be launched using a simple command but, due to Docker's behaviour with files external to the container itself, the user needs to mount the folder containing the input file within the container itself.
One easy option could be to create a folder called "data", use it to store all the input files and launch the command: 
```bash
docker run  --mount type=bind,source="$(pwd)"/data,target=/PipeIT/data,consistency=consistent -it pipeit:latest [-u path/to/unmerged.bed -f genome.fasta]
```
