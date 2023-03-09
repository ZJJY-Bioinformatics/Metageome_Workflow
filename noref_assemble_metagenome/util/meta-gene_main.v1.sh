#!/bin/bash

rm sample.list

mkdir -p \
00.rawdata \
01.fastq_qc \
02.rmhost \
03.taxonomy \
04.assembly \
05.predict/prodigal \
06.annotation \
07.abundcalc \
08.binning

cat /data2/wangjiaxuan/meta-dev/0.Info/samples.tsv | while read group sample fq1 fq2
    do
    ln -s ${fq1} 00.rawdata/${sample}.R1.fq.gz
    ln -s ${fq1} 00.rawdata/${sample}.R2.fq.gz
    echo ${sample} >> sample.list
    done

mkdir -p 01.fastq_qc/logs
mkdir -p 00.rawdata/logs
mkdir -p 02.rmhost/logs
mkdir -p 04.assembly/logs
mkdir -p 05.predict/logs
mkdir -p 06.annotation/logs
mkdir -p 07.abundcalc/logs
mkdir -p 08.binning/logs

cat sample.list | while read sample
do
seqkit stats \
--all \
--basename \
--tabular \
--fq-encoding sanger \
--out-file 00.rawdata/${sample}.raw_stats.tsv \
--threads 4 \
00.rawdata/${sample}.R1.fq.gz 00.rawdata/${sample}.R2.fq.gz \
2> 00.rawdata/logs/${sample}.raw.seqkit.log

fastp \
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
2> 01.fastq_qc/logs/${sample}.fastp.log

seqkit stats \
--all \
--basename \
--tabular \
--fq-encoding sanger \
--out-file 01.fastq_qc/${sample}_trimming_stats.tsv \
--threads 4 \
01.fastq_qc/${sample}.trimming.1.fq.gz 01.fastq_qc/${sample}.trimming.2.fq.gz \
2> 01.fastq_qc/logs/${sample}.seqkit.log
done
#-----------------------------------------------------

multiqc \
--outdir 01.fastq_qc \
--title fastp \
--module fastp \
01.fastq_qc/*.fastp.json \
2> 01.fastq_qc/logs/multiqc.fastp.log
#-------------
cat sample.list | while read sample
do
bowtie2 \
--threads 8 \
-x /data2/wangjiaxuan/refer/metapi_db/human_pangenomics/CHM13/bowtie2/chm13v2.0 \
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
-2 02.rmhost/${sample}.rmhost.2.fq.gz -
done

cat sample.list | while read sample
do
rm 01.fastq_qc/${sample}.trimming.[12].fq.gz

seqkit stats \
--all \
--basename \
--tabular \
--fq-encoding sanger \
--out-file 02.rmhost/${sample}_rmhost_stats.tsv.raw \
--threads 4 \
02.rmhost/${sample}.rmhost.1.fq.gz 02.rmhost/${sample}.rmhost.2.fq.gz \
2> 02.rmhost/logs/${sample}.seqkit.log

kraken2 \
--db /data3/wangjiaxuan/refer/kraken2_db/PlusPFP_20220908 \
--report 03.taxonomy/${sample}.taxa.tsv \
--use-mpa-style \
--use-name \
--thread 4 \
--paired 02.rmhost/${sample}.rmhost.1.fq.gz 02.rmhost/${sample}.rmhost.2.fq.gz \
> /dev/null

echo -e "#clade_name\treads" > 03.taxonomy/${sample}.finalouput
cat 03.taxonomy/${sample}.taxa.tsv >> 03.taxonomy/${sample}.finalouput
done

python util/merge_table.py 03.taxonomy/*.finalouput -c reads -o 03.taxonomy/taxonomy.txt --overwrite

cat sample.list | while read sample
do
    /tools/SPAdes/bin/metaspades.py \
        -1 02.rmhost/${sample}.rmhost.1.fq.gz \
        -2 02.rmhost/${sample}.rmhost.2.fq.gz \
        -k 21,33,55,77 \
        --memory 81 \
        --threads 8 \
        -o 04.assembly/${sample}_metaspades.out \
        > 04.assembly/logs/${sample}_metaspades.log

# REMOVE TEMP FILES
    files=(corrected misc pipeline_state tmp)

    for element in ${files[@]}
        do
        echo 04.assembly/${sample}_metaspades.out/${element}
        rm -rf 04.assembly/${sample}_metaspades.out/${element}
        done

    tar -czvf 04.assembly/${sample}_metaspades.out/metaspades.tar.gz 04.assembly/${sample}_metaspades.out/K*
    rm -rf 04.assembly/${sample}_metaspades.out/K*


    cat 04.assembly/${sample}_metaspades.out/scaffolds.fasta | \
    prodigal \
    -m \
    -a  05.predict/prodigal/${sample}_metaspades.faa \
    -d  05.predict/prodigal/${sample}_metaspades.ffn \
    -o  05.predict/prodigal/${sample}_metaspades.gff \
    -f gff \
    -p meta -q \
    2> 05.predict/logs/${sample}_metaspades.prodigal.log  
done



# 过滤长度小于300bp的orf

python util/filter_length.py

# 合并所有的样本的orf

cat 05.predict/prodigal/*300bp.fa > 05.predict/all.orf.300bp.fa
cp 05.predict/all.orf.300bp.fa 06.annotation/
# CD-hit去orf区域的冗余

cd-hit-est \
    -i 06.annotation/all.orf.300bp.fa \
    -o 06.annotation/all.orf.300bp.fa.95.90 \
    -c 0.95 -n 8 -M 10200 -aS 0.9 -T 20 -d 0 -G 0 -g 1 \
    1> 06.annotation/logs/cd-hit.log

# functional annotation by alignment to KEGG database

diamond blastx \
-p 10 \
-d /data3/wangjiaxuan/refer/anno_db/KEGG/KEGG_20200402_meta.dmnd \
-q 06.annotation/all.orf.300bp.fa.95.90 \
-e 1e-4 -k 1 \
--sensitive \
-o 06.annotation/all.orf.300bp.fa.95.90.kegg.annotation.out \
-f 6 qseqid sseqid stitle pident length qlen slen mismatch gapopen qstart qend sstart send evalue bitscore qcovhsp

# https://github.com/kblin/ncbi-genome-download,https://ftp.ncbi.nlm.nih.gov/genomes/refseq/,https://academic.oup.com/nar/article/44/D1/D73/2502704
# https://gtdb.ecogenomic.org/downloads
# python /data3/wangjiaxuan/refer/create_GTDBTk_db.py
# GCA and GCf https://www.ncbi.nlm.nih.gov/datasets/docs/v2/reference-docs/gca-and-gcf-explained/

# nohup /data/wangjiaxuan/biosoft/ncbi-blast-2.13.0+/bin/makeblastdb \
# -in /data3/wangjiaxuan/refer/GTDBTk_db_65703.sp.fa \
# -dbtype nucl \
# -title GTDBTk_db_65703.sp.fa \
# -parse_seqids \
# -out ./GTDBTk_db_65703.sp.bldb/GTDBTk_db_65703.sp.fa \
# -logfile make_GTDBTk_db_65703.sp.fa.log &


/data/wangjiaxuan/biosoft/ncbi-blast-2.13.0+/bin/blastn \
-query 06.annotation/all.orf.300bp.fa.95.90 \
-db /data3/wangjiaxuan/refer/GTDBTk_db_65703.sp.bldb/GTDBTk_db_65703.sp.fa \
-outfmt 6 \
-out 06.annotation/all.orf.300bp.6530set_cov0.8_id0.65.btab \
-max_target_seqs 10 -perc_identity 0.65 -qcov_hsp_perc 0.8 -evalue 0.01

cat sample.list | while read sample
do
    /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/bbmap.sh \
    ref=06.annotation/all.orf.300bp.fa.95.90 \
    in=02.rmhost/${sample}.rmhost.1.fq.gz \
    in2=02.rmhost/${sample}.rmhost.2.fq.gz \
    out=07.abundcalc/${sample}.bam \
    k=13 minid=0.90 t=20 nodisk=true rpkm=07.abundcalc/${sample}.rpkm
    
    samtools view -F 4 -h 07.abundcalc/${sample}.bam -o 07.abundcalc/${sample}.sam
    grep '^\@' 07.abundcalc/${sample}.sam > 07.abundcalc/${sample}_3M.sam
    grep -v '^\@' 07.abundcalc/${sample}.sam > 07.abundcalc/${sample}_noheader.sam
    shuf 07.abundcalc/${sample}_noheader.sam -n 3000000 >> 07.abundcalc/${sample}_3M.sam
    samtools view -bS 07.abundcalc/${sample}_3M.sam -o 07.abundcalc/${sample}_3M.bam
    samtools sort 07.abundcalc/${sample}_3M.bam -o 07.abundcalc/${sample}.sorted.bam -@ 10
    rm 07.abundcalc/${sample}*.sam ${sample}_3M.bam
    /data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/jgi_summarize_bam_contig_depths --outputDepth 07.abundcalc/${sample}.depth.txt 07.abundcalc/${sample}.sorted.bam

    echo -e "#contigName\tcontigLen\ttotalAvgDepth\tsorted.bam\tsorted.bam-var" > 07.abundcalc/${sample}_depth.finalouput
    cat 07.abundcalc/${sample}.depth.txt >> 07.abundcalc/${sample}_depth.finalouput
done

# merge orf depth 
python util/merge_table.py 07.abundcalc/*_depth.finalouput -c sorted.bam -o  07.abundcalc/all_sample_depth.txt --overwrite
# merge orf exp
python util/merge_table.py 07.abundcalc/*.rpkm -c FPKM -o 07.abundcalc/all_sample_GeneExp.txt --overwrite
# change the name
sed -i 's: #.*\=[0-9.]\+\t:\t:ig' 07.abundcalc/all_sample_GeneExp.txt

/data/wangjiaxuan/biosoft/miniconda3/bin/Rscript util/merge_exp_and_annot.r


