# 宏基因组无参组装分析流程v1.0

本宏基因组分析流程主要是是针对宏基因组无参组装，以方便更好的进行数据库进行注释的，获得更丰富的菌群基因信息。

> 可能相比于kneaddata+metaphlan+humann3的有参分析流程，组装的基因数目和定量的菌群种类更丰富，但数据也更冗余, 之前分析的377个大约测序量在6G左右的粪便宏基因组样本，分析用时2 weeks， 一共鉴定了16054个物种，组装了1164557个基因。

本流程分析可以得到以下结果

1、kraken2输出的菌的丰度矩阵
2、metaspade组装并过滤去冗余后的菌基因序列
3、菌基因序列的KEGG注释以及物种注释
4、菌基因的表达丰度

# 分析流程概览

全流程分为五个步骤（一切为了速度~）

1. 生成meta表
2. 投递big_sample.main_s1.sh，进行质控、去宿主、菌群定量、基因组装
3. 投递big_sample.main_s2.sh，基因进行序列过滤、去冗余、数据比对注释
4. 投递big_sample.main_s3.sh，进行基因定量
5. 投递big_sample.main_s4.sh，整理以上结果，输出目录

## 安装

检验医学部的集群上分析,环境可以直接使用我配置好的. 安装只需要`git clone`本仓库到集群上的`分析路径上就可以`.

例如:

```bash
mkdir metagenome_denovo
cd metagenome_denovo
git clone https://github.com/ZJJY-Bioinformatics/Metageome_Workflow.git
# 进入无参组装的文件目录里
cd Metageome_Workflow/noref_assemble_metagenome
```

## Step0 生成样本meta表格

制表符分割的，一共有**四列**，分别是`组名`（可以不分组，但是一定要写），`样本名称`，`样本测序Read1的fq.gz文件的绝对路径`，`样本测序Read2的fq.gz文件的绝对路径`.

> 注意，必须是压缩格式的fq.gz，给集群省点资源

格式模板如下：

```
# 组名 样本名 read1 read2 (这一行不要写入meta表)
group	SC00000858	~/SC00000858.R1.fq.gz	~/SC00000858.R2.fq.gz
group	SC00001700	~/SC00001700.R1.fq.gz	~/SC00001700.R2.fq.gz
```

## Step1 投递big_sample.main_s1.sh

> 脚本包含“质控去宿主组装物种定量”

运行`bash big_sample.main_s1.sh`, 成功后会有`qsub_run_main.sh`文件的生成，可以简单查看这个文件，一行是一个样本的命令。

接下来用一个测试数据做个demo，其中`../test/sample.tsv`是整理好的meta表。

```
bash big_sample.main_s1.sh -i ../test/sample.tsv
```

然后根据提示运行命令

```
nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r qsub_run_main.sh -b 1 &
```
将投递任务挂起即可。

随后等待等待所有样本分析结束。

# Step2 投递big_sample.main_s2.sh

> 脚本包含”序列过滤去冗余功能注释”

终端输入`/data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 -r big_sample.main_s2.sh`。 等到任务分析完成。

# Step2 投递big_sample.main_s3.sh

> 脚本包含”基因定量”

运行`bash big_sample.main_s3.sh`, 成功后会有`qsub_run_main.sh`文件的生成，可以简单查看这个文件，一行是一个样本的命令。

```
bash big_sample.main_s3.sh -i ../test/sample.tsv
```

然后根据提示运行命令`nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r qsub_run_main.sh -b 1 &`将投递任务挂起即可。

```
nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r qsub_run_main.sh -b 1 &
```

随后等待等待所有样本分析结束。

# Step4 运行big_sample.main_s4.sh

> 脚本包含”结果整理”

这个脚本不用投递，直接在终端`bash big_sample.main_s4.sh`，等待结果输出即可. 结果放在`09.result/`, 其他中间文件在各自的文件中.

```
bash big_sample.main_s4.sh
```

# 结果输出

