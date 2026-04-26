# 上市公司资本结构影响因素分析

> [作业要求](https://github.com/lianxhcn/dsfin/blob/main/homework/ex_P03_Panel-capital_strucuture.md)

---

## 个人信息
- **姓名**：黄文雅
- **邮箱**：huang_wong@qq.com

---

## 数据来源
- **数据库**：CSMAR（中国股票市场与会计研究数据库）  
- **下载时间**：2026-04-26  
- **最终样本**：4,357 家公司，38,385 个公司-年度观测值，时间范围为 2011–2025 年  

---

## 样本筛选过程
1. 初始样本（2010 – 2025 年全部 A 股）  
2. 剔除金融、保险行业（行业代码 J 开头）  
3. 剔除曾被 ST、*ST、PT 处理的全部公司‑年度  
4. 剔除资不抵债样本（Lev > 1）  
5. 剔除关键变量缺失的观测（Lev、NPR、Size、Tang、Growth、NDTS、SOE 等）  
6. 最终保留 2011 – 2025 年（因 Growth 需滞后一期，2010 年自动进入计算但不保留）  

---

## 使用工具
- **Stata 17.0**：面板数据回归、固定效应模型、交互项、时变系数、门槛效应等  
- **Python 3.10**：数据清洗、合并、变量构造、Winsorize、描述性统计图表  
- **Jupyter Notebook / VS Code**：交互编程环境  
- **nbstata**：在 Jupyter 中使用 Stata 内核  

---

## GitHub 仓库
[https://github.com/mia-Tomato](https://github.com/mia-Tomato)  

---

## Quarto Book（知识库）
[https://mia-Tomato.github.io/quarto_book/](https://mia-Tomato.github.io/quarto_book/)

---

## 主要发现（5 条）
1. **盈利能力（NPR）与杠杆率（Lev）在所有模型中均显著负相关**，为优序融资理论提供了稳健的经验支持。  
2. **国有企业显著减弱了盈利‑杠杆的负相关关系**，产权性质是资本结构决策的重要调节变量。  
3. **NPR‑Lev 关系在 2018 – 2019 年和 2023 – 2024 年出现显著时变**，与“去杠杆”政策及后疫情货币政策调整高度吻合。  
4. **大规模企业盈利对杠杆的影响更强**，规模异质性需要结合融资约束和企业生命周期理论加以解释。  
5. **控制宏观货币环境（IFE）后，盈利对杠杆的独立影响有所下降**，表明宏观变量是资本结构研究中不可忽视的遗漏变量。  

---

## 项目结构
```
ex03/                                    # 作业根目录
├── data_raw/                            # 原始 CSMAR 下载的 CSV 文件
├── data_clean/                          # 清洗合并后的分析数据 (analysis_data.csv)
├── output/
│   ├── figures/                         # 所有图表 (Fig1 – Fig7)
│   └── tables/                          # 回归结果表格 (csv / tex)
├── log/                                 # Stata 日志文件
├── 01_merge_clean.ipynb                 # Python 数据处理与变量构造
├── 02_descriptive_stats.ipynb           # Python 描述性统计与图表
├── panel_analysis.do                    # Stata 主分析脚本 (模型估计与输出)
├── quarto/                              # Quarto Book 项目目录
│   ├── _quarto.yml                      # 项目配置 (output-dir: docs)
│   ├── index.qmd                        # 前言
│   ├── 01-intro.qmd                     # 引言与假设
│   ├── 02-data.qmd                      # 数据与变量
│   ├── 03-results.qmd                  # 实证结果
│   ├── 04-robustness.qmd               # 稳健性检验
│   ├── 05-conclusion.qmd               # 结论与讨论
│   └── docs/                           # 渲染输出的 HTML 网站 (GitHub Pages 源)
├── README.md                           # 本文件
└── .gitignore                          # Git 忽略规则
```