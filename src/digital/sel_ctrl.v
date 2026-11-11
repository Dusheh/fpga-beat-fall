module sel_ctrl(
input wire clk,
input wire rst_n,
input wire [5:0] dp_seg,
output reg [5:0] sel,
output reg 		  dp,
input  wire[24:0]show_num_in,
output reg [3:0] show_num_out
);

parameter delay = 50_000;
reg [25:0] cnt;
reg [3:0]  cnt_ms;

always@(posedge clk)
	if(!rst_n)
		cnt<=0;
	else if(cnt == delay - 1)
		cnt<=0;
	else
		cnt<=cnt+1;
		
always@(posedge clk)
	if(!rst_n)
		cnt_ms<=0;
	else if(cnt == delay - 1)begin
		if(cnt_ms == 5)
			cnt_ms<=0;
		else
			cnt_ms<=cnt_ms + 1;
		end
	else
		cnt_ms<=cnt_ms;
		
always@(posedge clk)
	if(!rst_n)begin
		sel		<=0;
		show_num_out<=0;
		dp			<=1'b1;
		//dp			<=6'b111_111;
	end
	else
		case(cnt_ms)
			0:begin
				sel 			<=6'b011_111;
				show_num_out	<=show_num_in[3:0];
				dp				<=dp_seg[0];
			end
			
			
			1:begin
				sel 			<=6'b101_111;
				show_num_out	<=show_num_in[7:4];
				dp				<=dp_seg[1];
			end
			
			2:begin
				sel 			<=6'b110_111;
				show_num_out	<=show_num_in[11:8];
				dp				<=dp_seg[2];
			end
			
			3:begin
				sel 			<=6'b111_011;
				show_num_out	<=show_num_in[15:12];
				dp				<=dp_seg[3];
			end
			
			4:begin
				sel 			<=6'b111_101;
				show_num_out	<=show_num_in[19:16];
				dp				<=dp_seg[4];
			end
			
			5:begin
				sel 			<=6'b111_110;
				show_num_out	<=show_num_in[23:20];
				dp				<=dp_seg[5];
			end
			
			default:begin
				sel 			<=0;
				show_num_out	<=0;
				dp				<=6'b111_111;
			end
		endcase
	
endmodule
			