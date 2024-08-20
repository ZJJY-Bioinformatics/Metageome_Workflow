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

if [ -e run_main.sh ]; then rm run_main.sh;fi
if [ -e samples.tsv ]; then rm samples.tsv;fi
if [ -e samples_exist.tsv ]; then rm samples_exist.tsv;fi

# 设置工作路径
if [ ! -e 0.Input/ ]; then mkdir 0.Input  ;fi
if [ ! -e 3.Result_Sum ]; then mkdir 3.Result_Sum  ;fi
if [ ! -e 2.Humann2_Quantity ]; then mkdir 2.Humann2_Quantity  ;fi
if [ ! -e 1.Kneaddata_Clean ]; then mkdir 1.Kneaddata_Clean  ;fi
if [ ! -e 1.Kneaddata_Clean/log ]; then mkdir 1.Kneaddata_Clean/log  ;fi
if [ ! -e 1.Kneaddata_Clean/clean_data ]; then mkdir 1.Kneaddata_Clean/clean_data  ;fi
if [ ! -e 1.Kneaddata_Clean/host_data ]; then mkdir 1.Kneaddata_Clean/host_data  ;fi
if [ ! -e 4.Annot ]; then mkdir 4.Annot  ;fi
if [ ! -e 4.Annot/ARG ]; then mkdir 4.Annot/ARG  ;fi
if [ ! -e 4.Annot/RGI ]; then mkdir 4.Annot/RGI  ;fi
if [ ! -e 5.Assemble ]; then mkdir 5.Assemble  ;fi
if [ ! -e 5.Assemble/Megahit ]; then mkdir 5.Assemble/Megahit  ;fi
if [ ! -e 6.SNP ]; then mkdir 6.SNP  ;fi
if [ ! -e 6.SNP/marker_snp ]; then mkdir 6.SNP/marker_snp  ;fi

if [ ! -e shell/ ]; then mkdir shell  ;fi
if [ ! -e temp/ ]; then mkdir temp  ;fi

cat ${input} | while read group sample fq1 fq2
do
ln -s ${fq1} 0.Input/${sample}.raw.R1.fq.gz
ln -s ${fq2} 0.Input/${sample}.raw.R2.fq.gz
done

# var set
kneaddata_db=/data3/Group7/wangjiaxuan/refer/kneaddata_db/Homo_sapiens_hg37_and_human_contamination_Bowtie2_v0.1/
run_mem=506384m
trimmomatic_p="SLIDINGWINDOW:4:20 MINLEN:50 ILLUMINACLIP:/tools/Trimmomatic-0.38/adapters/TruSeq3-PE.fa:2:30:10"

# main script
cat ${input} | while read group sample fq1 fq2
do
echo "export PATH="/data3/Group7/wangjiaxuan/biosoft/miniconda3/bin/:\$PATH" && source activate meta && \
pigz -p 8 -d -c 0.Input/${sample}.raw.R1.fq.gz -c > 0.Input/${sample}.R1.fq && \
pigz -p 8 -d -c 0.Input/${sample}.raw.R2.fq.gz -c > 0.Input/${sample}.R2.fq && \
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/kneaddata \
  -i 0.Input/${sample}.R1.fq \
  -i 0.Input/${sample}.R2.fq \
  -o 1.Kneaddata_Clean \
  --output-prefix ${sample}.kneaddata \
  --remove-intermediate-output \
  --reorder \
  --log 1.Kneaddata_Clean/log/${sample}.kneaddata.log \
  -db ${kneaddata_db} \
  -t 10 \
  --sequencer-source TruSeq3 \
  --max-memory ${run_mem} \
  --trimmomatic-options \"${trimmomatic_p}\" \
  --bowtie2-options \"--very-sensitive --dovetail\" \
  --remove-intermediate-output \
  --trf /data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/ \
  --trimmomatic /data3/Group7/wangjiaxuan/biosoft/Trimmomatic \
  --run-fastqc-start \
  --run-fastqc-end \
  --fastqc /data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin && \
  mv 1.Kneaddata_Clean/${sample}.kneaddata_paired_[12].fastq 1.Kneaddata_Clean/clean_data/ && \
  mv 1.Kneaddata_Clean/${sample}.kneaddata_unmatched_[12].fastq 1.Kneaddata_Clean/clean_data/ && \
  mv 1.Kneaddata_Clean/${sample}.kneaddata_*_contam.fastq 1.Kneaddata_Clean/host_data/ && \
  mv 1.Kneaddata_Clean/${sample}.kneaddata_*contam_[12].fastq 1.Kneaddata_Clean/host_data/ && \
  cat 1.Kneaddata_Clean/clean_data/${sample}*.fastq > 1.Kneaddata_Clean/clean_data/${sample}.kneaddata.fastq && \
  rm 0.Input/${sample}.R1.fq  && \
  rm 0.Input/${sample}.R2.fq  && \
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/metaphlan \
  1.Kneaddata_Clean/clean_data/${sample}.kneaddata.fastq \
  -o 2.Humann2_Quantity/${sample}_profiled_metagenome.txt \
  -s 2.Humann2_Quantity/${sample}.sam.bz2 \
  --input_type fastq \
  -t rel_ab_w_read_stats \
  --nproc 12 \
  --bowtie2out 2.Humann2_Quantity/${sample}_metagonem_mapping && \
/home/tangwenli/miniconda3/envs/humann3/bin/humann  \
  --threads 25 \
  --input  1.Kneaddata_Clean/clean_data/${sample}.kneaddata.fastq \
  --output 2.Humann2_Quantity \
  --search-mode uniref90 && \
  /data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_renorm_table \
  -i 2.Humann2_Quantity/${sample}.kneaddata_genefamilies.tsv \
  -o 2.Humann2_Quantity/${sample}.kneaddata_genefamilies_cpm.tsv \
  --units cpm && \
  rm -rf 2.Humann2_Quantity/${sample}.kneaddata_humann_temp && \
  rm 1.Kneaddata_Clean/clean_data/${sample}.kneaddata.fastq && \
  pigz -p 8 1.Kneaddata_Clean/clean_data/${sample}.kneaddata_unmatched_[12].fastq && \
  pigz -p 8 1.Kneaddata_Clean/clean_data/${sample}.kneaddata_paired_[12].fastq && \
  pigz -p 8 1.Kneaddata_Clean/host_data/${sample}.*.fastq && \
  rm  1.Kneaddata_Clean/${sample}*.fast[qa] 1.Kneaddata_Clean/${sample}*.fast[qa]*.dat 1.Kneaddata_Clean/reformatted_identifier*${sample}*" >> run_main.sh
done

echo "please run the comand <<<<nohup /data3/Group7/wangjiaxuan/biosoft/miniconda3/bin/python /data3/Group7/wangjiaxuan/script/qsub.py -s 1 -g 30g -c 8 -l 16 --mn -r run_main.sh -b 1 &>>>>"

#metaphlan --install --bowtie2db /data3/Group7/wangjiaxuan/refer/metaphlan/
# ## 更新格式：humann_config --update <section> <name> <value>
# humann_config --update database_folders nucleotide /data3/Group7/wangjiaxuan/refer/humann3_db/chocophlan_v31_201901/
# humann_config --update database_folders protein /data3/Group7/wangjiaxuan/refer/humann3_db//uniref90_v201901b/
# humann_config --update database_folders utility_mapping /data3/Group7/wangjiaxuan/refer/humann3_db//mapping_v201901b/

#  rm -rf 0.Input 1.Kneaddata_Clean 2.Humann2_Quantity 3.Result_Sum 4.Annot run_main.sh samples.tsv temp shell work_qsub*.sh 
