# PipeIT documentation (v1.2.20)

PipeIT ([Garofoli et al. 2019](https://reader.elsevier.com/reader/sd/pii/S1525157818303386)) is a somatic variant calling workflow for Ion Torrent sequencing data. The PipeIT Singularity image (see Note 1) was built on a CentOS7 Docker image and requires a working Singularity installation.

PipeIT is composed of two analysis pipelines, allowing somatic variant calling with and without matched germline samples. In the tumor-gemline workflow, the sequencing of the matched germline control is used to filter out germline variants as well as recurrent sequencing artefacts. This component was published in [Garofoli et al. 2019](https://reader.elsevier.com/reader/sd/pii/S1525157818303386). In the more clinically realistic scenario, where matched germline is not sequenced due to costs and/or availability issues, the tumor-only pipeline leverages unmatched control samples and population genetic databases to define somatic variants. PipeIT offers standard parameters previously optimized from benchmark studies but also provides various options for customization.

<img src="https://github.com/ckynlab/PipeIT/blob/master/images/PipeIT_schema_v1.2.20.png" align="left" width="1000" >


## Tumor-germline workflow

The tumor-germline workflow performs somatic variant calling using the sequencing data of a cancer sample together with its matched germline sample. The workflow consists of the following steps:
1. Variant calling: Variant calling is performed using the Torrent Variant Caller (TVC) version 5.12 (https://github.com/iontorrent/TS), using a set of previously benchmarked low-stringency parameters. The list of parameters is contained in a JSON file present within the container. However, PipeIT also allows user-specified TVC parameters provided as a JSON file. 
2. Post-processing of multiallelic variants: Multiallelic variants are frequent in TVC output, particularly in homopolymer or repeated regions, which may also include variants with zero variant allele fraction (VAF). To facilitate downstream filtering and annotation, PipeIT splits multiallelic variants into monoallelic variants with norm in BCFtools (http://samtools.github.io/bcftools) and left-aligns the monoallelic variants with the LeftAlignAndTrimVariants function in the Genome Analysis ToolKit (GATK). 
3. Variant filtration: The GATK VariantFiltration function is used for identifying variants that are outside the target regions or do not meet minimum requirements based on read depth, variant quality score, the number of reads supporting the variants or the VAF ratio between tumor and normal. Given the biological and clinical significance of many hotspot variants, hotspot variants are annotated and whitelisted even when they do not meet the thresholds. We recommend manually reviewing hotspot variants.
4. Annotation (optional): Filtered variants, as well as whitelisted hotspot variants, are annotated by the SnpEff ann function, using the canonical transcripts (defined as the longest protein coding transcript) from the genome version GRCh37.75.

## Tumor-only workflow
The tumor-only workflow performs somatic variant calling using the sequencing data of a cancer sample without a matched germline sample. Instead of the matched germline sample, the PipeIT tumor-only workflow leverages publicly available population databases, namely the 1000 Genomes (1000G) Project, the Exome Aggregation Consortium (ExAC), the NHLBI Exome Sequencing Project (NHLBI-ESP) and the Genome Aggregation Database (GnomAD), to remove likely germline variants. The tumor-only workflow can also perform additional filtering using variants from a panel of normal (PoN), generated from a set of unmatched normal samples. The PoN variants would consist of likely germline variants, as well as systematic sequencing artefacts. 

The tumor-only workflow consists of the following steps:

1. Variant calling: Variant calling is performed using TVC as described in the tumor-germline workflow, except that TVC is run without a normal sample.
2. Post-processing of multiallelic variants: Normalization of variants is as described in the tumor-germline workflow.
3. Variant filtration: Similar to the tumor-germline workflow,  the GATK VariantFiltration function is used to identify variants outside the target regions and variants which do not meet minimum requirements based on read depth, variant quality, the number of reads supporting the variant and variant allele fraction. Additionally, variants are filtered out if they are in homopolymeric regions. Variants are then annotated for their population frequencies in 1000G, ExAC, NHLBI-ESP and GnomAD using ANNOVAR. Variants with VAF between 40% and 60% which are present in any of the four databases are considered likely germline variants and filtered out. Common variants (variants with a MAF above the population threshold specified with -k) are also removed regardless of the VAF. Hotspot variants are annotated and whitelisted as with the tumor-germline workflow.
4. Panel of normal filtering (optional): Variants derived from a panel of normal samples (PoN) sequenced using the same sequencing assay can be useful for the filtering of likely germline variants and recurrent sequencing and alignment artefacts. PoN filtering is optional but recommended. Whitelisted hotspot variants are not filtered out by the PoN filtering.
5. Annotation (optional): Filtered variants, as well as whitelisted hotspot variants, are annotated by the SnpEff ann function, as described in the tumor-germline workflow.

## Executing PipeIT
PipeIT can be executed as follows:
```
singularity run PipeIT_<version>.img [options]
```

The complete list of parameters can be displayed using the following command:
```
singularity run PipeIT_<version>.img --help
```

The PipeIT version can be printed on screen using the following command:
```
singularity run PipeIT_<version>.img --version
```

## Input files
The basic command needed to perform the tumor-germline workflow is:
```
singularity run PipeIT_<version>.img -t path/to/tumor.bam -n path/to/normal.bam -e path/to/region.bed 
```

The mandatory input files for the matched tumor-germline pipeline are the tumor and the normal BAM files (the `-t` and `-n` parameters, respectively), and the BED file of the targeted regions (the `-e` parameter). Paths to input files must be relative paths (see Note 2).

The basic command needed to perform the tumor-only workflow is:
```
singularity run PipeIT_<version>.img -t path/to/tumor.bam -e path/to/region.bed -c path/to/annovar/humandb/folder
```

The mandatory input files for the tumor-only pipeline are the tumor BAM file (the `-t` parameter) and the BED file of the targeted regions (the `-e` parameter). The path to ANNOVAR population databases (the `-c` parameter) is also required for variant filtering (see Note 3). Paths to input files must be relative paths (see Note 2).

## Parameters
The PipeIT pipeline includes the following parameters. Those specific to either the tumor-germline workflow or the tumor-only workflow are indicated.

Mandatory parameters:
```
-t, --tumor <path>: Path to the BAM file of the tumor sample.
-n, --normal <path> (tumor-germline workflow only): Path to the BAM file of the germline sample (see Note 3).
-c, --humandb <path> (tumor-only workflow only): Path to the folder where the ANNOVAR population data is stored (see Note 4). 
-e, --bed <path>: Path to the BED file of the targeted genomic regions.
```

Optional parameters:
```
-o, --output <string>: The prefix for the output and intermediate files. PipeIT places the output files in the PipeIT/results/ folder and intermediate files in PipeIT/sample/ and, if relevant, PipeIT/pon/. When -o is specified, the output and intermediate files will have the prefix PipeIT/results/<name>.PipeIT.vcf and so on. If this is not provided, PipeIT will use the name of the tumor BAM file, minus the bam file extension.
-u, --unmerged <path>: The path to the unmerged BED file. If this is not provided, PipeIT will create it internally (see Note 5).
-j, --TVC_json <path>: The path to the JSON file that includes the parameters for TVC. If not specified, PipeIT will use a set of parameters included within the container image.
-l, --black_list <path>: The path to the blacklist bed file to be used by TVC (see Note 6).
-p, --threads <n>:  The number of parallel threads used by TVC. The default is 4.
-a, --run_annotation <true/false>: Whether to annotate the variants with SnpEff. The default is true.
-i, --intermediate_files <true/false>: Whether PipeIT should keep the intermediate files produced during the analysis (in directories PipeIT/sample/ and PipeIT/pon/). The intermediate files may be useful for debugging and for testing parameters. The default is false. 
```

Optional parameters to customize filtering:
```
-q, --quality <n>: The minimum quality score of the variant. The default is 0.
-s, --min_supporting_reads <n>: The minimal number of reads supporting the variant,  used for filtering. The default is 8.
-m, --min_tumor_depth <n>: The minimum read depth for the tumor sample. The default is 10 for the tumor-germline workflow and 20 for the tumor-only workflow.
-r, --min_normal_depth <n> (tumor-germline workflow only): The minimum read depth for the normal sample. The default is 10.
-f, --min_TN_VAF_ratio <n> (tumor-germline workflow only): The minimum VAF ratio between tumor and normal samples. The default is 10.
-g, --min_allele_fraction <n> (tumor-only workflow only): The minimum VAF in the tumor sample. The default is 0.1.
-d, --pon <path> (tumor-only workflow only): This parameter can either point to a VCF file containing variants from a panel of normal samples (PoN), or to a .txt file containing the paths to BAM files of a panel of normal samples, one per line. If the .txt file is provided, PipeIT will generate the PoN VCF file used for the analysis (see Note 7). 
-b, --homopolymer_run <n> (tumor-only workflow only): The maximum homopolymer length accepted. Variants in homopolymer regions exceeding this length will be filtered out. The value 0 will disable this filter. The default is 4.
-k, --max_pop_af <n> (tumor-only workflow only): The maximum minor allele frequency of the variant in public databases. The default is 0.005.
-y, --non_coding <true/false>: Whether PipeIT should report non-coding variants in the final output. The default is true. 
```

## Output file
The final output is a VCF file of the variants (PipeIT/results/<name>.PipeIT.vcf). Tables below list the INFO fields of particular relevance for variant filtering for the tumor-germline and tumor-only pipelines respectively. In both cases, the output VCF file contains the allele counts information (see Note 8) and, if relevant, SnpEff gene annotations. The output VCF of the tumor-only pipeline also contains information regarding homopolymer length of the flanking region and population frequencies.


#### Table 1: Table of selected INFO fields in the output VCF file of the tumor-germline workflow.


| Annotation | Description |
| :--------- | :---------- |
| FAO | Flow space alternate allele depth at position |
| AO | Alternate allele depth at position |
| FRO | Flow space reference allele depth at position |
| RO | Reference allele depth at position |
| AF | Allele frequency |

<br/>

#### Table 2: Table of selected INFO fields in the output VCF file of the tumor-only workflow.


| Annotation | Description |
| :--------- | :---------- |
| FAO | Flow space alternate allele depth at position |
| AO | Alternate allele depth at position |
| FRO | Flow space reference allele depth at position |
| RO | Reference allele depth at position |
| AF | Allele frequency |
| FSAF | Flow alternate allele frequency on the forward strand |
| FSAR | Flow alternate allele frequency on the reverse strand |
| SAF | Alternate allele frequency on the forward strand |
| SAR | Alternate allele frequency on the reverse strand |
| HRUN | Length of the homopolymer region in the reference genome |
| ExAC_ALL | Alternate allele frequency in the Exome Aggregation Consortium dataset |
| esp6500siv2_all | Alternate allele frequency in the NHLBI-ESP project dataset |
| ANN_1000g2015aug | Alternate allele frequency in the 1000 Genomes Project dataset |
| gnomAD_genome_ALL | Alternate allele frequency in the gnomAD dataset |

<br/>

## Notes
1. A Singularity framework is mandatory in order to use PipeIT. Please refer to the Singularity official documentation (https://sylabs.io/docs/) for more detailed information regarding the installation process.

2. Because of the way Singularity treats relative and absolute paths, paths to input files have to be relative paths. Relative paths will appear to PipeIT as files defined outside of the container, while fully qualified paths refer to files inside the container. Depending on the high performance computing environment, it may be necessary to mount additional files and paths. By default, Singularity automatically mounts certain directories such as the user's home directory, /tmp, /proc, /sys, and /dev inside the container. If the input files are located outside of these mounted directories, the paths of the input files must be specified by using the -B flag. For example, if the BAM and BED files are stored in `/myHPC/a/different/folder/`:
```
singularity run -B /myHPC/a/different/folder/ PipeIT_<version>.img -t path/to/tumor.bam -n path/to/normal.bam -e path/to/region.bed
```
Further information can be found in the Singularity official documentation (https://sylabs.io/docs/).

3. PipeIT determines whether to run the tumor-germline or the tumor-only workflow based on if `-n` is provided.

4. The ANNOVAR population databases required for the tumor-only workflow are large and therefore not included in the PipeIT Singularity image. We have provided a script in PipeIT to facilitate the automatic downloading of the databases. The following commands will execute the downloads:
```
singularity exec PipeIT_<version>.img annotate_variation.pl -downdb -webfrom annovar -buildver hg19 esp6500siv2_all humandb/
singularity exec PipeIT_<version>.img annotate_variation.pl -downdb -webfrom annovar -buildver hg19 1000g2015aug humandb/
singularity exec PipeIT_<version>.img annotate_variation.pl -downdb -webfrom annovar -buildver hg19 exac03 humandb/
singularity exec PipeIT_<version>.img annotate_variation.pl -downdb -webfrom annovar -buildver hg19 gnomad_genome humandb/
```

5. The unmerged bed can be manually created using the `tvcutils validate_bed --unmerged-detail-bed` option from the Torrent Suite (https://github.com/iontorrent/TS) by providing it with the BED file of the target regions.

6. The blacklist typically consists of recurrent artefacts identified through the sequencing of normal samples. Some commercially available gene panels come with a blacklist, typically included in the hotspot BED file and these variants are tagged with `BSTRAND=F` (on the forward strand), `BSTRAND=R` (on the reverse strand), or `BSTRAND=B` (on both strands). 

7. Variants derived from a panel of normal samples (PoN) sequenced using the same sequencing assay can be useful for the filtering of likely germline variants and recurrent sequencing and alignment artefacts. A PoN VCF file can be directly used by PipeIT to remove variants present in the file. If a list of BAM files is given, PipeIT will call variants as per the variant calling and the post-processing of multiallelic variants steps in the tumor-only workflow and merge the variants from these files into a single PoN VCF to be used for filtering.

8. TVC provides two types of allele counts: the conventional allele counts and the flow evaluator allele counts. In general, we compute VAF using the flow evaluator allele counts (FAO and FRO), except when they are not reported by TVC, in which case we compute VAF using the conventional allele counts (AO and RO). FAO and FRO are usually equal to AO and RO, respectively, but may also differ due to complex alleles and/or downsampling. FDP and DP are not used for the calculation of VAF.

## Citation
If you use PipeIT, please cite Garofoli et al, *PipeIT: A Singularity Container for Molecular Diagnostic Somatic Variant Calling on the Ion Torrent Next-Generation Sequencing Platform* [DOI: 10.1016/j.jmoldx.2019.05.001](https://doi.org/10.1016/j.jmoldx.2019.05.001). 

### Version history

* **1.1.0**     First release
* **1.1.1-3**   Bug fixes
* **1.2.1**     Added the option for an analysis without a paired normal bam file
* **1.2.2-3**   Bug fixes
* **1.2.4**     Added Exome Aggregation Consortium (ExAC) in the annotation and filtering in the tumor only analysis
* **1.2.5-6**   Bug fixes
* **1.2.7**     Bug fixes
* **1.2.8**     Removed the need for the dbSNP annotation. Bug fixes
* **1.2.9-10**  Bug fixes. Added the Genome Aggregation Database (gnomAD) in the annotation and filtering in the tumor only analysis
* **1.2.11**    Command arguments' letters changed, now -t (--tumor) is used for both the analyses. PipeIT will pick one of the two pipelines base on the presence of the -n (--normal) germline control or -c (--humandb) Annovar databaes' files. The -r (--homopolymer_run) argument for the homopolymer filter value for the tumor-only pipeline was added, making this filter not mandatory anymore. Added more arguments for the tumor-only pipeline.
* **1.2.12-15** Bug fixes. Panel of normals filter is not mandatory anymore. If the -d (--pon) argument is not provided this step is not performed.

//Moreover, some of the annotation steps need the dbSNP VCF file, which can be downloaded with:
//```
//wget ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/dbsnp_138.hg19.vcf.gz
//```

