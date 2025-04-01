# Metannotation

一行命令完成物种丰度注释！

# Usage

```bash
./MetaGenPipe.sh all -d /data/khanh/test -i /data/khanh/test/2.cleandata/ -b /public/database/kraken/kraken2/PlusPF/20241228 --r1-pattern ".un.1.fq.gz" --r2-pattern ".un.2.fq.gz" --size 1
```



# MetaGenPipe元基因组分析流程标准操作程序(SOP)

## 1. 简介

MetaGenPipe是一个全面的元基因组分析工具，用于使用Kraken2和Bracken进行分类学分析。此SOP将指导您完成从原始数据到分类分析结果的整个过程。

## 2. 先决条件

### 2.1. 软件要求

* Kraken2：用于序列分类
* Bracken：用于估计物种丰度
* Python3：带有pandas库
* 标准Unix/Linux工具：bash, awk, sed等

### 2.2. 数据要求

* 配对末端测序数据（通常为fastq.gz格式）

## 3. 设置工作环境

### 3.1. 下载MetaGenPipe脚本

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="token comment"># 将MetaGenPipe.sh脚本下载到工作目录</span><span class="">
</span></span><span class=""><span class=""></span><span class="token function">wget</span><span class=""> https://your-repository.com/MetaGenPipe.sh
</span></span><span class=""><span class=""></span><span class="token function">chmod</span><span class=""> +x MetaGenPipe.sh</span></span></code></div></div></div></pre>

### 3.2. 创建目录结构

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="token comment"># 创建基本目录结构</span><span class="">
</span></span><span class="">./MetaGenPipe.sh setup -d /path/to/your/project</span></code></div></div></div></pre>

## 4. 准备输入数据

将原始配对末端测序数据放入适当的目录中，例如 `/path/to/your/project/2.cleandata/`。

## 5. 运行完整的分析流程

### 5.1. 一步完成全流程

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="">./MetaGenPipe.sh all </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -d /path/to/your/project </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -i /path/to/your/project/2.cleandata </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -b /path/to/kraken2/database </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --r1-pattern </span><span class="token string">"*.r1.fq.gz"</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --r2-pattern </span><span class="token string">"*.r2.fq.gz"</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --size </span><span class="token number">100</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --parallel </span><span class="token number">4</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --threads </span><span class="token number">16</span></span></code></div></div></div></pre>

参数说明：

* `-d`：项目的基础目录
* `-i`：包含测序读取的输入目录
* `-b`：Kraken2/Bracken数据库目录
* `--r1-pattern`：R1文件的模式（根据您的文件命名方式调整）
* `--r2-pattern`：R2文件的模式（根据您的文件命名方式调整）
* `--size`：每组样本的数量（默认100）
* `--parallel`：最大并行作业数（默认4）
* `--threads`：每个作业的线程数（默认16）

## 6. 分步运行分析流程

如果您想分步骤运行流程以便更好地控制和监控，可以按以下步骤进行：

### 6.1. 样本分组

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="">./MetaGenPipe.sh group </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -i /path/to/your/project/2.cleandata </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -o /path/to/your/project/2.cleandata/grouped </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --r1-pattern </span><span class="token string">"*.r1.fq.gz"</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --r2-pattern </span><span class="token string">"*.r2.fq.gz"</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --size </span><span class="token number">100</span></span></code></div></div></div></pre>

### 6.2. Kraken2分析

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="">./MetaGenPipe.sh kraken </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -i /path/to/your/project/2.cleandata/grouped </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -o /path/to/your/project/5.annotation/kraken2 </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -d /path/to/kraken2/database </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --parallel </span><span class="token number">4</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --threads </span><span class="token number">16</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --confidence </span><span class="token number">0.1</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --min-hits </span><span class="token number">3</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --r1-pattern </span><span class="token string">"*.r1.fq.gz"</span><span class=""></span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --r2-pattern </span><span class="token string">"*.r2.fq.gz"</span></span></code></div></div></div></pre>

### 6.3. Bracken分析

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="">./MetaGenPipe.sh bracken </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -i /path/to/your/project/5.annotation/kraken2 </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  -d /path/to/kraken2/database </span><span class="token punctuation">\</span><span class="">
</span></span><span class=""><span class="">  --read-len </span><span class="token number">150</span></span></code></div></div></div></pre>

### 6.4. 生成MPA格式文件

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="">./MetaGenPipe.sh mpa </span><span class="token punctuation">\</span><span class="">
</span></span><span class="">  -k /path/to/your/project/5.annotation/kraken2</span></code></div></div></div></pre>

### 6.5. 增强Bracken结果

<pre><div class="relative flex flex-col rounded-lg"><div class="text-text-300 absolute pl-3 pt-2.5 text-xs">bash</div><div class="pointer-events-none sticky my-0.5 ml-0.5 flex items-center justify-end px-1.5 py-1 mix-blend-luminosity top-0"><div class="from-bg-300/90 to-bg-300/70 pointer-events-auto rounded-md bg-gradient-to-b p-0.5 backdrop-blur-md"><button class="flex flex-row items-center gap-1 rounded-md p-1 py-0.5 text-xs transition-opacity delay-100 text-text-300 active:scale-95 select-none hover:bg-bg-200 opacity-60 hover:opacity-100" data-state="closed"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="text-text-500 mr-px -translate-y-[0.5px]"><path d="M200,32H163.74a47.92,47.92,0,0,0-71.48,0H56A16,16,0,0,0,40,48V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V48A16,16,0,0,0,200,32Zm-72,0a32,32,0,0,1,32,32H96A32,32,0,0,1,128,32Zm72,184H56V48H82.75A47.93,47.93,0,0,0,80,64v8a8,8,0,0,0,8,8h80a8,8,0,0,0,8-8V64a47.93,47.93,0,0,0-2.75-16H200Z"></path></svg><span class="text-text-200 pr-0.5">Copy</span></button></div></div><div><div class="prismjs code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed"><code class="language-bash"><span class=""><span class="">./MetaGenPipe.sh enhance </span><span class="token punctuation">\</span><span class="">
</span></span><span class="">  -k /path/to/your/project/5.annotation/kraken2</span></code></div></div></div></pre>

## 7. 结果文件解析

完成后，主要结果文件将位于以下目录：

1. **Kraken2结果** ：

* 位置：`/path/to/your/project/5.annotation/kraken2/`
* 文件：`*_kraken2.report`和 `*_kraken2.output`
* 说明：每个样本的分类结果和报告

1. **Bracken结果** ：

* 位置：`/path/to/your/project/5.annotation/bracken/`
* 文件：各分类级别目录下的 `*_bracken_*.txt`文件
* 合并文件：`combined_bracken_*.txt`（各分类级别）
* 说明：各分类级别（种、属、科、目、纲、门、域）的丰度估计

1. **MPA格式文件** ：

* 位置：`/path/to/your/project/5.annotation/kraken2/combined_mpa.txt`
* 说明：MetaPhlAn格式的合并分类结果

1. **增强的Bracken结果** ：

* 位置：`/path/to/your/project/5.annotation/bracken/enhanced/`
* 文件：`enhanced_bracken_*.txt`
* 说明：包含完整分类谱系的Bracken结果

## 8. 故障排除

### 8.1. 文件模式问题

如果脚本无法找到您的输入文件，请确保正确指定了 `--r1-pattern`和 `--r2-pattern`参数，以匹配您的文件命名方式。

### 8.2. 路径问题

确保所有指定的路径都是绝对路径或相对于当前工作目录的正确路径。

### 8.3. 权限问题

确保所有目录都有适当的读写权限。

### 8.4. 内存或磁盘空间问题

Kraken2分析可能需要大量内存，特别是对于大数据库。确保您的系统有足够的资源。

## 9. 额外提示

* 在运行全流程之前，建议先在小数据集上测试脚本。
* 为获得最佳性能，根据您的系统资源调整 `--parallel`和 `--threads`参数。
* 定期检查日志文件，以监控进度并及早发现任何问题。
* 日志文件位于各个步骤的相应目录中。
