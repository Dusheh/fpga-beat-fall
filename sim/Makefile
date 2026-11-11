# 用 Icarus Verilog 仿真（brew install icarus-verilog）
IVERILOG ?= iverilog
VVP      ?= vvp
RTL      := ../src

.PHONY: all beep rgb clean

all: beep rgb

# 蜂鸣器驱动：统计输出电平宽度，< 1us 的电平段会被标成 RUNT
beep:
	@mkdir -p build
	$(IVERILOG) -g2012 -o build/tb_beep.vvp tb_beep.v $(RTL)/beep.v
	$(VVP) build/tb_beep.vvp

# WS2812 点阵驱动：写入测试图案后把比特流解码回来逐像素比对
rgb:
	@mkdir -p build
	$(IVERILOG) -g2012 -o build/tb_rgb.vvp tb_rgb.v $(RTL)/rgbRenderer.v
	$(VVP) build/tb_rgb.vvp

clean:
	rm -rf build
