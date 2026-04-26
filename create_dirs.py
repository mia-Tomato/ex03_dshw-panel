import os

# 项目根目录（请确认路径与你的一致）
root = r"C:\Users\mingar\Downloads\Finance\homework\ex03"

# 定义需要创建的所有子目录
subdirs = [
    "data_raw",                # 存放从CSMAR下载的原始CSV文件
    "data_clean",              # 存放清洗合并后的分析用数据
    "output/figures",          # 存放所有图形
    "output/tables",           # 存放回归结果表格（可选）
    "log",                     # 存放日志文件
    "notebooks",               # 存放分析用的 .ipynb（可选，你也可以直接在根目录写）
]

# 批量创建目录
for sub in subdirs:
    path = os.path.join(root, sub)
    os.makedirs(path, exist_ok=True)
    print(f"已创建: {path}")

print("✅ 目录结构创建完毕")