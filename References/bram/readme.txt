ip核：Block Memory Generator
选项：Memory type:
		Single Port RAM: 单端口 RAM，只有一个读写端口。
		Simple Dual Port RAM: 伪双口 RAM，一个端口专门用于写，另一个专门用于读。		
		True Dual Port RAM: 真双口 RAM，有两个完全独立的读写端口（Port A 和 Port B）。
	Port of A:  Width:位宽
			Depth: 存储的深度（容量即为Width*Depth）
			Operating Mode: 读写冲突时的行为。
					Write First: 当同一时钟周期、同一地址发生读写时，输出端口会输出新写入的数据。
					Read First: 输出端口会输出原始存储的数据，然后在下一个周期更新为新数据。
					No Change: 输出端口的数据保持不变（不确定时使用 Write First）。
			Enable Port Type: Always Enabled 表示端口始终使能。Use ENA Pin 会生成一个 ena 使能引脚，只有当 ena 为高时，端口才工作。
	Port of B: 与A一致。
	Other Options:  Load Init File: 如果希望 BRAM 在上电时就预装载一些数据,可以提供coe文件
				RSTA/RSTB Pin: 是否为端口 A/B 生成复位引脚。
实例化：复制veo文件即可