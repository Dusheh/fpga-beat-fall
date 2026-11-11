module main(
// ******** Base ************
	input wire clk,    
	input wire replay, //key1
	input wire [3:0] buttons, //key2-key5
	
// ******** RGB Martix ***********
	output wire rgb_martix,

// ******** 4 LED ************
	output wire [3:0] progressLED,

// ******** Beeper ************
	output wire beepPwm,
	input  wire enable,
	
// ******** Digital LED ***********
	output wire [7:0]digitalLED,
	output wire [5:0]digitalSelect
	
// ********
	
);

//reg enable = 1;
wire [25:0]toneFreq;
wire [4:0]toneTime;
wire [7:0]bpm;
wire finish;

/*songData sD(
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
);*/

gameController controller(
.clk(clk),
.buttons(buttons), //KEY1-4
.rst_bt(replay), //KEY5
.enabled(enable),	  //SW10

//Digital
.digitalLED(digitalLED),
.digitalSelect(digitalSelect),

//LED
.LittleLED(progressLED),

//RGB Martix
.RGBMartix(rgb_martix),

//Beeper
.Beeper(beepPwm)
);


/*
rgbRenderer rgb(
.clk(clk),
.rst_n(rst_n),



.mt_in(rgb_martix)
);
*/

endmodule
