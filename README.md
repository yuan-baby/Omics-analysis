# 基于HISAT2, StringTie和Ballgown的RNA-seq分析流程

## 摘要

mRNA 的高通量测序（RNA-seq）已经成为衡量和比较各种生物物种和条件下基因表达水平的标准方法。RNA-seq 实验生成的大型、复杂的数据集需要快速、准确、灵活的软件来将原始的读取数据转化为可理解的结果。HISAT2（Hierarchical Indexing for Spliced Alignment of Transcripts）、StringTie和 Ballgown 是针对 RNA-seq 实验的全面分析而设计的免费且开源的软件工具。这些工具一起将帮助科学家对 RNA-seq 数据进行基因组比对，转录本的组装（包括新的剪接异构体），识别样本中不同转录本的丰度，并进行实验间比较以确定差异表达的基因和转录本。在本项目中，我们编写了 Dockerfile 用于构建已完成 HISAT2、StringTie 和 Ballgown 这些工具的配置的centos镜像，并编写了流程shell脚本和R脚本用于 RNA-seq 的差异表达分析。您可以从 https://github.com/yuan-baby/RNA-seq-analysis 下载 Dockerfile 和 RNA-seq 分析的流程脚本。

## 前言

### 背景介绍

RNA-seq是一种能够测定细胞或组织中RNA分子数量和类型的技术。它为我们提供了有关基因表达、转录本水平、剪接变异以及新基因发现等重要信息，有助于深入了解基因的调控和表达机制。通过RNA-seq，我们可以量化不同基因在不同生物物种、组织、时期或受不同刺激时的表达量。对于那些存在多个转录本的基因，RNA-seq可以检测剪接变异，从而确认该基因的转录本和不同剪接形式的相对表达量。此外，RNA-seq还可以识别单核苷酸多态性（SNP）等基因突变。与预先设计的引物或探针不同，RNA-seq不依赖于这些特定的设计，因此在基因组注释中更为全面。RNA-seq还能够定量和分类非编码RNA，包括长链非编码RNA、短链非编码RNA以及其他RNA分子。RNA-seq的应用越来越广泛，涵盖生命科学中的疾病研究、生态学、进化学、农业和生物技术等领域。

然而，RNA-seq实验所产生的数据集非常庞大、复杂、维度高，通常需要大量的计算和存储资源。因此，需要使用快速、准确、灵活的数据分析软件能够将原始频次数据转化为可解释和可视化的结果。此外，RNA-seq数据集可能包含有一定数量的低质量序列和无用垃圾序列等，软件可以过滤它们并提高数据质量和可靠性。软件可以通过分析数据集中的错误和偏差，帮助研究人员选择最佳数据过滤策略，评估RNA-seq数据集的质量，从而选择最好的数据分析方向。RNA-seq数据的主要应用是定量基因表达和比较不同条件下基因表达水平。软件可以进行这些分析，找出差异性表达的基因，并进行聚类分析和信号通路分析，帮助找到这些基因的功能。一些基因可能具有多个外显子，因此RNA-seq数据可以用于检测剪接变异，并对不同外显子的表达量进行定量分析。软件可以进行这些剪接变异分析，并识别出具有生物学重要性的剪接事件。因此，使用快速、准确、灵活的软件工具，能够从RNA-seq数据集中获得有意义的生物学信息，转化成易于理解和可视化的结果。

为此，来自Jhon Hopkins大学的研究团队于2016年开发了 HISAT, StringTie 和 Ballgown^[2]^ 这组软件用于RNA-seq的数据全流程分析，作为2012年同一团队开发的 TopHat 和 Cufflinks^[1]^ 软件的更新换代。

### 工作思路

RNA-seq分析有四个主要任务

(i)测序序列与基因组的比对;

(ii)将比对组合成全长转录本;

(iii)定量测定各基因及转录物的表达水平;

(iv)计算各基因在不同实验条件下的表达差异。

通过对软件的研究，我们可以使用以下流程图所展现的形式进行RNA-seq的数据分析。

![image-20230613225737055](https://s2.loli.net/2023/06/13/NXy5WkUfIrmSpL1.png)

<p><center>图1 New-Tuxedo分析流程</center></p>

在涉及多个RNA-seq数据集的实验中，首先使用HISAT将reads映射到基因组(步骤1和2)。参考基因和转录本的注释可以作为输入，但这是可选的，如虚线所示。然后将比对传递给StringTie(步骤3)，它组装并量化每个样本中的转录本。(在替代流程中，步骤2中的对齐直接传递到步骤6，跳过所有组装步骤。步骤6将只对已知的、注释的转录本估计丰度。)在初始组装之后，通过一个特殊的StringTie模块将组装好的转录本合并在一起(步骤4)，该模块为所有样本创建一组统一的转录本。StringTie可以在这两个步骤中使用注释，如虚线所示。然后，gffcompare程序将基因和转录本与注释进行比较，并报告此比较的统计数据(步骤5)。在步骤6中，StringTie处理读取比对和合并的转录本或参考注释(通过标记为“or”的菱形)。使用这个输入，StringTie在必要的地方重新估计丰度，并为输入到Ballgown创建新的转录表。然后，Ballgown比较不同条件下的所有转录本，并生成差异表达基因和转录本的表格和图(步骤7-21)。图中的黑色和蓝色曲线线分别表示程序的输入和输出。可选输入用虚线表示。

### 工作概要

在本项目中，我们编写了 Dockerfile 用于构建已完成 HISAT2、StringTie 和 Ballgown 这些工具的配置的 centos 镜像，并编写了执行 RNA-seq 数据分析流程的 shell 脚本和进行差异基因分析的 R 脚本用于 RNA-seq 的差异表达分析。

## 数据集与方法

### 涉及的软件工具

**HISAT2**是一个用于将 RNA-seq reads 与基因组进行比对并发现转录本剪接位点的软件。它比 TopHat2 运行速度更快，且需要的计算机内存更少。

**StringTie**是一个用于将比对结果组装成完整和部分转录本的软件。它可以根据需要创建多个亚型，并估计所有基因和转录本的表达水平。

**Ballgown** 是一个 R 包，用于对 RNA-seq 数据进行差异表达分析。它可以读取 StringTie 生成的表格数据，并提供数据可视化、统计检验、多重检验校正和结果汇总等功能。

gffcompare 是一种用于比较和评估注释文件的软件工具。gffcompare 可以比较多个基因组注释文件（如 GTF、GFF3 等）并对它们进行合并、分类和过滤，以确定每个基因和转录本在各个注释文件中的表达情况。gffcompare 可以有效地评估注释结果的准确性和完整性，并提供一个统一的标准，以便更好地进行数据分析和解释。

SAMtools 是一个广泛使用的软件包，用于处理和分析下一代测序（NGS）数据。它使用Sequence Alignment/Map（SAM）格式来存储测序数据，并提供了一系列功能用于读取、过滤和操纵这些数据。

SRAtools 是一组用于处理 NCBI 序列读取存档（SRA）数据格式的软件工具。SRA是一种用于存储高通量测序数据的文件格式，由 NCBI 提供在线访问和下载。SRA 文件包含原始的、未经处理的读取数据，通过 SRAtools 可以有效的下载、转换、处理和分析这些数据，并提取有用的信息。

### 使用的数据

对于高通量 RNA-seq 实验而言，RNA-seq 的数据文件往往非常大。因此，为了使流程对新手用户更快、更简单，这里使用了原论文^[2]^中提供的数据文件。在这个数据文件中，论文作者提取了映射到人类X染色体的 reads 子集，这是一条相对丰富的染色体，跨越151兆碱基(Mb)，约占基因组的 5% 。但是本项目中的流程同样适用于完整数据集，只是需要更长的时间。

在 ftp://ftp.ccb.jhu.edu/pub/RNAseq_protocol/chrX_data.tar.gz 下载数据后，对其进行解压，可以得到一个文件夹`chrX_data/`，它具有以下结构: `samples/ indexes/ genome/ genes/`。

`samples/` 包含12个样本的成对端 RNA-seq reads，其中 GBR (来自英国的英国人)和 YRI (来自尼日利亚伊巴丹的 oruba 人)两个种群各6个样本。对于每个总体，男性和女性受试者各有三个样本。所有序列都是压缩的“fastq”格式，它将每个读取存储在四行中。每个样本依次包含在两个文件中:一个用于读取1，另一个用于读取2。

`indexes/` 包含X染色体的 HISAT2 索引（有些可以直接HISAT官网下载，有些要自定义创建，具体见论文）

`genome/` 包含一个文件，`chrX.fa`，这是人类X染色体 (GRCh38 build 81) 的序列。

`genes/` 包含一个文件，chrX.gtf，包含RefSeq数据库中 GRCh38 的人类基因注释。

`chrX_data` 目录还包含另外两个文件:`mergelist.txt`和`geuvadis_phenodata.csv`。这些文件是运行流程所需的文本文件

### 计算环境的建立

请下载并安装以下软件的最新版本：hisat2 ( http://ccb.jhu.edu/software/hisat2 ) 和 stringtie ( http://ccb.jhu.edu/software/stringtie )。按照论文^[2]^中的说明，在 R 中安装 Ballgown 软件包及其它依赖项。同时，在系统上安装 samtools 程序 ( http://samtools.sourceforge.net/ )。本脚本支持从0.1.19到1.3的全部版本。

或者直接运行本项目中的Dockerfile构建完成环境配置的centos7.2镜像，使用以下命令：

```shell
# 若直接构建出错则先运行这一命令
# docker pull centos:7.2.1511

# 构建镜像，rna-seq可以修改为其他镜像名
docker build -t rna-seq .
```

### 详细分析流程

 1. 为这次流程运行创建或选择一个工作目录（输入和输出文件将存储在这个目录中）。

 2. 请在当前工作目录中下载 `chrX_data.tar.gz`、`rnaseq_pipeline.sh` 和 `rnaseq_pipeline.config.sh`。解压缩 `chrX_data.tar.gz`，使用以下命令：

    ```shell
    tar -zxvf chrX_data.tar.gz
    ```

    这个命令将会在当前目录下创建一个名为 `./chrX_data` 的目录。

 3. 打开 `rnaseq_pipeline.config.sh` 文件，验证并根据需要更改相关变量的值，特别是：

    * NUMCPUS应设置为运行流程各个步骤时要使用的CPU线程数；通常情况下，这不能设置为高于计算机上可用CPU核数的值。
    * HISAT2、STRINGTIE和SAMTOOLS应设置为这些程序在系统上的完整路径。默认情况下，脚本会尝试自动查找这些程序，如果程序在当前shell的任何PATH目录中则能成功找到。

 4. 执行主脚本：

    ```shell
    ./rnaseq_pipeline.sh out
    ```

    这将运行分析流程并创建`./out`，`./out/hisat2/`和`./out/ballgown/`目录。Ballgown的计数表将位于`./out/ballgown/`目录中。带有每个步骤时间戳的日志消息将显示在终端上，也将保存在 `run.log` 文件中。ballgown得到的差异表达分析结果将保存在两个CSV文件中：`./out/chrX_transcripts_results.csv`和`./out/chrX_genes_results.csv`

在Intel i7-2600 Desktop CPU上（配置文件中NUMCPUS=4）运行流程脚本需要约13分钟，在AMD Opteron 6172服务器上（NUMCPUS设置为8）需要约23分钟。

## 结果

| Gene name | Gene id   | Transcript name | id   | Fold change | P value    | q value    |
| --------- | --------- | --------------- | ---- | ----------- | ---------- | ---------- |
| XIST      | MSTRG.506 | NR_001564       | 1729 | 0.003255    | 7.0447e-10 | 1.6160e-06 |
| <none>    | MSTRG.506 | MSTRG.506.1     | 1728 | 0.016396    | 1.2501e-08 | 1.4339e-05 |
| TSIX      | MSTRG.505 | NR_003255       | 1726 | 0.083758    | 2.4939e-06 | 1.9070e-03 |
| <none>    | MSTRG.506 | MSTRG.506.2     | 1727 | 0.047965    | 3.7175e-06 | 2.1319e-03 |
| <none>    | MSTRG.585 | MSTRG.585.1     | 1919 | 7.318925    | 9.3945e-06 | 3.7715e-03 |
| PNPLA4    | MSTRG.56  | NM_004650       | 203  | 0.466647    | 9.8645e-06 | 3.7715e-03 |
| <none>    | MSTRG.506 | MSTRG.506.5     | 1731 | 0.046993    | 2.1350e-05 | 6.9968e-03 |
| <none>    | MSTRG.592 | MSTRG.592.1     | 1923 | 9.186257    | 3.5077e-05 | 1.0058e-02 |
| <none>    | MSTRG.518 | MSTRG.518.1     | 1744 | 11.972859   | 4.4476e-05 | 1.1336e-02 |

<p><center>表1 性别间的差异表达转录本（ q值<5% ）</center></p>

由 表 1 所示，X染色体有 9 个性别间差异表达的转录本，其中的三个对应于已知基因的亚型（XIST, TSIX 和 PNPLA4）。

| Gene id   | Fold change | P value    | q value    |
| --------- | ----------- | ---------- | ---------- |
| MSTRG.506 | 0.00267     | 6.8069e-11 | 6.7593e-08 |
| MSTRG.56  | 0.54688     | 3.6604e-06 | 1.8174e-03 |
| MSTRG.585 | 7.28272     | 6.9974e-06 | 2.3161e-03 |
| MSTRG.505 | 0.08930     | 1.1660e-05 | 2.8948e-03 |
| MSTRG.356 | 0.56441     | 1.7126e-05 | 3.4013e-03 |
| MSTRG.592 | 9.14996     | 3.2120e-05 | 5.3159e-03 |
| MSTRG.518 | 12.23489    | 4.3775e-05 | 6.2098e-03 |
| MSTRG.492 | 0.65092     | 1.9811e-04 | 2.4590e-02 |
| MSTRG.594 | 7.71803     | 2.2935e-04 | 2.5305e-02 |
| MSTRG.788 | 1.74428     | 3.5797e-04 | 3.5547e-02 |

<p><center>表2 性别间的差异表达基因（ q值<5% ）</center></p>

在基因水平，由 表 2 所示，X染色体在相同的 q 值截段有 10 个差异表达的基因。

![image-20230620221150678](https://s2.loli.net/2023/06/20/uQcnYwEVDpaB9Pf.png)

<p><center>图2 12个样本间的FPKM值分布</center></p>

来自同一性别的样本以同一颜色标注：男性为蓝色，女性为橙色。FPKM (Fragments Per Kilobase of exon model per Million mapped fragments) 是每千个碱基的转录每百万映射读取的片段数， 是一种用于衡量基因表达水平的指标。它结合了RNA-Seq测序数据中的基因长度和测序深度，用于估计每个基因的表达水平。

在RNA-Seq分析中，首先对RNA样本进行测序，然后将测序reads与参考基因组或转录组进行比对，得到每个基因的测序reads数。FPKM值通过将每个基因的测序reads数标准化为每千个碱基长度，并将其除以所有基因的总reads数，再乘以一百万，从而得到每个基因的表达水平。在 图 4 中使用了FPKM值来展示样本间基因的丰度分布。

![image-20230620221251079](https://s2.loli.net/2023/06/20/WP9oKzbZHIOjC3M.png)

<p><center>图3 对于来自GTPBP6基因的转录本NM_012227在男女中的FPKM分布</center></p>

GTPBP6 (GTP binding protein 6) 已知是一个在男性中高表达的基因。图 3 也充分展示了男性中的转录本丰度要高于女性。

![image-20230620221449295](https://s2.loli.net/2023/06/20/L75GFTADmqseQdC.png)

<p><center>图4 ERR188234样本中XIST基因的五个不同亚型的结构和表达水平</center></p>

图 4 中表达量用黄色的深浅程度变化来展示。可以观察到第三个亚型比其他亚型的表达水平高出相当多。在图 4 中展示了包含第一个转录本的基因的所有转录本。

## 讨论

### 关键点

在本项目中，我们编写了 Dockerfile 用于构建已完成 HISAT2、StringTie 和 Ballgown 这些工具的配置的 centos 镜像，并编写了执行 RNA-seq 数据分析流程的 shell 脚本和进行差异基因分析的 R 脚本用于 RNA-seq 的差异表达分析。对于熟悉 Unix 命令行操作的用户，不需要预先的编程知识，按照本项目的指示操作即可轻松完成 RNA-seq 数据的分析。

### 不足

对于使用SRA下载的数据，还需要操作论文^[2]^中的方法从软件官网下载或者自己建立HISAT索引。另外，本项目也没有直接给出使用SRA下载数据的代码。

## 贡献

| 成员   | 贡献                                        |
| ------ | ------------------------------------------- |
| 刘致远 | 编写Dockerfile，撰写项目报告                |
| 邓卫青 | 编写流程脚本和R脚本，对数据执行流程获得结果 |



## 参考文献

[1] Trapnell, C., Roberts, A., Goff, L. *et al.* Differential gene and transcript expression analysis of RNA-seq experiments with TopHat and Cufflinks. *Nat Protoc* **7**, 562–578 (2012). https://doi.org/10.1038/nprot.2012.016

[2] Pertea, M., Kim, D., Pertea, G. *et al.* Transcript-level expression analysis of RNA-seq experiments with HISAT, StringTie and Ballgown. *Nat Protoc* **11**, 1650–1667 (2016). https://doi.org/10.1038/nprot.2016.095

## 附录

### Dockerfile

```dockerfile
FROM centos:7.2.1511

# 更新yum源并安装常用依赖和Python、R等软件
RUN yum update -y && \
    yum install -y wget gcc-c++ make zlib1g-dev libbz2-dev \
	ncurses ncurses-devel xz xz-devel bzip2 bzip2-devel zlib zlib-devel libcurl libcurl-devel zlib zlib-devel \
    liblzma-dev libncurses5-dev apt-utils ca-certificates curl unzip \
    build-essential gfortran git libreadline-dev pkg-config python3-dev \
    python3-pip python3-setuptools python3-venv r-base r-base-dev \
	epel-release libcurl-devel libxml2-devel openssl-devel && \
	yum install -y R && \
	chmod +x /usr/bin/g++
	
# 将R可执行文件的路径放入环境变量
ENV PATH="/usr/lib64/R/bin:${PATH}"

# 下载并安装HISAT2
RUN wget https://cloud.biohpc.swmed.edu/index.php/s/oTtGWbWjaxsQ2Ho/download && \
	mv download hisat2-2.2.1.zip && \
    unzip hisat2-2.2.1.zip && \
    rm -rf hisat2-2.2.1.zip && \
    cp hisat2-2.2.1/hisat2* hisat2-2.2.1/*.py /usr/bin

# 下载并安装StringTie
RUN wget -O stringtie-2.1.1.Linux_x86_64.tar.gz "http://ccb.jhu.edu/software/stringtie/dl/stringtie-2.1.1.Linux_x86_64.tar.gz" && \
    tar -xzf stringtie-2.1.1.Linux_x86_64.tar.gz && \
    rm -rf stringtie-2.1.1.Linux_x86_64.tar.gz && \
    mv stringtie-2.1.1.Linux_x86_64/stringtie /usr/bin/

# 下载并编译安装gffcompare
RUN wget -O gffcompare-0.12.6.tar.gz "https://github.com/gpertea/gffcompare/archive/v0.12.6.tar.gz" && \
    tar -xzf gffcompare-0.12.6.tar.gz && \
    cd gffcompare-0.12.6 && \
    make release && \
    cd ../ && \
    mv gffcompare-0.12.6 /usr/bin/ && \
    rm -rf gffcompare-0.12.6.tar.gz

# 安装SRA toolkit
RUN wget -O sratoolkit.current-centos_linux64.tar.gz "https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-centos_linux64.tar.gz" && \
	tar -xzf sratoolkit.current-centos_linux64.tar.gz && \
	cp -R sratoolkit.3.0.5-centos_linux64/bin/* /usr/local/bin/ && \
	rm -rf sratoolkit.current-centos_linux64.tar.gz sratoolkit.3.0.5-centos_linux64/
    
# 下载安装SAMtools
RUN wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
	tar -xjf samtools-1.17.tar.bz2 && \
	cd samtools-1.17 && \
	make && \
	cd ../ && \
	cp samtools-1.17/samtools /usr/bin

# 安装ballgown包
RUN R -e 'install.packages("devtools",repos="http://cran.us.r-project.org");install.packages("BiocManager");library(BiocManager);BiocManager::install(c("alyssafrazee/RSkittleBrewer","ballgown","genefilter","dplyr"))'

# 配置镜像启动后的默认命令
CMD ["/bin/bash"]
```



### 流程shell脚本

1. rnaseq_pipeline.sh

```shell
#!/usr/bin/env bash
usage() {
    NAME=$(basename $0)
    cat <<EOF
Usage:
  ${NAME} [output_dir]
Wrapper script for HISAT2/StringTie RNA-Seq analysis protocol.
In order to configure the pipeline options (input/output files etc.)
please copy and edit a file rnaseq_pipeline.config.sh which must be
placed in the current (working) directory where this script is being launched.

Output directories "hisat2" and "ballgown" will be created in the 
current working directory or, if provided, in the given <output_dir>
(which will be created if it does not exist).

EOF
}

OUTDIR="."
if [[ "$1" ]]; then
 if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 1
 fi
 OUTDIR=$1
fi

## load variables
if [[ ! -f ./rnaseq_pipeline.config.sh ]]; then
 usage
 echo "Error: configuration file (rnaseq_pipeline.config.sh) missing!"
 exit 1
fi

source ./rnaseq_pipeline.config.sh
WRKDIR=$(pwd -P)
errprog=""
if [[ ! -x $SAMTOOLS ]]; then
    errprog="samtools"
fi
if [[ ! -x $HISAT2 ]]; then
    errprog="hisat2"
fi
if [[ ! -x $STRINGTIE ]]; then
    errprog="stringtie"
fi

if [[ "$errprog" ]]; then    
  echo "ERROR: $errprog program not found, please edit the configuration script."
  exit 1
fi

if [[ ! -f rnaseq_ballgown.R ]]; then
   echo "ERROR: R script rnaseq_ballgown.R not found in current directory!"
   exit 1
fi

#determine samtools version
newsamtools=$( ($SAMTOOLS 2>&1) | grep 'Version: 1\.')

set -e
#set -x

if [[ $OUTDIR != "." ]]; then
  mkdir -p $OUTDIR
  cd $OUTDIR
fi

SCRIPTARGS="$@"
ALIGNLOC=./hisat2
BALLGOWNLOC=./ballgown

LOGFILE=./run.log

for d in "$TEMPLOC" "$ALIGNLOC" "$BALLGOWNLOC" ; do
 if [ ! -d $d ]; then
    mkdir -p $d
 fi
done

# main script block
pipeline() {

echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> START: " $0 $SCRIPTARGS

for ((i=0; i<=${#reads1[@]}-1; i++ )); do
    sample="${reads1[$i]%%.*}"
    sample="${sample%_*}"
    stime=`date +"%Y-%m-%d %H:%M:%S"`
    echo "[$stime] Processing sample: $sample"
    echo [$stime] "   * Alignment of reads to genome (HISAT2)"
    $HISAT2 -p $NUMCPUS --dta -x ${GENOMEIDX} \
     -1 ${FASTQLOC}/${reads1[$i]} \
     -2 ${FASTQLOC}/${reads2[$i]} \
     -S ${TEMPLOC}/${sample}.sam 2>${ALIGNLOC}/${sample}.alnstats
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Alignments conversion (SAMTools)"
    if [[ "$newsamtools" ]]; then
     $SAMTOOLS view -S -b ${TEMPLOC}/${sample}.sam | \
      $SAMTOOLS sort -@ $NUMCPUS -o ${ALIGNLOC}/${sample}.bam -
    else
     $SAMTOOLS view -S -b ${TEMPLOC}/${sample}.sam | \
      $SAMTOOLS sort -@ $NUMCPUS - ${ALIGNLOC}/${sample}
    fi
    #$SAMTOOLS index ${ALIGNLOC}/${sample}.bam
    #$SAMTOOLS flagstat ${ALIGNLOC}/${sample}.bam
    
    #echo "..removing intermediate files"
    rm ${TEMPLOC}/${sample}.sam
    #rm ${TEMPLOC}/${sample}.unsorted.bam

    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Assemble transcripts (StringTie)"
    $STRINGTIE -p $NUMCPUS -G ${GTFFILE} -o ${ALIGNLOC}/${sample}.gtf \
     -l ${sample} ${ALIGNLOC}/${sample}.bam
done

## merge transcript file
echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Merge all transcripts (StringTie)"
ls -1 ${ALIGNLOC}/*.gtf > ${ALIGNLOC}/mergelist.txt

$STRINGTIE --merge -p $NUMCPUS -G  ${GTFFILE} \
    -o ${BALLGOWNLOC}/stringtie_merged.gtf ${ALIGNLOC}/mergelist.txt

## estimate transcript abundance
echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Estimate abundance for each sample (StringTie)"
for ((i=0; i<=${#reads1[@]}-1; i++ )); do
    sample="${reads1[$i]%%.*}"
    dsample="${sample%%_*}"
    sample="${sample%_*}"
    if [ ! -d ${BALLGOWNLOC}/${dsample} ]; then
       mkdir -p ${BALLGOWNLOC}/${dsample}
    fi
    $STRINGTIE -e -B -p $NUMCPUS -G ${BALLGOWNLOC}/stringtie_merged.gtf \
    -o ${BALLGOWNLOC}/${dsample}/${dsample}.gtf ${ALIGNLOC}/${sample}.bam
done

echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Generate the DE tables (Ballgown)"

Rscript ${WRKDIR}/rnaseq_ballgown.R ${PHENODATA}
### This should generate the DE tables in the output directory: 
###      chrX_transcripts_results.csv
###      chrX_genes_results.csv

echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> DONE."
} #pipeline end

pipeline 2>&1 | tee $LOGFILE

```

2. rnaseq_pipeline.config.sh

```shell
## Configuration file for rnaseq_pipeline.sh
##
## Place this script in a working directory and edit it accordingly.
##
## The default configuration assumes that the user unpacked the 
## chrX_data.tar.gz file in the current directory, so all the input
## files can be found in a ./chrX_data sub-directory

#how many CPUs to use on the current machine?
NUMCPUS=8

#### Program paths ####

## optional BINDIR, using it here because these programs are installed in a common directory
#BINDIR=/usr/local/bin
#HISAT2=$BINDIR/hisat2
#STRINGTIE=$BINDIR/stringtie
#SAMTOOLS=$BINDIR/samtools

#if these programs are not in any PATH directories, please edit accordingly:
HISAT2=$(which hisat2)
STRINGTIE=$(which stringtie)
SAMTOOLS=$(which samtools)

#### File paths for input data
### Full absolute paths are strongly recommended here.
## Warning: if using relatives paths here, these will be interpreted 
## relative to the  chosen output directory (which is generally the 
## working directory where this script is, unless the optional <output_dir>
## parameter is provided to the main pipeline script)

## Optional base directory, if most of the input files have a common path
# BASEDIR="/home/johnq/RNAseq_protocol/chrX_data"
BASEDIR=$(pwd -P)/chrX_data

FASTQLOC="$BASEDIR/samples"
GENOMEIDX="$BASEDIR/indexes/chrX_tran"
GTFFILE="$BASEDIR/genes/chrX.gtf"
PHENODATA="$BASEDIR/geuvadis_phenodata.csv"

TEMPLOC="./tmp" #this will be relative to the output directory

## list of samples 
## (only paired reads, must follow _1.*/_2.* file naming convention)
reads1=(${FASTQLOC}/*_1.*)
reads1=("${reads1[@]##*/}")
reads2=("${reads1[@]/_1./_2.}")

```



### 差异化分析R脚本

```R
#!/usr/bin/env Rscript
# run this in the output directory for rnaseq_pipeline.sh
# passing the pheno data csv file as the only argument 
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
# assume no output directory argument was given to rnaseq_pipeline.sh
  pheno_data_file <- paste0(getwd(), "/chrX_data/geuvadis_phenodata.csv")
} else {
  pheno_data_file <- args[1]
}

library(ballgown)
library(RSkittleBrewer)
library(genefilter)
library(dplyr)
library(devtools)

## Read phenotype sample data
pheno_data <- read.csv(pheno_data_file)

## Read in expression data
bg_chrX <- ballgown(dataDir = "ballgown", samplePattern="ERR", pData=pheno_data)

## Filter low abundance genes
bg_chrX_filt <- subset(bg_chrX, "rowVars(texpr(bg_chrX)) > 1", genomesubset=TRUE)

## DE by transcript
results_transcripts <-  stattest(bg_chrX_filt, feature='transcript', covariate='sex', 
         adjustvars=c('population'), getFC=TRUE, meas='FPKM')

## DE by gene
results_genes <-  stattest(bg_chrX_filt, feature='gene', covariate='sex', 
         adjustvars=c('population'), getFC=TRUE, meas='FPKM')

## Add gene name
results_transcripts <- data.frame(geneNames=ballgown::geneNames(bg_chrX_filt),
          geneIDs=ballgown::geneIDs(bg_chrX_filt), results_transcripts)

## Sort results from smallest p-value
results_transcripts <- arrange(results_transcripts, pval)
results_genes <-  arrange(results_genes, pval)

## Write results to CSV
write.csv(results_transcripts, "chrX_transcripts_results.csv", row.names=FALSE)
write.csv(results_genes, "chrX_genes_results.csv", row.names=FALSE)

## Filter for genes with q-val <0.05
subset(results_transcripts, results_transcripts$qval <=0.05)
subset(results_genes, results_genes$qval <=0.05)

## Plotting setup
tropical <- c('darkorange', 'dodgerblue', 'hotpink', 'limegreen', 'yellow')
palette(tropical)

## Plotting gene abundance distribution
fpkm <- texpr(bg_chrX, meas='FPKM')
fpkm <- log2(fpkm +1)
boxplot(fpkm, col=as.numeric(pheno_data$sex), las=2,ylab='log2(FPKM+1)')

## Plot individual transcripts
ballgown::transcriptNames(bg_chrX)[12]
plot(fpkm[12,] ~ pheno_data$sex, border=c(1,2),
     main=paste(ballgown::geneNames(bg_chrX)[12], ' : ',ballgown::transcriptNames(bg_chrX)[12]),
     pch=19, xlab="Sex", ylab='log2(FPKM+1)')
points(fpkm[12,] ~ jitter(as.numeric(pheno_data$sex)), col=as.numeric(pheno_data$sex))

## Plot gene of transcript 1729
plotTranscripts(ballgown::geneIDs(bg_chrX)[1729], bg_chrX,
                main=c('Gene XIST in sample ERR188234'), sample=c('ERR188234'))

## Plot average expression
plotMeans(ballgown::geneIDs(bg_chrX)[203], bg_chrX_filt, groupvar="sex", legend=FALSE)


```

