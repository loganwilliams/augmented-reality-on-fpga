`include "../params.v"
`include "../memory_interface.v"

module tb3;
	`include "tb_template.v"

	dummy_zbt mem0(.clock(clock),.reset(reset),.wr(mem0_wr),.addr(mem0_addr),.write(mem0_write),.data(mem0_read));
	dummy_zbt mem1(.clock(clock),.reset(reset),.wr(mem1_wr),.addr(mem1_addr),.write(mem1_write),.data(mem1_read));

	integer i;
	initial begin
		frame_flag = 0;
		ntsc_flag = 0;
		ntsc_pixel = 0;
		vga_flag = 0;
		// continuous stream
		for (i = 0;i < 2000;i=i+1) begin
			#10
			ntsc_pixel = i*7;
			ntsc_flag = 1;
		end
			
		// non-continuous stream
		for (i = 2000;i < 4000;i=i+1) begin
			#10
			ntsc_pixel = i*8;
			ntsc_flag = 1;
			#10
			ntsc_flag = 0;
		end
		#10 frame_flag = 1;
		#10 frame_flag = 0;
		#10 frame_flag = 1;
		#10 frame_flag = 0;
		// capt pixels should now be disp pixels
		// continuous stream
		for (i = 0;i < 2000;i=i+1) begin
			#10
			vga_flag = 1;
		end
			
		// non-continuous stream
		for (i = 2000;i < 4000;i=i+1) begin
			#10
			vga_flag = 1;
			#10
			vga_flag = 0;
		end
	end

	initial begin
		#100000 $stop;
	end
endmodule
