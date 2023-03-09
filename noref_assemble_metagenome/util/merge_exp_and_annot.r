require(tidyverse)

blast_out = read_tsv("06.annotation/all.orf.300bp.6530set_cov0.8_id0.65.btab",col_names = F)


colnames(blast_out) = c("Queryid", "Subjectid", "identity", "alignment_length", "mismatches", "gap", "q.start", "q.end", "s.start", "s.end", "e-value", "bit score")

blast_out %>% 
    separate(Subjectid, into = c("sp","ncbi_id"), sep = "~") %>%
    group_by(Queryid) %>%
    slice_min(order_by = `e-value`, n = 1)  %>% 
    slice_max(order_by = `bit score`, n = 1)  %>%
    slice_max(order_by = `alignment_length`, n = 1)  %>%
    slice_head(n = 1) %>%
    select(Queryid, sp) -> blast_out_s1

# tax table
taxonomy_data = read_tsv("/data3/wangjiaxuan/refer/metapi_db/GTDBTk_db/release207_v2/taxonomy/gtdb_taxonomy_GCF_only.tsv",col_names = F)
colnames(taxonomy_data) = c("sp","taxonomy")
kegg_out = read_tsv("06.annotation/all.orf.300bp.fa.95.90.kegg.annotation.out",col_names =  F)

kegg_out %>% 
    select(X1,X3) %>%
    separate(X3,into = c("kegg","genbank"),sep = "\\|\\ \\(GenBank\\)\\ ") %>%
    mutate(KO = str_extract(kegg, "(?<= )(K\\d+)(?=\\ )")) %>%
    select(X1,KO,genbank) -> kegg_out_s1

exp_data = read_tsv("07.abundcalc/all_sample_GeneExp.txt",col_names = T,comment = "#")

# merger the kegg
tax_merge_data1 = left_join(exp_data, kegg_out_s1, by = c("Name" = "X1"))
# merge the spiece info
tax_merge_data2 = left_join(tax_merge_data1,blast_out_s1,c("Name" = "Queryid"))
# merge the taxonomy
tax_merge_data3 = left_join(tax_merge_data2,taxonomy_data,c("sp" = "sp"))

write_tsv(tax_merge_data3 ,"07.abundcalc/all_gene_result_out.tsv")
