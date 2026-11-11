module rgbRenderer(
    input clk,
    input rst_n,
	 // write var
	 input [2:0] x,
	 input [2:0] y,
	 input [23:0] pixelToWrite,
	 input write_flag,
	 
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

reg [23:0] write_buf [0:7][0:7]; // bufferr
reg [23:0] disp_buf  [0:7][0:7]; // dis mem

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

// **************************************************
reg write_flag_r;
wire write_toggle;
assign write_toggle = write_flag ^ write_flag_r;
// 捕捉write_flag翻转，采样x,y,pixelToWrite
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_flag_r <= 1'b0;
    end
    else begin
        write_flag_r <= write_flag;
        if(write_toggle) begin
            write_buf[y][x] <= pixelToWrite;
        end
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
                curr_pix <= disp_buf[ty][tx];
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
                                curr_pix <= disp_buf[pix_idx+1][tx];
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
                                curr_pix <= disp_buf[pix_idx+1][tx];
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
					integer yi, xi; //for(xy)
                cnt <= cnt + 1'b1;
                mt_in <= 1'b0;
                // 缓冲区拷贝 write_buf -> disp_buf
                for(yi=0; yi<8; yi=yi+1) begin
                    for(xi=0; xi<8; xi=xi+1) begin
                        disp_buf[yi][xi] <= write_buf[yi][xi];
                    end
                end
                if(cnt >= RST_CYC) begin
                    state <= S_IDLE;
                end
            end
        endcase
    end
end
endmodule