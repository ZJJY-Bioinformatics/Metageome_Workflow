# Meta Genome 使用

## 维护者

[王家轩](https://github.com/wangjiaxuan666)	邮箱（992914078@qq.com）


## 环境要求

首先需要加载human3的环境，humann3已经安装在集群上，运行如下命令，测试是否成功

```sh
export PATH="/data/wangjiaxuan/biosoft/miniconda3/bin:$PATH"
which conda
source activate meta
```
如果上述运行成功，说明已经具有运行改脚本所需的环境

## 运行

需要一个`tsv`配置文件,有四列，但是没有表头，分别是`group`，`sample`， `read1 path`，`read2 path`。

例如[示例文件](0.Input/sample_input_path.tsv)：

```
GroupA	NCD42	/data/wangjiaxuan/workflow/meta-genome/test/NCD42.R1.fq	/data/wangjiaxuan/workflow/meta-genome/test/NCD42.R2.fq
GroupA	NCD44	/data/wangjiaxuan/workflow/meta-genome/test/NCD44.R1.fq	/data/wangjiaxuan/workflow/meta-genome/test/NCD44.R2.fq
GroupA	NCD47	/data/wangjiaxuan/workflow/meta-genome/test/NCD47.R1.fq	/data/wangjiaxuan/workflow/meta-genome/test/NCD47.R2.fq
GroupB	NCD50	/data/wangjiaxuan/workflow/meta-genome/test/NCD50.R1.fq	/data/wangjiaxuan/workflow/meta-genome/test/NCD50.R2.fq
GroupB	NCD8	/data/wangjiaxuan/workflow/meta-genome/test/NCD8.R1.fq	/data/wangjiaxuan/workflow/meta-genome/test/NCD8.R2.fq
```

可见，一行是一个样本，如果是一个样本对应多个line的fq文件，可以自己合并在一起，再输入合并后的read1和read2 路径。

剩下的就是运行

```bash
bash main.sh -i ${whereareyourtsv}.tsv
```

## 结果展示

当结果分析完成，会生成三个文件，目录结构如下：

```
.
├── 0.Input # 输入配置文件-------------------------
│   └── sample_input_path.tsv # 输入的配置文献
├── 1.Kneaddata_Clean # Kneaddata 输出文件-------------------------
│   ├── fastqc #  不用看
│   ├── kneaddata_qc_result.tsv # 简单的kneaddata 输入前后的质控
│   ├── multiqc_result # 详细的kneaddata 输入前后的质控
│   ├── NCD42_humann2_in4.fq # 输入到human2中的数据是，kneaddata_paired_[12].fastq,kneaddata_unmatched_[12].fastq四个文件合并来的
│   ├── NCD42.uniq.R1_kneaddata_hg37dec_v0.1_bowtie2_paired_contam_1.fastq # 见附录-kneaddata的输出结果
│   ├── NCD42.uniq.R1_kneaddata_hg37dec_v0.1_bowtie2_paired_contam_2.fastq
│   ├── NCD42.uniq.R1_kneaddata_hg37dec_v0.1_bowtie2_unmatched_1_contam.fastq
│   ├── NCD42.uniq.R1_kneaddata_hg37dec_v0.1_bowtie2_unmatched_2_contam.fastq
│   ├── NCD42.uniq.R1_kneaddata.log
│   ├── NCD42.uniq.R1_kneaddata_paired_1.fastq
│   ├── NCD42.uniq.R1_kneaddata_paired_2.fastq
│   ├── NCD42.uniq.R1_kneaddata_unmatched_1.fastq
│   ├── NCD42.uniq.R1_kneaddata_unmatched_2.fastq
├── 2.Humann2_Quantity # Humann2 输出文件-------------------------
│   ├── NCD42_humann2_in4_genefamilies_cpm.tsv # 其中某个样本的基因｜物种的定量结果（CPM标准化后）
│   ├── NCD42_humann2_in4_genefamilies.tsv # 其中某个样本的基因｜物种的定量结果
│   ├── NCD42_humann2_in4_pathabundance.tsv # 其中某个样本的功能通路的定量结果
│   ├── NCD42_humann2_in4_pathcoverage.tsv # 其中某个样本的物种的覆盖度结果
├── 3.Result_Sum # 所有样本的汇总输出文件-------------------------
│   ├── all.sample_Functionfamilie_cpms.tsv 
│   ├── all.sample_Functionfamilies.tsv
│   ├── all.sample_genefamilies_cpm.tsv
│   ├── all.sample_genefamilies.tsv
│   ├── all.sample_pathabundance.tsv
│   └── all.sample_pathcoverage.tsv
├── main.sh # 主要脚本
```

## 附录

### Kneaddata的输出结果

参考：https://github.com/biobakery/biobakery/wiki/kneaddata

Output:

| Output Files (Listed in the order created)              | Description                                                  |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| seq1_kneaddata.log                                      | Log file of the kneaddata run                                |
| seq1_kneaddata.trimmed.1.fastq                          | This file has trimmed reads (Mate 1) as a output of Paired Ends run in Trimmomatic |
| seq1_kneaddata.trimmed.2.fastq                          | This file has trimmed reads (Mate 2) as a output of Paired Ends run in Trimmomatic |
| seq1_kneaddata.trimmed.single.1.fastq                   | This file has trimmed reads (only Mate 1 survived) after running Trimmomatic |
| seq1_kneaddata.trimmed.single.2.fastq                   | This file has trimmed reads (only Mate 2 survived) after running Trimmomatic |
| seq1_kneaddata_demo_db_bowtie2_paired_contam_1.fastq    | FASTQ file containing reads that were identified as contaminants from the database. |
| seq1_kneaddata_demo_db_bowtie2_paired_contam_2.fastq    | FASTQ file containing reads that were identified as contaminants from the database. |
| seq1_kneaddata_demo_db_bowtie2_unmatched_1_contam.fastq | This file includes reads (Mate 1) that were identified as contaminants from the database |
| seq1_kneaddata_demo_db_bowtie2_unmatched_2_contam.fastq | This file includes reads (Mate 2) that were identified as contaminants from the database |
| **seq1_kneaddata_paired_1.fastq**                       | Final output of KneadData after running Trimmomatic + Bowtie2 for seq1 |
| **seq1_kneaddata_paired_2.fastq**                       | Final output of KneadData after running Trimmomatic + Bowtie2 for seq1 |
| seq1_kneaddata_unmatched_1.fastq                        | Final output of KneadData after running Trimmomatic + Bowtie2 for seq1 (only Mate 1 survived) |
| seq1_kneaddata_unmatched_2.fastq                        | Final output of KneadData after running Trimmomatic + Bowtie2 for seq1 (only Mate 2 survived) |