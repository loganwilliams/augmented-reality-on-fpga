`include "../params.v"
`include "../memory_interface.v"

module tb1;
	`include "tb_template.v"

	initial begin
		frame_flag = 0;
		#1000 frame_flag = 1;
		#10 frame_flag = 0;
	end

	integer i;
	initial begin
		vga_flag = 0;
		ntsc_flag = 0;
		#100
		for (i = 0;i < 150;i=i+1) begin
			#10 vga_flag = ~vga_flag;
			ntsc_flag = ~ntsc_flag;
		end
	end

	initial #2000 $finish;
endmodule
