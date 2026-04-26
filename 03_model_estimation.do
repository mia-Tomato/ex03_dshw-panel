
ssc install ftools, replace

net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")


ssc install estout, replace
ssc install coefplot, replace
ssc install xthreg, replace   // 门槛回归，若失败先不管，我们后面提供替代方案

*==========================================================================
* 上市公司资本结构影响因素分析 —— 面板数据模型
* 数据：data_clean/analysis_data.csv
* 日期：2026-04-26
*==========================================================================

clear all
set more off
capture log close

* 设置工作路径（请确认路径正确）
cd "C:\Users\mia\Downloads\Finance\homework\ex03"

* 创建 log 文件夹（如果不存在）
capture mkdir log

* 打开日志文件
log using "log/panel_analysis.log", replace text

* 导入清洗好的数据
import delimited using "data_clean/analysis_data.csv", clear encoding("utf-8")

* 设定面板结构
xtset stkcd year, yearly

* 查看数据基本信息
describe
summarize lev npr size tang growth ndts soe m2_growth

* 生成缺失 m2_growth 的观测在回归中会自动忽略，不必担心

*--------------------------------------------------------------------------
* 模型 M1：双向固定效应基准模型（TWFE）
*--------------------------------------------------------------------------
reghdfe lev npr size tang growth ndts, absorb(stkcd year) vce(cluster stkcd year)
estimates store M1_TWFE

* 边际效应（可选）
margins, dydx(npr) post

*--------------------------------------------------------------------------
* 模型 M1 稳健性检验：交互固定效应（加入 SOE 交互和 m2_growth）
*--------------------------------------------------------------------------
reghdfe lev c.npr##i.soe size tang growth ndts m2_growth, absorb(stkcd year) vce(cluster stkcd year)
estimates store M1_IFE

*--------------------------------------------------------------------------
* 模型 M2：分组回归（国有企业 vs 民营企业）
*--------------------------------------------------------------------------
* 国有企业
reghdfe lev npr size tang growth ndts if soe == 1, absorb(stkcd year) vce(cluster stkcd year)
estimates store M2_SOE

* 民营企业
reghdfe lev npr size tang growth ndts if soe == 0, absorb(stkcd year) vce(cluster stkcd year)
estimates store M2_NonSOE

*--------------------------------------------------------------------------
* 模型 M3：交互项调节效应
*--------------------------------------------------------------------------
* M3 交互项调节效应 —— 用行业 FE 替代公司 FE
* 先生成行业虚拟变量（已存在 ind_sector）
encode ind_sector, gen(ind_fe)

reghdfe lev c.npr##i.soe size tang growth ndts, ///
    absorb(ind_fe year) vce(cluster stkcd)
estimates store M3_Interact

margins soe, at(npr=(-0.2(0.05)0.2))
marginsplot, title("SOE 对 NPR‑LEV 关系的调节效应") ///
    ytitle("线性预测 Lev") xtitle("NPR") ///
    legend(order(1 "民营企业" 2 "国有企业")) ///
    scheme(s2color) saving(output/figures/Fig4_SOE_margins, replace)
graph export "output/figures/Fig4_SOE_margins.png", replace width(1200)

*--------------------------------------------------------------------------
* 模型 M4：时变系数模型（β 随时间变化）
*--------------------------------------------------------------------------
* 生成年份虚拟变量与 npr 的交互项（以 2011 年为基期）
tab year, gen(yr_)
forvalues t = 2012/2025 {
    gen npr_yr`t' = npr * yr_`= `t'-2010'
}

* 回归（包含基期 npr）
reghdfe lev npr npr_yr* size tang growth ndts, absorb(stkcd year) vce(cluster stkcd year)
estimates store M4_TimeVarying

* 绘制系数图
coefplot, vertical keep(npr npr_yr*) ///
    coeflabels(npr = 2011 npr_yr2012 = 2012 npr_yr2013 = 2013 ///
               npr_yr2014 = 2014 npr_yr2015 = 2015 npr_yr2016 = 2016 ///
               npr_yr2017 = 2017 npr_yr2018 = 2018 npr_yr2019 = 2019 ///
               npr_yr2020 = 2020 npr_yr2021 = 2021 npr_yr2022 = 2022 ///
               npr_yr2023 = 2023 npr_yr2024 = 2024 npr_yr2025 = 2025) ///
    title("NPR 系数随时间变化 (基期 2011)") ///
    yline(0, lpattern(dash)) ///
    scheme(s2color) saving(output/figures/Fig5_beta_time, replace)
graph export "output/figures/Fig5_beta_time.png", replace width(1200)

* 清理临时变量
drop yr_* npr_yr*

*--------------------------------------------------------------------------
* 模型 M5：路径系数模型（NPR 系数随 Size 变化）
*--------------------------------------------------------------------------
*==========================================================================
* 模型 M5：规模异质性 —— 按 Size 中位数分组回归
*==========================================================================

* 清理可能存在的旧分组变量
cap drop size_group

* 生成中位数分组变量
quietly summarize size, detail
gen size_group = (size > r(p50))
label define sgroup 0 "小规模" 1 "大规模"
label values size_group sgroup

* 检查分组观测数（确保每组足够）
tab size_group

* 分组回归：小规模
reghdfe lev npr size tang growth ndts if size_group == 0, ///
    absorb(stkcd year) vce(cluster stkcd year)
estimates store M5_small

* 分组回归：大规模
reghdfe lev npr size tang growth ndts if size_group == 1, ///
    absorb(stkcd year) vce(cluster stkcd year)
estimates store M5_large

* 绘制 NPR 系数对比图
coefplot M5_small || M5_large, ///
    keep(npr) vertical ///
    coeflabels(npr = "NPR 系数") ///
    legend(order(1 "小规模" 2 "大规模")) ///
    title("不同规模下 NPR 对 Lev 的边际效应") ///
    yline(0, lpattern(dash)) ///
    scheme(s2color) saving(output/figures/Fig6_beta_size, replace)
graph export "output/figures/Fig6_beta_size.png", replace width(2400)


* 导出分组结果表格
esttab M5_small M5_large using "output/tables/M5_size_groups.csv", ///
    replace plain star keep(npr size tang growth ndts) ///
    order(npr) ///
    mtitles("小规模" "大规模") ///
    stats(r2_w N, fmt(%9.3f %9.0g))
	

	
*--------------------------------------------------------------------------
* 模型 M6：面板门槛回归（Size 作为门槛变量）
*--------------------------------------------------------------------------
* 需要安装 xthreg 命令，若之前安装失败，可用替代方案（见注释）
capture xthreg lev npr growth tang ndts, rx(size) qx(size) thnum(1) bs(300) trim(0.05) grid(100)
if _rc == 0 {
    estimates store M6_Threshold
    * 似然比统计量图会自动弹出，手动保存
    graph export "output/figures/Fig7_threshold_LR.png", replace width(1200)
}
else {
    * 替代方案：按 size 中位数分为大小两组，分别回归
    di "xthreg 未安装，采用分组回归替代"
    quietly summarize size, detail
    gen large = (size > r(p50))
    reghdfe lev npr size tang growth ndts if large == 0, absorb(stkcd year) vce(cluster stkcd year)
    est store M6_small
    reghdfe lev npr size tang growth ndts if large == 1, absorb(stkcd year) vce(cluster stkcd year)
    est store M6_large
    * 之后手动比较两组 npr 系数
}

*--------------------------------------------------------------------------
* 第四部分：结果汇总表
*--------------------------------------------------------------------------
*==========================================================================
* 回归结果汇总表（所有模型）
*==========================================================================
esttab M1_TWFE M1_IFE M2_SOE M2_NonSOE M3_Interact ///
    using "output/tables/reg_results.csv", ///
    replace plain star ///
    order(npr c.npr#1.soe 1.soe m2_growth size tang growth ndts) ///
    drop(_cons) ///
    stats(r2_w N, fmt(%9.3f %9.0g) labels("Within R²" "N")) ///
    mtitles("M1 TWFE" "M1 IFE" "M2 SOE" "M2 Non-SOE" "M3 Interact") ///
    nonotes addnotes("双向聚类标准误在公司-年度层面")

* 同时输出 latex 表格（可选）
esttab M1_TWFE M1_IFE M2_SOE M2_NonSOE M3_Interact ///
    using "output/tables/reg_results.tex", ///
    replace star(* 0.1 ** 0.05 *** 0.01) ///
    order(npr c.npr#1.soe 1.soe m2_growth size tang growth ndts) ///
    drop(_cons) ///
    stats(r2_w N, fmt(%9.3f %9.0g) labels("Within R²" "N")) ///
    mtitles("M1 TWFE" "M1 IFE" "M2 SOE" "M2 Non-SOE" "M3 Interact") ///
    nonotes addnotes("双向聚类标准误在公司-年度层面")

* M4 和 M5 的结果可以单独导出
esttab M4_TimeVarying using "output/tables/M4_results.csv", replace plain star
esttab M5_SizeInteraction using "output/tables/M5_results.csv", replace plain star

* 保存整个工作空间（可选）
save "data_clean/panel_analysis.dta", replace

log close
di "所有模型运行完毕，图表和表格已保存。"



*---------------------------------------------------
* 确保所有估计结果仍在内存中（如果重启了 Stata 可能需要重新跑模型）
* 然后运行：

* 查看所有估计的模型名
estimates dir

* 输出包含 npr 和 m2_growth 的汇总表（用 order，不会报错）
esttab M1_TWFE M1_IFE M2_SOE M2_NonSOE M3_Interact M5_small M5_large ///
    using "output/tables/key_coefficients.csv", ///
    replace plain star ///
    order(npr m2_growth) ///
    stats(N, fmt(%9.0g) labels("N")) ///
    mtitles("M1 TWFE" "M1 IFE" "M2 SOE" "M2 Non-SOE" "M3 Interact" "M5 Small" "M5 Large") ///
    nonotes

* 屏幕显示
esttab M1_TWFE M1_IFE M2_SOE M2_NonSOE M3_Interact M5_small M5_large ///
    , star(* 0.1 ** 0.05 *** 0.01) ///
    order(npr m2_growth) ///
    stats(N, fmt(%9.0g) labels("N")) ///
    mtitles("M1 TWFE" "M1 IFE" "M2 SOE" "M2 Non-SOE" "M3 Interact" "M5 Small" "M5 Large")
	
	
	
* 显示各模型关键系数
estimates replay M1_TWFE
estimates replay M1_IFE
estimates replay M2_SOE
estimates replay M2_NonSOE
estimates replay M3_Interact
estimates replay M5_small
estimates replay M5_large


esttab M1_TWFE M1_IFE M2_SOE M2_NonSOE M3_Interact M5_small M5_large, ///
    star(* 0.1 ** 0.05 *** 0.01) order(npr m2_growth) stats(N, fmt(%9.0g))