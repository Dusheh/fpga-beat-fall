module songSource(
    input  wire        clk,
    input  wire        resetIdx,   // 低有效
    input  wire        nextFlag,
    input  wire [3:0]  songSel,    // 0=晴天, 1=我不难过, 2=太聪明
    output wire [25:0] tone,
    output wire [4:0]  toneTime,
    output wire [31:0] toneCnt,
    output wire [7:0]  bpm,
    output wire        finish,
	 output wire [9:0]   songIdx,
	 output wire [9:0]   songLength
);

localparam SONG_NUM = 3;   // 以后加歌改这里

// 越界保护：选到不存在的歌就回落到 0
wire [3:0] sel = (songSel < SONG_NUM) ? songSel : 4'd0;

// 每个实例一组输出线（net 数组）
wire [25:0] toneArr [0:SONG_NUM-1];
wire [4:0]  timeArr [0:SONG_NUM-1];
wire [31:0] cntArr  [0:SONG_NUM-1];
wire [7:0]  bpmArr  [0:SONG_NUM-1];
wire        finArr  [0:SONG_NUM-1];
wire        rstArr  [0:SONG_NUM-1];
wire [9:0]  lenArr  [0:SONG_NUM-1];
wire [9:0]  idxArr  [0:SONG_NUM-1];

genvar i;
generate
    for (i = 0; i < SONG_NUM; i = i + 1) begin : g_song
        // 没被选中的实例一直压在复位里，不让它跟着nextFlag乱跑
        assign rstArr[i] = resetIdx & (sel == i);

        if (i == 0) begin : g_qt
            songDataQT u_song(
                .clk(clk), .resetIdx(rstArr[i]), .nextFlag(nextFlag),
                .tone(toneArr[i]), .toneTime(timeArr[i]), .toneCnt(cntArr[i]),
                .bpm(bpmArr[i]), .finish(finArr[i]), .songLength(lenArr[i]),
					 .songIdx(idxArr[i])
            );
        end
        else if (i == 1) begin : g_getter
            songDataGetter u_song(
                .clk(clk), .resetIdx(rstArr[i]), .nextFlag(nextFlag),
                .tone(toneArr[i]), .toneTime(timeArr[i]), .toneCnt(cntArr[i]),
                .bpm(bpmArr[i]), .finish(finArr[i]), .songLength(lenArr[i]),
					 .songIdx(idxArr[i])
            );
        end
        else if (i == 2) begin : g_tcm
            songDataTCM u_song(
                .clk(clk), .resetIdx(rstArr[i]), .nextFlag(nextFlag),
                .tone(toneArr[i]), .toneTime(timeArr[i]), .toneCnt(cntArr[i]),
                .bpm(bpmArr[i]), .finish(finArr[i]), .songLength(lenArr[i]),
					 .songIdx(idxArr[i])
            );
        end
        // 以后新增：else if (i == 2) begin : g_xxx  songDataXxx u_song(...); end
    end
endgenerate

// 选择器本体：变量索引的 net 数组，Quartus 会综合成一组 mux
assign tone     = toneArr[sel];
assign toneTime = timeArr[sel];
assign toneCnt  = cntArr[sel];
assign bpm      = bpmArr[sel];
assign finish   = finArr[sel];
assign songLength = lenArr[sel];
assign songIdx	 = idxArr[sel];

endmodule