`timescale 1ns/1ps
// WS2812 点阵驱动仿真：写入 8x8 测试图案，再把输出引脚上的比特流解码回来，
// 逐像素和写入值比对。用来看"画进去的东西到底有没有按顺序发出去"。
//
//   cd sim && make rgb

module tb_rgb;
reg clk = 0, rst_n = 0, write_flag = 0;
reg [2:0] x = 0, y = 0;
reg [23:0] pix = 0;
wire mt_in;

rgbRenderer dut(.clk(clk), .rst_n(rst_n), .x(x), .y(y),
                .pixelToWrite(pix), .write_flag(write_flag), .mt_in(mt_in));

always #10 clk = ~clk;          // 50 MHz

integer xi, yi;
integer hcnt = 0, bitcnt = 0, pixcnt = 0, wrong = 0, checked = 0;
reg [23:0] sh = 0;

initial begin
  rst_n = 0; #100 rst_n = 1;
  // 逐行写入像素：值 = (序号+1) * 0x010101，三通道相同，方便肉眼对号
  for (yi = 0; yi < 8; yi = yi + 1)
    for (xi = 0; xi < 8; xi = xi + 1) begin
      y = yi[2:0];
      x = xi[2:0];
      pix = (yi*8 + xi + 1) * 24'h010101;
      #6  write_flag = ~write_flag;   // 避开时钟沿，模拟上层"写完翻标志"
      #54;
    end
  #6_000_000;                       // 等两帧发完
  $display("---- 比对 %0d 个像素，错误 %0d 个", checked, wrong);
  $finish;
end

// 用高电平宽度判 0/1（T0H=15 个周期，T1H=35 个周期，30MHz 以下阈值取 25）
always @(posedge clk) begin
  if (mt_in) hcnt = hcnt + 1;
  else if (hcnt > 0) begin
    sh = {sh[22:0], (hcnt > 25) ? 1'b1 : 1'b0};
    hcnt = 0;
    bitcnt = bitcnt + 1;
    if (bitcnt == 24) begin
      // 第一帧读的是复位后还是 X 的 disp_buf，跳过；第二帧才是拷贝后的画面
      if (pixcnt >= 64 && pixcnt < 128) begin
        checked = checked + 1;
        if (sh !== ((pixcnt-64+1) * 24'h010101)) begin
          wrong = wrong + 1;
          if (wrong <= 8)
            $display("  (%0d,%0d) 收到 0x%06h  期望 0x%06h",
                     (pixcnt-64)/8, (pixcnt-64)%8, sh, (pixcnt-64+1)*24'h010101);
        end
      end
      pixcnt = pixcnt + 1;
      bitcnt = 0;
    end
  end
end
endmodule
