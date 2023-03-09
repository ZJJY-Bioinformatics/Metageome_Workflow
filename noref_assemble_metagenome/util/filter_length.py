#!/data/wangjiaxuan/biosoft/miniconda3/envs/meta/bin/python

import os
import pysam
from pathlib import Path

for path in list(Path("05.predict/prodigal/").glob("*.ffn")):
    out_file = open(str(path).replace("ffn","300bp.fa"),"w")
    with pysam.FastxFile(str(path)) as fa:
        for seq in fa:
            if len(seq.sequence) >= 300:
                out_file.write(">"+ seq.name + " " + seq.comment + "\n" + seq.sequence + "\n")
out_file.close()