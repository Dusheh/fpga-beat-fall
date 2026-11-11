/*module tonePlayer(
	input		wire		clk,
	input 	wire		rst_n,
	input		wire 		en,
	input		wire	[25:0] FREQ_T,
	input		wire	[7:0]	 ZKB,
	output	wire		pwm
);

reg [25:0] cnt;

always@(posedge clk)
	if(!rst_n)
		cnt<=0;
	else if(en == 1) begin
		if(cnt == FREQ_T - 1)
			cnt <= 0;
		else cnt <= cnt + 1;
						end
	else cnt <= cnt;
	
assign pwm = (cnt <= FREQ_T * ZKB / 100) ? 1 : 0;

endmodule*/

//***************************

module tonePlayer(
	input		wire		clk,
	input 	wire		rst_n,
	input		wire 		isBeep,
	input		wire	[25:0] FREQ_T,
	output	wire		pwm
);

reg [25:0] cnt;

always@(posedge clk)
	if(!rst_n)
		cnt<=0;
	else if(isBeep == 1) begin
		if(cnt == FREQ_T - 1)
			cnt <= 0;
		else cnt <= cnt + 1;
						end
	else cnt <= cnt;
	
assign pwm = (cnt <= FREQ_T * 50 / 100) ? 1 : 0;

endmodule

