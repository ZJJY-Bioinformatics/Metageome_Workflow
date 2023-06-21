#!/bin/bash

mkdir -p shell

mv  work_qsub* shell
#---------------------------------

python /data3/Group7/wangjiaxuan/script/merge_table.py \
2.Humann2_Quantity/*_temp/*_bugs_list.tsv \
-c relative_abundance > 3.Result_Sum/all.sample_buglist.tsv

/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/kneaddata_read_count_table \
--input 1.Kneaddata_Clean \
--output 1.Kneaddata_Clean/kneaddata_qc_result.tsv

#
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/multiqc \
-d 1.Kneaddata_Clean/fastqc \
-o 1.Kneaddata_Clean/multiqc_result

#
/data3/Group7/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/humann_join_tables \
-i 2.Humann2_Quantity \
-o 3.Result_Sum/all.sample_genefamilies.tsv \
--file_name genefamilies

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
