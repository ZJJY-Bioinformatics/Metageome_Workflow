#/bin/bash
/data/wangjiaxuan/biosoft/miniconda3/bin/python util/merge_table.py 03.taxonomy/*.finalouput -c reads -o 03.taxonomy/all_sample_taxonomy_profile.xls --overwrite 
sed -i "s/'//ig" 03.taxonomy/all_sample_taxonomy_profile.xls


# merge ARG table
#paste -d "\t" 06.annotation/ARG/*_outdir/*.final_out.rpkm.subtype.txt > 06.annotation/ARG/all_sample_ARG.rpkm.subtype.txt
/data/wangjiaxuan/biosoft/miniconda3/bin/python util/merge_table_v2.py 06.annotation/ARG/*_outdir/*.final_out.rpkm.subtype.txt -o  06.annotation/ARG/all_sample_ARG.rpkm.subtype.txt --overwrite --skip_rownumber  2 --colnames_replace .final_out.rpkm.subtype.txt -c 0
/data/wangjiaxuan/biosoft/miniconda3/bin/python util/merge_table_v2.py 06.annotation/ARG/*_outdir/*.final_out.rpkm.type.txt -o  06.annotation/ARG/all_sample_ARG.rpkm.type.txt --overwrite --skip_rownumber  1 --colnames_replace .final_out.rpkm.type.txt -c 0
# merge orf depth 
/data/wangjiaxuan/biosoft/miniconda3/bin/python util/merge_table.py 07.abundcalc/*_depth.finalouput -c sorted.bam -o  07.abundcalc/all_sample_depth.txt --overwrite
# merge orf exp
/data/wangjiaxuan/biosoft/miniconda3/bin/python util/merge_table.py 07.abundcalc/*.rpkm -c FPKM -o 07.abundcalc/all_sample_GeneExp.txt --overwrite
# change the name
sed -i 's: #.*\=[0-9.]\+\t:\t:ig' 07.abundcalc/all_sample_depth.txt
sed -i 's: #.*\=[0-9.]\+\t:\t:ig' 07.abundcalc/all_sample_GeneExp.txt

/data/wangjiaxuan/biosoft/miniconda3/bin/Rscript util/merge_exp_and_annot.r

/data/wangjiaxuan/biosoft/miniconda3/bin/python util/sum_result_out.py
/data/wangjiaxuan/biosoft/miniconda3/bin/python util/split_taxonomy_profile_table.py

# output ==========
mkdir -p 09.result
mkdir -p 09.result/1.QC

cp -r 00.rawdata/raw_fastp_stat.csv 09.result/1.QC
cp -r 01.fastq_qc/trimming_fastp_stat.csv 09.result/1.QC
cp -r 02.rmhost/mapping_host_stat.csv 09.result/1.QC
cp -r 02.rmhost/rmhost_fastp_stat.csv 09.result/1.QC

mkdir -p 09.result/2.taxonomy_profile
cp -r 03.taxonomy/all_sample_taxonomy_profile* 09.result/2.taxonomy_profile

mkdir -p 09.result/3.gene_profile
cp -r 07.abundcalc/all_gene_result_out.tsv 09.result/3.gene_profile
cp -r 07.abundcalc/all_sample_depth.txt 09.result/3.gene_profile

if [ -a qsub_run_main.sh ]; then rm qsub_run_main.sh ;fi
if [ -a sample.list ]; then rm sample.list ;fi

rm .R1.fq.gz .R2.fq.gz .RData