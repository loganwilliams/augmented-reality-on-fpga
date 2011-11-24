`include "../params.v"
`include "../memory_interface.v"

module tb1;
	// STANDARD SIGNALS
	reg clock;
	reg reset;
	// NTSC_CAPTURE
	reg frame_flag;
	reg ntsc_flag;
	reg [`LOG_MEM-1:0] ntsc_pixel;
	wire done_ntsc;
	// LPF
	reg lpf_flag;
	reg lpf_wr;
	reg [`LOG_WIDTH-1:0] lpf_x;
	reg [`LOG_HEIGHT-1:0] lpf_y;
	reg [`LOG_MEM-1:0] lpf_pixel_write;
	wire done_lpf;
	wire [`LOG_MEM-1:0] lpf_pixel_read;
	// PROJECTIVE_TRANSFORM
	reg pt_flag;
	reg pt_wr;
	reg [`LOG_WIDTH-1:0] pt_x;
	reg [`LOG_HEIGHT-1:0] pt_y;
	reg [`LOG_TRUNC-1:0] pt_pixel_write;
	wire done_pt;
	// VGA_WRITE
	reg vga_flag;
	wire done_vga;
	wire [`LOG_FULL-1:0] vga_pixel;
	// MEMORY
	// MEM ADDRESSES
	wire [`LOG_ADDR-1:0] mem0_addr;
	wire [`LOG_ADDR-1:0] mem1_addr;
	// MEM READ	
	reg [`LOG_MEM-1:0] mem0_read;
	reg [`LOG_MEM-1:0] mem1_read;
	// MEM WRITE
	wire [`LOG_MEM-1:0] mem0_write;
	wire [`LOG_MEM-1:0] mem1_write;
	// WR FLAGS
	wire mem0_wr;
	wire mem1_wr;

	memory_interface mem_int (
		.clock				(clock),
		.reset				(reset),
		.frame_flag 		(frame_flag),
		.ntsc_flag			(ntsc_flag),
		.ntsc_pixel			(ntsc_pixel),
		.done_ntsc			(done_ntsc),
		.lpf_flag			(lpf_flag),
		.lpf_wr				(lpf_wr),
		.lpf_x				(lpf_x),
		.lpf_y				(lpf_y),
		.lpf_pixel_write	(lpf_pixel_write),
		.done_lpf			(done_lpf),
		.lpf_pixel_read		(lpf_pixel_read),
		.pt_flag			(pt_flag),
		.pt_wr				(pt_wr),
		.pt_x				(pt_x),
		.pt_y				(pt_y),
		.pt_pixel_write		(pt_pixel_write),
		.done_pt			(done_pt),
		.vga_flag			(vga_flag),
		.done_vga			(done_vga),
		.vga_pixel			(vga_pixel),
		.mem0_addr			(mem0_addr),
		.mem1_addr			(mem1_addr),
		.mem0_read			(mem0_read),
		.mem1_read			(mem1_read),
		.mem0_write			(mem0_write),
		.mem1_write			(mem1_write),
		.mem0_wr			(mem0_wr),
		.mem1_wr			(mem1_wr)
	);

	initial begin
		clock = 0;
		reset = 1;
		#10 reset = 0;
	end

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
		for (i = 0;i < 100;i=i+1) begin
			#10 vga_flag = ~vga_flag;
			ntsc_flag = ~ntsc_flag;
		end
	end

	initial begin
		$dumpvars;
	end

	initial #2000 $finish;

	always #5 clock = !clock;
endmodule
