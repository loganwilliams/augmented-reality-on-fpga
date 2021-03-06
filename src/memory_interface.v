`default_nettype none
// comment out when testing
`include "params.v"
// memory_interface
// handles EVERYTHING ram related
// actual ram modules are instantiated in top module

module memory_interface
	(
		// STANDARD SIGNALS
		input clock,
		input reset,
		// NTSC_CAPTURE
		input frame_flag,
		input ntsc_flag,
		input [`LOG_MEM-1:0] ntsc_pixel,
		output reg done_ntsc,
		// LPF
		input lpf_flag,
		input lpf_wr,
		input [`LOG_WIDTH-1:0] lpf_x,
		input [`LOG_HEIGHT-1:0] lpf_y,
		input [`LOG_MEM-1:0] lpf_pixel_write,
		output reg done_lpf,
		output reg [`LOG_MEM-1:0] lpf_pixel_read,
		// PROJECTIVE_TRANSFORM
		input pt_flag,
		input [`LOG_WIDTH-1:0] pt_x,
		input [`LOG_HEIGHT-1:0] pt_y,
		input [`LOG_TRUNC-1:0] pt_pixel,
		output done_pt,
		// VGA_WRITE
		input vga_flag,
		output reg done_vga,
		output reg [`LOG_MEM-1:0] vga_pixel,
		// MEMORY
		// MEM ADDRESSES
		output reg [`LOG_ADDR-1:0] mem0_addr,
		output reg [`LOG_ADDR-1:0] mem1_addr,	
		// MEM READ	
		input [`LOG_MEM-1:0] mem0_read,
		input [`LOG_MEM-1:0] mem1_read,
		// MEM WRITE
		output reg [`LOG_MEM-1:0] mem0_write,
		output reg [`LOG_MEM-1:0] mem1_write,
		// WR FLAGS
		output reg mem0_wr,
		output reg mem1_wr,
		// TESTING
		output [3:0] debug_blocks,
		output [7:0] debug_locs
	);

	/******** PARAMETERS ********/
	// READ QUEUE LENGTH
	parameter QUEUE_LENGTH = 2;
	// MODULE ORDINALS
	parameter NTSC = 4'b1000;
	parameter VGA  = 4'b0100;
	parameter LPF  = 4'b0010;
	parameter PTF  = 4'd0001;
	parameter NONE = 4'd0000;
	parameter LOG_ORD = 4;
	/****************************/

	// PT_FETCHER
	wire ptf_flag;
	wire ptf_wr;
	wire [`LOG_WIDTH-1:0] ptf_x;
	wire [`LOG_HEIGHT-1:0] ptf_y;
	wire [`LOG_MEM-1:0] ptf_pixel_write;
	reg done_ptf;
	reg [`LOG_MEM-1:0] ptf_pixel_read;
	// INSTANTIATE pt_fetcher here

	// BLOCK OF SRAM IMAGE IS IN
	reg capt_mem_block;
	reg proc_mem_block;
	reg nexd_mem_block;
	reg disp_mem_block;

	// LOCATIONS OF IMAGES IN EACH BLOCK
	// making it a 2bit number to allow for the possibility
	// of loading an image from flash and storing a third image
	// for processing
	reg [1:0] capt_mem_loc;
	reg [1:0] proc_mem_loc;
	reg [1:0] nexd_mem_loc;	
	reg [1:0] disp_mem_loc;

	// ADDRESSES
	reg [`LOG_ADDR-1:0] ntsc_addr;
	reg [`LOG_ADDR-1:0] vga_addr;
	reg [`LOG_ADDR-1:0] lpf_addr;
	reg [`LOG_ADDR-1:0] ptf_addr;
	reg [`LOG_ADDR-1:0] next_ntsc_addr;
	reg [`LOG_ADDR-1:0] next_vga_addr;

	// NEXT LOCS AND BLOCKS
	reg [3:0] next_blocks;
	reg [7:0] next_locs;
	reg next_capt_mem_block;
	reg next_proc_mem_block;
	reg next_nexd_mem_block;
	reg next_disp_mem_block;
	reg [1:0] next_capt_mem_loc;
	reg [1:0] next_proc_mem_loc;
	reg [1:0] next_nexd_mem_loc;
	reg [1:0] next_disp_mem_loc;

	// PARTIAL DONE FLAGS
	reg [3:0] mem0_done;
	reg [3:0] mem1_done;
	
	// READ QUEUES
	reg [QUEUE_LENGTH*LOG_ORD-1:0] mem0_read_queue;
	reg [QUEUE_LENGTH*LOG_ORD-1:0] mem1_read_queue;
	reg [QUEUE_LENGTH*LOG_ORD-1:0] next_mem0_read_queue;
	reg [QUEUE_LENGTH*LOG_ORD-1:0] next_mem1_read_queue;
	// ELEMENTS AT END OF QUEUES
	reg [LOG_ORD-1:0] mem0_next_read;
	reg [LOG_ORD-1:0] mem1_next_read;

	// PREVIOUS LPF, VGA, AND PTF READ VALUES
	// (for stable vga_pixel, lpf_pixel_read, and ptf_pixel_read)
	reg [`LOG_MEM-1:0] prev_vga_pixel;
	reg [`LOG_MEM-1:0] prev_lpf_pixel_read;
	reg [`LOG_MEM-1:0] prev_ptf_pixel_read;

	// DEBUG
	assign debug_blocks = {capt_mem_block,disp_mem_block,2'b00};
	assign debug_locs = {capt_mem_loc, disp_mem_loc, 2'b00};

	always @(*) begin
		// shifting
		if (reset) begin
			// choose starting condition such that capt and disp never overlap
			next_blocks = 4'b0011;
			next_locs = {2'b00, 2'b01, 2'b00, 2'b01};
		end
		else if (frame_flag) begin
			next_blocks = {proc_mem_block, disp_mem_block, capt_mem_block, nexd_mem_block};
			next_locs = {proc_mem_loc, disp_mem_loc, capt_mem_loc, nexd_mem_loc};
		end
		// retain until shift
		else begin
			next_blocks = {capt_mem_block, proc_mem_block, nexd_mem_block, disp_mem_block};
			next_locs = {capt_mem_loc, proc_mem_loc, nexd_mem_loc, disp_mem_loc};
		end
		{next_capt_mem_block,next_proc_mem_block,next_nexd_mem_block,next_disp_mem_block} = next_blocks;
		{next_capt_mem_loc,next_proc_mem_loc,next_nexd_mem_loc,next_disp_mem_loc} = next_locs;

		// set address & write & done flags
		// assign write value to mem0 & mem1 based on who's writing
		if (!capt_mem_block && ntsc_flag) begin
			mem0_addr = ntsc_addr;
			mem0_write = ntsc_pixel;
			mem0_wr = 1;
			mem0_done = NTSC;
		end
		else if (!disp_mem_block && vga_flag) begin
			mem0_addr = vga_addr;
			mem0_wr = 0;
			mem0_done = VGA;
		end
		else if (!proc_mem_block && lpf_flag) begin
			mem0_addr = lpf_addr;
			mem0_write = lpf_pixel_write;
			mem0_wr = lpf_wr;
			mem0_done = LPF;
		end
		else if (!nexd_mem_block && ptf_flag) begin
			mem0_addr = ptf_addr;
			mem0_write = ptf_pixel_write;
			mem0_wr = ptf_wr;
			mem0_done = PTF;
		end 
		else begin // nothing's happening
			mem0_addr = 0;
			mem0_write = 0;
			mem0_wr = 0;
			mem0_done = NONE;
		end

		if (capt_mem_block && ntsc_flag) begin
			mem1_addr = ntsc_addr;
			mem1_write = ntsc_pixel;
			mem1_wr = 1;
			mem1_done = NTSC;
		end
		else if (disp_mem_block && vga_flag) begin
			mem1_addr = vga_addr;
			mem1_wr = 0;
			mem1_done = VGA;
		end
		else if (proc_mem_block && lpf_flag) begin
			mem1_addr = lpf_addr;
			mem1_write = lpf_pixel_write;
			mem1_wr = lpf_wr;
			mem1_done = LPF;
		end
		else if (nexd_mem_block && ptf_flag) begin
			mem1_addr = ptf_addr;
			mem1_write = ptf_pixel_write;
			mem1_wr = ptf_wr;
			mem1_done = PTF;
		end
		else begin // nothing's happening
			mem1_addr = 0;
			mem1_write = 0;
			mem1_wr = 0;
			mem1_done = NONE;
		end

		// set done flags
		done_ntsc = mem0_done[3] || mem1_done[3];
		done_vga  = mem0_done[2] || mem1_done[2];
		done_lpf  = mem0_done[1] || mem1_done[1];
		done_ptf  = mem0_done[0] || mem1_done[0];

		// assign read value to corresponding member of queue
		mem0_next_read = mem0_read_queue[QUEUE_LENGTH*LOG_ORD-1:(QUEUE_LENGTH-1)*LOG_ORD];
		mem1_next_read = mem1_read_queue[QUEUE_LENGTH*LOG_ORD-1:(QUEUE_LENGTH-1)*LOG_ORD];
		
		// LPF's turn in the queue
		if (mem0_next_read == LPF) lpf_pixel_read = mem0_read;
		else if (mem1_next_read == LPF) lpf_pixel_read = mem1_read;
		else lpf_pixel_read = prev_lpf_pixel_read;

		// PTF's turn
		if (mem0_next_read == PTF) ptf_pixel_read = mem0_read;
		else if (mem1_next_read == PTF) ptf_pixel_read = mem1_read;
		else ptf_pixel_read = prev_ptf_pixel_read;

		// VGA's turn
		if (mem0_next_read == VGA) vga_pixel = mem0_read;
		else if (mem1_next_read == VGA) vga_pixel = mem1_read;
		else vga_pixel = prev_vga_pixel;

		// shifting of queue on next cycle
		next_mem0_read_queue[QUEUE_LENGTH*LOG_ORD-1:LOG_ORD] = mem0_read_queue[(QUEUE_LENGTH-1)*LOG_ORD-1:0];
		next_mem1_read_queue[QUEUE_LENGTH*LOG_ORD-1:LOG_ORD] = mem1_read_queue[(QUEUE_LENGTH-1)*LOG_ORD-1:0];

		// add new queue members, if any
		if (mem0_done == VGA) next_mem0_read_queue[LOG_ORD-1:0] = VGA;
		else if (mem0_done == LPF && !lpf_wr) next_mem0_read_queue[LOG_ORD-1:0] = LPF;
		else if (mem0_done == PTF && !ptf_wr) next_mem0_read_queue[LOG_ORD-1:0] = PTF;
		else next_mem0_read_queue[LOG_ORD-1:0] = NONE;

		if (mem1_done == VGA) next_mem1_read_queue[LOG_ORD-1:0] = VGA;
		else if (mem1_done == LPF && !lpf_wr) next_mem1_read_queue[LOG_ORD-1:0] = LPF;
		else if (mem1_done == PTF && !ptf_wr) next_mem1_read_queue[LOG_ORD-1:0] = PTF;
		else next_mem1_read_queue[LOG_ORD-1:0] = NONE;

		// set addresses of LPF and PTF from (x,y) coordinates
		// addr = y*(image_width/2) + lpf_x/2 + loc*(image_width*image_height/2)
		lpf_addr = (`IMAGE_WIDTH_D2 * lpf_y) + lpf_x[`LOG_WIDTH-1:1] + (proc_mem_loc * `IMAGE_LENGTH);
		ptf_addr = (`IMAGE_WIDTH_D2 * ptf_y) + ptf_x[`LOG_WIDTH-1:1] + (nexd_mem_loc * `IMAGE_LENGTH);

		// set next addresses of NTSC and VGA
		// set to starting address at the start of each frame or when the FPGA is reset
		if (reset || frame_flag) begin
			next_ntsc_addr = (next_capt_mem_loc*`IMAGE_LENGTH);
			next_vga_addr = (next_disp_mem_loc*`IMAGE_LENGTH);
		end
		// set addresses of NTSC and VGA / update if pixels have been read or written
		else begin
			next_ntsc_addr = ntsc_addr + done_ntsc;
			next_vga_addr = vga_addr + done_vga;
		end
		// this should be it
	end

	always @(posedge clock) begin
		// update blocks and locations of images in RAM
		{capt_mem_block, proc_mem_block, nexd_mem_block, disp_mem_block} <= next_blocks;
		{capt_mem_loc, proc_mem_loc, nexd_mem_loc, disp_mem_loc} <= next_locs;

		// update ntsc and vga addresses
		ntsc_addr <= next_ntsc_addr;
		vga_addr <= next_vga_addr;

		// update read queues
		mem0_read_queue <= next_mem0_read_queue;
		mem1_read_queue <= next_mem1_read_queue;

		// retain previous output pixel values
		prev_vga_pixel <= vga_pixel;
		prev_lpf_pixel_read <= lpf_pixel_read;
		prev_ptf_pixel_read <= ptf_pixel_read;
	end
endmodule
