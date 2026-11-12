module show(
input	 	wire	[3:0]		show_num_in,
output	reg	[6:0]		show_num_out
);

always@(*)
	case(show_num_in)
		0:show_num_out = 7'b1000000;
		1:show_num_out = 7'b1111001;
		2:show_num_out = 7'b0100100;
		3:show_num_out = 7'b0110000;
		4:show_num_out = 7'b0011001;
		5:show_num_out = 7'b0010010;
		6:show_num_out = 7'b0000010;
		7:show_num_out = 7'b1111000;
		8:show_num_out = 7'b0000000;
		9:show_num_out = 7'b0010000;
		4'hA:show_num_out = 7'b0001100;  // P
		4'hB:show_num_out = 7'b0001000;  // A
		4'hC:show_num_out = 7'b1000001;  // U
		4'hD:show_num_out = 7'b0010010;  // S
		4'hE:show_num_out = 7'b0000110;  // E
		4'hF:show_num_out = 7'b1111111;  // 空白
		default:show_num_out = 7'b1000000;
	endcase

endmodule
