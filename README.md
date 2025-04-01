# Metannotation

一行命令完成物种丰度注释！

# Usage

```shell
./MetaGenPipe.sh all -d /data/khanh/test -i /data/khanh/test/2.cleandata/ -b /public/database/kraken/kraken2/PlusPF/20241228 --r1-pattern ".un.1.fq.gz" --r2-pattern ".un.2.fq.gz" --size 1
```

# Metannotation 元基因组分析流程标准操作程序（SOP）

## 1. 简介

Metannotatin 是一个全面的元基因组分析工具，用于使用 Kraken2 和 Bracken 进行分类学分析。此 SOP 将指导您完成从原始数据到分类分析结果的整个过程。

## 2. 先决条件

### 2.1. 软件要求

* Kraken2：用于序列分类
* Bracken：用于估计物种丰度
* Python3：带有 pandas 库
* 标准 Unix/Linux 工具：bash, awk, sed 等

### 2.2. 数据要求

* 配对末端测序数据（通常为fastq.gz格式）

## 3. 设置工作环境

### 3.1. 下载 MetaGenPipe 脚本

```shell
# 将 Metannotation.sh 脚本下载到工作目录
wget https://github.com/hahntoh/Metannotation/blob/main/Metannotation.sh
chmod +x Metannotation.sh
```

### 3.2. 创建目录结构

```shell
# 创建基本目录结构
./Metannotation.sh setup -d /path/to/your/project
```

## 4. 准备输入数据

将原始配对末端测序数据链接到指定目录中， `/path/to/your/project/2.cleandata/`。

## 5. 运行完整的分析流程

### 5.1. 一步完成全流程

```shell
./Metannotation.sh all \
  -d /path/to/your/project \
  -i /path/to/your/project/2.cleandata \
  -b /path/to/kraken2/database \
  --r1-pattern "*.r1.fq.gz" \
  --r2-pattern "*.r2.fq.gz" \
  --size 100 \
  --parallel 4 \
  --threads 16
```

参数说明：

* `-d`：项目的基础目录
* `-i`：包含测序读取的输入目录
* `-b`：Kraken2/Bracken 数据库目录
* `--r1-pattern`：R1 文件的模式（根据您的文件命名方式调整）
* `--r2-pattern`：R2 文件的模式（根据您的文件命名方式调整）
* `--size`：每组样本的数量（默认 100）
* `--parallel`：最大并行作业数（默认 4）
* `--threads`：每个作业的线程数（默认 16）

## 6. 分步运行分析流程

如果您想分步骤运行流程以便更好地控制和监控，可以按以下步骤进行：

### 6.1. 样本分组

```shell
./Metannotation.sh group \
  -i /path/to/your/project/2.cleandata \
  -o /path/to/your/project/2.cleandata/grouped \
  --r1-pattern "*.r1.fq.gz" \
  --r2-pattern "*.r2.fq.gz" \
  --size 100
```

### 6.2. Kraken2 分析

```shell
./Metannotation.sh kraken \
  -i /path/to/your/project/2.cleandata/grouped \
  -o /path/to/your/project/5.annotation/kraken2 \
  -d /path/to/kraken2/database \
  --parallel 4 \
  --threads 16 \
  --confidence 0.1 \
  --min-hits 3 \
  --r1-pattern "*.r1.fq.gz" \
  --r2-pattern "*.r2.fq.gz"
```

### 6.3. Bracken 分析

```shell
./Metannotation.sh bracken \
  -i /path/to/your/project/5.annotation/kraken2 \
  -d /path/to/kraken2/database \
  --read-len 150
```

### 6.4. 生成MPA格式文件

```shell
./MetaGenPipe.sh mpa -k /path/to/your/project/5.annotation/kraken2
```

### 6.5. 增强Bracken结果

```shell
./Metannotation.sh enhance -k /path/to/your/project/5.annotation/kraken2
```

## 7. 结果文件解析

完成后，主要结果文件将位于以下目录：

1. **Kraken2结果** ：

* 位置：`/path/to/your/project/5.annotation/kraken2/`
* 文件：`*_kraken2.report` 和 `*_kraken2.output`
* 说明：每个样本的分类结果和报告

1. **Bracken结果** ：

* 位置：`/path/to/your/project/5.annotation/bracken/`
* 文件：各分类级别目录下的 `*_bracken_*.txt` 文件
* 合并文件：`combined_bracken_*.txt`（各分类级别）
* 说明：各分类级别（种、属、科、目、纲、门、域）的丰度估计

1. **MPA格式文件** ：

* 位置：`/path/to/your/project/5.annotation/kraken2/combined_mpa.txt`
* 说明：MetaPhlAn 格式的合并分类结果

1. **增强的Bracken结果** ：

* 位置：`/path/to/your/project/5.annotation/bracken/enhanced/`
* 文件：`enhanced_bracken_*.txt`
* 说明：包含完整分类谱系的 Bracken 结果

## 8. 故障排除

### 8.1. 文件模式问题

如果脚本无法找到您的输入文件，请确保正确指定了 `--r1-pattern` 和 `--r2-pattern` 参数，以匹配您的文件命名方式。

### 8.2. 路径问题

确保所有指定的路径都是绝对路径或相对于当前工作目录的正确路径。

### 8.3. 权限问题

确保所有目录都有适当的读写权限。

### 8.4. 内存或磁盘空间问题

Kraken2 分析可能需要大量内存，特别是对于大数据库。确保您的系统有足够的资源。

## 9. 额外提示

* 在运行全流程之前，建议先在小数据集上测试脚本。
* 为获得最佳性能，根据您的系统资源调整 `--parallel` 和 `--threads` 参数。
* 定期检查日志文件，以监控进度并及早发现任何问题。
* 日志文件位于各个步骤的相应目录中。
