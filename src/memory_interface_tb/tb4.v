`default_nettype none
`include "../params.v"
`include "../memory_interface.v"

module tb4;
	// STANDARD SIGNALS
	reg clock;
	reg reset;
	// NTSC_CAPTURE
	reg frame_flag;
	wire ntsc_flag;
	wire [`LOG_MEM-1:0] ntsc_pixel;
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
	wire pt_flag;
	reg pt_wr;
	wire [`LOG_WIDTH-1:0] pt_x;
	wire [`LOG_HEIGHT-1:0] pt_y;
	wire [`LOG_TRUNC-1:0] pt_pixel_write;
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
	wire [`LOG_MEM-1:0] mem0_read;
	wire [`LOG_MEM-1:0] mem1_read;
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
		$dumpvars;
	end

	always #5 clock = !clock;

	dummy_zbt mem0(.clock(clock),.reset(reset),.wr(mem0_wr),.addr(mem0_addr),.write(mem0_write),.data(mem0_read));
	dummy_zbt mem1(.clock(clock),.reset(reset),.wr(mem1_wr),.addr(mem1_addr),.write(mem1_write),.data(mem1_read));

	reg start;

	writer #(.DELAY(2), .REPS(32'd1000), .START(32'd1), .DEL(1)) ntsc(.clock(clock), .reset(reset), .start(start), .done(done_ntsc), .flag(ntsc_flag), .pixel(ntsc_pixel));
	writer #(.DELAY(3), .REPS(32'd1000), .START(32'd3000), .DEL(4)) pt(.clock(clock), .reset(reset), .start(start), .done(done_pt), .flag(pt_flag), .pixel(pt_pixel_write), .x(pt_x), .y(pt_y));

	integer i;
	initial begin
		frame_flag = 0;
		vga_flag = 0;
		lpf_flag = 0;
		pt_wr = 1;
		#10 frame_flag = 1;
		#10 frame_flag = 0;
		#10 start = 1;
		#10 start = 0;
		#20000 frame_flag = 1;
		#10 frame_flag = 0;
		// capt pixels should now be disp pixels
		// continuous stream
		for (i = 0;i < 1500;i=i+1) begin
			#10
			vga_flag = 1;
		end
		#10 frame_flag = 1;
		#10 frame_flag = 0;
		for (i = 0;i < 1500;i=i+1) begin
			#10
			vga_flag = 1;
		end
	end

	initial begin
		#80000 $stop;
	end
endmodule

module writer #(parameter DELAY=2,REPS=1000,START=1,DEL=1) 
	(
		input clock,
		input reset,
		input start,
		input done,
		output reg flag,
		output reg [`LOG_MEM-1:0] pixel,
		output reg [`LOG_WIDTH-1:0] x,
		output reg [`LOG_HEIGHT-1:0] y
	);

	parameter IDLE     = 3'b001;
	parameter WRITING  = 3'b010;
	parameter COUNTING = 3'b100;
	reg [2:0] state;
	reg [31:0] count;
	reg [31:0] rep_count;

	always @(*) begin
		flag = (state == WRITING);
	end

	always @(posedge clock) begin
		if (reset) begin
			state <= IDLE;
			count <= 32'b0;
			rep_count <= 0;
			pixel <= START;
			x <= 0;
			y <= 0;
		end
		else begin
			case (state)
				IDLE: begin
					if (start) state <= WRITING;
					else state <= state;
					count <= 0;
					rep_count <= 0;
					pixel <= START;
					x <= 0;
					y <= 0;
				end
				WRITING: begin
					if (done) begin
						state <= COUNTING;
						count <= 1;
						rep_count <= rep_count+1;
						pixel <= pixel+DEL;
						if (x == `IMAGE_WIDTH-1) begin
							x <= 0;
							y <= y+1;
						end
						else begin
							x <= x+1;
							y <= y;
						end
					end
					else begin
						state <= state;
						count <= count;
						rep_count <= rep_count;
						pixel <= pixel;
						x <= x;
						y <= y;
					end
				end
				COUNTING: begin
					if (rep_count == REPS-1) begin
						state <= IDLE;
						count <= 0;
					end
					else if (count == DELAY-1) begin
						state <= WRITING;
						count <= 0;
					end
					else begin
						state <= COUNTING;
						count <= count+1;
					end
					rep_count <= rep_count;
					pixel <= pixel;
					x <= x;
					y <= y;
				end
				default: begin
					state <= state;
					count <= count;
					rep_count <= rep_count;
					pixel <= pixel;
					x <= x;
					y <= y;
				end
			endcase
		end
	end
endmodule
