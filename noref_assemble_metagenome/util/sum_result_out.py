#!/data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python

#-----------------------------
# 合并samtools的统计结果

# function

import os
import os
import re
import pandas as pd
import concurrent.futures
from decimal import *
import concurrent.futures
from pathlib import Path

def flagstats_summary(flagstats, method = 2, **kwargs):
    """
    get alignment rate from sorted bam file
    samtools flagstat --threads 8 sample.sort.bam
    """
    mapping_info = []
    getcontext().prec = 8

    # with open(flagstat_list, 'r') as list_handle:
    if method == 1:
        list_handle = open(flagstats, "r")
    if method == 2:
        list_handle = flagstats

    for flagstat_file in list_handle:
        if os.path.exists(flagstat_file.strip()):
            info = {}
            info["sample_id"] = os.path.basename(flagstat_file.strip()).split(".")[0]
            stat_list = open(flagstat_file.strip(), "r").readlines()

            info["total_num"] = stat_list[0].split(" ")[0]

            if len(stat_list) == 13:
                info["read_1_num"] = stat_list[6].split(" ")[0]
                info["read_2_num"] = stat_list[7].split(" ")[0]

                mapped = re.split(r"\(|\s+", stat_list[4])
                info["mapped_num"] = mapped[0]
                info["mapped_rate"] = Decimal(mapped[5].rstrip("%")) / Decimal(100)
            
                #primary_mapped = re.split(r"\(|\s+", stat_list[5])
                #info["primary_mapped_num"] = primary_mapped[0]
                #info["primary_mapped_rate"] = Decimal(primary_mapped[6].rstrip("%")) / Decimal(100)

            elif len(stat_list) == 16:
                info["read_1_num"] = stat_list[9].split(" ")[0]
                info["read_2_num"] = stat_list[10].split(" ")[0]

                mapped = re.split(r"\(|\s+", stat_list[6])
                info["mapped_num"] = mapped[0]
                info["mapped_rate"] = Decimal(mapped[5].rstrip("%")) / Decimal(100)
            
                primary_mapped = re.split(r"\(|\s+", stat_list[7])
                info["primary_mapped_num"] = primary_mapped[0]
                info["primary_mapped_rate"] = Decimal(primary_mapped[6].rstrip("%")) / Decimal(100)
 
            paired = re.split(r"\(|\s+", stat_list[-5])
            info["paired_num"] = paired[0]
            paired_rate = paired[6].rstrip("%")
            if paired_rate != "N/A":
                info["paired_rate"] = Decimal(paired_rate) / Decimal(100)
                info["mapping_type"] = "paired-end"
            else:
                info["paired_rate"] = paired_rate
                info["mapping_type"] = "single-end"

            singletons = re.split(r"\(|\s+", stat_list[-3])
            info["singletons_num"] = singletons[0]
            singletons_rate = singletons[5].rstrip("%")
            if singletons_rate != "N/A":
                info["singletons_rate"] = Decimal(singletons_rate) / Decimal(100)
            else:
                info["singletons_rate"] = singletons_rate

            info["mate_mapped_num"] = re.split(r"\(|\s+", stat_list[-2])[0]
            info["mate_mapped_num_mapQge5"] = re.split(r"\(|\s+", stat_list[-1])[0]
            mapping_info.append(info)

    mapping_info_df = pd.DataFrame(mapping_info)
    if "output" in kwargs:
        mapping_info_df.to_csv(kwargs["output"], sep="\t", index=False)
    return mapping_info_df

in_file_list = [str(x) for x in list(Path("02.rmhost").glob("*.align2host.flagstat"))]

sum_flagstat= flagstats_summary(in_file_list)

sum_flagstat.to_csv("02.rmhost/mapping_host_stat.csv")

# 统计fastp的质控结果
trim_fastp_stat = open("01.fastq_qc/fastq_trim_stats.txt","w")
with open("01.fastq_qc/fastp_multiqc_report_data/multiqc_general_stats.txt","r") as f:
    i = 1
    for line in f:
        if i == 1:
            l = line.replace("fastp_mqc-generalstats-fastp-","").title()
        else:
            l = line
        trim_fastp_stat.write(l)
        i += 1
trim_fastp_stat.close()


# 合并fastp的输出
# function

def parse(stats_file,sep = "\t"):
    if os.path.exists(stats_file):
        try:
            df = pd.read_csv(stats_file, sep = sep)
        except pd.errors.EmptyDataError:
            print("%s is empty, please check" % stats_file)
            return None

        if not df.empty:
            return df
        else:
            return None
    else:
        print("%s is not exists" % stats_file)
        return None


def merge(input_list, func, workers = 4, **kwargs):
    df_list = []
    with concurrent.futures.ProcessPoolExecutor(max_workers=workers) as executor:
        for df in executor.map(func, input_list):
            if df is not None:
                df_list.append(df)

    df_ = pd.concat(df_list)

    if "output" in kwargs:
        df_.to_csv(kwargs["output"], sep="\t", index=False)
    return df_

# 00.rawdata
fastp_file_list = [x for x in list(Path("00.rawdata/").glob("*raw_stats.tsv"))]
fastp_stat = merge(fastp_file_list,parse,8)
fastp_stat.to_csv("00.rawdata//raw_fastp_stat.csv")

# 01.fastq_qc
fastp_file_list = [x for x in list(Path("01.fastq_qc/").glob("*_trimming_stats.tsv"))]
fastp_stat = merge(fastp_file_list,parse,8)
fastp_stat.to_csv("01.fastq_qc//trimming_fastp_stat.csv")

# 02.rmhost
fastp_file_list = [x for x in list(Path("02.rmhost/").glob("*_rmhost_stats.tsv.raw"))]
fastp_stat = merge(fastp_file_list,parse,8)
fastp_stat.to_csv("02.rmhost/rmhost_fastp_stat.csv")
