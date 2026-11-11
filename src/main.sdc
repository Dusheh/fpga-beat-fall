# 50 MHz 板载晶振
create_clock -name clk -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]

# 异步输入（按键），不做时序分析
set_false_path -from [get_ports {replay}]
set_false_path -from [get_ports {enable}]
set_false_path -from [get_ports {buttons[*]}]
