#!/bin/bash

func() {
    echo "Usage:"
    echo "[-i]: The input tsv without header including four column which mean group, sample ,read1 and read2 fq file path"
    echo "[-h]: The help document"
    # shellcheck disable=SC2242
    # shellcheck disable=SC2242
    exit -1
}

input="0.Input/sample_input_path.tsv"

while getopts "i:h" opt; do
    case $opt in
      i) input="$OPTARG";;
      h) func;;
      ?) func;;
    esac
done

# 设置工作路径
if [ ! -e 0.Input/ ]; then mkdir 0.Input  ;fi
if [ ! -e 3.Result_Sum ]; then mkdir 3.Result_Sum  ;fi
if [ ! -e 2.Humann2_Quantity ]; then mkdir 2.Humann2_Quantity  ;fi
if [ ! -e 1.Kneaddata_Clean ]; then mkdir 1.Kneaddata_Clean  ;fi
if [ ! -e 4.Annot ]; then mkdir 4.Annot  ;fi
if [ ! -e shell/ ]; then mkdir shell  ;fi

# var set
kneaddata_db=/data3/wangjiaxuan/refer/kneaddata_db/Homo_sapiens_hg37_and_human_contamination_Bowtie2_v0.1/
run_mem=506384m
trimmomatic_p="SLIDINGWINDOW:5:20 MINLEN:36 LEADING:3 TRAILING:3 ILLUMINACLIP:/tools/Trimmomatic-0.38/adapters/TruSeq3-PE.fa:2:30:10"

# shellcheck disable=SC1073
if [ -e run_main.sh ]; then rm run_main.sh;fi
if [ -e samples.tsv ]; then rm samples.tsv;fi
cat ${input} | while read group sample fq1 fq2
do
echo "${sample}" >> samples.tsv
done

cat ${input} | while read group sample fq1 fq2
do
echo ${sample}
echo "  export PATH="/data/wangjiaxuan/biosoft/miniconda3/bin:\$PATH" && source activate meta && \
echo -e "${fq1}\\\\n${fq2}" > 0.Input/${sample}_fq.list && \
/data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/fastuniq \
-i 0.Input/${sample}_fq.list \
-o 0.Input/${sample}.uniq.R1.fq -p 0.Input/${sample}.uniq.R2.fq && \
kneaddata \
  -i 0.Input/${sample}.uniq.R1.fq \
  -i 0.Input/${sample}.uniq.R2.fq \
  -o 1.Kneaddata_Clean \
  -db ${kneaddata_db} \
  -t 10 \
  --max-memory ${run_mem} \
  --trimmomatic-options \"${trimmomatic_p}\" \
  --bowtie2-options \"--very-sensitive --dovetail\" \
  --remove-intermediate-output \
  --trf /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/ \
  --trimmomatic /data/wangjiaxuan/biosoft/Trimmomatic \
  --run-fastqc-start \
  --run-fastqc-end \
  --fastqc /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin && \
  cat 1.Kneaddata_Clean/${sample}*_kneaddata_[pu]*.fastq > 1.Kneaddata_Clean/${sample}_humann2_in4.fq && \
  /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann \
  --threads 25 \
  --input  1.Kneaddata_Clean/${sample}_humann2_in4.fq \
  --output 2.Humann2_Quantity \
  --search-mode uniref90 && \
  humann_renorm_table \
  -i 2.Humann2_Quantity/${sample}_humann2_in4_genefamilies.tsv \
  -o 2.Humann2_Quantity/${sample}_humann2_in4_genefamilies_cpm.tsv \
  --units cpm && \
  /data/wangjiaxuan/biosoft/seqtk/seqtk sample -s100 1.Kneaddata_Clean/${sample}*_kneaddata_pair*_1.fastq 3000000 > 4.Annot/ARG/${sample}_1.fq && \
  /data/wangjiaxuan/biosoft/seqtk/seqtk sample -s100 1.Kneaddata_Clean/${sample}*_kneaddata_pair*_2.fastq 3000000 > 4.Annot/ARG/${sample}_2.fq && \
  echo -e "SampleID\\\\tName\\\\tCategory" > 0.Input/arg_metadata.tsv && \
  echo -e "1\\\\t${sample}\\\\t${group}" >> 0.Input/arg_metadata.tsv && \
  /data/wangjiaxuan/biosoft/ARG/argoap_pipeline_stageone_version2.pl \
  -i 4.Annot/ARG \
  -o 4.Annot/ARG/outdir \
  -m 0.Input/arg_metadata.tsv -n 20 && \
  /data/wangjiaxuan/biosoft/ARG/argoap_pipeline_stagetwo_version2-rpkm.pl \
  -i 4.Annot/ARG/outdir/extracted.fa \
  -m 4.Annot/ARG/outdir/meta_data_online.txt \
  -o 4.Annot/ARG/final_out/${sample} -n 20 \
  " >> run_main.sh
done

  # /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/metaphlan \
  # 1.Kneaddata_Clean/${sample}_humann2_in4.fq   \
  # -o 2.Humann2_Quantity/${sample}_profiled_metagenome.txt \
  # --input_type fastq \
  # -t rel_ab_w_read_stats \
  # --bowtie2out ${sample}_metagonem_mapping \
  # --bowtie2db /data2/wangjiaxuan/refer/metaphlan/ && \

echo "please run the comand <<<</data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r run_main.sh -b 1>>>>"


# ## 更新格式：humann_config --update <section> <name> <value>
# humann_config --update database_folders nucleotide /path/to/databases/chocophlan_v296_201901
# humann_config --update database_folders protein /path/to/databases/uniref90_v201901/
# humann_config --update database_folders utility_mapping /path/to/databases/mapping_v201901/