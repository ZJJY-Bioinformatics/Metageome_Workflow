mkdir -p 5.HostGene_EXP

if [ -e 5.HostGene_EXP/hostrna_input.tsv ]; then rm 5.HostGene_EXP/hostrna_input.tsv;fi

cat samples.tsv | while read group sample fq1 fq2
do
  fq1=$(realpath 1.Kneaddata_Clean/${sample}*_contam_1.fastq)
  fq2=$(realpath 1.Kneaddata_Clean/${sample}*_contam_2.fastq)
  echo -e "${group}\t${sample}\t${fq1}\t${fq2}" >> 5.HostGene_EXP/hostrna_input.tsv
done

cd  5.HostGene_EXP

cp /data/wangjiaxuan/workflow/bulk-rna-seq/WDL/input.RNAseq.json ./

/data/wangjiaxuan/workflow/bulk-rna-seq/run_RNAseq -i input.RNAseq.json
