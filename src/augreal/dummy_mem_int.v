`default_nettype none
`include "params.v"

module dummy_mem_int
	(
		input clock,
		input reset,
		input frame_flag,

		input vga_flag,
		output reg [`LOG_MEM-1:0] vga_pixel,
		output reg done_vga,

		input [`LOG_HCOUNT-1:0] hcount
	);

	always @(*) begin
		done_vga = vga_flag;
		vga_pixel = (hcount[4:0] > 15) ? `LOG_MEM'h000000000 : `LOG_MEM'hFFFFFFFFF;
	end
endmodule
