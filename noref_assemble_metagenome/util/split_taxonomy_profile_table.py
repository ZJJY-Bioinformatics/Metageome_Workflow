#!/data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python

# 加载
import re
from collections import defaultdict
'''
这是为了将输入的总表，按照分类级别输出表格
'''
# 词典
taxonomy_level = [
    "domain",
    "superkingdom",
    "phylum",
    "class",
    "order",
    "family",
    "genus",
    "species",
    "strain",
]

taxonomy_dict = {
    "strain": r"t__(.*?)[\|\t]",
    "species": r"s__(.*?)[\|\t]",
    "genus": r"g__(.*?)[\|\t]",
    "family": r"f__(.*?)[\|\t]",
    "order": r"o__(.*?)[\|\t]",
    "class": r"c__(.*?)[\|\t]",
    "phylum": r"p__(.*?)[\|\t]",
    "superkingdom": r"k__(.*?)[\|\t]",
    "domain" : r"d__(.*?)[\|\t]",
}

level_dict = {
    "strain": "t",
    "species": "s",
    "genus": "g",
    "family": "f",
    "order": "o",
    "class": "c",
    "phylum": "p",
    "superkingdom": "k",
    "domain" : "d"
}

# 输入
taxonomy_table = open("03.taxonomy/all_sample_taxonomy_profile.xls","r")
# 输出
level_output_file = defaultdict(list)
level_output_header = dict()

for line in taxonomy_table:
    # 拆分分类和表达量
    taxonomy_info = line.split("\t")[0]
    exp_info = line.split("\t")[1:]
    taxonomy_name = []
    # header的输出
    if "clade_name" in line and "#" not in line:
        level_output_header['header'] = "\t".join(taxonomy_level)+"\t"+"\t".join(exp_info)
    elif "#" not in line:
        # 名字输出
        final_taxonomy_var = "unclassified"
        for lev in taxonomy_level:
            re_result = re.findall(taxonomy_dict[lev],line)
            if re_result:
                taxonomy_name.append(level_dict[lev]+"__"+re_result[0])
                final_taxonomy_var = lev
            else:
                taxonomy_name.append("unclassified")
        level_output_file['all'].append("\t".join(taxonomy_name)+"\t"+"\t".join(exp_info))
        level_output_file[final_taxonomy_var].append("\t".join(taxonomy_name)+"\t"+"\t".join(exp_info))

for lev in level_output_file:
    with open(f'03.taxonomy/all_sample_taxonomy_profile_{lev}.xls',"w") as f:
        f.write(level_output_header['header'])
        for line in level_output_file[lev]:
            f.write(line)
    f.close()
