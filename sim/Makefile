# 用 Icarus Verilog 仿真蜂鸣器驱动（brew install icarus-verilog）
IVERILOG ?= iverilog
VVP      ?= vvp

.PHONY: all beep clean

all: beep

beep:
	@mkdir -p build
	$(IVERILOG) -g2012 -o build/tb_beep.vvp tb_beep.v ../src/beep.v
	$(VVP) build/tb_beep.vvp

clean:
	rm -rf build
