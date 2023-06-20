# Meta Genome 使用

## 维护者

[王家轩](https://github.com/wangjiaxuan666)	邮箱（992914078@qq.com）

## 环境要求

首先需要加载human3的环境，humann3已经安装在集群上，运行如下命令，测试是否成功

```sh
which conda
export PATH="/data3/Group7/wangjiaxuan/biosoft/miniconda3/bin:$PATH"
source activate meta
```
如果上述运行成功，说明已经具有运行改脚本所需的环境

## 运行

需要一个`tsv`配置文件,有四列，但是没有表头，分别是`group`，`sample`， `read1 path`，`read2 path`。

例如[示例文件../test/sample_fq.tsv](../test/sample_fq.tsv)：

```
GroupA	NCD42	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD42.R1.fq	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD42.R2.fq.gz
GroupA	NCD44	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD44.R1.fq	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD44.R2.fq.gz
GroupA	NCD47	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD47.R1.fq	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD47.R2.fq.gz
GroupB	NCD50	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD50.R1.fq	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD50.R2.fq.gz
GroupB	NCD8	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD8.R1.fq	/data2/wangjiaxuan/MetaGenome_workflow/test/NCD8.R2.fq.gz
```

可见，一行是一个样本，如果是一个样本对应多个line的**fq.gz文件(必须是gz压缩格式的)**，可以自己合并在一起，再输入合并后的read1和read2 路径。

剩下的就是运行

```bash
bash ref_metagenome_step1.sh -i 上述示例meta文件.tsv
```

然后会生成一个投递脚本`run_main.sh`, 根据提示用qsub投递任务。

```
nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r run_main.sh -b 1 &
```

然后开始每个样本分别投递，当分析完后，运行`ref_metagenome_step2.sh`
可以用自己的qsub投递，也可以直接

```
nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 -r ref_metagenome_step2.sh &
```

## 附录：
ref_metagenome_step3.sh 主要是针对宏转录组的宿主转录组分析，如果是宏基因组测序可以不做

运行：
```
nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 -r ref_metagenome_step3.sh &
```

