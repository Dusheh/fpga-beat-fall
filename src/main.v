module main(
	input wire clk,    
	input wire replay, //key1
	input wire [3:0] buttons, //key2-key5
//	output reg rgb_martix,
//	output reg [3:0] progressLED,
	output wire beepPwm,
	input wire enable
);

//reg enable = 1;

wire [25:0]toneFreq;
wire [4:0]toneTime;
wire [7:0]bpm;
wire finish;

songData sD(
.clk 		(clk),
.enable	(enable),
.resetIdx(replay),
.tone		(toneFreq),
.toneTime(),
.bpm		(),
.finish	()
);

beep beep_u(
.clk		(clk),
.rst_n	(replay),
.en		(enable),
.FREQ_T	(toneFreq),
.pwm		(beepPwm)
);

endmodule