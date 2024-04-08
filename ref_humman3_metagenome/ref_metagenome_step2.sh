#!/bin/bash

mkdir -p shell

mv  work_qsub* shell
#---------------------------------
# 输出相对丰度
python /data3/Group7/wangjiaxuan/script/merge_table_v2.py \
2.Humann2_Quantity/*_profiled_metagenome.txt \
-c 1 \
-o 3.Result_Sum/all.sample_buglist_rel.tsv \
--skip_rownumber 5 \
--colnames_replace _profiled_metagenome.txt \
--overwrite
# 输出绝对丰度
python /data3/Group7/wangjiaxuan/script/merge_table_v2.py \
2.Humann2_Quantity/*_profiled_metagenome.txt \
-c 3 \
-o 3.Result_Sum/all.sample_buglist.tsv \
--skip_rownumber 5 \
--colnames_replace _profiled_metagenome_count.txt \
--overwrite
# 输出质控
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/multiqc \
-d 1.Kneaddata_Clean/fastqc \
-o 1.Kneaddata_Clean/multiqc_result

# 汇总下humann的结果
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_join_tables \
-i 2.Humann2_Quantity \
-o 3.Result_Sum/all.sample_genefamilies.tsv \
--file_name genefamilies.tsv

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_join_tables \
-i 2.Humann2_Quantity \
-o 3.Result_Sum/all.sample_pathabundance.tsv \
--file_name pathabundance

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_join_tables \
-i 2.Humann2_Quantity \
-o 3.Result_Sum/all.sample_pathcoverage.tsv \
--file_name pathcoverage

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_join_tables \
-i 2.Humann2_Quantity \
-o 3.Result_Sum/all.sample_genefamilies_cpm.tsv \
--file_name genefamilies_cpm

#----------<end>----------------
#--------------<function>--------
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_rename_table \
--input 3.Result_Sum/all.sample_genefamilies.tsv \
--output 3.Result_Sum/all.sample_kegg-pathway.tsv \
--names kegg-pathway

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_rename_table \
--input 3.Result_Sum/all.sample_genefamilies_cpm.tsv \
--output 3.Result_Sum/all.sample_eggnog_cpms.tsv \
--names eggnog
#--------------<end>---------

# humann_rename_table \
# --input 3.Result_Sum/all.sample_genefamilies_cpm.tsv \
# --output 3.Result_Sum/all.sample_KO_cpms.tsv \
# --names kegg-pathway

# Go注释

# /data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_regroup_table \
# --input 3.Result_Sum/all.sample_genefamilies_cpm.tsv \
# --groups uniref90_go \
# --output 3.Result_Sum/all.sample_GO_cpms.tsv

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_rename_table \
--input 3.Result_Sum/all.sample_GO_cpms.tsv \
--output 3.Result_Sum/all.sample_GO_term_cpms.tsv \
--names go

# metacyc pathway

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_regroup_table \
--input 3.Result_Sum/all.sample_genefamilies_cpm.tsv \
--groups uniref90_rxn \
--output 3.Result_Sum/all.sample_metacyc_rxn_cpms.tsv

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_rename_table \
--input 3.Result_Sum/all.sample_metacyc_rxn_cpms.tsv \
--output 3.Result_Sum/all.sample_metacyc_cpms.tsv \
--names metacyc-rxn

# kegg 注释

# /data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_regroup_table \
# --input 3.Result_Sum/all.sample_genefamilies_cpm.tsv \
# --groups uniref90_ko \
# --output 3.Result_Sum/all.sample_KO_cpms.tsv

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_rename_table \
--input 3.Result_Sum/all.sample_KO_cpms.tsv \
--output 3.Result_Sum/all.sample_KEGG_pathway_cpms.tsv \
--names kegg-orthology

#=================================

mkdir  4.Out2CAMP

/data3/Group7/wangjiaxuan/biosoft/miniconda3/bin/Rscript \
/data3/Group7/wangjiaxuan/script/out2cmap.r


# ARGS
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/args_oap stage_one \
-i 1.Kneaddata_Clean/clean_data/ \
-o 4.Annot/ARG \
-f fastq \
-t 32 > 4.Annot/ARG/stage_one_log 2>&1 

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/args_oap stage_two \
-i 4.Annot/ARG/ \
-t 64 > 4.Annot/ARG/stage_two_log 2>&1

# Strainphlan
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/sample2markers.py \
-i 2.Humann2_Quantity/*.sam.bz2 -o 6.SNP -n 8

mkdir -p 6.SNP/target_markers_seq
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/extract_markers.py \
-c t__SGB10115 -o 6.SNP/target_markers_seq

mkdir -p 6.SNP/output
mkdir -p 6.SNP/tmp

strainphlan -s 6.SNP/marker_snp/*.pkl \
-m 6.SNP/target_markers_seq/t__SGB10115.fna \
-o 6.SNP/output \
-n 8 \
-c t__SGB10115 \
--mutation_rates

#-r reference_genomes/G000273725.fna.bz2

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/iqtree \
-s t__SGB10115.StrainPhlAn4_concatenated.aln \
-m TEST \
-bb 1000 \
-nt 2 \
-pre iqtree_output
