# 1、**查找配对文件中未生成的文件**

```bash
comm -23 <(ls *output | sed 's/\.output$//' | sort) <(ls *.report | sed 's/\.report$//' | sort)
```

> 这个命令使用了几个Linux命令行工具组合在一起：
>
> 1. <(...) 是进程替换，会将括号内命令的输出作为一个临时文件传递给外部命令
> 2. ls *output 列出所有以.output结尾的文件
> 3. sed 's/\.output$//' 移除每个文件名末尾的.output后缀，只保留基本文件名
> 4. sort 将结果按字母顺序排序
> 5. 同样的操作也应用于.report文件
> 6. comm 命令用于比较两个已排序的文件：
>    * -1 选项会抑制第一个文件特有的行
>    * -2 选项会抑制第二个文件特有的行
>    * -3 选项会抑制两个文件共有的行
>
> 因此：
>
> * comm -23 表示只显示第一个文件中有但第二个文件中没有的行
> * 在这个例子中，就是显示有.output文件但没有对应.report文件的那些基本文件名
>   执行这个命令后，输出的结果就是那个缺少.report文件的文件名（不带后缀）。

# 2、SCP  **压缩传输文件**

```bash
scp -C /data/khanh/hurmicro/3.alignment/nonpareil/fasta/6*.un.1.fasta zhangcg@124.16.144.150:/data1/zhangcg/khanh/nonp
```

# 3、删除  bracken **注释丰度表的相对丰度的列**

```bash
awk 'BEGIN{FS=OFS="\t"} NR==1{for(i=1;i<=NF;i++) if($i !~ /_frac/) col[++n]=i} {for(i=1;i<=n;i++) printf "%s%s", $(col[i]), (i<n?OFS:ORS)}' enhanced_bracken_species.txt > species.bk.txt

awk 'BEGIN{FS=OFS="\t"} NR==1{for(i=1;i<=NF;i++) if($i !~ /_frac/) col[++n]=i} {for(i=1;i<=n;i++) printf "%s%s", $(col[i]), (i<n?OFS:ORS)}' enhanced_bracken_family.txt > family.bk.txt

awk 'BEGIN{FS=OFS="\t"} NR==1{for(i=1;i<=NF;i++) if($i !~ /_frac/) col[++n]=i} {for(i=1;i<=n;i++) printf "%s%s", $(col[i]), (i<n?OFS:ORS)}' enhanced_bracken_genus.txt > genus.bk.txt
```

# 4、拆分 fq **文件**

```bash
seqkit split2 -p 5 -O output_dir sample_R1.fq.gz sample_R2.fq.gz
```
