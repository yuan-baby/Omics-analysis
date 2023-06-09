FROM centos:7.2.1511

# 更新yum源并安装依赖
RUN yum update -y && \
    yum install -y wget gcc-c++ make zlib1g-dev libbz2-dev \
	ncurses ncurses-devel xz xz-devel bzip2 bzip2-devel zlib zlib-devel libcurl libcurl-devel zlib zlib-devel \
        liblzma-dev libncurses5-dev apt-utils ca-certificates curl unzip \
        build-essential gfortran git libreadline-dev pkg-config python3-dev \
        python3-pip python3-setuptools python3-venv r-base r-base-dev \
	epel-release openssl-devel gcc-gfortran readline-devel libjpeg-turbo-devel libpng-devel libtiff-devel zlib-devel pcre-devel libcurl-devel libxml2-devel blas-devel lapack-devel && \
	chmod +x /usr/bin/g++

# 安装R 4.3
RUN wget https://cran.r-project.org/src/base/R-4/R-4.3.0.tar.gz && \
    tar -zxvf R-4.3.0.tar.gz && \
    cd R-4.3.0 && \
    ./configure && \
    make && \
    make install
	
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
RUN R -e 'install.packages("bioconductor",repos="https://mirrors.sjtug.sjtu.edu.cn/cran/");options(BioC_mirror="https://mirror.sjtu.edu.cn/bioconductor");BiocManager::install(c("alyssafrazee/RSkittleBrewer","ballgown","genefilter","dplyr","devtools"))'

# 配置镜像启动后的默认命令
CMD ["/bin/bash"]
