export PATH="/data/wangjiaxuan/biosoft/miniconda3/bin:$PATH" && source activate meta

multiqc \
--outdir 01.fastq_qc \
--title fastp \
--module fastp \
01.fastq_qc/*.fastp.json \
2> 01.fastq_qc/logs/multiqc.fastp.log

# 过滤长度小于300bp的orf

python util/filter_length.py

rm -rf 04.assembly/${sample}_metaspades.out
rm -rf 06.annotation/arg_metadata_*.tsv
# 合并所有的样本的orf

cat 05.predict/prodigal/*300bp.fa > 05.predict/all.orf.300bp.fa
cp 05.predict/all.orf.300bp.fa 06.annotation/
# CD-hit去orf区域的冗余

cd-hit-est \
    -i 06.annotation/all.orf.300bp.fa \
    -o 06.annotation/all.orf.300bp.fa.95.90 \
    -c 0.95 -n 8 -aS 0.9 -T 64 -d 0 -G 0 -g 1 \
    -M 100000 \
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

/data/wangjiaxuan/biosoft/ncbi-blast-2.13.0+/bin/blastn \
-query 06.annotation/all.orf.300bp.fa.95.90 \
-db /data3/wangjiaxuan/refer/GTDBTk_db_65703.sp.bldb/GTDBTk_db_65703.sp.fa \
-outfmt 6 \
-out 06.annotation/all.orf.300bp.6530set_cov0.8_id0.65.btab \
-max_target_seqs 10 -perc_identity 0.65 -qcov_hsp_perc 0.8 -evalue 0.01 