#!/bin/bash

func() {
    echo "Usage:"
    echo "[-i]: The input tsv without header including four column which mean group, sample ,read1 and read2 fq file path"
    echo "[-h]: The help document"
    # shellcheck disable=SC2242
    # shellcheck disable=SC2242
    exit -1
}

input="../test/sample.tsv"

while getopts "i:h" opt; do
    case $opt in
      i) input="$OPTARG";;
      h) func;;
      ?) func;;
    esac
done


if [ -a qsub_run_main.sh ]; then rm qsub_run_main.sh ;fi
if [ -a sample.list ]; then rm sample.list ;fi

out_dictory=(00.rawdata 01.fastq_qc 02.rmhost 03.taxonomy 04.assembly 05.predict 06.annotation 07.abundcalc 08.binning)

for dictory in ${out_dictory[@]}
do
    mkdir -p ${dictory}
    mkdir -p ${dictory}/logs
done

mkdir -p 05.predict/prodigal
mkdir -p 06.annotation/ARG

touch sample.list

cat ${input} | while read group sample fq1 fq2
do
    ln -s ${fq1} 00.rawdata/${sample}.R1.fq.gz
    ln -s ${fq2} 00.rawdata/${sample}.R2.fq.gz
    echo ${sample} >> sample.list
done

abspath=$(pwd)

#<<< main >>》
cat sample.list | while read sample
do
    echo "export PATH="/data/wangjiaxuan/biosoft/miniconda3/bin:\$PATH" && source activate meta && \
    seqkit stats \
    --all \
    --basename \
    --tabular \
    --fq-encoding sanger \
    --out-file 00.rawdata/${sample}.raw_stats.tsv \
    --threads 4 \
    00.rawdata/${sample}.R1.fq.gz 00.rawdata/${sample}.R2.fq.gz \
    2> 00.rawdata/logs/${sample}.raw.seqkit.log \
    && \
    /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/fastp \
    --in1 00.rawdata/${sample}.R1.fq.gz \
    --in2 00.rawdata/${sample}.R2.fq.gz \
    --out1 01.fastq_qc/${sample}.trimming.1.fq.gz \
    --out2 01.fastq_qc/${sample}.trimming.2.fq.gz \
    --compression 6 \
    --detect_adapter_for_pe \
    --cut_front \
    --cut_tail \
    --cut_front_window_size 4 \
    --cut_front_mean_quality 20 \
    --cut_tail_window_size 4 \
    --cut_tail_mean_quality 20 \
    --n_base_limit 5 \
    --length_required 51 \
    --thread 4 \
    --html 01.fastq_qc/${sample}.fastp.html \
    --json 01.fastq_qc/${sample}.fastp.json \
    2> 01.fastq_qc/logs/${sample}.fastp.log \
    && \
    seqkit stats \
    --all \
    --basename \
    --tabular \
    --fq-encoding sanger \
    --out-file 01.fastq_qc/${sample}_trimming_stats.tsv \
    --threads 4 \
    01.fastq_qc/${sample}.trimming.1.fq.gz 01.fastq_qc/${sample}.trimming.2.fq.gz \
    2> 01.fastq_qc/logs/${sample}.seqkit.log \
    && \
    bowtie2 \
    --threads 8 \
    -x /data3/wangjiaxuan/refer/metapi_db/human_pangenomics/CHM13/bowtie2/chm13v2.0 \
    -1 01.fastq_qc/${sample}.trimming.1.fq.gz \
    -2 01.fastq_qc/${sample}.trimming.2.fq.gz \
    --very-sensitive \
    2> 02.rmhost/logs/${sample}.bowtie2.log | \
    tee >(samtools flagstat \
        -@8 - \
        > 02.rmhost/${sample}.align2host.flagstat) | \
        samtools fastq \
    -@8 \
    -c 6 \
    -N -f 12 -F 256 \
    -1 02.rmhost/${sample}.rmhost.1.fq.gz \
    -2 02.rmhost/${sample}.rmhost.2.fq.gz - \
    2> 02.rmhost/logs/${sample}.rmhost.log \
    && \
    rm 01.fastq_qc/${sample}.trimming.[12].fq.gz \
    && \
    seqkit stats \
    --all \
    --basename \
    --tabular \
    --fq-encoding sanger \
    --out-file 02.rmhost/${sample}_rmhost_stats.tsv.raw \
    --threads 4 \
    02.rmhost/${sample}.rmhost.1.fq.gz 02.rmhost/${sample}.rmhost.2.fq.gz \
    2> 02.rmhost/logs/${sample}.seqkit.log \
    && \
    /data/wangjiaxuan/biosoft/seqtk/seqtk sample -s100 02.rmhost/${sample}.rmhost.1.fq.gz 3000000 > 06.annotation/ARG/${sample}_1.fq && \
    /data/wangjiaxuan/biosoft/seqtk/seqtk sample -s100 02.rmhost/${sample}.rmhost.2.fq.gz 3000000 > 06.annotation/ARG/${sample}_2.fq && \
    echo -e "SampleID\\\\tName\\\\tCategory" > 06.annotation/arg_metadata_${sample}.tsv && \
    echo -e "1\\\\t${sample}\\\\t${sample}" >> 06.annotation/arg_metadata_${sample}.tsv && \
    /data/wangjiaxuan/biosoft/ARG/argoap_pipeline_stageone_version2.pl \
    -i 06.annotation/ARG \
    -o 06.annotation/ARG/${sample}_outdir \
    -m 06.annotation/arg_metadata_${sample}.tsv -n 20 \
    && \
    rm 06.annotation/ARG/${sample}_1.fq && rm 06.annotation/ARG/${sample}_2.fq \
    && \
    rm 06.annotation/ARG/${sample}_1.fa && rm 06.annotation/ARG/${sample}_2.fa \
    && \
    /data/wangjiaxuan/biosoft/ARG/argoap_pipeline_stagetwo_version2-rpkm.pl \
    -i 06.annotation/ARG/${sample}_outdir/extracted.fa \
    -m 06.annotation/ARG/${sample}_outdir/meta_data_online.txt \
    -o 06.annotation/ARG/${sample}_outdir/${sample}.final_out -n 20 \
    && \
    kraken2 \
    --db /data3/wangjiaxuan/refer/kraken2_db/PlusPFP_20220908 \
    --report 03.taxonomy/${sample}.taxa.tsv \
    --use-mpa-style \
    --use-name \
    --thread 4 \
    --paired 02.rmhost/${sample}.rmhost.1.fq.gz 02.rmhost/${sample}.rmhost.2.fq.gz \
    > /dev/null \
    && \
    echo -e \"#clade_name\\treads\" > 03.taxonomy/${sample}.finalouput \
    && \
    cat 03.taxonomy/${sample}.taxa.tsv >> 03.taxonomy/${sample}.finalouput \
    && \
    /tools/SPAdes/bin/metaspades.py \
    -1 02.rmhost/${sample}.rmhost.1.fq.gz \
    -2 02.rmhost/${sample}.rmhost.2.fq.gz \
    -k 21,33,55,77 \
    --memory 81 \
    --threads 8 \
    -o 04.assembly/${sample}_metaspades.out \
    > 04.assembly/logs/${sample}_metaspades.log \
    && \
    cat 04.assembly/${sample}_metaspades.out/scaffolds.fasta | \
    prodigal \
    -m \
    -a  05.predict/prodigal/${sample}_metaspades.faa \
    -d  05.predict/prodigal/${sample}_metaspades.ffn \
    -o  05.predict/prodigal/${sample}_metaspades.gff \
    -f gff \
    -p meta -q \
    2> 05.predict/logs/${sample}_metaspades.prodigal.log \
    && \
    rm -rf 04.assembly/${sample}_metaspades.out/K* && rm  -rf 04.assembly/${sample}_metaspades.out/corrected 04.assembly/${sample}_metaspades.out/misc 04.assembly/${sample}_metaspades.out/pipeline_state 04.assembly/${sample}_metaspades.out/tmp" >> qsub_run_main.sh
done
#<<< main >>》

echo "please run the comand <<<<   nohup /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python /data/wangjiaxuan/script/qsub.py -s 1 -g 100g -c 8 -l 8 --mn -r qsub_run_main.sh -b 1 &  >>>>"

# rm -rf 00.rawdata 03.taxonomy 06.annotation 01.fastq_qc 04.assembly 07.abundcalc 02.rmhost 05.predict 08.binning sample.list util qsub_run_main.sh
