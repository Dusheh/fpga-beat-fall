/*
module gameController(
input ? [3:0]button,
input ? 
);

int state = 0;

void updater()
{
	if(state == IDLE)
	{
		mainMenuLooper();
	}
	else if(state == ENTER_GAME)
	{
		int gameChoose = 0;
		
		state = LOAD;
	}
	else if(state == LOAD)
	{
		// find songData
		// set output to tonePlayer
		// other...
	}
	else if(state == PLAYING)
	{
		//update tones position in LED Martix
		
		//check the button to correct tone
		
		//if correct, add score
		
		//set progress LED;
		if(songData.idx>=25%)
			Progress.LED |= 4'b1000;
		if(songData.idx>=50%)
			Progress.LED |= 4'b0100;
		if(songData.idx>=75%)
			Progress.LED |= 4'b0010;
		if(songData.idx>=100%)
			Progress.LED |= 4'b0001;
			
		//end
		if(songData.finish) state = FINISHED;
	}
	else if(state == FINISHED)
	{
		// shine Play Score in digital LED
		// play some effect on LED Martix
		
		if(cnt == finish_animation_end) state = IDLE;
	}
} 



endmodule
*/

module gameController(
//Base
input wire clk,

//Buttons
input wire [3:0] buttons, //KEY1-4
input wire rst_bt, //KEY5
input wire enabled,	  //SW10

//Digital
output wire [7:0]digitalLED,
output wire [5:0]digitalSelect,

//LED
output reg [3:0] LittleLED,

//RGB Martix
output wire RGBMartix,

//Beeper
output Beeper
);

//State Machine
localparam IDLE = 0;
localparam ENTER_GAME = 1;
localparam LOAD = 2;
localparam PLAYING = 3;
localparam FINISHED = 4;
reg [2:0] STATE = IDLE;

// ===== 内部上电复位：配置完成后保持约 1.3ms 复位 =====
// 释放后 KEY5(rst_bt) 不再参与复位，可作普通按键使用
reg [15:0] porCnt = 16'd0;
wire por_rst_n = (&porCnt);

always@(posedge clk) begin
	if(!por_rst_n)
		porCnt <= porCnt + 1'b1;
end

//SongData Var
reg resetIdx;
reg nextFlag;
wire [25:0]tone;
wire [4:0]toneTime;
wire [31:0]toneCnt;
wire [7:0]bpm;
wire finish;

//Beeper Var
reg beeperEnable = 0;
reg [31:0]cnt = 0;

songDataQT sDG(
.clk		(clk),
.resetIdx(resetIdx),
.nextFlag(nextFlag),
.tone		(tone),
.toneTime(toneTime),
.toneCnt	(toneCnt),
.bpm		(bpm),
.finish	(finish)
);

beep beeper(
.clk(clk),
.rst_n(por_rst_n), 
.en(beeperEnable),
.FREQ_T(tone),
.pwm(Beeper)
);

//rgbRenderer
reg [2:0]x;
reg [2:0]y;
reg [23:0] pixelToWrite;
reg write_flag;

rgbRenderer rR(
.clk(clk),
.rst_n(por_rst_n),
.x(x),
.y(y),
.pixelToWrite(pixelToWrite),
.write_flag(write_flag),
.mt_in(RGBMartix)
);

//Digital LED
reg [23:0] digitalNum;
digitalRenderer dR(
.clk			(clk),
.rst_n		(por_rst_n),
.select		(digitalSelect),
.digitalLED	(digitalLED),
.numToRender(digitalNum)
);

// Menu Var - 使用 BCD 数字直接计数，避免 32 位除法器
reg [3:0] chooseOnes = 4'd1;  // 个位 0~9
reg [3:0] chooseTens = 4'd0;  // 十位 0~9
reg animationCompleted = 0;
localparam SKIP_ANIM = 1'b1;

reg [3*5:0]aniX,aniY;
reg [3*5:0]brightness;

// Button Var - 1ms 采样 + 连续 5 次一致才认（每键独立，低电平有效）
reg [15:0] msDiv;
reg        msTick;
reg [3:0]  keyStable;   // 1=松开，0=按下
reg [3:0]  keyStableD;
reg [2:0]  keySame0, keySame1, keySame2, keySame3;
wire [3:0] key_press = ~keyStable & keyStableD; // 按下那一拍

// Loading Animation
 //Random
 reg [7:0] rnd;

 wire fb = rnd[7]^rnd[5]^rnd[4]^rnd[3];
 
 always @(posedge clk) begin 
	if (!por_rst_n) rnd <= 8 'hA5 ; // 种子不能为0
	else rnd <= {rnd[6:0], fb};

 end

always@(posedge clk) begin
	if(!por_rst_n) begin
		msDiv  <= 16'd0;
		msTick <= 1'b0;
	end else if(msDiv == 16'd49_999) begin
		msDiv  <= 16'd0;
		msTick <= 1'b1;
	end else begin
		msDiv  <= msDiv + 1'b1;
		msTick <= 1'b0;
	end
end

// 消抖
always@(posedge clk) begin
	if(!por_rst_n) begin
		keyStable  <= 4'b1111;
		keyStableD <= 4'b1111;
		keySame0   <= 3'd0;
		keySame1   <= 3'd0;
		keySame2   <= 3'd0;
		keySame3   <= 3'd0;
		end 
	else begin
		keyStableD <= keyStable;
		if(msTick) begin
			if(buttons[0] != keyStable[0]) begin
				if(keySame0 == 3'd4) begin 
					keyStable[0] <= buttons[0];
					keySame0 <= 3'd0; 
				end
				else keySame0 <= keySame0 + 1'b1;
				end 
			else keySame0 <= 3'd0;

			if(buttons[1] != keyStable[1]) begin
				if(keySame1 == 3'd4) begin
					keyStable[1] <= buttons[1];
					keySame1 <= 3'd0; 
				end
				else keySame1 <= keySame1 + 1'b1;
			end 
			else keySame1 <= 3'd0;

			if(buttons[2] != keyStable[2]) begin
				if(keySame2 == 3'd4) begin
					keyStable[2] <= buttons[2];
					keySame2 <= 3'd0;
					end
				else keySame2 <= keySame2 + 1'b1;
				end 
			else keySame2 <= 3'd0;

			if(buttons[3] != keyStable[3]) begin
				if(keySame3 == 3'd4) begin 
					keyStable[3] <= buttons[3];
					keySame3 <= 3'd0; 
					end
				else keySame3 <= keySame3 + 1'b1;
				end
			else keySame3 <= 3'd0;
		end
	end
end

always@(posedge clk) begin
	if(!por_rst_n) begin
		STATE      <= IDLE;
		chooseOnes <= 4'd1;
		chooseTens <= 4'd0;
		digitalNum <= 24'd0;
		beeperEnable<=0;
		resetIdx	  <=1;
		x<=0;
		y<=0;
		aniX={
			rnd[2:0]/rnd[5:3]*rnd[7:6],
			rnd[2:0]*rnd[5:3]/rnd[7:6],
			rnd[5:3]/rnd[2:0]*rnd[7:6],
			rnd[5:3]*rnd[2:0]/rnd[7:6],
			rnd[2:0]/rnd[4:3]*rnd[7:5],
			rnd[2:0]*rnd[4:3]/rnd[7:5],
			};
		aniY={
			rnd[2:0]/rnd[5:3]*rnd[7:6],
			rnd[2:0]*rnd[5:3]/rnd[7:6],
			rnd[2:0]/rnd[4:3]*rnd[7:5],
			rnd[2:0]*rnd[4:3]/rnd[7:5],
			rnd[5:3]/rnd[2:0]*rnd[7:6],
			rnd[5:3]*rnd[2:0]/rnd[7:6],
			};
		brightness={
			rnd[2:0]/rnd[5:3]*rnd[7:6],
			rnd[2:0]*rnd[5:3]/rnd[7:6],
			rnd[5:3]/rnd[2:0]*rnd[7:6],
			rnd[5:3]*rnd[2:0]/rnd[7:6],
			rnd[2:0]/rnd[4:3]*rnd[7:5],
			rnd[2:0]*rnd[4:3]/rnd[7:5],
			};
	end
	else begin
		case(STATE)
		IDLE:begin
			if(key_press[1])begin
				// BCD 递减，到 00 为止
				if(chooseOnes == 4'd0) begin
					if(chooseTens != 4'd0) begin
						chooseOnes <= 4'd9;
						chooseTens <= chooseTens - 1'b1;
					end
				end else begin
					chooseOnes <= chooseOnes - 1'b1;
				end
			end
			else if(key_press[3])begin
				// BCD 递增，到 99 为止
				if(chooseOnes == 4'd9) begin
					if(chooseTens != 4'd9) begin
						chooseOnes <= 4'd0;
						chooseTens <= chooseTens + 1'b1;
					end
				end else begin
					chooseOnes <= chooseOnes + 1'b1;
				end
			end
			else if(key_press[2]) begin
				STATE <= ENTER_GAME;
			end
			
			// Digital LED - 直接输出 BCD 数字，无需除法
			digitalNum <= 24'h000;
			digitalNum[3:0] <= chooseOnes;
			digitalNum[7:4] <= chooseTens;
			
			//RGB Martix Animation
			
			/*x            <= 3'd1;
			y            <= 3'd2;
			pixelToWrite <= 24'h0F0F0F;
			write_flag   <= ~write_flag;*/
			//aniX[2:0]  <= aniX[2:0]   + rnd[0] - 1 + rnd[0] + 1;//x0
			//aniX[5:3]  <= aniX[5:3]   + rnd[1] - 1 + rnd[1] + 1;//x1
			//aniX[8:6]  <= aniX[8:6]   + rnd[2] - 1 + rnd[2] + 1;//x2
			//aniX[11:9] <= aniX[11:9]  + rnd[3] - 1 + rnd[3] + 1;//x3
			//aniX[14:12]<= aniX[14:12] + rnd[4] - 1 + rnd[4] + 1;//x4
			//aniX[17:15]<= aniX[17:15] + rnd[5] - 1 + rnd[5] + 1;//x5
			
		end
		ENTER_GAME:begin
			//Play enter animation
			if(animationCompleted || SKIP_ANIM) begin
				STATE <= LOAD;
			end
			else begin
				
			end
		end
		LOAD:begin
			//Set song data and initialize
			//STATE <= PLAYING;
			digitalNum = 0;
			if(resetIdx)
				resetIdx<=0;
			else begin
				STATE <= PLAYING;
				resetIdx<=1;
			end
		end
		PLAYING:begin
			if(finish) STATE<=FINISHED;
			if(cnt==0) begin //刚清零过，也就是下一个音符
				nextFlag<=0;
			end
			LittleLED[0]<=4'b0000;
			beeperEnable<=1;
			cnt<=cnt+1'b1;
			if(toneCnt==0) begin beeperEnable <= 0; cnt <= 0; nextFlag<=1; end
			else if(cnt>=toneCnt-1) begin
				nextFlag<=1;
				cnt<=0;
			end
			
			STATE <= STATE;
		end
		FINISHED:begin
			STATE <= IDLE;
		end
		default:begin
			STATE <= IDLE;
		end
		endcase
	end
end

initial begin

end

endmodule

