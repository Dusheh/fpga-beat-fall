module beep(
    input   wire            clk     ,
    input   wire            rst_n   ,
    input   wire            en      ,//1:发声；0：不发声
    input   wire    [25:0]  FREQ_T  ,//周期/频率
    output  wire            pwm      //方波
);//蜂鸣器驱动：方波

reg [25:0] cnt;

always@(posedge clk)
    if(!rst_n)
        cnt <= 0;
    else if(en == 1)begin  //开关打开，周期计数
        if(cnt >= FREQ_T - 26'd1)  //最大值
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= cnt;

assign pwm = (en && cnt <= FREQ_T / 2) ? 1 : 0;

endmodule
