# Loongson

目录

.
├── arch6=r1/                          # ✅ 当前正式架构 v1 by lza
│
├── core_v3.5 带cache架构/             # 🧩 V3.5原型核心（含Cache支持）
│
├── Old_World/                         # 🗃️ 历史开发原型集合
│   ├── Core_prototype/                # ├── 核心架构原型（多版本演进）
│   │   ├── arch0=Pipeline5_LoongArch_by_ymy&wyc/
│   │   ├── arch0=Pipeline5_MIPS32/
│   │   ├── arch1=乱序单发射原型机v1/
│   │   ├── arch2=3-2-3 多发射原型机v2/
│   │   ├── arch3=3-3-3 访存原型机v3/
│   │   ├── core_v3优化版本/
│   │   └── image/                    #   └── ALU相关文档/截图
│   │
│   ├── Module/                        # └── 模块原型合集
│   │   ├── module1=BranchPredictor_by_wyc/
│   │   └── module2=Cashe_by_wyc/
│   │ 
│   └── v1~v3开发日志_by_lza.md
│
├── utils/                             # 🔧 工具链 & 辅助资料
│   ├── LA_compiler/                   # ├── 编译器工具链
│   ├── LA32/                          # ├── LoongArch32r 指令集分析
│   ├── Loongson_run_linux/           # ├── Linux部署环境/启动脚本
│   ├── References/                    # ├── 规范文档与参考材料
│   └── workflow=test.md              # └── 工作流测试脚本
│
├── r1开发日志_by_lza.md               # 📝 架构R1设计日志
└── README.md                          # 📘 项目说明文档
