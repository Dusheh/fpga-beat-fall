`timescale 1ns/1ps
module tb_beep;
reg clk = 0, rst_n = 0, en = 1;
reg [25:0] FREQ_T = 26'd0;
wire pwm;

beep dut(.clk(clk), .rst_n(rst_n), .en(en), .FREQ_T(FREQ_T), .pwm(pwm));
always #10 clk = ~clk;

time last_edge = 0;
integer runts = 0, edges = 0;
real min_w = 1e9, max_w = 0;

always @(pwm) if ($time > 1000) begin
  time w;
  w = $time - last_edge;
  last_edge = $time;
  edges = edges + 1;
  if (w < min_w) min_w = w;
  if (w > max_w) max_w = w;
  if (w < 1000) begin           // 宽度 < 1us 的电平段 = 毛刺
    runts = runts + 1;
    if (runts <= 6) $display("  !! RUNT #%0d at %0t ns, width=%0d ns", runts, $time, w);
  end
end

task setf(input [25:0] f, input integer dur);
  begin $display(">> FREQ_T=%0d (%0.1f Hz) at %0t ns", f, 5.0e7/f, $time); FREQ_T = f; #(dur); end
endtask

initial begin
  FREQ_T = 26'd190800;      // 低音 DO
  #200 rst_n = 1;
  #1_000_000;
  setf(26'd25400,  600_000);  // 高音 XI
  setf(26'd190800, 600_000);  // 低音 DO
  setf(26'd191200, 600_000);  // 中音 DO（相邻音，常见换音）
  setf(26'd0,      400_000);  // 休止
  setf(26'd25400,  400_000);
  $display("---- edges=%0d  runts=%0d  min_edge=%0.1f us  max_edge=%0.1f us", edges, runts, min_w/1000.0, max_w/1000.0);
  $finish;
end
endmodule
