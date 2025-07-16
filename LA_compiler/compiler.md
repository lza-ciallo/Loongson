# LoongArch-GCC交叉编译工具使用概述

---

### 1.loongarch32r-linux-gnusf-gcc编译工具安装

基于wsl2, 根据 《[第 4 章 单周期CPU设计 | CPU设计实战：LoongArch版](https://bookdown.org/loongson/_book3/chapter-single-cycle-cpu.html#func%E5%8A%9F%E8%83%BD%E6%B5%8B%E8%AF%95%E7%A8%8B%E5%BA%8F)》4.2.3.3节安装。

【解释】

安装过程是

- 将工具包(以压缩包形式)下载并解压到linux系统(或wsl)的/opt/路径下
- 将LoongArch交叉编译工具链的路径添加到系统的PATH环境变量中

【注意！】

```
echo “export PATH=/opt/loongarch32r-linux-gnusf-*/bin/:$PATH” >> ~/.bashrc
```

> wsl为了增强与win系统之间的互动，会将win系统PATH环境变量、wsl系统自己的各种PATH也自动展开进来，造成终端配置文件 `~/.bashrc`除了交叉编译工具所需路径外，还引入了大串无关路径，且win系统PATH所支持的空格、括号等字符linux往往不支持，会导致编译环境配置失败。
>
> 目前采取的方法是手动打开 `~/.bashrc`进行删除。

---

### **2.运行逻辑**

> 以敲入 `make`为例，解释在当前wsl中 `make`指令/`Makefile`文件/`**.S`汇编代码之间的协作关系

```
WSL终端输入: make
    ↓
WSL的shell接收命令
    ↓
shell在PATH环境变量中(根据./~bash的配置)查找 "make" 可执行文件
    ↓
找到 GNU Make 4.3 (x86_64-pc-linux-gnu)
    ↓
在当前工作目录(/mnt/d/Users/yuanm/.../func)查找Makefile
    ↓
按优先级尝试打开文件:
  1. GNUmakefile (不存在)
  2. makefile (不存在) 
  3. Makefile (找到!)
    ↓
通过open()系统调用打开Makefile文件
    ↓
读取Makefile内容到内存
    ↓
词法分析: 识别变量、目标、命令等元素
    ↓
语法分析: 构建规则和依赖关系
    ↓
构建内部数据结构:
  - 目标列表
  - 依赖关系图
  - 变量表
  - 规则表
    ↓
按照规则执行
```


---

### 3.官方所给Makefile文件运行规则

### `default` (默认规则)

* **作用** : 当执行 `make` 时的默认行为
* **执行内容** :
* 调用 `make all` (编译所有文件)
* 调用 `make tidy` (清理临时文件)
* 显示EXP参数使用提示

### `all` (完整编译规则)

* **作用** : 编译整个项目
* **执行内容** :
* 创建 `./obj` 目录
* 生成 `inst_ram.coe` 和 `test.s` 文件

### `tidy` (清理规则)

* **作用** : 清理编译过程中的临时文件
* **清理内容** : convert、main.bin、main.data、main.elf、start.s/o、init.s/o
* **额外操作** : 调用 `inst` 目录下的清理

**完整的构建依赖：**

```
源文件(.S, .c)
    ↓
预处理(.s)
    ↓
目标文件(.o) + 库文件(.a)
    ↓
ELF文件(.elf)
    ↓
二进制文件(.bin, .data)
    ↓
FPGA内存文件(.coe, .mif)
```


---

### 4.自定义Makefile

> 根据已写*.s汇编文件，按照LoongArch32r的规则，生成.txt二进制机器码
