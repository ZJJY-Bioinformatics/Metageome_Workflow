#!/bin/bash

if [ ! -a qsub_run_main.sh ]; then rm qsub_run_main.sh ;fi
if [ ! -a sample.list ]; then rm sample.list ;fi

cat /data/wangjiaxuan/rawdata/calm05_metagenome/all_samples.tsv | while read group sample fq1 fq2
do
    echo ${sample} >> sample.list
done


# 抽取2M reads做分析（速度快,测序深度均一化）
cat sample.list | while read sample
do
    echo "export PATH="/data/wangjiaxuan/biosoft/miniconda3/bin:\$PATH" && source activate meta && \
    /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/bbmap.sh \
    ref=06.annotation/all.orf.300bp.fa.95.90 \
    in=02.rmhost/${sample}.rmhost.1.fq.gz \
    in2=02.rmhost/${sample}.rmhost.2.fq.gz \
    out=07.abundcalc/${sample}.bam \
    k=13 minid=0.90 t=20 nodisk=true rpkm=07.abundcalc/${sample}.rpkm \
    && \
    samtools view -F 4 -h 07.abundcalc/${sample}.bam -o 07.abundcalc/${sample}.sam \
    && \
    grep '^\@' 07.abundcalc/${sample}.sam > 07.abundcalc/${sample}_2M.sam \
    && \
    grep -v '^\@' 07.abundcalc/${sample}.sam > 07.abundcalc/${sample}_noheader.sam \
    && \
    shuf 07.abundcalc/${sample}_noheader.sam -n 2000000 >> 07.abundcalc/${sample}_2M.sam \
    && \
    samtools view -bS 07.abundcalc/${sample}_2M.sam -o 07.abundcalc/${sample}_2M.bam \
    && \
    samtools sort 07.abundcalc/${sample}_2M.bam -o 07.abundcalc/${sample}.sorted.bam -@ 10 \
    && \
    rm 07.abundcalc/${sample}*.sam 07.abundcalc/${sample}_2M.bam \
    && \
    /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/jgi_summarize_bam_contig_depths --outputDepth 07.abundcalc/${sample}.depth.txt 07.abundcalc/${sample}.sorted.bam \
    && \
    echo -e \"#contigName\\tcontigLen\\ttotalAvgDepth\\tsorted.bam\\tsorted.bam-var\" > 07.abundcalc/${sample}_depth.finalouput \
    && \
    cat 07.abundcalc/${sample}.depth.txt >> 07.abundcalc/${sample}_depth.finalouput" >> qsub_run_main.sh
done

echo "please run the comand <<<<   nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r qsub_run_main.sh -b 1 &  >>>>"

# rm -rf 00.rawdata 03.taxonomy 06.annotation 01.fastq_qc 04.assembly 07.abundcalc 02.rmhost 05.predict 08.binning sample.list util qsub_run_main.sh