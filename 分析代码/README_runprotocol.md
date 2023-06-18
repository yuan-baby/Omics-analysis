# HISAT-StringTie 流程简要操作方法

为了在示例数据 (chrX_data.tar.gz) 上运行 HISAT-StringTie 流程，建议使用至少8GB内存和多核心的Linux或OS X计算机，并按照以下建议的步骤进行操作。若需要查看更详细的流程步骤，参见论文^[1]^

 1. 请下载并安装以下软件的最新版本：
     hisat2 (http://ccb.jhu.edu/software/hisat2) 和 
     stringtie (http://ccb.jhu.edu/software/stringtie)。
    按照论文^[1]^中的说明，在 R 中安装 Ballgown 软件包及其它依赖项。
    同时，在系统上安装 samtools 程序（http://samtools.sourceforge.net/）。本脚本支持从0.1.19到1.3的全部版本。
    
    在本项目中使用Dockerfile即可获得完成环境配置的centos7.2镜像，使用以下命令：
    
    ```shell
    # 若直接构建出错则先运行这一命令
    # docker pull centos:7.2.1511
    
    # 构建镜像，rna-seq可以修改为其他镜像名
    docker build -t rna-seq .
    ```
    
    构建需要大约，请耐心等候。
    
 2. 为这次流程运行创建或选择一个工作目录（输入和输出文件将存储在这个目录中）。

 3. 请在当前工作目录中下载 `chrX_data.tar.gz`、`rnaseq_pipeline.sh` 和 `rnaseq_pipeline.config.sh`。解压缩 `chrX_data.tar.gz`，使用以下命令：

    ```shell
    tar -zxvf chrX_data.tar.gz
    ```

    这个命令将会在当前目录下创建一个名为 `./chrX_data` 的目录。

 4. 打开 `rnaseq_pipeline.config.sh` 文件，验证并根据需要更改相关变量的值，特别是：

    * NUMCPUS应设置为运行流程各个步骤时要使用的CPU线程数；通常情况下，这不能设置为高于计算机上可用CPU核数的值。
    * HISAT2、STRINGTIE和SAMTOOLS应设置为这些程序在系统上的完整路径。默认情况下，脚本会尝试自动查找这些程序，如果程序在当前shell的任何PATH目录中则能成功找到。

 5. 执行主脚本：

    ```shell
    ./rnaseq_pipeline.sh out
    ```

    这将运行分析流程并创建`./out`，`./out/hisat2/`和`./out/ballgown/`目录。Ballgown的计数表将位于`./out/ballgown/`目录中。带有每个步骤时间戳的日志消息将显示在终端上，也将保存在 `run.log` 文件中。ballgown得到的差异表达分析结果将保存在两个CSV文件中：`./out/chrX_transcripts_results.csv`和`./out/chrX_genes_results.csv`

在Intel i7-2600 Desktop CPU上（配置文件中NUMCPUS=4）运行流程脚本需要约13分钟，在AMD Opteron 6172服务器上（NUMCPUS设置为8）需要约23分钟。

[1] Pertea, M., Kim, D., Pertea, G. *et al.* Transcript-level expression analysis of RNA-seq experiments with HISAT, StringTie and Ballgown. *Nat Protoc* **11**, 1650–1667 (2016). https://doi.org/10.1038/nprot.2016.095