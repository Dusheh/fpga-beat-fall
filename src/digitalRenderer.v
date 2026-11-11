module digitalRenderer(
input		wire			clk,
input		wire			rst_n,
output 	wire	[5:0]	select,
output 	wire	[7:0]	digitalLED,
input		wire 	[24:0]numToRender
);

wire [3:0]	show_num_in;
wire [6:0]	show_num_out;
wire 			dp;

assign digitalLED = {dp,show_num_out};

sel_ctrl sel_ctrl_u(
.clk		(clk),
.rst_n	(rst_n),
.dp_seg	(6'b111111),
.sel		(select),
.dp		(dp),
.show_num_in	(numToRender),
.show_num_out	(show_num_in)
);

show show_u(
.show_num_in	(show_num_in),
.show_num_out	(show_num_out)
);

endmodule