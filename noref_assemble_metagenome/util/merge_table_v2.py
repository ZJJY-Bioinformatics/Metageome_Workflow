import argparse
import os
import sys
import pandas as pd
from itertools import takewhile

#parameter----
# skip_rows = 2
# column_loc = 0
# colnames_replace = ".final_out.rpkm.subtype.txt"
# out_file = "test.xls"
#-----
def merge(infile_list,out_file,colnames_replace,skip_rows,column_loc = 0):

    profiles_list = []
    merged_tables = None

    for f in infile_list:
        #skip rows
        if skip_rows is None:
            headers = [x.strip() for x in takewhile(lambda x: x.startswith('#'), open(f))]
            skip_n = len(headers)
            names = headers[-1].split('#')[1].strip().split('\t')
        elif isinstance(skip_rows,int):
            skip_n = skip_rows
        #which column is
        iIn = pd.read_csv(f, sep='\t', skiprows=skip_n, skip_blank_lines=False,index_col=0)

        if isinstance(column_loc,str):
            column_loc_num = iIn.columns.tolist().index(column_loc)
        elif isinstance(column_loc, int):
            column_loc_num = column_loc

        #which column need to merge
        if not isinstance(column_loc_num,int):
            sys.exit("None column to merge")

        profiles_list.append(pd.Series(data=iIn.iloc[:,column_loc_num], index=iIn.index,
                                       name=os.path.basename(f).replace(colnames_replace, '')))

    merged_tables = pd.concat([merged_tables, pd.concat(profiles_list, axis=1).fillna(0)], axis=1).fillna(0)
    merged_tables.to_csv(out_file, sep='\t')

argp = argparse.ArgumentParser(prog="merge_metaphlan_tables.py",
                               description="Performs a table join on one or more metaphlan output files.")
argp.add_argument("aistms", metavar="input.txt", nargs="*", help="One or more tab-delimited text tables to join")
argp.add_argument("-l", help="Name of file containing the paths to the files to combine")
argp.add_argument("--column","-c", type=int,help="which column where be keep if the tabel have mutiple column")
argp.add_argument('-o', metavar="output.txt", help="Name of output file in which joined tables are saved")
argp.add_argument('--overwrite', default=False, action='store_true', help="Overwrite output file if exists")
argp.add_argument('--skip_rownumber', default=None,type=int, help="the skip number for rows")
argp.add_argument('--colnames_replace', default=None, help="the replace character for colnames")

argp.usage = (argp.format_usage() + "\nPlease make sure to supply file paths to the files to combine.\n\n" +
              "If combining 3 files (Table1.txt, Table2.txt, and Table3.txt) the call should be:\n" +
              "   ./merge_metaphlan_tables.py Table1.txt Table2.txt Table3.txt > output.txt\n\n" +
              "A wildcard to indicate all .txt files that start with Table can be used as follows:\n" +
              "    ./merge_metaphlan_tables.py Table*.txt > output.txt")

def main( ):
    args = argp.parse_args()

    if args.l:
        args.aistms = [x.strip().split()[0] for x in open(args.l)]

    if not args.aistms:
        print('no inputs to merge!')
        return

    if args.o and os.path.exists(args.o) and not args.overwrite:
        print('merge_metaphlan_tables: output file "{}" exists, specify the --overwrite param to ovrewrite it!'.format(args.o))
        return

    merge(args.aistms,
          open(args.o, 'w') if args.o else sys.stdout,
          args.colnames_replace,
          args.skip_rownumber,
          args.column)

if __name__ == '__main__':
    main()