# PipeIT
PipeIT is a stand-alone Singularity Container for somatic variant calling on the Ion Torrent platform.

### Introduction
We present PipeIT, an accurate somatic variant calling pipeline specific for Ion Torrent sequencing data. The pipeline has been enclosed into a Singularity image to allow easy and high throughput analyses.

### Software requirements
The only requirement of PipeIT is a working Singularity installation. Please visit the [official website](https://singularity.lbl.gov/) for more information.

### Installation
PipeIT can be downloaded from our laboratory's website: http://oncogenomicslab.org/software-downloads/. 
No further installation is required, all the dependencies needed to perform the whole analysis are already installed within the container.

### Running the pipeline
PipeIT can be executed by simply running this command: 
```
singularity run PipeIT.img -t path/to/tumor.bam -n path/to/normal.bam -e path/to/region.bed [-u path/to/unmerged.bed]
```
The mandatory input files are the tumor and the normal BAM files, and the BED file of the targeted regions. The BAM files can be obtained directly from the Torrent Server. Optionally, the user can specify their own unmerged BED. If this file is not provided, PipeIT will build it.

While specifying input files please note that due to Singularity's nature:
- Paths to input files have to be *Relative*
> ... relative paths will resolve outside the container, and fully qualified paths will resolve inside the container.

Please read [Singularity's FAQ page](http://singularity.lbl.gov/archive/docs/v2-2/faq) for more information about this.
- Singularity automatically mounts some folders inside the container:
> ... Some of the bind paths are automatically derived (e.g. a user’s home directory) and some are statically defined (e.g. bind path in the Singularity configuration file). In the default configuration, the directories $HOME, /tmp, /proc, /sys, and /dev are among the system-defined bind points. 

Input files should be inside these folders to make them accessible to Singularity, otherwise PipeIT cannot find them.
User can also manually mount additional files and folders using the -B flag, in which case the folders and files within these folders are accesile to Singularity. For example:
```
singularity run -B /myHPC/home/username/files/ PipeIT.img -t RELATIVEpath/to/tumor.bam -n RELATIVEpath/to/normal.bam -e RELATIVEpath/to/region.bed
```

For a comprehensive description on which folders are automatically mounted within the container and on how to mount additional folders, users should read [Singularity's official documentation](http://singularity.lbl.gov/docs-mount).

### Output files
PipeIT will locally create a folder that will include both the final output (a VCF file), and the intermediate files . The latter will be automatically deleted by PipeIT at the end of its execution.

Please note that an empty final VCF file means that PipeIT have found no mutation in the input sample.

### Workflow
<p align="right">
![Workflow](https://github.com/ckynlab/PipeIT/blob/master/images/Workflow.png)
</p>

- Step 1 (Variant calling): Variant calling using the Torrent Variant Caller is performed.
- Step 2 (Post-processing multiallelic variants): Multiallelic variants are split, left aligned, trimmed and merged once again with the biallelic variants using BCFtools and GATK.
- Step 3 (Variant filtration): Variants outside of the target regions are removed. Hotspot variants are whitelisted. Variants covered by fewer than 10 reads in either the tumor or the matched normal sample or supported by fewer than 8 reads are removed. Furthermore, variants not likely to be somatic based on the ratio of VAF between tumor and normal (default to minimum 10:1) are also removed. Given the clinical significance of many hotspot mutations, we conservatively whitelist hotspot mutations even if they do not pass all read count and/or VAF filters. We recommend reviewing the whitelisted hotspot variants that did not pass the above read count and/or VAF filters. 
- Step 4 (Variant annotation): SnpEff annotation using canonical transcripts.

***

## Docker version

**Please note that the Docker image may not be up-to-date. Please use the Singularity image or contact us**

A Docker image has also been built for Docker users and can be found on the Docker Hub page: https://hub.docker.com/r/ckynlab/pipeit/. We suggest to use the Singularity version of PipeIT because the pipeline was defined to work on HPC environments, execution times on local machines will not be optimal.

### Running the pipeline
Similar to the Singularity image, the Docker version of PipeIT can also be launched using a simple command. However, due to Docker's behaviour with files external to the container itself, the user needs to mount the folder containing the input file within the container itself.
One easy option could be to create a folder called "data", use it to store all the input files and launch the command: 
```
docker run  --mount type=bind,source="$(pwd)"/data,target=/PipeIT/data,consistency=consistent -it pipeit:latest -t nameoftumor.bam -n nameofnormal.bam -e nameofregion.bed [-u nameofunmerged.bed]
```
Please notice that if you are using the "data" folder you must only use the name of the files, not the path.
PipeIT will create the output files within this directory.
