module songData(     // 改名到 songTonePlayer
input wire clk,
input wire enable,
input wire resetIdx, 
output reg [25:0]tone,
output reg [4:0]toneTime,
output wire [7:0]bpm,
output reg finish
);

(* ramstyle = "M9K" *)reg [18:0] tones [0:404];
(* ramstyle = "M9K" *)reg [5:0] ttime [0:404];

reg [8:0] idx; // 0~511

localparam length = 404;

// ===== 音符定义（周期） =====
localparam REST=0;
localparam LDO= 3816 * 50;
localparam LRE= 3401 * 50;
localparam LMI= 3030 * 50;
localparam LFA= 2865 * 50;
localparam LSOL=2551 * 50;
localparam B_LLA		= 2410 * 50;
localparam LLA= 2272 * 50;
localparam LXI= 2024 * 50;
localparam DO = 1912 * 50;
localparam RE = 1703 * 50;
localparam B_MI		= 1608 * 50;
localparam MI = 1517 * 50;
localparam FA = 1432 * 50;
localparam SHARP_FA	= 1351 * 50;
localparam SOL= 1275 * 50;
localparam LA = 1136 * 50;
localparam XI = 1012 * 50;
localparam HDO= 955  * 50;
localparam HRE= 851  * 50;
localparam HMI= 758  * 50;
localparam HFA= 751  * 50;
localparam HSOL=637  * 50;
localparam HLA= 568  * 50;
localparam HXI= 508  * 50;

// ===== 默认速度 =====
localparam Nowbpm = 8'd64;
 // 单片机频率：50MHz；
 // 现实一秒=50_000_000
 // 1s    = 50_000_000
 // 300ms = 15_000_000
 // 150ms =  7_500_000
 // 50ms  =  2_500_000
 // 10ms  =    500_000
 // 1ms   =     50_000
 
 //bpm64 = 60/64 = 0.9375s/4拍
 //bps   = 60/64 = 0.9375s
 
 //8分音符= bps/2
 //4分音符= bps
 //2分音符= bps*2

localparam bps = 50_000_000 / Nowbpm * 60;
reg [31:0] val = 0;

// ===== 指针推进 =====
reg [31:0] cnt_t;
always @(posedge clk or negedge resetIdx) begin
	
	if(!resetIdx) begin
		idx <= 8'd0;
		cnt_t <= 0;
		finish <= 0;
	end
	else if(enable && !finish)begin
		cnt_t <= cnt_t + 1;
		
		if(cnt_t >= val - 1) begin
			
			cnt_t <= 0;
			if(idx == length) begin
				finish <= 1;
			end
			else
				idx <= idx + 1'b1;
		end
    end
end

initial begin
	//bps = 50_000_000 / Nowbpm * 60;
end
assign bpm = Nowbpm;

// ===== 输出当前音符 =====
always @(*) begin
   tone     = finish ? 26'd0 : tones[idx];
   toneTime = ttime[idx];
	
	case(ttime[idx])
		1:val=bps*4;
		2:val=bps*2;
		4:val=bps;
		8:val=bps/2;
		16:val=bps/4;
		default:val=bps;
	endcase 
end

initial begin
    tones[0]  = DO      ;  ttime[0]  = 5'd8;
    tones[1]  = SOL     ;  ttime[1]  = 5'd8;
    tones[2]  = HDO     ;  ttime[2]  = 5'd16;
    tones[3]  = XI      ;  ttime[3]  = 5'd16;
    tones[4]  = LA      ;  ttime[4]  = 5'd16;
    tones[5]  = SOL     ;  ttime[5]  = 5'd16;
    tones[6]  = SOL     ;  ttime[6]  = 5'd8;
    tones[7]  = SOL     ;  ttime[7]  = 5'd16;
    tones[8]  = MI      ;  ttime[8]  = 5'd16;
    tones[9]  = SOL     ;  ttime[9]  = 5'd8;
    tones[10] = MI      ;  ttime[10] = 5'd8;
    tones[11] = RE      ;  ttime[11] = 5'd8;
    tones[12] = FA      ;  ttime[12] = 5'd8;
    tones[13] = HDO     ;  ttime[13] = 5'd4;
    tones[14] = HDO     ;  ttime[14] = 5'd4;
    tones[15] = HDO     ;  ttime[15] = 5'd4;
    tones[16] = DO      ;  ttime[16] = 5'd8;
    tones[17] = SOL     ;  ttime[17] = 5'd8;
    tones[18] = HDO     ;  ttime[18] = 5'd16;
    tones[19] = XI      ;  ttime[19] = 5'd16;
    tones[20] = LA      ;  ttime[20] = 5'd16;
    tones[21] = SOL     ;  ttime[21] = 5'd16;
    tones[22] = SOL     ;  ttime[22] = 5'd8;
    tones[23] = SOL     ;  ttime[23] = 5'd16;
    tones[24] = MI      ;  ttime[24] = 5'd16;
    tones[25] = SOL     ;  ttime[25] = 5'd8;
    tones[26] = MI      ;  ttime[26] = 5'd8;
    tones[27] = RE      ;  ttime[27] = 5'd8;
    tones[28] = FA      ;  ttime[28] = 5'd8;
    tones[29] = HMI     ;  ttime[29] = 5'd8;
    tones[30] = HRE     ;  ttime[30] = 5'd8;
    tones[31] = HRE     ;  ttime[31] = 5'd4;
    tones[32] = HRE     ;  ttime[32] = 5'd4;
    tones[33] = HRE     ;  ttime[33] = 5'd4;
    tones[34] = HRE     ;  ttime[34] = 5'd4;
    tones[35] = REST    ;  ttime[35] = 5'd8;
    tones[36] = REST    ;  ttime[36] = 5'd16;
    tones[37] = MI      ;  ttime[37] = 5'd16;
    tones[38] = MI      ;  ttime[38] = 5'd8;
    tones[39] = LLA     ;  ttime[39] = 5'd16;
    tones[40] = DO      ;  ttime[40] = 5'd16;
    tones[41] = DO      ;  ttime[41] = 5'd16;
    tones[42] = DO      ;  ttime[42] = 5'd16;
    tones[43] = DO      ;  ttime[43] = 5'd16;
    tones[44] = RE      ;  ttime[44] = 5'd16;
    tones[45] = RE      ;  ttime[45] = 5'd16;
    tones[46] = LLA     ;  ttime[46] = 5'd16;
    tones[47] = LSOL    ;  ttime[47] = 5'd16;
    tones[48] = LMI     ;  ttime[48] = 5'd16;
    tones[49] = LSOL    ;  ttime[49] = 5'd8;
    tones[50] = LMI     ;  ttime[50] = 5'd16;
    tones[51] = LSOL    ;  ttime[51] = 5'd16;
    tones[52] = LSOL    ;  ttime[52] = 5'd16;
    tones[53] = RE      ;  ttime[53] = 5'd8;
    tones[54] = RE      ;  ttime[54] = 5'd16;
    tones[55] = LXI     ;  ttime[55] = 5'd4;
    tones[56] = LSOL    ;  ttime[56] = 5'd16;
    tones[57] = LLA     ;  ttime[57] = 5'd16;
    tones[58] = LXI     ;  ttime[58] = 5'd16;
    tones[59] = LXI     ;  ttime[59] = 5'd16;
    tones[60] = LXI     ;  ttime[60] = 5'd16;
    tones[61] = DO      ;  ttime[61] = 5'd16;
    tones[62] = DO      ;  ttime[62] = 5'd16;
    tones[63] = DO      ;  ttime[63] = 5'd16;
    tones[64] = RE      ;  ttime[64] = 5'd8;
    tones[65] = LLA     ;  ttime[65] = 5'd8;
    tones[66] = LLA     ;  ttime[66] = 5'd4;
    tones[67] = LSOL    ;  ttime[67] = 5'd12;
    tones[68] = LLA     ;  ttime[68] = 5'd12;
    tones[69] = LMI     ;  ttime[69] = 5'd12;
    tones[70] = RE      ;  ttime[70] = 5'd4;
    tones[71] = RE      ;  ttime[71] = 5'd4;
    tones[72] = REST    ;  ttime[72] = 5'd4;
    tones[73] = REST    ;  ttime[73] = 5'd4;
    tones[74] = REST    ;  ttime[74] = 5'd8;
    tones[75] = MI      ;  ttime[75] = 5'd16;
    tones[76] = MI      ;  ttime[76] = 5'd16;
    tones[77] = MI      ;  ttime[77] = 5'd8;
    tones[78] = LLA     ;  ttime[78] = 5'd16;
    tones[79] = DO      ;  ttime[79] = 5'd16;
    tones[80] = DO      ;  ttime[80] = 5'd16;
    tones[81] = DO      ;  ttime[81] = 5'd16;
    tones[82] = DO      ;  ttime[82] = 5'd16;
    tones[83] = RE      ;  ttime[83] = 5'd16;
    tones[84] = RE      ;  ttime[84] = 5'd16;
    tones[85] = LLA     ;  ttime[85] = 5'd16;
    tones[86] = LSOL    ;  ttime[86] = 5'd16;
    tones[87] = LMI     ;  ttime[87] = 5'd16;
    tones[88] = LSOL    ;  ttime[88] = 5'd8;
    tones[89] = LMI     ;  ttime[89] = 5'd16;
    tones[90] = LSOL    ;  ttime[90] = 5'd16;
    tones[91] = LSOL    ;  ttime[91] = 5'd16;
    tones[92] = RE      ;  ttime[92] = 5'd8;
    tones[93] = RE      ;  ttime[93] = 5'd16;
    tones[94] = LXI     ;  ttime[94] = 5'd4;
    tones[95] = LSOL    ;  ttime[95] = 5'd16;
    tones[96] = LLA     ;  ttime[96] = 5'd16;
    tones[97] = LXI     ;  ttime[97] = 5'd16;
    tones[98] = LXI     ;  ttime[98] = 5'd16;
    tones[99] = LXI     ;  ttime[99] = 5'd16;
    tones[100]= DO      ;  ttime[100]= 5'd16;
    tones[101]= DO      ;  ttime[101]= 5'd16;
    tones[102]= DO      ;  ttime[102]= 5'd16;
    tones[103]= RE      ;  ttime[103]= 5'd8;
    tones[104]= LLA     ;  ttime[104]= 5'd8;
    tones[105]= LLA     ;  ttime[105]= 5'd4;
    tones[106]= MI      ;  ttime[106]= 5'd16;
    tones[107]= RE      ;  ttime[107]= 5'd16;
    tones[108]= DO      ;  ttime[108]= 5'd16;
    tones[109]= LLA     ;  ttime[109]= 5'd16;
    tones[110]= DO      ;  ttime[110]= 5'd4;
    tones[111]= DO      ;  ttime[111]= 5'd16;
    tones[112]= B_MI    ;  ttime[112]= 5'd8;
    tones[113]= B_MI    ;  ttime[113]= 5'd16;
    tones[114]= RE      ;  ttime[114]= 5'd8;
    tones[115]= DO      ;  ttime[115]= 5'd4;
    tones[116]= REST    ;  ttime[116]= 5'd16;
    tones[117]= DO      ;  ttime[117]= 5'd16;
    tones[118]= SOL     ;  ttime[118]= 5'd4;
    tones[119]= SOL     ;  ttime[119]= 5'd8;
    tones[120]= RE      ;  ttime[120]= 5'd8;
    tones[121]= DO      ;  ttime[121]= 5'd4;
    tones[122]= RE      ;  ttime[122]= 5'd16;
    tones[123]= DO      ;  ttime[123]= 5'd16;
    tones[124]= XI      ;  ttime[124]= 5'd16;
    tones[125]= DO      ;  ttime[125]= 5'd16;
    tones[126]= SOL     ;  ttime[126]= 5'd4;
    tones[127]= SOL     ;  ttime[127]= 5'd8;
    tones[128]= LXI     ;  ttime[128]= 5'd8;
    tones[129]= LXI     ;  ttime[129]= 5'd8;
    tones[130]= REST    ;  ttime[130]= 5'd4;
    tones[131]= SOL     ;  ttime[131]= 5'd16;
    tones[132]= LA      ;  ttime[132]= 5'd16;
    tones[133]= SOL     ;  ttime[133]= 5'd4;
    tones[134]= SOL     ;  ttime[134]= 5'd8;
    tones[135]= LA      ;  ttime[135]= 5'd16;
    tones[136]= SOL     ;  ttime[136]= 5'd16;
    tones[137]= SOL     ;  ttime[137]= 5'd8;
    tones[138]= SOL     ;  ttime[138]= 5'd16;
    tones[139]= LA      ;  ttime[139]= 5'd16;
    tones[140]= LLA     ;  ttime[140]= 5'd16;
    tones[141]= MI      ;  ttime[141]= 5'd16;
    tones[142]= MI      ;  ttime[142]= 5'd16;
    tones[143]= FA      ;  ttime[143]= 5'd16;
    tones[144]= FA      ;  ttime[144]= 5'd16;
    tones[145]= FA      ;  ttime[145]= 5'd16;
    tones[146]= FA      ;  ttime[146]= 5'd16;
    tones[147]= FA      ;  ttime[147]= 5'd16;
    tones[148]= FA      ;  ttime[148]= 5'd8;
    tones[149]= LLA     ;  ttime[149]= 5'd16;
    tones[150]= SOL     ;  ttime[150]= 5'd16;
    tones[151]= SOL     ;  ttime[151]= 5'd16;
    tones[152]= FA      ;  ttime[152]= 5'd16;
    tones[153]= FA      ;  ttime[153]= 5'd8;
    tones[154]= FA      ;  ttime[154]= 5'd4;
    tones[155]= REST    ;  ttime[155]= 5'd8;
    tones[156]= FA      ;  ttime[156]= 5'd8;
    tones[157]= FA      ;  ttime[157]= 5'd8;
    tones[158]= B_LLA   ;  ttime[158]= 5'd16;
    tones[159]= SOL     ;  ttime[159]= 5'd16;
    tones[160]= SOL     ;  ttime[160]= 5'd16;
    tones[161]= FA      ;  ttime[161]= 5'd16;
    tones[162]= FA      ;  ttime[162]= 5'd8;
    tones[163]= DO      ;  ttime[163]= 5'd8;
    tones[164]= RE      ;  ttime[164]= 5'd8;
    tones[165]= MI      ;  ttime[165]= 5'd8;
    tones[166]= SOL     ;  ttime[166]= 5'd16;
    tones[167]= SOL     ;  ttime[167]= 5'd16;
    tones[168]= SOL     ;  ttime[168]= 5'd8;
    tones[169]= SOL     ;  ttime[169]= 5'd16;
    tones[170]= SOL     ;  ttime[170]= 5'd16;
    tones[171]= RE      ;  ttime[171]= 5'd8;
    tones[172]= MI      ;  ttime[172]= 5'd16;
    tones[173]= DO      ;  ttime[173]= 5'd16;
    tones[174]= DO      ;  ttime[174]= 5'd16;
    tones[175]= RE      ;  ttime[175]= 5'd16;
    tones[176]= MI      ;  ttime[176]= 5'd16;
    tones[177]= LLA     ;  ttime[177]= 5'd16;
    tones[178]= DO      ;  ttime[178]= 5'd4;
    tones[179]= DO      ;  ttime[179]= 5'd16;
    tones[180]= RE      ;  ttime[180]= 5'd16;
    tones[181]= MI      ;  ttime[181]= 5'd16;
    tones[182]= LLA     ;  ttime[182]= 5'd16;
    tones[183]= DO      ;  ttime[183]= 5'd4;
    tones[184]= DO      ;  ttime[184]= 5'd16;
    tones[185]= RE      ;  ttime[185]= 5'd16;
    tones[186]= MI      ;  ttime[186]= 5'd16;
    tones[187]= LLA     ;  ttime[187]= 5'd16;
    tones[188]= DO      ;  ttime[188]= 5'd8;
    tones[189]= RE      ;  ttime[189]= 5'd16;
    tones[190]= DO      ;  ttime[190]= 5'd16;
    tones[191]= DO      ;  ttime[191]= 5'd8;
    tones[192]= RE      ;  ttime[192]= 5'd16;
    tones[193]= DO      ;  ttime[193]= 5'd16;
    tones[194]= RE      ;  ttime[194]= 5'd16;
    tones[195]= DO      ;  ttime[195]= 5'd8;
    tones[196]= DO      ;  ttime[196]= 5'd16;
    tones[197]= DO      ;  ttime[197]= 5'd8;
    tones[198]= RE      ;  ttime[198]= 5'd8;
    tones[199]= SOL     ;  ttime[199]= 5'd4;
    tones[200]= SOL     ;  ttime[200]= 5'd8;
    tones[201]= RE      ;  ttime[201]= 5'd16;
    tones[202]= DO      ;  ttime[202]= 5'd16;
    tones[203]= DO      ;  ttime[203]= 5'd4;
    tones[204]= RE      ;  ttime[204]= 5'd16;
    tones[205]= DO      ;  ttime[205]= 5'd16;
    tones[206]= LXI     ;  ttime[206]= 5'd16;
    tones[207]= LA      ;  ttime[207]= 5'd16;
    tones[208]= LA      ;  ttime[208]= 5'd16;
    tones[209]= SOL     ;  ttime[209]= 5'd8;
    tones[210]= SOL     ;  ttime[210]= 5'd16;
    tones[211]= SOL     ;  ttime[211]= 5'd8;
    tones[212]= LA      ;  ttime[212]= 5'd16;
    tones[213]= SOL     ;  ttime[213]= 5'd16;
    tones[214]= LXI     ;  ttime[214]= 5'd16;
    tones[215]= LXI     ;  ttime[215]= 5'd8;
    tones[216]= LXI     ;  ttime[216]= 5'd16;
    tones[217]= REST    ;  ttime[217]= 5'd8;
    tones[218]= SOL     ;  ttime[218]= 5'd16;
    tones[219]= LA      ;  ttime[219]= 5'd16;
    tones[220]= SOL     ;  ttime[220]= 5'd4;
    tones[221]= SOL     ;  ttime[221]= 5'd8;
    tones[222]= LA      ;  ttime[222]= 5'd16;
    tones[223]= SOL     ;  ttime[223]= 5'd16;
    tones[224]= SOL     ;  ttime[224]= 5'd8;
    tones[225]= SOL     ;  ttime[225]= 5'd16;
    tones[226]= LA      ;  ttime[226]= 5'd16;
    tones[227]= LLA     ;  ttime[227]= 5'd16;
    tones[228]= MI      ;  ttime[228]= 5'd16;
    tones[229]= MI      ;  ttime[229]= 5'd16;
    tones[230]= FA      ;  ttime[230]= 5'd16;
    tones[231]= FA      ;  ttime[231]= 5'd16;
    tones[232]= FA      ;  ttime[232]= 5'd16;
    tones[233]= FA      ;  ttime[233]= 5'd16;
    tones[234]= FA      ;  ttime[234]= 5'd16;
    tones[235]= FA      ;  ttime[235]= 5'd8;
    tones[236]= LLA     ;  ttime[236]= 5'd8;
    tones[237]= SOL     ;  ttime[237]= 5'd8;
    tones[238]= FA      ;  ttime[238]= 5'd4;
    tones[239]= FA      ;  ttime[239]= 5'd8;
    tones[240]= REST    ;  ttime[240]= 5'd8;
    tones[241]= FA      ;  ttime[241]= 5'd8;
    tones[242]= FA      ;  ttime[242]= 5'd8;
    tones[243]= B_LLA   ;  ttime[243]= 5'd16;
    tones[244]= SOL     ;  ttime[244]= 5'd16;
    tones[245]= SOL     ;  ttime[245]= 5'd16;
    tones[246]= FA      ;  ttime[246]= 5'd16;
    tones[247]= FA      ;  ttime[247]= 5'd8;
    tones[248]= DO      ;  ttime[248]= 5'd8;
    tones[249]= RE      ;  ttime[249]= 5'd8;
    tones[250]= MI      ;  ttime[250]= 5'd8;
    tones[251]= SOL     ;  ttime[251]= 5'd16;
    tones[252]= SOL     ;  ttime[252]= 5'd16;
    tones[253]= SOL     ;  ttime[253]= 5'd8;
    tones[254]= SOL     ;  ttime[254]= 5'd16;
    tones[255]= SOL     ;  ttime[255]= 5'd16;
    tones[256]= RE      ;  ttime[256]= 5'd8;
    tones[257]= MI      ;  ttime[257]= 5'd16;
    tones[258]= DO      ;  ttime[258]= 5'd16;
    tones[259]= DO      ;  ttime[259]= 5'd16;
    tones[260]= RE      ;  ttime[260]= 5'd16;
    tones[261]= MI      ;  ttime[261]= 5'd16;
    tones[262]= LLA     ;  ttime[262]= 5'd16;
    tones[263]= LLA     ;  ttime[263]= 5'd8;
    tones[264]= DO      ;  ttime[264]= 5'd8;
    tones[265]= DO      ;  ttime[265]= 5'd4;
    tones[266]= REST    ;  ttime[266]= 5'd4;
    tones[267]= DO      ;  ttime[267]= 5'd16;
    tones[268]= RE      ;  ttime[268]= 5'd16;
    tones[269]= MI      ;  ttime[269]= 5'd8;
    tones[270]= REST    ;  ttime[270]= 5'd8;
    tones[271]= SOL     ;  ttime[271]= 5'd8;
    tones[272]= DO      ;  ttime[272]= 5'd8;
    tones[273]= RE      ;  ttime[273]= 5'd16;
    tones[274]= DO      ;  ttime[274]= 5'd16;
    tones[275]= DO      ;  ttime[275]= 5'd8;
    tones[276]= SOL     ;  ttime[276]= 5'd8;
    tones[277]= HDO     ;  ttime[277]= 5'd16;
    tones[278]= XI      ;  ttime[278]= 5'd16;
    tones[279]= LA      ;  ttime[279]= 5'd16;
    tones[280]= SOL     ;  ttime[280]= 5'd16;
    tones[281]= SOL     ;  ttime[281]= 5'd8;
    tones[282]= SOL     ;  ttime[282]= 5'd16;
    tones[283]= MI      ;  ttime[283]= 5'd16;
    tones[284]= SOL     ;  ttime[284]= 5'd8;
    tones[285]= MI      ;  ttime[285]= 5'd8;
    tones[286]= RE      ;  ttime[286]= 5'd8;
    tones[287]= FA      ;  ttime[287]= 5'd8;
    tones[288]= HDO     ;  ttime[288]= 5'd4;
    tones[289]= HDO     ;  ttime[289]= 5'd4;
    tones[290]= HDO     ;  ttime[290]= 5'd4;
    tones[291]= DO      ;  ttime[291]= 5'd8;
    tones[292]= SOL     ;  ttime[292]= 5'd8;
    tones[293]= HDO     ;  ttime[293]= 5'd16;
    tones[294]= XI      ;  ttime[294]= 5'd16;
    tones[295]= LA      ;  ttime[295]= 5'd16;
    tones[296]= SOL     ;  ttime[296]= 5'd16;
    tones[297]= SOL     ;  ttime[297]= 5'd8;
    tones[298]= SOL     ;  ttime[298]= 5'd16;
    tones[299]= MI      ;  ttime[299]= 5'd16;
    tones[300]= SOL     ;  ttime[300]= 5'd8;
    tones[301]= MI      ;  ttime[301]= 5'd8;
    tones[302]= RE      ;  ttime[302]= 5'd8;
    tones[303]= FA      ;  ttime[303]= 5'd8;
    tones[304]= HMI     ;  ttime[304]= 5'd8;
    tones[305]= HRE     ;  ttime[305]= 5'd8;
    tones[306]= HRE     ;  ttime[306]= 5'd4;
    tones[307]= HRE     ;  ttime[307]= 5'd4;
    tones[308]= HRE     ;  ttime[308]= 5'd4;
    tones[309]= HRE     ;  ttime[309]= 5'd4;
    tones[310]= REST    ;  ttime[310]= 5'd16;
    tones[311]= SOL     ;  ttime[311]= 5'd8;
    tones[312]= RE      ;  ttime[312]= 5'd16;
    tones[313]= RE      ;  ttime[313]= 5'd8;
    tones[314]= MI      ;  ttime[314]= 5'd16;
    tones[315]= RE      ;  ttime[315]= 5'd16;
    tones[316]= DO      ;  ttime[316]= 5'd4;
    tones[317]= MI      ;  ttime[317]= 5'd8;
    tones[318]= RE      ;  ttime[318]= 5'd16;
    tones[319]= DO      ;  ttime[319]= 5'd16;
    tones[320]= XI      ;  ttime[320]= 5'd8;
    tones[321]= MI      ;  ttime[321]= 5'd16;
    tones[322]= MI      ;  ttime[322]= 5'd16;
    tones[323]= MI      ;  ttime[323]= 5'd8;
    tones[324]= MI      ;  ttime[324]= 5'd16;
    tones[325]= MI      ;  ttime[325]= 5'd16;
    tones[326]= FA      ;  ttime[326]= 5'd8;
    tones[327]= FA      ;  ttime[327]= 5'd16;
    tones[328]= MI      ;  ttime[328]= 5'd16;
    tones[329]= MI      ;  ttime[329]= 5'd8;
    tones[330]= MI      ;  ttime[330]= 5'd16;
    tones[331]= MI      ;  ttime[331]= 5'd16;
    tones[332]= RE      ;  ttime[332]= 5'd16;
    tones[333]= MI      ;  ttime[333]= 5'd16;
    tones[334]= RE      ;  ttime[334]= 5'd16;
    tones[335]= DO      ;  ttime[335]= 5'd16;
    tones[336]= DO      ;  ttime[336]= 5'd8;
    tones[337]= RE      ;  ttime[337]= 5'd16;
    tones[338]= MI      ;  ttime[338]= 5'd16;
    tones[339]= RE      ;  ttime[339]= 5'd16;
    tones[340]= DO      ;  ttime[340]= 5'd8;
    tones[341]= RE      ;  ttime[341]= 5'd16;
    tones[342]= RE      ;  ttime[342]= 5'd16;
    tones[343]= DO      ;  ttime[343]= 5'd16;
    tones[344]= XI      ;  ttime[344]= 5'd16;
    tones[345]= LLA     ;  ttime[345]= 5'd16;
    tones[346]= XI      ;  ttime[346]= 5'd8;
    tones[347]= MI      ;  ttime[347]= 5'd16;
    tones[348]= MI      ;  ttime[348]= 5'd16;
    tones[349]= MI      ;  ttime[349]= 5'd8;
    tones[350]= MI      ;  ttime[350]= 5'd16;
    tones[351]= MI      ;  ttime[351]= 5'd16;
    tones[352]= FA      ;  ttime[352]= 5'd8;
    tones[353]= SOL     ;  ttime[353]= 5'd16;
    tones[354]= MI      ;  ttime[354]= 5'd16;
    tones[355]= MI      ;  ttime[355]= 5'd8;
    tones[356]= MI      ;  ttime[356]= 5'd16;
    tones[357]= MI      ;  ttime[357]= 5'd16;
    tones[358]= RE      ;  ttime[358]= 5'd16;
    tones[359]= MI      ;  ttime[359]= 5'd16;
    tones[360]= RE      ;  ttime[360]= 5'd16;
    tones[361]= DO      ;  ttime[361]= 5'd16;
    tones[362]= DO      ;  ttime[362]= 5'd8;
    tones[363]= RE      ;  ttime[363]= 5'd16;
    tones[364]= MI      ;  ttime[364]= 5'd16;
    tones[365]= RE      ;  ttime[365]= 5'd16;
    tones[366]= DO      ;  ttime[366]= 5'd8;
    tones[367]= DO      ;  ttime[367]= 5'd16;
    tones[368]= RE      ;  ttime[368]= 5'd16;
    tones[369]= DO      ;  ttime[369]= 5'd16;
    tones[370]= XI      ;  ttime[370]= 5'd16;
    tones[371]= DO      ;  ttime[371]= 5'd16;
    tones[372]= LLA     ;  ttime[372]= 5'd4;
    tones[373]= RE      ;  ttime[373]= 5'd4;
    tones[374]= SHARP_FA;  ttime[374]= 5'd8;
    tones[375]= SHARP_FA;  ttime[375]= 5'd16;
    tones[376]= RE      ;  ttime[376]= 5'd16;
    tones[377]= RE      ;  ttime[377]= 5'd4;
    tones[378]= DO      ;  ttime[378]= 5'd4;
    tones[379]= FA      ;  ttime[379]= 5'd4;
    tones[380]= B_LLA   ;  ttime[380]= 5'd8;
    tones[381]= SOL     ;  ttime[381]= 5'd8;
    tones[382]= DO      ;  ttime[382]= 5'd8;
    tones[383]= RE      ;  ttime[383]= 5'd16;
    tones[384]= SOL     ;  ttime[384]= 5'd16;
    tones[385]= REST    ;  ttime[385]= 5'd8;
    tones[386]= LSOL    ;  ttime[386]= 5'd8;
    tones[387]= DO      ;  ttime[387]= 5'd8;
    tones[388]= RE      ;  ttime[388]= 5'd16;
    tones[389]= DO      ;  ttime[389]= 5'd16;
    tones[390]= DO      ;  ttime[390]= 5'd4;
    tones[391]= DO      ;  ttime[391]= 5'd4;
    tones[392]= REST    ;  ttime[392]= 5'd4;
    tones[393]= REST    ;  ttime[393]= 5'd4;
    tones[394]= REST    ;  ttime[394]= 5'd4;
    tones[395]= REST    ;  ttime[395]= 5'd4;
    tones[396]= REST    ;  ttime[396]= 5'd4;
    tones[397]= REST    ;  ttime[397]= 5'd4;
    tones[398]= REST    ;  ttime[398]= 5'd4;
    tones[399]= REST    ;  ttime[399]= 5'd4;
    tones[400]= REST    ;  ttime[400]= 5'd4;
    tones[401]= REST    ;  ttime[401]= 5'd4;
    tones[402]= REST    ;  ttime[402]= 5'd4;
    tones[403]= REST    ;  ttime[403]= 5'd4;
end


endmodule