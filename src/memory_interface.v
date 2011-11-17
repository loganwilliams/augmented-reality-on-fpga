`default_nettype none
`include params.v
// memory_interface
// handles EVERYTHING ram related
// a clock signal must be fed into it

module memory_interface
	(
		// standard inputs
		input clock,
		input reset,
		// ntsc_capture
		input frame_flag,
		input [`LOG_MEM:0] captured_pixels,
		input pixel_flag,
		output reg done_ntsc,
		// lpf
		input lpf_wr,
		input [`LOG_WIDTH:0] lpf_x,
		input [`LOG_HEIGHT:0] lpf_y,
		input [`LOG_MEM:0] lpf_pixel_write,
		output reg done_lpf,
		output reg [`LOG_MEM:0] pixel_read,
		// projective_transform inputs
		input pt_wr,
		input [`LOG_WIDTH:0] pt_x,
		input [`LOG_HEIGHT:0] pt_y,
		input [`LOG_TRUNC:0] pt_pixel_write,
		output reg done_pt,
		// vga_write inputs
		input request_pixel,
		output reg [`LOG_FULL:0] pixel_vga
	);

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
	reg [`LOG_ADDR:0] ntsc_addr;
	reg [`LOG_ADDR:0] vga_addr;
	reg [`LOG_ADDR:0] lpf_addr;
	reg [`LOG_ADDR:0] pt_addr;

	// NEXT LOCS AND BLOCKS
	reg [3:0] next_blocks;
	reg [7:0] next_locs;

	always @(*) begin
		// shifting
		if (reset) begin
			// choose starting condition such that capt and disp never overlap
			next_blocks = {0,0,1,1};
			next_locs = {2'b00, 2'b01, 2'b00, 2'b01};
		end
		else if (flame_flag) begin
			next_blocks = {proc_mem_block, disp_mem_block, capt_mem_block, nexd_mem_block};
			next_locs = {proc_mem_loc, disp_mem_loc, capt_mem_loc, nexd_mem_loc};
		end
		// retain until shift
		else begin
			next_blocks = {capt_mem_block, proc_mem_block, nexd_mem_block, disp_mem_block};
			next_locs = {capt_mem_loc, proc_mem_loc, nexd_mem_loc, disp_mem_loc};
		end

		// set addresses of LPF and PT from (x,y) coordinates
		lpf_addr = (`IMAGE_WIDTH * lpf_y) + lpf_x + (proc_mem_loc * `IMAGE_LENGTH);
		pt_addr = (`IMAGE_WIDTH * pt_y) + pt_x + (next_mem_loc * `IMAGE_LENGTH);
	end

	always @(posedge clock) begin
		{capt_mem_block, proc_mem_block, nexd_mem_block, disp_mem_block} <= next_blocks;
		{capt_mem_loc, proc_mem_loc, nexd_mem_loc, disp_mem_loc} <= next_locs;

		// set addresses of NTSC and VGA / update if pixels have been read or written
		ntsc_addr <= (reset) ? 0 : (ntsc_addr + done_ntsc);
		vga_addr <= (reset) ? 0 : (vga_addr + done_vga);

		// base pixel fed to mem on flag signal
	end
endmodule

// TODO:
// - add logic for all of the done flags
// - interface with memory

/* FOR REFERENCE
	// SRAMs
   assign ram0_data = 36'hZ;
   assign ram0_address = 19'h0;
   assign ram0_adv_ld = 1'b0;
   assign ram0_clk = 1'b0;
   assign ram0_cen_b = 1'b1;
   assign ram0_ce_b = 1'b1;
   assign ram0_oe_b = 1'b1;
   assign ram0_we_b = 1'b1;
   assign ram0_bwe_b = 4'hF;
   assign ram1_data = 36'hZ; 
   assign ram1_address = 19'h0;
   assign ram1_adv_ld = 1'b0;
   assign ram1_clk = 1'b0;
   assign ram1_cen_b = 1'b1;
   assign ram1_ce_b = 1'b1;
   assign ram1_oe_b = 1'b1;
   assign ram1_we_b = 1'b1;
   assign ram1_bwe_b = 4'hF;
   assign clock_feedback_out = 1'b0;
*/
