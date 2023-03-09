# ZJJY ZhouLab MetaGenome workflow

本流程有两个版本的流程，根据分析需求进行选择。

## 1.有参宏基因组流程

优点:
1. 速度稍快一些
2. 目前文章用的方法这种更多一些（认可度更高）
   
缺点:
1. 无法研究到数据中没有的菌，
2. 没法研究到数据库没有的功能注释(除KEGG,GO,Metacyc以外的数据库都不支持)
3. 无法做宏基因组binning，去得到单菌的基因组草图

[中文REAFME](ref_humman3_metagenome/README.md)

## 2. 无参组装宏基因组流程

优点:
1. 能注释到更多的菌和功能
2. 数据库可扩展，理论上支持所有功能数据库注释
3. 做宏基因组binning，去得到单菌的基因组草图
   
缺点:
1. 速度慢一点
2. 发文章时候可能要把代码附上，Method也要详细撰写分析过程和软件版本

[中文README](noref_assemble_metagenome/README.md)


## 安装

```
git clone 本仓库
```

## 运行

选择那个流程，就进入那个流程的目录下，根据README操作