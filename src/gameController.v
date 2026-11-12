/*
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
*/

module gameController(
//Base
input wire clk,

//Switch
input wire enabled,	  		//SW10

//Buttons
input wire [3:0] buttons, 	//KEY1-4
input wire rst_bt, 			//KEY5

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
localparam INIT = 5;
localparam PAUSED = 6;
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

reg[3:0] songSelecter = 0;

songSource sDG(
.clk		(clk),
.resetIdx(resetIdx),
.nextFlag(nextFlag),
.songSel(songSelecter),
.tone		(tone),
.toneTime(toneTime),
.toneCnt	(toneCnt),
.bpm		(bpm),
.finish	(finish),
.songIdx (songIdx),
.songLength(songLength)
);

//Beeper Var
reg beeperEnable = 0;
reg [31:0]cnt = 0;

beep beeper(
.clk(clk),
.rst_n(por_rst_n), 
.en(beeperEnable),
.FREQ_T(playTone),
.pwm(Beeper)
);

//rgbRenderer
reg [2:0]x;
reg [2:0]y;
reg [23:0] pixelToWrite;
reg write_flag;
reg clear_flag;

rgbRenderer rR(
.clk(clk),
.rst_n(por_rst_n),
.x(x),
.y(y),
.pixelToWrite(pixelToWrite),
.write_flag(write_flag),
.clear_flag(clear_flag),
.animEn(STATE==IDLE || STATE==ENTER_GAME || STATE==LOAD),
.mt_in(RGBMartix),
.lightCell(lightCell),
.lightCellEn(STATE==PLAYING),
.flashEn(flashEn),
.flashCol(flashCol)
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
reg [3:0] chooseOnes = 4'd0;  // 个位 0~9
reg [3:0] chooseTens = 4'd0;  // 十位 0~9
reg animationCompleted = 0;
localparam SKIP_ANIM = 1'b1;

reg [3*8-1:0]aniX,aniY;
reg [3*8-1:0]brightness;
reg [3:0]    animStep;   // 进场动画步数：0~7 上升，8~15 下降
integer      ai;          // 进场动画 8 点循环变量

// Button Var - 1ms 采样 + 连续 5 次一致才认（每键独立，低电平有效）
reg [15:0] msDiv;
reg        msTick;
reg [3:0]  keyStable;   // 1=松开，0=按下
reg [3:0]  keyStableD;
reg [2:0]  keySame0, keySame1, keySame2, keySame3;
wire [3:0] key_press = ~keyStable & keyStableD; // 按下那一拍

// Game Var
wire [9:0]  songIdx;
wire [9:0]  songLength;

 //下面这几个都不是给外部用的变量
 reg [25:0] lookTones[15:0];
 reg [31:0] lookTimes[15:0]; // 这个应该获取toneCnt
 reg [31:0] lookTimesD[15:0];// 显示指针专用副本（写口和lookTimes相同）
 reg [2:0]  lookCols[15:0];  // 显示用：{是否非休止, 音高低2位}，单独存一份，避免第二个读口
 reg [4:0]  lookIdx;
 reg [3:0]  playIdx;

// ===== 判定参数（50MHz）=====
localparam [31:0] WIN_GOOD = 32'd6_000_000;   // ±120ms 判定窗口

reg  [2:0]  curCol, nextCol;   // 当前/下一个音符 {是否非休止, 列号}
reg         hitCur, hitNext;   // 对应音符是否已判定
reg  [23:0] scoreBCD;          // 6 位 BCD 分数，避免除法器

// ===== 延音连击：判定成功后，紧邻的同列音符自动成功 =====
reg  [1:0]  holdCol;           // 当前连击所在的列
reg         holdChain;         // 连击链是否有效
wire [2:0]  colNow   = lookCols[playIdx];
wire [2:0]  colNextW = lookCols[playIdx + 4'd1];
wire        autoHit  = holdChain && colNow[2] && (colNow[1:0] == holdCol);

// ===== 按键底线红色反馈：按下后底线对应列亮红 100ms =====
reg  [1:0]  flashCol;
reg  [24:0] flashCnt;
wire        flashEn = (flashCnt != 25'd0);

// ===== 结束结算 =====
reg  [31:0] endDelay;   // 最后一块落底后的等待
reg  [31:0] finCnt;     // 结算画面停留计时
// 满分（歌曲音符数）转 3 位 BCD
wire [9:0]  q10      = songLength / 10'd10;
wire [9:0]  r10      = songLength - q10 * 10;
wire [9:0]  q100     = q10 / 10'd10;
wire [9:0]  r100     = q10 - q100 * 10;
wire [11:0] totalBCD = {2'b0, q100[3:0], r100[3:0], r10[3:0]};

// BCD 自增（逐位进位，纯组合逻辑）
function [23:0] bcd_inc;
	input [23:0] v;
	begin
		bcd_inc = v;
		if (bcd_inc[3:0] != 4'd9) bcd_inc[3:0] = bcd_inc[3:0] + 4'd1;
		else begin
			bcd_inc[3:0] = 4'd0;
			if (bcd_inc[7:4] != 4'd9) bcd_inc[7:4] = bcd_inc[7:4] + 4'd1;
			else begin
				bcd_inc[7:4] = 4'd0;
				if (bcd_inc[11:8] != 4'd9) bcd_inc[11:8] = bcd_inc[11:8] + 4'd1;
				else begin
					bcd_inc[11:8] = 4'd0;
					if (bcd_inc[15:12] != 4'd9) bcd_inc[15:12] = bcd_inc[15:12] + 4'd1;
					else begin
						bcd_inc[15:12] = 4'd0;
						if (bcd_inc[19:16] != 4'd9) bcd_inc[19:16] = bcd_inc[19:16] + 4'd1;
						else begin
							bcd_inc[19:16] = 4'd0;
							if (bcd_inc[23:20] != 4'd9) bcd_inc[23:20] = bcd_inc[23:20] + 4'd1;
							else bcd_inc[23:20] = 4'd0;
						end
					end
				end
			end
		end
	end
endfunction

reg [31:0] cnt_2s;
reg [31:0] playTime;
reg [31:0] leadCnt;   // 前奏计时
reg        leadDone;  // 前奏结束标志
reg [3:0]  dIdx;      // 显示指针：自己带计时器，始终领先播放指针 0.52s
reg [31:0] dTime;     // 显示指针当前音符的剩余时间
wire [2:0] dCol = lookCols[dIdx];   // {是否非休止, 列号}
wire [31:0] durNow = 32'd28_000_000; // 固定下落时长：7格×0.08s=0.56s，即每0.08s下移一格
reg        isCnt2sOver;
reg [31:0] cnt_fall;
reg [31:0]  lightCell;

reg [25:0] playTone;

// ===== 进度条：按 songIdx/songLength 分 4 档 =====
wire [11:0] idx2x = {songIdx, 1'b0};                            // 2*idx
wire [11:0] idx4x = {songIdx, 2'b00};                           // 4*idx
wire [11:0] len1x = {2'b0, songLength};
wire [11:0] len2x = {songLength, 1'b0};                         // 2*len
wire [11:0] len3x = {songLength, 1'b0} + {2'b0, songLength};    // 3*len
wire [2:0]  progressLvl =
	(songIdx >= songLength) ? 3'd4 :
	(idx4x >= len3x)        ? 3'd3 :
	(idx2x >= len2x)        ? 3'd2 :
	(idx4x >= len1x)        ? 3'd1 : 3'd0;
wire        blinkLed = cnt[23];                                 // 约3Hz闪烁

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
		chooseOnes <= 4'd0;
		chooseTens <= 4'd0;
		cnt		  <= 0;
		digitalNum <= 24'd0;
		scoreBCD   <= 24'd0;
		curCol     <= 3'd0;
		nextCol    <= 3'd0;
		hitCur     <= 1'b0;
		hitNext    <= 1'b0;
		holdChain  <= 1'b0;
		holdCol    <= 2'd0;
		flashCnt   <= 25'd0;
		beeperEnable<=0;
		resetIdx	  <=1;
		x<=0;
		y<=0;
		aniX={
			rnd[2:0]+3'd7, rnd[2:0]+3'd6, rnd[2:0]+3'd5, rnd[2:0]+3'd4,
			rnd[2:0]+3'd3, rnd[2:0]+3'd2, rnd[2:0]+3'd1, rnd[2:0]+3'd0};
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
		isCnt2sOver<=0;
		lightCell<=0;
		LittleLED<=4'b0;
	end
	else begin
		case(STATE)
		IDLE:begin
			if(key_press[0])begin
				// BCD 递减，到 00 为止
				if(chooseOnes == 4'd0) begin	//边界
					if(chooseTens != 4'd0) begin
						chooseOnes <= 4'd9;
						chooseTens <= chooseTens - 1'b1;
					end
				end else begin
					chooseOnes <= chooseOnes - 1'b1;
				end
			end
			else if(key_press[2])begin
				// BCD 递增，到 99 为止
				if(chooseOnes == 4'd9) begin	//边界
					if(chooseTens != 4'd9) begin
						chooseOnes <= 4'd0;
						chooseTens <= chooseTens + 1'b1;
					end
				end else begin
					chooseOnes <= chooseOnes + 1'b1;
				end
			end
			else if(key_press[1]) begin
				songSelecter <= {4'd0,chooseTens} * 8'd10 + {4'd0,chooseOnes};
				STATE <= ENTER_GAME;
				cnt<=0;
				brightness[2:0]  <= 3'b111;
				brightness[5:3]  <= 3'b111;
				brightness[8:6]  <= 3'b111;
				brightness[11:9] <= 3'b111;
				brightness[14:12]<= 3'b111;
				lookIdx <= 0;
			end
			
			//计数器逻辑
			cnt <= cnt + 1;
				//0.05秒后的时
			if(cnt==2_500_000) begin
				cnt<=0;

				aniX[2:0]  <= aniX[2:0]   + rnd[0] - 1 + rnd[4];//x0
				aniX[5:3]  <= aniX[5:3]   + rnd[1] - 1 + rnd[3];//x1
				aniX[8:6]  <= aniX[8:6]   + rnd[2] - 1 + rnd[1];//x2
				aniX[11:9] <= aniX[11:9]  + rnd[3] - 1 + rnd[4];//x3
				aniX[14:12]<= aniX[14:12] + rnd[4] - 1 + rnd[2];//x4
	
				aniY[2:0]  <= aniY[2:0]   + rnd[4] - 1 + rnd[4];//y0
				aniY[5:3]  <= aniY[5:3]   + rnd[5] - 1 + rnd[5];//y1
				aniY[8:6]  <= aniY[8:6]   + rnd[0] - 1 + rnd[1];//y2
				aniY[11:9] <= aniY[11:9]  + rnd[1] - 1 + rnd[3];//y3
				aniY[14:12]<= aniY[14:12] + rnd[2] - 1 + rnd[2];//y4

				brightness[2:0]  <= brightness[2:0]   + rnd[4] - 1 + rnd[4];//0
				brightness[5:3]  <= brightness[5:3]   + rnd[5] - 1 + rnd[5];//1
				brightness[8:6]  <= brightness[8:6]   + rnd[0] - 1 + rnd[1];//2
				brightness[11:9] <= brightness[11:9]  + rnd[1] - 1 + rnd[3];//3
				brightness[14:12]<= brightness[14:12] + rnd[2] - 1 + rnd[2];//4
				
				clear_flag	 <= ~clear_flag;
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

			 //x=cnt[5:3]%8
			 //y=cnt[2:0]/8
			 //select=cnt[2:0]

			case(cnt[2:0]%6)
				0:begin
					x<=aniX[2:0];
					y<=aniY[2:0];
					pixelToWrite<={21'b0,brightness[2:0]};
					write_flag   <= ~write_flag;
				end
				1:begin
					x<=aniX[5:3];
					y<=aniY[5:3];
					pixelToWrite<={21'b0,brightness[5:3]};
					write_flag   <= ~write_flag;
				end
				2:begin
					x<=aniX[8:6];
					y<=aniY[8:6];
					pixelToWrite<={13'b0,brightness[8:6],8'b0};
					write_flag   <= ~write_flag;
				end
				3:begin
					x<=aniX[11:9];
					y<=aniY[11:9];
					pixelToWrite<={13'b0,brightness[11:9],8'b0};
					write_flag   <= ~write_flag;
				end
				4:begin
					x<=aniX[14:12];
					y<=aniY[14:12];
					pixelToWrite<={5'b0,brightness[14:12],16'b0};
					write_flag   <= ~write_flag;
				end
				5:begin
					//clear_flag	 <= ~clear_flag;
				end
			endcase
			
			//aniX[(cnt[2:0]%5+1)*3:(cnt[2:0]%5)*3]
			
		end
		ENTER_GAME:begin
			if(!rst_bt) STATE<=INIT;
			//Play enter animation
			if(animationCompleted || SKIP_ANIM) begin
				resetIdx <= 0;          // 进LOAD前给一拍低电平，把歌指针清回0
				lookIdx  <= 0;          // 保证LOAD从槽0开始预取
				cnt      <= 0;
				STATE    <= LOAD;
			end
			else begin
				cnt <= cnt + 1;
				
				// 进场第一拍：5个旧点沉到底部，3个新点已在顶部，全部从暗开始
				if(cnt==0) begin
					aniY[14:0]  <= 15'h7FFF;
					aniY[23:15] <= 9'd0;
					brightness  <= 24'd0;
					animStep    <= 4'd0;
				end
				
				// 每0.1s一步：0~7步上升(同时变白)，8~15步下降(同时变暗)
				else if(cnt%5_000_000==0) begin
					for(ai=0;ai<8;ai=ai+1) begin
						if(animStep[3]) begin
							// 下降：y 0->7，亮度 7->0
							aniY[ai*3 +: 3]       <= (aniY[ai*3 +: 3]==3'd7)      ? 3'd7 : aniY[ai*3 +: 3] + 3'd1;
							brightness[ai*3 +: 3] <= (brightness[ai*3 +: 3]==3'd0) ? 3'd0 : brightness[ai*3 +: 3] - 3'd1;
						end
						else begin
							// 上升：y 7->0，亮度 0->7
							aniY[ai*3 +: 3]       <= (aniY[ai*3 +: 3]==3'd0)      ? 3'd0 : aniY[ai*3 +: 3] - 3'd1;
							brightness[ai*3 +: 3] <= (brightness[ai*3 +: 3]==3'd7) ? 3'd7 : brightness[ai*3 +: 3] + 3'd1;
						end
					end
					animStep   <= animStep + 1'b1;
					clear_flag <= ~clear_flag;
				end
				
				if(animStep >= 4'd15) begin
					cnt <= 0;
					animStep <= 4'd0;
					animationCompleted <= 1;
					lookIdx<=0;
					resetIdx <= 0;      // 进LOAD前给一拍低电平，把歌指针清回0
					STATE<=LOAD;
				end
				//渲染：8个点轮流写，红绿蓝同值=白色，随 brightness 同步变亮/变暗
				case(cnt[2:0])
					3'd0:begin x<=aniX[2:0];   y<=aniY[2:0];   pixelToWrite<={5'b0,brightness[2:0],5'b0,brightness[2:0],5'b0,brightness[2:0]}; write_flag<=~write_flag; end
					3'd1:begin x<=aniX[5:3];   y<=aniY[5:3];   pixelToWrite<={5'b0,brightness[5:3],5'b0,brightness[5:3],5'b0,brightness[5:3]}; write_flag<=~write_flag; end
					3'd2:begin x<=aniX[8:6];   y<=aniY[8:6];   pixelToWrite<={5'b0,brightness[8:6],5'b0,brightness[8:6],5'b0,brightness[8:6]}; write_flag<=~write_flag; end
					3'd3:begin x<=aniX[11:9];  y<=aniY[11:9];  pixelToWrite<={5'b0,brightness[11:9],5'b0,brightness[11:9],5'b0,brightness[11:9]}; write_flag<=~write_flag; end
					3'd4:begin x<=aniX[14:12]; y<=aniY[14:12]; pixelToWrite<={5'b0,brightness[14:12],5'b0,brightness[14:12],5'b0,brightness[14:12]}; write_flag<=~write_flag; end
					3'd5:begin x<=aniX[17:15]; y<=aniY[17:15]; pixelToWrite<={5'b0,brightness[17:15],5'b0,brightness[17:15],5'b0,brightness[17:15]}; write_flag<=~write_flag; end
					3'd6:begin x<=aniX[20:18]; y<=aniY[20:18]; pixelToWrite<={5'b0,brightness[20:18],5'b0,brightness[20:18],5'b0,brightness[20:18]}; write_flag<=~write_flag; end
					3'd7:begin x<=aniX[23:21]; y<=aniY[23:21]; pixelToWrite<={5'b0,brightness[23:21],5'b0,brightness[23:21],5'b0,brightness[23:21]}; write_flag<=~write_flag; end
				endcase
			end
		end
		LOAD:begin
			if(!rst_bt) STATE<=INIT;
			//Set song data and initialize
			//STATE <= PLAYING;
			digitalNum <= {12'd0, totalBCD};	//LOAD期间数码管展示本关满分
			isCnt2sOver <= 0;
			cnt_2s <= 0;
			playIdx <= 0;
			scoreBCD <= 24'd0; curCol <= 3'd0; nextCol <= 3'd0; hitCur <= 1'b0; hitNext <= 1'b0;
			holdChain <= 1'b0; holdCol <= 2'd0; flashCnt <= 25'd0;
			dIdx <= 0;
			dTime <= 0;
			cnt_fall <= 0;
			lightCell<=0;
			leadCnt <= 0;
			leadDone <= 0;
			
			if(!resetIdx) begin
				resetIdx <= 1;                  // 复位那一拍过去，恢复高电平
			end
			else if(lookIdx<=15) begin
				if(!nextFlag)
					nextFlag<=1;                // 先发一拍，让songData推一位
				else begin                      // 下一拍tone才是新音符（ROM同步读有1拍延迟）
					nextFlag<=0;
					lookTones[lookIdx]<=tone;
					lookTimes[lookIdx]<=toneCnt;
					lookTimesD[lookIdx]<=toneCnt;
					lookCols[lookIdx]<={tone!=26'd0,tone[9:8]};
					lookIdx<=lookIdx+1;
				end
			end
			else begin
				//******* 进场动画：8点上升8步、下降8步，同时数码管展示满分 *******
				cnt <= cnt + 1'b1;
				if(cnt==0) begin
					for(ai=0;ai<8;ai=ai+1)
						aniX[ai*3 +: 3] <= (rnd[2:0] + ai[2:0]) & 3'd7;   // 8点各占一个不同列
					aniY[23:15] <= 9'd0;        // 新增的3个点直接在顶部
					// 前5个点保留主菜单里的位置和亮度，从原处接着上升
					animStep    <= 4'd0;        // 确保动画从0步开始
				end
				else if(cnt%5_000_000==0) begin
					for(ai=0;ai<8;ai=ai+1) begin
						if(animStep[3]) begin
							aniY[ai*3 +: 3]       <= (aniY[ai*3 +: 3]==3'd7)      ? 3'd7 : aniY[ai*3 +: 3] + 3'd1;
							brightness[ai*3 +: 3] <= (brightness[ai*3 +: 3]==3'd0) ? 3'd0 : brightness[ai*3 +: 3] - 3'd1;
						end
						else begin
							aniY[ai*3 +: 3]       <= (aniY[ai*3 +: 3]==3'd0)      ? 3'd0 : aniY[ai*3 +: 3] - 3'd1;
							brightness[ai*3 +: 3] <= (brightness[ai*3 +: 3]==3'd7) ? 3'd7 : brightness[ai*3 +: 3] + 3'd1;
						end
					end
					animStep   <= animStep + 1'b1;
					clear_flag <= ~clear_flag;
				end
				//渲染8个点
				case(cnt[2:0])
					3'd0:begin x<=aniX[2:0];   y<=aniY[2:0];   pixelToWrite<={5'b0,brightness[2:0],5'b0,brightness[2:0],5'b0,brightness[2:0]}; write_flag<=~write_flag; end
					3'd1:begin x<=aniX[5:3];   y<=aniY[5:3];   pixelToWrite<={5'b0,brightness[5:3],5'b0,brightness[5:3],5'b0,brightness[5:3]}; write_flag<=~write_flag; end
					3'd2:begin x<=aniX[8:6];   y<=aniY[8:6];   pixelToWrite<={5'b0,brightness[8:6],5'b0,brightness[8:6],5'b0,brightness[8:6]}; write_flag<=~write_flag; end
					3'd3:begin x<=aniX[11:9];  y<=aniY[11:9];  pixelToWrite<={5'b0,brightness[11:9],5'b0,brightness[11:9],5'b0,brightness[11:9]}; write_flag<=~write_flag; end
					3'd4:begin x<=aniX[14:12]; y<=aniY[14:12]; pixelToWrite<={5'b0,brightness[14:12],5'b0,brightness[14:12],5'b0,brightness[14:12]}; write_flag<=~write_flag; end
					3'd5:begin x<=aniX[17:15]; y<=aniY[17:15]; pixelToWrite<={5'b0,brightness[17:15],5'b0,brightness[17:15],5'b0,brightness[17:15]}; write_flag<=~write_flag; end
					3'd6:begin x<=aniX[20:18]; y<=aniY[20:18]; pixelToWrite<={5'b0,brightness[20:18],5'b0,brightness[20:18],5'b0,brightness[20:18]}; write_flag<=~write_flag; end
					3'd7:begin x<=aniX[23:21]; y<=aniY[23:21]; pixelToWrite<={5'b0,brightness[23:21],5'b0,brightness[23:21],5'b0,brightness[23:21]}; write_flag<=~write_flag; end
				endcase
				if(animStep >= 4'd15) begin
					animStep   <= 4'd0;
					STATE      <= PLAYING;
					lookIdx    <= 0;
					cnt        <= 0;
					clear_flag <= 1'b1;         // 清屏进入游戏
				end
			end
		end
		PLAYING:begin
			//******* 进度条：前沿那盏闪，播完全部流水灯 *******
			case(progressLvl)
				3'd0: LittleLED <= {blinkLed, 3'b000};        // 25%前：第1盏闪
				3'd1: LittleLED <= {1'b1, blinkLed, 2'b00};   // 50%前：第1盏常亮，第2盏闪
				3'd2: LittleLED <= {2'b11, blinkLed, 1'b0};   // 75%前：第3盏闪
				3'd3: LittleLED <= {3'b111, blinkLed};        // 100%前：第4盏闪
				3'd4: LittleLED <= 4'b1000 >> cnt[25:24];     // 播完：流水灯
			endcase
			
			//************* 暂停部分 ****************
			if(!enabled) begin
				beeperEnable<=0;
				STATE        <= PAUSED;   // SW10 拨下即暂停，计时全部冻结
			end
				else begin
				
				//******* 前奏：画面先跑2秒，之后才开始发声 *******
				if(!leadDone) begin
					leadCnt <= leadCnt + 1'b1;
					if(leadCnt >= 2*50_000_000-1) begin
						leadDone <= 1;
					end
					beeperEnable <= 0;
				end
				else begin
					if(cnt_2s==0) begin
						playTone           <= lookTones[playIdx];
						playTime           <= lookTimes[playIdx];  // 锁存本音符时值
						curCol             <= colNow;                   // 当前音符列
						nextCol            <= colNextW;                 // 下一音符列，用于提前击
						if(autoHit) begin
							// 紧邻同列：延音自动判定成功
							hitCur   <= 1'b1;
							scoreBCD <= bcd_inc(scoreBCD);
						end
						else if(hitNext) begin
							// 上一音符期间已提前击打这个音
							hitCur    <= 1'b1;
							holdChain <= 1'b1;
							holdCol   <= colNow[1:0];
						end
						else begin
							hitCur    <= 1'b0;
							holdChain <= 1'b0;   // 音高变了，连击链断开，必须重新按
						end
						hitNext  <= 1'b0;
						nextFlag           <= 0;
						playIdx <= playIdx + 1;
					end
					// 写完槽位延后一拍（读和写不再同拍同址），值仍是同一个音
					else if(cnt_2s==1) begin
						lookTones[playIdx-4'd1] <= tone;
						lookTimes[playIdx-4'd1] <= toneCnt;
						lookTimesD[playIdx-4'd1] <= toneCnt;
						lookCols[playIdx-4'd1] <= {tone!=26'd0,tone[9:8]};
					end	
					
					cnt_2s<=cnt_2s+1'b1;		//给playIdx
					
					//******** 发声逻辑 ***********
					//playTone/playTime 已经在音符起点锁存好，这里只负责计时和结束
					beeperEnable<=1;
					// 提前3拍推进songData：nextFlag有效后要2拍tone/toneCnt才更新，
					// 这样下一个音符起点采到的正好是该槽的音，修索引偏移
					if(cnt_2s==playTime-32'd3) nextFlag<=1;
					else if(cnt_2s==playTime-32'd2) nextFlag<=0;
					if(cnt_2s>=playTime-1) begin
						cnt_2s<=0;
					end

					//******** 按键判定（误差按音符真实播放时间算）********
					// 晚按：当前音符已开播，误差 = cnt_2s
					if(curCol[2] && !hitCur && !autoHit && (cnt_2s <= WIN_GOOD) && key_press[curCol[1:0]]) begin
						hitCur    <= 1'b1;
						holdChain <= 1'b1;          // 从这个音开始连击
						holdCol   <= curCol[1:0];
						scoreBCD  <= bcd_inc(scoreBCD);
					end
					// 早按：下一个音符，误差 = 距离它真正播放的时间
					else if(nextCol[2] && !hitNext && ((playTime - cnt_2s) <= WIN_GOOD) && key_press[nextCol[1:0]]) begin
						hitNext   <= 1'b1;
						holdChain <= 1'b1;
						holdCol   <= nextCol[1:0];
						scoreBCD  <= bcd_inc(scoreBCD);
					end
				end
				
				//******** 按键底线红色反馈（按下即亮100ms）********
				if(flashCnt != 25'd0) flashCnt <= flashCnt - 1'b1;
				if(key_press[0]) begin flashCol <= 2'd0; flashCnt <= 25'd5_000_000; end
				else if(key_press[1]) begin flashCol <= 2'd1; flashCnt <= 25'd5_000_000; end
				else if(key_press[2]) begin flashCol <= 2'd2; flashCnt <= 25'd5_000_000; end
				else if(key_press[3]) begin flashCol <= 2'd3; flashCnt <= 25'd5_000_000; end
				
				digitalNum <= scoreBCD;		//实时显示得分
				cnt<=cnt+1'b1;				//给lookIdx
				cnt_fall<=cnt_fall+1'b1;//给掉落块逻辑
				
				//曲子放完：finish 只表示歌曲指针到头，缓冲里还有16个音的余量，
				//等真正播到静音音（playTone==0）再进结算，避免结尾被截断
				if(finish && playTone==26'd0) begin
					// 等最后一块落到底线（7格下落时间）再进结算
					if(endDelay >= 32'd35_000_000) STATE<=FINISHED;
					else endDelay <= endDelay + 1'b1;
				end
				
				/*	已弃用，这个方案不方便用于游戏逻辑
				//************* 音乐部分 ****************
				if(finish) STATE<=FINISHED;
				if(cnt==0) begin //刚清零过，也就是下一个音符
					nextFlag<=0;
				end
				beeperEnable<=1;
				if(toneCnt==0) begin beeperEnable <= 0; cnt <= 0; nextFlag<=1; end
				else if(cnt>=toneCnt-1) begin
					nextFlag<=1;
					cnt<=0;
				end*/
				
				//************* 画面部分 ****************
				// 8行x4列，每格 ci/4 行、(ci%4)*2 列；固定每0.25s下移一格，
				// 从第0行掉到第7行共1.75s，所以块落到第7行的时刻 = 它发声的时刻
				cnt_fall <= cnt_fall + 7;
				if(cnt_fall + 7 >= durNow)begin
					cnt_fall<=0;
					lightCell[31:28] <= lightCell[27:24];
					lightCell[27:24] <= lightCell[23:20];
					lightCell[23:20] <= lightCell[19:16];
					lightCell[19:16] <= lightCell[15:12];
					lightCell[15:12] <= lightCell[11:8];
					lightCell[11:8]  <= lightCell[7:4];
					lightCell[7:4]   <= lightCell[3:0];
					lightCell[3:0]   <= 4'b0000;
				end
				// 显示指针：自己带一个计时器，跟播放指针各走各的，领先它 0.52s。
				// 所以它推到的音，0.52s 后由播放指针发声，块基本同时落到第7行。
				if(leadCnt==74_000_000) begin
					if(dCol[2]) lightCell[3:0] <= 4'b0001 << dCol[1:0];  // 首块：1.48s出现，2s落地
					dIdx  <= 4'd1;
					dTime <= lookTimesD[dIdx] - 1'b1;
				end
				else if(leadCnt > 74_000_000) begin
					if(dTime==0) begin
						if(dCol[2]) lightCell[3:0] <= 4'b0001 << dCol[1:0];  // 休止符不出块
						dTime <= lookTimesD[dIdx] - 1'b1;
						dIdx  <= dIdx + 4'd1;
					end
					else dTime <= dTime - 1'b1;
				end
				
				
				//************* 进度条部分 **************
				//LittleLED[0]<=4'b0000;
				//LittleLED<={cnt[8],1'b0,1'b0,1'b0};
				
				//************* 互动部分 ****************
				
				
				end
			if(!rst_bt) STATE<=INIT;
		end
		PAUSED:begin
			beeperEnable <= 0;
			digitalNum   <= 24'hABCDEF;   // 左→右: P A U S E 空白
			if(enabled)  STATE <= PLAYING;
			else if(!rst_bt) STATE <= INIT;
		end
		FINISHED:begin
			beeperEnable <= 0;
			LittleLED    <= 4'b1111;
			digitalNum   <= {scoreBCD[11:0], totalBCD}; // 左3位得分 / 右3位满分
			finCnt <= finCnt + 1'b1;
			if(finCnt >= 32'd200_000_000) STATE <= INIT; // 停留4秒
			else if(!rst_bt) STATE <= INIT;
		end
		INIT:begin
			STATE      <= IDLE;
			cnt		  <= 0;
			chooseOnes <= 4'd0;
			chooseTens <= 4'd0;
			digitalNum <= 24'd0;
			beeperEnable<=0;
			resetIdx	  <=1;
			lightCell	  <=0;      // 退出游戏时清掉方块，别留在屏幕上
			LittleLED   <=4'b0000; // 退出时进度灯全灭
			flashCnt    <=25'd0;
			endDelay    <=32'd0;
			finCnt      <=32'd0;
			animationCompleted <= 0;  // 每次回主菜单都要能重放进场动画
			animStep    <=4'd0;
			x<=0;
			y<=0;
			aniX={
				rnd[2:0]+3'd7, rnd[2:0]+3'd6, rnd[2:0]+3'd5, rnd[2:0]+3'd4,
				rnd[2:0]+3'd3, rnd[2:0]+3'd2, rnd[2:0]+3'd1, rnd[2:0]+3'd0};
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
			isCnt2sOver<=0;
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

