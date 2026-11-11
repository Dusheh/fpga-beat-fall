module beep(
    input   wire            clk     ,
    input   wire            rst_n   ,
    input   wire            en      ,//1:发声；0：不发声
    input   wire    [25:0]  FREQ_T  ,//周期（50MHz 下的时钟数，0 = 休止）
    output  wire            pwm      //50% 占空比方波
);//蜂鸣器驱动

reg [25:0] cnt;     // 相位计数器 0 ~ FREQ_T-1
reg [25:0] freq_d;  // 上一拍的音高，用来检测换音
reg        pwm_r;   // 寄存输出，避免组合比较器在换音瞬间产生毛刺

always@(posedge clk)
    if(!rst_n) begin
        cnt    <= 26'd0;
        freq_d <= 26'd0;
        pwm_r  <= 1'b0;
    end
    else begin
        freq_d <= FREQ_T;

        if(en && FREQ_T != 26'd0) begin
            // 换音时强制把相位清零，从完整周期起点开始，
            // 否则新音符周期更短时 cnt 会立刻越过上限，
            // 输出一个只有几个时钟宽的残缺脉冲（高频分量 → 听感上的"尖音"）
            if(FREQ_T != freq_d || cnt >= FREQ_T - 26'd1) begin
                cnt   <= 26'd0;
                pwm_r <= 1'b1;
            end
            else begin
                cnt   <= cnt + 1'b1;
                pwm_r <= (cnt + 1'b1 < (FREQ_T >> 1));
            end
        end
        else begin
            cnt   <= 26'd0;
            pwm_r <= 1'b0;
        end
    end

assign pwm = pwm_r;

endmodule
