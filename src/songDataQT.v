module songDataQT(
input wire clk,
input wire resetIdx,
input wire nextFlag, 
output reg [25:0]tone,
output reg [4:0] toneTime,
output reg [31:0]toneCnt,
output wire [7:0]bpm,
output reg finish
);

(* ramstyle = "M9K" *)reg [18:0] tones [0:336];
(* ramstyle = "M9K" *)reg [4:0] ttime [0:336];

reg [8:0] idx; // 0~511

localparam length = 336;

// ===== 音符定义（周期） =====
localparam REST=0;
localparam LLXI=4048 * 50;
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
localparam SHARP_SOL = 1203 * 50;
localparam LA = 1136 * 50;
localparam XI = 1012 * 50;
localparam HDO= 955  * 50;
localparam HRE= 851  * 50;
localparam HMI= 758  * 50;
localparam HFA= 716  * 50;
localparam HSOL=637  * 50;
localparam HLA= 568  * 50;
localparam HXI= 508  * 50;

// ===== 默认速度 =====
localparam Nowbpm = 8'd67;
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
	else if(nextFlag)begin
		if(idx == length) begin
			finish <= 1;
		end
		else
			idx <= idx + 1'b1;
    end
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
	toneCnt = val;
end

initial begin
    tones[ 0 ]  = LLA      ;  ttime[ 0 ]  = 5 'd8 ;
    tones[ 1 ]  = DO       ;  ttime[ 1 ]  = 5 'd8 ;
    tones[ 2 ]  = SOL      ;  ttime[ 2 ]  = 5 'd8 ;
    tones[ 3 ]  = DO       ;  ttime[ 3 ]  = 5 'd8 ;
    tones[ 4 ]  = LFA      ;  ttime[ 4 ]  = 5 'd8 ;
    tones[ 5 ]  = LSOL     ;  ttime[ 5 ]  = 5 'd16 ;
    tones[ 6 ]  = LLA      ;  ttime[ 6 ]  = 5 'd16 ;
    tones[ 7 ]  = SOL      ;  ttime[ 7 ]  = 5 'd8 ;
    tones[ 8 ]  = DO       ;  ttime[ 8 ]  = 5 'd8 ;
    tones[ 9 ]  = LDO      ;  ttime[ 9 ]  = 5 'd8 ;
    tones[ 10 ] = LSOL     ;  ttime[ 10 ] = 5 'd8 ;
    tones[ 11 ] = SOL      ;  ttime[ 11 ] = 5 'd8 ;
    tones[ 12 ] = DO       ;  ttime[ 12 ] = 5 'd8 ;
    tones[ 13 ] = LDO      ;  ttime[ 13 ] = 5 'd8 ;
    tones[ 14 ] = SOL      ;  ttime[ 14 ] = 5 'd8 ;
    tones[ 15 ] = LLXI     ;  ttime[ 15 ] = 5 'd8 ;
    tones[ 16 ] = SOL      ;  ttime[ 16 ] = 5 'd8 ;
    tones[ 17 ] = LLA      ;  ttime[ 17 ] = 5 'd8 ;
    tones[ 18 ] = DO       ;  ttime[ 18 ] = 5 'd8 ;
    tones[ 19 ] = SOL      ;  ttime[ 19 ] = 5 'd8 ;
    tones[ 20 ] = LLA      ;  ttime[ 20 ] = 5 'd8 ;
    tones[ 21 ] = LFA      ;  ttime[ 21 ] = 5 'd8 ;
    tones[ 22 ] = LSOL     ;  ttime[ 22 ] = 5 'd16 ;
    tones[ 23 ] = LLA      ;  ttime[ 23 ] = 5 'd16 ;
    tones[ 24 ] = SOL      ;  ttime[ 24 ] = 5 'd8 ;
    tones[ 25 ] = DO       ;  ttime[ 25 ] = 5 'd8 ;
    tones[ 26 ] = LDO      ;  ttime[ 26 ] = 5 'd8 ;
    tones[ 27 ] = LSOL     ;  ttime[ 27 ] = 5 'd8 ;
    tones[ 28 ] = SOL      ;  ttime[ 28 ] = 5 'd8 ;
    tones[ 29 ] = DO       ;  ttime[ 29 ] = 5 'd8 ;
    tones[ 30 ] = LDO      ;  ttime[ 30 ] = 5 'd8 ;
    tones[ 31 ] = SOL      ;  ttime[ 31 ] = 5 'd8 ;
    tones[ 32 ] = LLXI     ;  ttime[ 32 ] = 5 'd16 ;
    tones[ 33 ] = DO       ;  ttime[ 33 ] = 5 'd16 ;
    tones[ 34 ] = SOL      ;  ttime[ 34 ] = 5 'd8 ;
    tones[ 35 ] = LLA      ;  ttime[ 35 ] = 5 'd8 ;
    tones[ 36 ] = DO       ;  ttime[ 36 ] = 5 'd8 ;
    tones[ 37 ] = SOL      ;  ttime[ 37 ] = 5 'd8 ;
    tones[ 38 ] = DO       ;  ttime[ 38 ] = 5 'd8 ;
    tones[ 39 ] = LFA      ;  ttime[ 39 ] = 5 'd8 ;
    tones[ 40 ] = LSOL     ;  ttime[ 40 ] = 5 'd16 ;
    tones[ 41 ] = LLA      ;  ttime[ 41 ] = 5 'd16 ;
    tones[ 42 ] = SOL      ;  ttime[ 42 ] = 5 'd8 ;
    tones[ 43 ] = DO       ;  ttime[ 43 ] = 5 'd8 ;
    tones[ 44 ] = LDO      ;  ttime[ 44 ] = 5 'd8 ;
    tones[ 45 ] = LSOL     ;  ttime[ 45 ] = 5 'd8 ;
    tones[ 46 ] = SOL      ;  ttime[ 46 ] = 5 'd8 ;
    tones[ 47 ] = DO       ;  ttime[ 47 ] = 5 'd8 ;
    tones[ 48 ] = LDO      ;  ttime[ 48 ] = 5 'd8 ;
    tones[ 49 ] = SOL      ;  ttime[ 49 ] = 5 'd8 ;
    tones[ 50 ] = LLXI     ;  ttime[ 50 ] = 5 'd8 ;
    tones[ 51 ] = SOL      ;  ttime[ 51 ] = 5 'd8 ;
    tones[ 52 ] = LLA      ;  ttime[ 52 ] = 5 'd8 ;
    tones[ 53 ] = DO       ;  ttime[ 53 ] = 5 'd8 ;
    tones[ 54 ] = SOL      ;  ttime[ 54 ] = 5 'd8 ;
    tones[ 55 ] = LLA      ;  ttime[ 55 ] = 5 'd8 ;
    tones[ 56 ] = LFA      ;  ttime[ 56 ] = 5 'd8 ;
    tones[ 57 ] = LSOL     ;  ttime[ 57 ] = 5 'd16 ;
    tones[ 58 ] = LLA      ;  ttime[ 58 ] = 5 'd16 ;
    tones[ 59 ] = SOL      ;  ttime[ 59 ] = 5 'd8 ;
    tones[ 60 ] = DO       ;  ttime[ 60 ] = 5 'd8 ;
    tones[ 61 ] = LDO      ;  ttime[ 61 ] = 5 'd8 ;
    tones[ 62 ] = LSOL     ;  ttime[ 62 ] = 5 'd8 ;
    tones[ 63 ] = SOL      ;  ttime[ 63 ] = 5 'd8 ;
    tones[ 64 ] = DO       ;  ttime[ 64 ] = 5 'd8 ;
    tones[ 65 ] = LDO      ;  ttime[ 65 ] = 5 'd8 ;
    tones[ 66 ] = SOL      ;  ttime[ 66 ] = 5 'd8 ;
    tones[ 67 ] = LLXI     ;  ttime[ 67 ] = 5 'd16 ;
    tones[ 68 ] = DO       ;  ttime[ 68 ] = 5 'd16 ;
    tones[ 69 ] = SOL      ;  ttime[ 69 ] = 5 'd8 ;
    tones[ 70 ] = REST     ;  ttime[ 70 ] = 5 'd8 ;
    tones[ 71 ] = SOL      ;  ttime[ 71 ] = 5 'd8 ;
    tones[ 72 ] = SOL      ;  ttime[ 72 ] = 5 'd8 ;
    tones[ 73 ] = DO       ;  ttime[ 73 ] = 5 'd8 ;
    tones[ 74 ] = DO       ;  ttime[ 74 ] = 5 'd4 ;
    tones[ 75 ] = RE       ;  ttime[ 75 ] = 5 'd8 ;
    tones[ 76 ] = MI       ;  ttime[ 76 ] = 5 'd8 ;
    tones[ 77 ] = REST     ;  ttime[ 77 ] = 5 'd8 ;
    tones[ 78 ] = SOL      ;  ttime[ 78 ] = 5 'd8 ;
    tones[ 79 ] = SOL      ;  ttime[ 79 ] = 5 'd8 ;
    tones[ 80 ] = DO       ;  ttime[ 80 ] = 5 'd8 ;
    tones[ 81 ] = DO       ;  ttime[ 81 ] = 5 'd8 ;
    tones[ 82 ] = RE       ;  ttime[ 82 ] = 5 'd16 ;
    tones[ 83 ] = MI       ;  ttime[ 83 ] = 5 'd16 ;
    tones[ 84 ] = RE       ;  ttime[ 84 ] = 5 'd16 ;
    tones[ 85 ] = DO       ;  ttime[ 85 ] = 5 'd16 ;
    tones[ 86 ] = LSOL     ;  ttime[ 86 ] = 5 'd8 ;
    tones[ 87 ] = REST     ;  ttime[ 87 ] = 5 'd8 ;
    tones[ 88 ] = SOL      ;  ttime[ 88 ] = 5 'd8 ;
    tones[ 89 ] = SOL      ;  ttime[ 89 ] = 5 'd8 ;
    tones[ 90 ] = DO       ;  ttime[ 90 ] = 5 'd8 ;
    tones[ 91 ] = DO       ;  ttime[ 91 ] = 5 'd4 ;
    tones[ 92 ] = RE       ;  ttime[ 92 ] = 5 'd8 ;
    tones[ 93 ] = MI       ;  ttime[ 93 ] = 5 'd8 ;
    tones[ 94 ] = REST     ;  ttime[ 94 ] = 5 'd8 ;
    tones[ 95 ] = MI       ;  ttime[ 95 ] = 5 'd4 ;
    tones[ 96 ] = RE       ;  ttime[ 96 ] = 5 'd16 ;
    tones[ 97 ] = MI       ;  ttime[ 97 ] = 5 'd16 ;
    tones[ 98 ] = FA       ;  ttime[ 98 ] = 5 'd16 ;
    tones[ 99 ] = MI       ;  ttime[ 99 ] = 5 'd16 ;
    tones[ 100 ] = RE       ;  ttime[ 100 ] = 5 'd16 ;
    tones[ 101 ] = FA       ;  ttime[ 101 ] = 5 'd16 ;
    tones[ 102 ] = MI       ;  ttime[ 102 ] = 5 'd16 ;
    tones[ 103 ] = RE       ;  ttime[ 103 ] = 5 'd16 ;
    tones[ 104 ] = DO       ;  ttime[ 104 ] = 5 'd8 ;
    tones[ 105 ] = LSOL     ;  ttime[ 105 ] = 5 'd8 ;
    tones[ 106 ] = DO       ;  ttime[ 106 ] = 5 'd8 ;
    tones[ 107 ] = DO       ;  ttime[ 107 ] = 5 'd8 ;
    tones[ 108 ] = MI       ;  ttime[ 108 ] = 5 'd8 ;
    tones[ 109 ] = FA       ;  ttime[ 109 ] = 5 'd8 ;
    tones[ 110 ] = MI       ;  ttime[ 110 ] = 5 'd8 ;
    tones[ 111 ] = RE       ;  ttime[ 111 ] = 5 'd8 ;
    tones[ 112 ] = DO       ;  ttime[ 112 ] = 5 'd16 ;
    tones[ 113 ] = RE       ;  ttime[ 113 ] = 5 'd16 ;
    tones[ 114 ] = MI       ;  ttime[ 114 ] = 5 'd8 ;
    tones[ 115 ] = MI       ;  ttime[ 115 ] = 5 'd8 ;
    tones[ 116 ] = MI       ;  ttime[ 116 ] = 5 'd8 ;
    tones[ 117 ] = MI       ;  ttime[ 117 ] = 5 'd8 ;
    tones[ 118 ] = RE       ;  ttime[ 118 ] = 5 'd16 ;
    tones[ 119 ] = MI       ;  ttime[ 119 ] = 5 'd16 ;
    tones[ 120 ] = RE       ;  ttime[ 120 ] = 5 'd8 ;
    tones[ 121 ] = DO       ;  ttime[ 121 ] = 5 'd4 ;
    tones[ 122 ] = LSOL     ;  ttime[ 122 ] = 5 'd8 ;
    tones[ 123 ] = DO       ;  ttime[ 123 ] = 5 'd8 ;
    tones[ 124 ] = RE       ;  ttime[ 124 ] = 5 'd8 ;
    tones[ 125 ] = MI       ;  ttime[ 125 ] = 5 'd8 ;
    tones[ 126 ] = FA       ;  ttime[ 126 ] = 5 'd8 ;
    tones[ 127 ] = MI       ;  ttime[ 127 ] = 5 'd8 ;
    tones[ 128 ] = RE       ;  ttime[ 128 ] = 5 'd8 ;
    tones[ 129 ] = DO       ;  ttime[ 129 ] = 5 'd16 ;
    tones[ 130 ] = RE       ;  ttime[ 130 ] = 5 'd16 ;
    tones[ 131 ] = MI       ;  ttime[ 131 ] = 5 'd8 ;
    tones[ 132 ] = MI       ;  ttime[ 132 ] = 5 'd8 ;
    tones[ 133 ] = MI       ;  ttime[ 133 ] = 5 'd8 ;
    tones[ 134 ] = MI       ;  ttime[ 134 ] = 5 'd8 ;
    tones[ 135 ] = RE       ;  ttime[ 135 ] = 5 'd16 ;
    tones[ 136 ] = MI       ;  ttime[ 136 ] = 5 'd16 ;
    tones[ 137 ] = RE       ;  ttime[ 137 ] = 5 'd8 ;
    tones[ 138 ] = DO       ;  ttime[ 138 ] = 5 'd8 ;
    tones[ 139 ] = DO       ;  ttime[ 139 ] = 5 'd16 ;
    tones[ 140 ] = LXI      ;  ttime[ 140 ] = 5 'd16 ;
    tones[ 141 ] = DO       ;  ttime[ 141 ] = 5 'd16 ;
    tones[ 142 ] = DO       ;  ttime[ 142 ] = 5 'd16 ;
    tones[ 143 ] = DO       ;  ttime[ 143 ] = 5 'd16 ;
    tones[ 144 ] = DO       ;  ttime[ 144 ] = 5 'd16 ;
    tones[ 145 ] = LXI      ;  ttime[ 145 ] = 5 'd16 ;
    tones[ 146 ] = DO       ;  ttime[ 146 ] = 5 'd8 ;
    tones[ 147 ] = DO       ;  ttime[ 147 ] = 5 'd16 ;
    tones[ 148 ] = DO       ;  ttime[ 148 ] = 5 'd16 ;
    tones[ 149 ] = DO       ;  ttime[ 149 ] = 5 'd16 ;
    tones[ 150 ] = DO       ;  ttime[ 150 ] = 5 'd16 ;
    tones[ 151 ] = DO       ;  ttime[ 151 ] = 5 'd16 ;
    tones[ 152 ] = LXI      ;  ttime[ 152 ] = 5 'd16 ;
    tones[ 153 ] = DO       ;  ttime[ 153 ] = 5 'd8 ;
    tones[ 154 ] = DO       ;  ttime[ 154 ] = 5 'd16 ;
    tones[ 155 ] = DO       ;  ttime[ 155 ] = 5 'd16 ;
    tones[ 156 ] = DO       ;  ttime[ 156 ] = 5 'd16 ;
    tones[ 157 ] = DO       ;  ttime[ 157 ] = 5 'd16 ;
    tones[ 158 ] = DO       ;  ttime[ 158 ] = 5 'd16 ;
    tones[ 159 ] = LXI      ;  ttime[ 159 ] = 5 'd16 ;
    tones[ 160 ] = DO       ;  ttime[ 160 ] = 5 'd8 ;
    tones[ 161 ] = DO       ;  ttime[ 161 ] = 5 'd16 ;
    tones[ 162 ] = DO       ;  ttime[ 162 ] = 5 'd16 ;
    tones[ 163 ] = DO       ;  ttime[ 163 ] = 5 'd16 ;
    tones[ 164 ] = DO       ;  ttime[ 164 ] = 5 'd16 ;
    tones[ 165 ] = DO       ;  ttime[ 165 ] = 5 'd16 ;
    tones[ 166 ] = SOL      ;  ttime[ 166 ] = 5 'd16 ;
    tones[ 167 ] = SOL      ;  ttime[ 167 ] = 5 'd8 ;
    tones[ 168 ] = SOL      ;  ttime[ 168 ] = 5 'd16 ;
    tones[ 169 ] = REST     ;  ttime[ 169 ] = 5 'd16 ;
    tones[ 170 ] = SOL      ;  ttime[ 170 ] = 5 'd16 ;
    tones[ 171 ] = SOL      ;  ttime[ 171 ] = 5 'd16 ;
    tones[ 172 ] = SOL      ;  ttime[ 172 ] = 5 'd16 ;
    tones[ 173 ] = SOL      ;  ttime[ 173 ] = 5 'd16 ;
    tones[ 174 ] = SOL      ;  ttime[ 174 ] = 5 'd8 ;
    tones[ 175 ] = SOL      ;  ttime[ 175 ] = 5 'd16 ;
    tones[ 176 ] = SOL      ;  ttime[ 176 ] = 5 'd16 ;
    tones[ 177 ] = SOL      ;  ttime[ 177 ] = 5 'd8 ;
    tones[ 178 ] = SOL      ;  ttime[ 178 ] = 5 'd16 ;
    tones[ 179 ] = SOL      ;  ttime[ 179 ] = 5 'd16 ;
    tones[ 180 ] = FA       ;  ttime[ 180 ] = 5 'd16 ;
    tones[ 181 ] = MI       ;  ttime[ 181 ] = 5 'd16 ;
    tones[ 182 ] = MI       ;  ttime[ 182 ] = 5 'd16 ;
    tones[ 183 ] = MI       ;  ttime[ 183 ] = 5 'd4 ;
    tones[ 184 ] = MI       ;  ttime[ 184 ] = 5 'd4 ;
    tones[ 185 ] = REST     ;  ttime[ 185 ] = 5 'd4 ;
    tones[ 186 ] = DO       ;  ttime[ 186 ] = 5 'd16 ;
    tones[ 187 ] = DO       ;  ttime[ 187 ] = 5 'd16 ;
    tones[ 188 ] = DO       ;  ttime[ 188 ] = 5 'd16 ;
    tones[ 189 ] = DO       ;  ttime[ 189 ] = 5 'd16 ;
    tones[ 190 ] = LLA      ;  ttime[ 190 ] = 5 'd8 ;
    tones[ 191 ] = LXI      ;  ttime[ 191 ] = 5 'd8 ;
    tones[ 192 ] = DO       ;  ttime[ 192 ] = 5 'd8 ;
    tones[ 193 ] = SOL      ;  ttime[ 193 ] = 5 'd8 ;
    tones[ 194 ] = FA       ;  ttime[ 194 ] = 5 'd8 ;
    tones[ 195 ] = MI       ;  ttime[ 195 ] = 5 'd8 ;
    tones[ 196 ] = DO       ;  ttime[ 196 ] = 5 'd8 ;
    tones[ 197 ] = DO       ;  ttime[ 197 ] = 5 'd8 ;
    tones[ 198 ] = DO       ;  ttime[ 198 ] = 5 'd4 ;
    tones[ 199 ] = REST     ;  ttime[ 199 ] = 5 'd4 ;
    tones[ 200 ] = DO       ;  ttime[ 200 ] = 5 'd16 ;
    tones[ 201 ] = DO       ;  ttime[ 201 ] = 5 'd16 ;
    tones[ 202 ] = DO       ;  ttime[ 202 ] = 5 'd16 ;
    tones[ 203 ] = DO       ;  ttime[ 203 ] = 5 'd16 ;
    tones[ 204 ] = MI       ;  ttime[ 204 ] = 5 'd8 ;
    tones[ 205 ] = DO       ;  ttime[ 205 ] = 5 'd8 ;
    tones[ 206 ] = LLA      ;  ttime[ 206 ] = 5 'd8 ;
    tones[ 207 ] = LXI      ;  ttime[ 207 ] = 5 'd8 ;
    tones[ 208 ] = DO       ;  ttime[ 208 ] = 5 'd8 ;
    tones[ 209 ] = SOL      ;  ttime[ 209 ] = 5 'd8 ;
    tones[ 210 ] = FA       ;  ttime[ 210 ] = 5 'd8 ;
    tones[ 211 ] = MI       ;  ttime[ 211 ] = 5 'd8 ;
    tones[ 212 ] = DO       ;  ttime[ 212 ] = 5 'd8 ;
    tones[ 213 ] = RE       ;  ttime[ 213 ] = 5 'd8 ;
    tones[ 214 ] = RE       ;  ttime[ 214 ] = 5 'd4 ;
    tones[ 215 ] = RE       ;  ttime[ 215 ] = 5 'd4 ;
    tones[ 216 ] = REST     ;  ttime[ 216 ] = 5 'd4 ;
    tones[ 217 ] = REST     ;  ttime[ 217 ] = 5 'd4 ;
    tones[ 218 ] = MI       ;  ttime[ 218 ] = 5 'd8 ;
    tones[ 219 ] = RE       ;  ttime[ 219 ] = 5 'd8 ;
    tones[ 220 ] = FA       ;  ttime[ 220 ] = 5 'd8 ;
    tones[ 221 ] = MI       ;  ttime[ 221 ] = 5 'd4 ;
    tones[ 222 ] = DO       ;  ttime[ 222 ] = 5 'd8 ;
    tones[ 223 ] = SOL      ;  ttime[ 223 ] = 5 'd8 ;
    tones[ 224 ] = XI       ;  ttime[ 224 ] = 5 'd8 ;
    tones[ 225 ] = HDO      ;  ttime[ 225 ] = 5 'd8 ;
    tones[ 226 ] = XI       ;  ttime[ 226 ] = 5 'd8 ;
    tones[ 227 ] = DO       ;  ttime[ 227 ] = 5 'd8 ;
    tones[ 228 ] = DO       ;  ttime[ 228 ] = 5 'd4 ;
    tones[ 229 ] = DO       ;  ttime[ 229 ] = 5 'd8 ;
    tones[ 230 ] = LA       ;  ttime[ 230 ] = 5 'd8 ;
    tones[ 231 ] = LA       ;  ttime[ 231 ] = 5 'd8 ;
    tones[ 232 ] = REST     ;  ttime[ 232 ] = 5 'd8 ;
    tones[ 233 ] = LA       ;  ttime[ 233 ] = 5 'd8 ;
    tones[ 234 ] = SOL      ;  ttime[ 234 ] = 5 'd8 ;
    tones[ 235 ] = SOL      ;  ttime[ 235 ] = 5 'd4 ;
    tones[ 236 ] = SOL      ;  ttime[ 236 ] = 5 'd8 ;
    tones[ 237 ] = FA       ;  ttime[ 237 ] = 5 'd8 ;
    tones[ 238 ] = MI       ;  ttime[ 238 ] = 5 'd8 ;
    tones[ 239 ] = RE       ;  ttime[ 239 ] = 5 'd8 ;
    tones[ 240 ] = MI       ;  ttime[ 240 ] = 5 'd8 ;
    tones[ 241 ] = FA       ;  ttime[ 241 ] = 5 'd8 ;
    tones[ 242 ] = MI       ;  ttime[ 242 ] = 5 'd8 ;
    tones[ 243 ] = MI       ;  ttime[ 243 ] = 5 'd4 ;
    tones[ 244 ] = MI       ;  ttime[ 244 ] = 5 'd4 ;
    tones[ 245 ] = MI       ;  ttime[ 245 ] = 5 'd8 ;
    tones[ 246 ] = SHARP_FA ;  ttime[ 246 ] = 5 'd8 ;
    tones[ 247 ] = SHARP_SOL;  ttime[ 247 ] = 5 'd8 ;
    tones[ 248 ] = MI       ;  ttime[ 248 ] = 5 'd4 ;
    tones[ 249 ] = FA       ;  ttime[ 249 ] = 5 'd8 ;
    tones[ 250 ] = SOL      ;  ttime[ 250 ] = 5 'd8 ;
    tones[ 251 ] = XI       ;  ttime[ 251 ] = 5 'd8 ;
    tones[ 252 ] = HRE      ;  ttime[ 252 ] = 5 'd8 ;
    tones[ 253 ] = XI       ;  ttime[ 253 ] = 5 'd8 ;
    tones[ 254 ] = HDO      ;  ttime[ 254 ] = 5 'd8 ;
    tones[ 255 ] = HDO      ;  ttime[ 255 ] = 5 'd4 ;
    tones[ 256 ] = HDO      ;  ttime[ 256 ] = 5 'd8 ;
    tones[ 257 ] = REST     ;  ttime[ 257 ] = 5 'd8 ;
    tones[ 258 ] = HDO      ;  ttime[ 258 ] = 5 'd8 ;
    tones[ 259 ] = HDO      ;  ttime[ 259 ] = 5 'd8 ;
    tones[ 260 ] = SOL      ;  ttime[ 260 ] = 5 'd8 ;
    tones[ 261 ] = SOL      ;  ttime[ 261 ] = 5 'd8 ;
    tones[ 262 ] = LA       ;  ttime[ 262 ] = 5 'd8 ;
    tones[ 263 ] = SOL      ;  ttime[ 263 ] = 5 'd16 ;
    tones[ 264 ] = FA       ;  ttime[ 264 ] = 5 'd16 ;
    tones[ 265 ] = FA       ;  ttime[ 265 ] = 5 'd8 ;
    tones[ 266 ] = RE       ;  ttime[ 266 ] = 5 'd8 ;
    tones[ 267 ] = MI       ;  ttime[ 267 ] = 5 'd8 ;
    tones[ 268 ] = FA       ;  ttime[ 268 ] = 5 'd8 ;
    tones[ 269 ] = SOL      ;  ttime[ 269 ] = 5 'd8 ;
    tones[ 270 ] = LA       ;  ttime[ 270 ] = 5 'd8 ;
    tones[ 271 ] = DO       ;  ttime[ 271 ] = 5 'd8 ;
    tones[ 272 ] = LLA      ;  ttime[ 272 ] = 5 'd8 ;
    tones[ 273 ] = LLA      ;  ttime[ 273 ] = 5 'd16 ;
    tones[ 274 ] = LXI      ;  ttime[ 274 ] = 5 'd16 ;
    tones[ 275 ] = XI       ;  ttime[ 275 ] = 5 'd4 ;
    tones[ 276 ] = MI       ;  ttime[ 276 ] = 5 'd8 ;
    tones[ 277 ] = RE       ;  ttime[ 277 ] = 5 'd8 ;
    tones[ 278 ] = FA       ;  ttime[ 278 ] = 5 'd8 ;
    tones[ 279 ] = MI       ;  ttime[ 279 ] = 5 'd4 ;
    tones[ 280 ] = DO       ;  ttime[ 280 ] = 5 'd8 ;
    tones[ 281 ] = SOL      ;  ttime[ 281 ] = 5 'd8 ;
    tones[ 282 ] = XI       ;  ttime[ 282 ] = 5 'd8 ;
    tones[ 283 ] = HDO      ;  ttime[ 283 ] = 5 'd8 ;
    tones[ 284 ] = XI       ;  ttime[ 284 ] = 5 'd8 ;
    tones[ 285 ] = DO       ;  ttime[ 285 ] = 5 'd8 ;
    tones[ 286 ] = DO       ;  ttime[ 286 ] = 5 'd4 ;
    tones[ 287 ] = DO       ;  ttime[ 287 ] = 5 'd8 ;
    tones[ 288 ] = LA       ;  ttime[ 288 ] = 5 'd8 ;
    tones[ 289 ] = LA       ;  ttime[ 289 ] = 5 'd8 ;
    tones[ 290 ] = REST     ;  ttime[ 290 ] = 5 'd8 ;
    tones[ 291 ] = LA       ;  ttime[ 291 ] = 5 'd8 ;
    tones[ 292 ] = SOL      ;  ttime[ 292 ] = 5 'd8 ;
    tones[ 293 ] = SOL      ;  ttime[ 293 ] = 5 'd4 ;
    tones[ 294 ] = SOL      ;  ttime[ 294 ] = 5 'd8 ;
    tones[ 295 ] = FA       ;  ttime[ 295 ] = 5 'd8 ;
    tones[ 296 ] = MI       ;  ttime[ 296 ] = 5 'd8 ;
    tones[ 297 ] = RE       ;  ttime[ 297 ] = 5 'd8 ;
    tones[ 298 ] = MI       ;  ttime[ 298 ] = 5 'd8 ;
    tones[ 299 ] = FA       ;  ttime[ 299 ] = 5 'd8 ;
    tones[ 300 ] = MI       ;  ttime[ 300 ] = 5 'd8 ;
    tones[ 301 ] = MI       ;  ttime[ 301 ] = 5 'd4 ;
    tones[ 302 ] = MI       ;  ttime[ 302 ] = 5 'd4 ;
    tones[ 303 ] = MI       ;  ttime[ 303 ] = 5 'd8 ;
    tones[ 304 ] = SHARP_FA ;  ttime[ 304 ] = 5 'd8 ;
    tones[ 305 ] = SHARP_SOL;  ttime[ 305 ] = 5 'd8 ;
    tones[ 306 ] = MI       ;  ttime[ 306 ] = 5 'd4 ;
    tones[ 307 ] = FA       ;  ttime[ 307 ] = 5 'd8 ;
    tones[ 308 ] = SOL      ;  ttime[ 308 ] = 5 'd8 ;
    tones[ 309 ] = XI       ;  ttime[ 309 ] = 5 'd8 ;
    tones[ 310 ] = HRE      ;  ttime[ 310 ] = 5 'd8 ;
    tones[ 311 ] = XI       ;  ttime[ 311 ] = 5 'd8 ;
    tones[ 312 ] = HDO      ;  ttime[ 312 ] = 5 'd8 ;
    tones[ 313 ] = HDO      ;  ttime[ 313 ] = 5 'd4 ;
    tones[ 314 ] = HDO      ;  ttime[ 314 ] = 5 'd8 ;
    tones[ 315 ] = REST     ;  ttime[ 315 ] = 5 'd8 ;
    tones[ 316 ] = HDO      ;  ttime[ 316 ] = 5 'd8 ;
    tones[ 317 ] = HDO      ;  ttime[ 317 ] = 5 'd8 ;
    tones[ 318 ] = SOL      ;  ttime[ 318 ] = 5 'd8 ;
    tones[ 319 ] = SOL      ;  ttime[ 319 ] = 5 'd8 ;
    tones[ 320 ] = LA       ;  ttime[ 320 ] = 5 'd8 ;
    tones[ 321 ] = SOL      ;  ttime[ 321 ] = 5 'd8 ;
    tones[ 322 ] = FA       ;  ttime[ 322 ] = 5 'd8 ;
    tones[ 323 ] = LLA      ;  ttime[ 323 ] = 5 'd8 ;
    tones[ 324 ] = LXI      ;  ttime[ 324 ] = 5 'd8 ;
    tones[ 325 ] = DO       ;  ttime[ 325 ] = 5 'd8 ;
    tones[ 326 ] = RE       ;  ttime[ 326 ] = 5 'd8 ;
    tones[ 327 ] = MI       ;  ttime[ 327 ] = 5 'd8 ;
    tones[ 328 ] = RE       ;  ttime[ 328 ] = 5 'd4 ;
    tones[ 329 ] = RE       ;  ttime[ 329 ] = 5 'd8 ;
    tones[ 330 ] = MI       ;  ttime[ 330 ] = 5 'd8 ;
    tones[ 331 ] = DO       ;  ttime[ 331 ] = 5 'd8 ;
    tones[ 332 ] = DO       ;  ttime[ 332 ] = 5 'd4 ;
    tones[ 333 ] = DO       ;  ttime[ 333 ] = 5 'd4 ;
    tones[ 334 ] = REST     ;  ttime[ 334 ] = 5 'd4 ;
    tones[ 335 ] = REST     ;  ttime[ 335 ] = 5 'd4 ;
end

endmodule
