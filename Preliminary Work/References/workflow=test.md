# 功能与性能测试工作流总结

> 本文档总结 nscscc-team-la32r团体技术包所给的**func_test**, **perf_test**测试原理及步骤，
>
> （注：技术包中另外的FPGA_test为外围二极管、数码管、开关等gpio设备功能检查，和利用一个已成bit流的初级soc测试linux上板运行的soc检查，详见Loongson_run_linux）

---

## 1.功能测试（基于Loong官方给出的顺序difftest)

（difftest指对待测设计与基准参考模型验证状态比对）

参考资料：[《LoongArch CPU设计实验》](https://bookdown.org/loongson/_book3/)

该测试方案似乎是一堂完整实验课的直接挪用

- dc_env, minicpu_env, 对内部模块的测试必要性不大
- mycpu_env是主要的测试环境（面向**单周期处理器**）

  - **func**: 在inst文件夹之下有测试所需的81个测试样例，测试函数定义在include\inst_test.h之下
  - 需要配置LoongArch-GCC交叉编译工具（参考资料），测试代码将会被编译到func/obj路径下，此时应该得到了三个文件

  | **inst_ram.coe** | **重新定制inst ram所需的coe文件** |
  | ---------------------- | --------------------------------------- |
  | **inst_ram.mif** | **仿真时inst ram读取的mif文件**   |
  | **test.s**       | **对main.elf反汇编得到的文件**    |


  - 使用工具链中的objcopy工具，将main.elf文件中的.  text段提取出来生成二进制格式的纯数据文件main.bin，将  main.elf文件中的.data段提取出来生成二进制格式的纯数   据文件main.data
  - 将上述两个文件，每个二进制纯数据文件都生成一个.coe  后缀的文件和一个.mif后缀的文件，一会儿cpu将利用   block RAM IP核的加载功能，加载测试代码进行运行
  - **gettrace**: 用vivado打开工程gettrace.xpr，使用已写好的参考cpu进行仿真，得到参考运行结果golden_trace.txt
  - **myCPU**: 当前mycpu是在用错误代码占位，我们需要将自己的RTL代码更新在这里
  - **module_verify**: 对cache, div, mul, tlb的模块测试, 其中div, mul可能用IP核实现，cache, tlb单独开发
  - **soc_verify**: ***soc测试是功能测试的核心***。
  - 每一个测试文件夹下的soc_lite_top.v中将会对我们的mycpu实例化，需要满足以下端口需求：
  - | **名称**            | **宽度** | **方向**   | **描述**                            |
    | ------------------------- | -------------- | ---------------- | ----------------------------------------- |
    | **clk**             | **1**    | **input**  | **时钟信号，来自clk_pll的输出时钟** |
    | **resetn**          | **1**    | **input**  | **复位信号，低电平同步复位**        |
    | **inst_sram_we**    | **1**    | **output** | **RAM写使能信号，高电平有效**       |
    | **inst_sram_addr**  | **32**   | **output** | **RAM读写地址，字节寻址**           |
    | **inst_sram_wdata** | **32**   | **output** | **RAM写数据**                       |
    | **inst_sram_rdata** | **32**   | **input**  | **RAM读数据**                       |
    | **data_sram_we**    | **1**    | **output** | **RAM写使能信号，高电平有效**       |
    | **data_sram_addr**  | **32**   | **output** | **RAM读写地址，字节寻址**           |
    | **data_sram_wdata** | **32**   | **output** | **RAM写数据**                       |
    | **data_sram_rdata** | **32**   | **input**  | **RAM读数据**                       |
  - 其下分了四个测试：
    - dram:

      - 对应规模缩减版func的n1~n20
    - bram:

      - 20条指令五级流水CPU，不考虑hazard，测试插NOP的func的n1~n20，增量开发。

        20条指令五级流水CPU，cancel解决control hazard，阻塞解决data hazard，测试func的n1~n20，增量开发。

        20条指令五级流水CPU，forward优化data hazard处理，测试func的n1~n20，增量开发。

        增加用户态运算类指令，测试func的n1~n36，增量开发。

        增加用户态转移指令和除了ll.w、sc.w之外的用户态访存指令，测试func的n1~n46，增量开发。

        支持syscall例外，测试func的n1~n47，增量开发。

        支持更多例外，测试func的n1~n58，增量开发。
    - hs_bram:

      - CPU采用带握手机制的接口，测试func的n1~n58，增量开发
    - axi:

      - CPU采用AXI接口，外部固定延迟响应，测试func的n1~n58，增量开发。

        CPU采用AXI接口，外部随机延迟响应，测试func的n1~n58，增量开发。

        CPU集成TLB模块后并支持TLB相关指令和CSR，测试func的n1~n70，增量开发。

        CPU支持TLB MMU功能，测试func的n1~n72，增量开发。

        CPU实现指令Cache，测试func的n1~n72，增量开发。

        CPU实现数据Cache，测试func的n1~n72，增量开发。

        CPU支持CACOP指令，测试func的n1~n79，增量开发。


---

## 2.性能测试

性能测试说明.pdf中阐述较功能测试更加详细，可以直接参考。甚至有些步骤（如编译等）与功能测试有重合，该文档里的描述也可以作为参照

性能测试时不再有trace对比机制，文档建议可以考虑抓取gs132运行测试程序的写回信息，用$fdisplay构建我们自己的trace


# 严重问题：

功能测试的difftest机制对于我们的乱序执行极其不友好，若我们确实希望测功能，也许要考虑预留一个顺序执行转换flag......
