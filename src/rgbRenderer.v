module rgbRenderer(
    input wire clk,
    input wire rst_n,
	 // write var
	 input wire [2:0] x,
	 input wire [2:0] y,
	 input wire [23:0] pixelToWrite,
	 input wire write_flag,
    input wire clear_flag,
	 input wire animEn,           // 1=动画状态(IDLE/ENTER_GAME)才响应write_flag
	 
	 // game var
	 input wire [31:0] lightCell, // 0->1->2->3\然后到第二行循环
	 input wire lightCellEn,      // 只有PLAYING才叠方块，别把IDLE的动画刷掉
	 input wire [1:0] flashCol,   // 按键命中列
	 input wire       flashEn,    // 按键红色底灯有效
	 
	 // rgb matrix
	 output reg mt_in
);

// 使用方法

//1.先更改x,y,pixelToWrite
//  注意pixelToWrite是GGBBRR形式

//2.然后反转write_flag，具体为write_flag=~write_flag;

//3.等待下一个时钟周期再继续写x，y

parameter TOTAL_PIX = 64; // 8x8
parameter PIX_W     = 24; // GGBBRR 4*8
parameter CLK_FREQ  = 50_000_000;
// WS2812时序 50M
parameter T0H       = 15;
parameter T0L       = 40;
parameter T1H       = 35;
parameter T1L       = 15;
parameter RST_CYC   = 14000;

reg [23:0] write_buf [0:7][0:7]; // bufferr（单缓冲：发送时直接读，省一份显存）

// 缓冲区初值清零：否则未写过的像素在综合时是 don't-care，会被绑成 1 → 整屏全亮
integer ii, jj;
initial begin
	for(ii=0; ii<8; ii=ii+1)
		for(jj=0; jj<8; jj=jj+1) begin
			write_buf[ii][jj] = 24'd0;
		end
end

localparam S_IDLE   = 2'd0; // 空闲
localparam S_TX     = 2'd1; // 发送像素数据中
localparam S_VBLANK = 2'd2; // 复位等待
reg [1:0] state;

reg [5:0] pix_idx; // 现在发送到的像素索引
reg [4:0] bit_idx; // 当前像素更改到的值索引（GGBBRR）
reg [15:0] cnt;	 // 全局时序计数器
reg [23:0] curr_pix;//锁存当前发送的像素

wire [2:0] ty = pix_idx[5:3]; //3bits:3~5
wire [2:0] tx = pix_idx[2:0]; //3bits:0~2
// 下一个像素的坐标（原来直接用 pix_idx+1 当 y 会越界）
wire [5:0] pix_nxt = pix_idx + 1'b1;
wire [2:0] tx_nxt  = pix_nxt[2:0];
wire [2:0] ty_nxt  = pix_nxt[5:3];

// **************************************************
reg write_flag_r;
wire write_toggle;
assign write_toggle = write_flag ^ write_flag_r;
reg clear_flag_r;
wire clear_toggle;
assign clear_toggle = clear_flag ^ clear_flag_r;
// 捕捉clear_flag翻转，清屏
// 捕捉write_flag翻转，采样x,y,pixelToWrite

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_flag_r <= 1'b0;
        clear_flag_r <= 1'b0;
    end
    else begin
		  integer ci, cj;
		  if(lightCellEn) begin
			  for(ci = 0; ci < 32; ci = ci + 1)begin
					write_buf[ci/4][(ci%4)*2]<=lightCell[ci]?24'h0F0F0F:0;
					write_buf[ci/4][(ci%4)*2+1]<=lightCell[ci]?24'h0F0F0F:0;
				end
		  end
	 
		  // 按键命中：底线对应列的两个物理像素亮红（放在方块之后，优先级最高）
		  if(flashEn) begin
			  write_buf[7][{flashCol,1'b0}]      <= 24'h0F0000;
			  write_buf[7][{flashCol,1'b0}+1'b1] <= 24'h0F0000;
		  end
		 
        write_flag_r <= write_flag;
        clear_flag_r <= clear_flag;
        if(write_toggle && animEn) begin
            write_buf[y][x] <= pixelToWrite;
        end
        if(clear_toggle) begin
            for(ci = 0; ci < 8; ci = ci + 1)
                for(cj = 0; cj < 8; cj = cj + 1)
                    write_buf[ci][cj] <= 24'd0;
        end
		  
		  //x:lightCell%4
		  //y:lightCell/4
    end
end
// **************************************************

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state    <= S_IDLE;
        pix_idx  <= 0;
        bit_idx  <= 0;
        cnt      <= 0;
        mt_in    <= 1'b0;
        curr_pix <= 24'd0;
    end
    else begin

        case(state)
            S_IDLE: begin
                pix_idx  <= 0;
                bit_idx  <= 5'd23;
                cnt      <= 0;
                curr_pix <= write_buf[3'd0][3'd0];  // 第一颗固定取(0,0)，不能用户旧pix_idx
                state    <= S_TX;
            end
            S_TX: begin
                cnt <= cnt + 1'b1;
                if(curr_pix[bit_idx]) begin
                    if(cnt < T1H)
                        mt_in <= 1'b1;
                    else if(cnt < T1H + T1L)
                        mt_in <= 1'b0;
                    else begin
                        cnt <= 0;
                        bit_idx <= bit_idx - 1'b1;
                        if(bit_idx == 0) begin
                            if(pix_idx < TOTAL_PIX - 1) begin
                                pix_idx <= pix_idx + 1'b1;
                                bit_idx <= 5'd23;
                                curr_pix <= write_buf[ty_nxt][tx_nxt];
                            end
                            else begin
                                state <= S_VBLANK;
                                cnt <= 0;
                            end
                        end
                    end
                end
                else begin
                    if(cnt < T0H)
                        mt_in <= 1'b1;
                    else if(cnt < T0H + T0L)
                        mt_in <= 1'b0;
                    else begin
                        cnt <= 0;
                        bit_idx <= bit_idx - 1'b1;
                        if(bit_idx == 0) begin
                            if(pix_idx < TOTAL_PIX - 1) begin
                                pix_idx <= pix_idx + 1'b1;
                                bit_idx <= 5'd23;
                                curr_pix <= write_buf[ty_nxt][tx_nxt];
                            end
                            else begin
                                state <= S_VBLANK;
                                cnt <= 0;
                            end
                        end
                    end
                end
            end
            S_VBLANK: begin
                cnt <= cnt + 1'b1;
                mt_in <= 1'b0;
                if(cnt >= RST_CYC) begin
                    state <= S_IDLE;
                end
            end
        endcase
    end
end
endmodule