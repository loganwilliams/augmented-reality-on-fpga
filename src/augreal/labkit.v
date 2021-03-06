`default_nettype none
`include "params.v"

///////////////////////////////////////////////////////////////////////////////
//
// 6.111 FPGA Labkit -- Template Toplevel Module
//
// For Labkit Revision 004
//
//
// Created: October 31, 2004, from revision 003 file
// Author: Nathan Ickes
//
///////////////////////////////////////////////////////////////////////////////
//
// CHANGES FOR BOARD REVISION 004
//
// 1) Added signals for logic analyzer pods 2-4.
// 2) Expanded "tv_in_ycrcb" to 20 bits.
// 3) Renamed "tv_out_data" to "tv_out_i2c_data" and "tv_out_sclk" to
//    "tv_out_i2c_clock".
// 4) Reversed disp_data_in and disp_data_out signals, so that "out" is an
//    output of the FPGA, and "in" is an input.
//
// CHANGES FOR BOARD REVISION 003
//
// 1) Combined flash chip enables into a single signal, flash_ce_b.
//
// CHANGES FOR BOARD REVISION 002
//
// 1) Added SRAM clock feedback path input and output
// 2) Renamed "mousedata" to "mouse_data"
// 3) Renamed some ZBT memory signals. Parity bits are now incorporated into 
//    the data bus, and the byte write enables have been combined into the
//    4-bit ram#_bwe_b bus.
// 4) Removed the "systemace_clock" net, since the SystemACE clock is now
//    hardwired on the PCB to the oscillator.
//
///////////////////////////////////////////////////////////////////////////////
//
// Complete change history (including bug fixes)
//
// 2006-Mar-08: Corrected default assignments to "vga_out_red", "vga_out_green"
//              and "vga_out_blue". (Was 10'h0, now 8'h0.)
//
// 2005-Sep-09: Added missing default assignments to "ac97_sdata_out",
//              "disp_data_out", "analyzer[2-3]_clock" and
//              "analyzer[2-3]_data".
//
// 2005-Jan-23: Reduced flash address bus to 24 bits, to match 128Mb devices
//              actually populated on the boards. (The boards support up to
//              256Mb devices, with 25 address lines.)
//
// 2004-Oct-31: Adapted to new revision 004 board.
//
// 2004-May-01: Changed "disp_data_in" to be an output, and gave it a default
//              value. (Previous versions of this file declared this port to
//              be an input.)
//
// 2004-Apr-29: Reduced SRAM address busses to 19 bits, to match 18Mb devices
//              actually populated on the boards. (The boards support up to
//              72Mb devices, with 21 address lines.)
//
// 2004-Apr-29: Change history started
//
///////////////////////////////////////////////////////////////////////////////

module labkit(beep, audio_reset_b, ac97_sdata_out, ac97_sdata_in, ac97_synch,
	       ac97_bit_clock,
	       
	       vga_out_red, vga_out_green, vga_out_blue, vga_out_sync_b,
	       vga_out_blank_b, vga_out_pixel_clock, vga_out_hsync,
	       vga_out_vsync,

	       tv_out_ycrcb, tv_out_reset_b, tv_out_clock, tv_out_i2c_clock,
	       tv_out_i2c_data, tv_out_pal_ntsc, tv_out_hsync_b,
	       tv_out_vsync_b, tv_out_blank_b, tv_out_subcar_reset,

	       tv_in_ycrcb, tv_in_data_valid, tv_in_line_clock1,
	       tv_in_line_clock2, tv_in_aef, tv_in_hff, tv_in_aff,
	       tv_in_i2c_clock, tv_in_i2c_data, tv_in_fifo_read,
	       tv_in_fifo_clock, tv_in_iso, tv_in_reset_b, tv_in_clock,

	       ram0_data, ram0_address, ram0_adv_ld, ram0_clk, ram0_cen_b,
	       ram0_ce_b, ram0_oe_b, ram0_we_b, ram0_bwe_b, 

	       ram1_data, ram1_address, ram1_adv_ld, ram1_clk, ram1_cen_b,
	       ram1_ce_b, ram1_oe_b, ram1_we_b, ram1_bwe_b,

	       clock_feedback_out, clock_feedback_in,

	       flash_data, flash_address, flash_ce_b, flash_oe_b, flash_we_b,
	       flash_reset_b, flash_sts, flash_byte_b,

	       rs232_txd, rs232_rxd, rs232_rts, rs232_cts,

	       mouse_clock, mouse_data, keyboard_clock, keyboard_data,

	       clock_27mhz, clock1, clock2,

	       disp_blank, disp_data_out, disp_clock, disp_rs, disp_ce_b,
	       disp_reset_b, disp_data_in,

	       button0, button1, button2, button3, button_enter, button_right,
	       button_left, button_down, button_up,

	       switch,

	       led,
	       
	       user1, user2, user3, user4,
	       
	       daughtercard,

	       systemace_data, systemace_address, systemace_ce_b,
	       systemace_we_b, systemace_oe_b, systemace_irq, systemace_mpbrdy,
	       
	       analyzer1_data, analyzer1_clock,
 	       analyzer2_data, analyzer2_clock,
 	       analyzer3_data, analyzer3_clock,
 	       analyzer4_data, analyzer4_clock);

   output beep, audio_reset_b, ac97_synch, ac97_sdata_out;
   input  ac97_bit_clock, ac97_sdata_in;
   
   output [7:0] vga_out_red, vga_out_green, vga_out_blue;
   output vga_out_sync_b, vga_out_blank_b, vga_out_pixel_clock,
	  vga_out_hsync, vga_out_vsync;

   output [9:0] tv_out_ycrcb;
   output tv_out_reset_b, tv_out_clock, tv_out_i2c_clock, tv_out_i2c_data,
	  tv_out_pal_ntsc, tv_out_hsync_b, tv_out_vsync_b, tv_out_blank_b,
	  tv_out_subcar_reset;
   
   input  [19:0] tv_in_ycrcb;
   input  tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, tv_in_aef,
	  tv_in_hff, tv_in_aff;
   output tv_in_i2c_clock, tv_in_fifo_read, tv_in_fifo_clock, tv_in_iso,
	  tv_in_reset_b, tv_in_clock;
   inout  tv_in_i2c_data;
        
   inout  [35:0] ram0_data;
   output [18:0] ram0_address;
   output ram0_adv_ld, ram0_clk, ram0_cen_b, ram0_ce_b, ram0_oe_b, ram0_we_b;
   output [3:0] ram0_bwe_b;
   
   inout  [35:0] ram1_data;
   output [18:0] ram1_address;
   output ram1_adv_ld, ram1_clk, ram1_cen_b, ram1_ce_b, ram1_oe_b, ram1_we_b;
   output [3:0] ram1_bwe_b;

   input  clock_feedback_in;
   output clock_feedback_out;
   
   inout  [15:0] flash_data;
   output [23:0] flash_address;
   output flash_ce_b, flash_oe_b, flash_we_b, flash_reset_b, flash_byte_b;
   input  flash_sts;
   
   output rs232_txd, rs232_rts;
   input  rs232_rxd, rs232_cts;

   input  mouse_clock, mouse_data, keyboard_clock, keyboard_data;

   input  clock_27mhz, clock1, clock2;

   output disp_blank, disp_clock, disp_rs, disp_ce_b, disp_reset_b;  
   input  disp_data_in;
   output  disp_data_out;
   
   input  button0, button1, button2, button3, button_enter, button_right,
	  button_left, button_down, button_up;
   input  [7:0] switch;
   output [7:0] led;

   inout [31:0] user1, user2, user3, user4;
   
   inout [43:0] daughtercard;

   inout  [15:0] systemace_data;
   output [6:0]  systemace_address;
   output systemace_ce_b, systemace_we_b, systemace_oe_b;
   input  systemace_irq, systemace_mpbrdy;

   output [15:0] analyzer1_data, analyzer2_data, analyzer3_data, 
		 analyzer4_data;
   output analyzer1_clock, analyzer2_clock, analyzer3_clock, analyzer4_clock;

	///////////////////////////////////////////////////////////////////////////
	//
	// Clock Assignments
	//
	/////////////////////////////////////////////////////////////////////////// 
	wire clock_50mhz, clock_50mhz_90, clock_50mhz_270, clock_25mhz, locked_ram, locked_25mhz;
	clock_gen cgen(.reset_button(button0), .clock_27mhz(clock_27mhz),
	.clock_feedback_in(clock_feedback_in), .clock_feedback_out(clock_feedback_out),
	.clock_50mhz(clock_50mhz), .clock_25mhz(clock_25mhz), .clock_50mhz_90(clock_50mhz_90),
	.clock_50mhz_270(clock_50mhz_270),
	.ram0_clk(ram0_clk), .ram1_clk(ram1_clk), .locked_ram(locked_ram), .locked_25mhz(locked_25mhz));
	assign led[0] = ~locked_ram;
	assign led[1] = ~locked_25mhz;
	
	///////////////////////////////////////////////////////////////////////////
	//
	// I/O Assignments
	//
	///////////////////////////////////////////////////////////////////////////

	// Audio Input and Output
	assign beep= 1'b0;
	assign audio_reset_b = 1'b0;
	assign ac97_synch = 1'b0;
	assign ac97_sdata_out = 1'b0;
	// ac97_sdata_in is an input

	// Video Output
	assign tv_out_ycrcb = 10'h0;
	assign tv_out_reset_b = 1'b0;
	assign tv_out_clock = 1'b0;
	assign tv_out_i2c_clock = 1'b0;
	assign tv_out_i2c_data = 1'b0;
	assign tv_out_pal_ntsc = 1'b0;
	assign tv_out_hsync_b = 1'b1;
	assign tv_out_vsync_b = 1'b1;
	assign tv_out_blank_b = 1'b1;
	assign tv_out_subcar_reset = 1'b0;

	// SRAMs
	// clock_feedback_in is an input

	// Flash ROM
	assign flash_data = 16'hZ;
	assign flash_address = 24'h0;
	assign flash_ce_b = 1'b1;
	assign flash_oe_b = 1'b1;
	assign flash_we_b = 1'b1;
	assign flash_reset_b = 1'b0;
	assign flash_byte_b = 1'b1;
	// flash_sts is an input

	// RS-232 Interface
	assign rs232_txd = 1'b1;
	assign rs232_rts = 1'b1;
	// rs232_rxd and rs232_cts are inputs

	// PS/2 Ports
	// mouse_clock, mouse_data, keyboard_clock, and keyboard_data are inputs


	// Buttons, Switches, and Individual LEDs
	assign led[7:2] = 6'b111111;
	// button0, button1, button2, button3, button_enter, button_right,
	// button_left, button_down, button_up, and switches are inputs

	// User I/Os
	assign user1 = 32'hZ;
	assign user2 = 32'hZ;
	assign user3 = 32'hZ;
	assign user4 = 32'hZ;

	// Daughtercard Connectors
	assign daughtercard = 44'hZ;

	// SystemACE Microprocessor Port
	assign systemace_data = 16'hZ;
	assign systemace_address = 7'h0;
	assign systemace_ce_b = 1'b1;
	assign systemace_we_b = 1'b1;
	assign systemace_oe_b = 1'b1;
	// systemace_irq and systemace_mpbrdy are inputs

   	//////////////////////////////////////////////////////////////////////////
	//
	// Reset Generation
	//
	// A shift register primitive is used to generate an active-high reset
	// signal that remains high for 16 clock cycles after configuration finishes
	// and the FPGA's internal clocks begin toggling.
	//
	////////////////////////////////////////////////////////////////////////////
	wire reset;
	SRL16 reset_sr(.D(1'b0), .CLK(clock_27mhz), .Q(reset),
		 		   .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
	defparam reset_sr.INIT = 16'hFFFF;
	
   	//////////////////////////////////////////////////////////////////////////
	//
	// OUR MODULES: ntsc_capture
	// 				memory_interface
	// 				lpf
	// 				projective_transform,
	//
	////////////////////////////////////////////////////////////////////////////

	wire frame_flag;
	wire done_ntsc;
	wire done_pt;
	wire done_lpf;
	wire done_vga;
	wire ntsc_flag;
	wire pt_flag;
	wire lpf_flag;
	wire vga_flag;
	wire [35:0] ntsc_pixels;
	wire [35:0] vga_pixel;
	wire vwr;
 
	/*************************************
	******* NTSC BLOCK *******************
	**************************************/

	assign tv_in_fifo_read = 1'b0;
	assign tv_in_fifo_clock = 1'b0;
	assign tv_in_iso = 1'b0;
	assign tv_in_clock = clock_27mhz;

	wire dv;
	wire [2:0] fvh;
	wire [9:0] nx;
	wire [8:0] ny;
	
	wire ntsc_flag_cleaned;
	wire frame_flag_cleaned;
	wire debug_state;
	
	wire [9:0] ntsc_x;
	wire [8:0] ntsc_y;

	wire [3:0] nr;
	wire [9:0] midcr, midcb, midy;
	wire [1:0] color;
	wire i_flag;
	wire nwr;

	// PARAMETER SELECTION AND SETTING
	wire [9:0] GREEN_LUM_MAX;
	wire [9:0] GREEN_LUM_MIN;
	wire [9:0] GREEN_CR_MAX;
	wire [9:0] GREEN_CR_MIN;
	wire [9:0] GREEN_CB_MAX;
	wire [9:0] GREEN_CB_MIN;
	
	wire [9:0] ORANGE_LUM_MAX;
	wire [9:0] ORANGE_LUM_MIN;
	wire [9:0] ORANGE_CR_MAX;
	wire [9:0] ORANGE_CR_MIN;
	wire [9:0] ORANGE_CB_MAX;
	wire [9:0] ORANGE_CB_MIN;
	
	wire [9:0] PINK_LUM_MAX;
	wire [9:0] PINK_LUM_MIN;
	wire [9:0] PINK_CR_MAX;
	wire [9:0] PINK_CR_MIN;
	wire [9:0] PINK_CB_MAX;
	wire [9:0] PINK_CB_MIN;
	
	wire [9:0] BLUE_LUM_MAX;
	wire [9:0] BLUE_LUM_MIN;
	wire [9:0] BLUE_CR_MAX;
	wire [9:0] BLUE_CR_MIN;
	wire [9:0] BLUE_CB_MAX;
	wire [9:0] BLUE_CB_MIN;

	wire [63:0] hex_output;

	parameter_set pset(
		.clock(clock_50mhz), .reset(reset), 
		.switch(switch[7:3]),.hex_output(hex_output),
		.GREEN_LUM_MAX(GREEN_LUM_MAX),
		.GREEN_LUM_MIN(GREEN_LUM_MIN), 
		.GREEN_CR_MAX(GREEN_CR_MAX), 
		.GREEN_CR_MIN(GREEN_CR_MIN), 
		.GREEN_CB_MAX(GREEN_CB_MAX), 
		.GREEN_CB_MIN(GREEN_CB_MIN),

		.ORANGE_LUM_MAX(ORANGE_LUM_MAX),
		.ORANGE_LUM_MIN(ORANGE_LUM_MIN), 
		.ORANGE_CR_MAX(ORANGE_CR_MAX), 
		.ORANGE_CR_MIN(ORANGE_CR_MIN), 
		.ORANGE_CB_MAX(ORANGE_CB_MAX), 
		.ORANGE_CB_MIN(ORANGE_CB_MIN),

		.PINK_LUM_MAX(PINK_LUM_MAX),
		.PINK_LUM_MIN(PINK_LUM_MIN), 
		.PINK_CR_MAX(PINK_CR_MAX), 
		.PINK_CR_MIN(PINK_CR_MIN), 
		.PINK_CB_MAX(PINK_CB_MAX), 
		.PINK_CB_MIN(PINK_CB_MIN),

		.BLUE_LUM_MAX(BLUE_LUM_MAX),
		.BLUE_LUM_MIN(BLUE_LUM_MIN), 
		.BLUE_CR_MAX(BLUE_CR_MAX), 
		.BLUE_CR_MIN(BLUE_CR_MIN), 
		.BLUE_CB_MAX(BLUE_CB_MAX), 
		.BLUE_CB_MIN(BLUE_CB_MIN));

	display_16hex ds(reset, clock_27mhz, hex_output,
		disp_blank, disp_clock, disp_rs, disp_ce_b,
		disp_reset_b, disp_data_out);
	// END PARAMETER_SET
	
	wire enable_highlighting_and_xhairs;
	debounce db6(
	.clock(clock_50mhz), .reset(reset), .noisy(switch[2]),
	.clean(enable_highlighting_and_xhairs));
		
	
	ntsc_capture ntsc(
		.clock_50mhz(clock_50mhz_90),
		.clock_27mhz(clock_27mhz),
		.reset(reset), 
		.tv_in_reset_b(tv_in_reset_b),
		.tv_in_i2c_clock(tv_in_i2c_clock), 
		.tv_in_i2c_data(tv_in_i2c_data),
		.tv_in_line_clock1(tv_in_line_clock1),
		.tv_in_ycrcb(tv_in_ycrcb),
		.ntsc_pixels(ntsc_pixels), 
		.ntsc_flag(ntsc_flag_cleaned),
		.o_frame_flag(frame_flag_cleaned), 
		.o_x(ntsc_x), 
		.o_y(ntsc_y),
		.read_state_out(wr_ack),
		.wr_en(wr_en),
		.empty(empty),
		.ntsc_raw(nr),
		.midcr(midcr),
		.midcb(midcb),
		.midy(midy),
		.o_i_flag(i_flag),
		.o_color(color),
		.ntsc_will_request(nwr),
		.GREEN_LUM_MAX(GREEN_LUM_MAX),
		.GREEN_LUM_MIN(GREEN_LUM_MIN), 
		.GREEN_CR_MAX(GREEN_CR_MAX), 
		.GREEN_CR_MIN(GREEN_CR_MIN), 
		.GREEN_CB_MAX(GREEN_CB_MAX), 
		.GREEN_CB_MIN(GREEN_CB_MIN),

		.ORANGE_LUM_MAX(ORANGE_LUM_MAX),
		.ORANGE_LUM_MIN(ORANGE_LUM_MIN), 
		.ORANGE_CR_MAX(ORANGE_CR_MAX), 
		.ORANGE_CR_MIN(ORANGE_CR_MIN), 
		.ORANGE_CB_MAX(ORANGE_CB_MAX), 
		.ORANGE_CB_MIN(ORANGE_CB_MIN),
		
		.PINK_LUM_MAX(PINK_LUM_MAX),
		.PINK_LUM_MIN(PINK_LUM_MIN), 
		.PINK_CR_MAX(PINK_CR_MAX), 
		.PINK_CR_MIN(PINK_CR_MIN), 
		.PINK_CB_MAX(PINK_CB_MAX), 
		.PINK_CB_MIN(PINK_CB_MIN),
		
		.BLUE_LUM_MAX(BLUE_LUM_MAX),
		.BLUE_LUM_MIN(BLUE_LUM_MIN), 
		.BLUE_CR_MAX(BLUE_CR_MAX), 
		.BLUE_CR_MIN(BLUE_CR_MIN), 
		.BLUE_CB_MAX(BLUE_CB_MAX), 
		.BLUE_CB_MIN(BLUE_CB_MIN)
	);
	
	/***************************************************
	************ OBJECT_RECOGNITION BLOCK **************
	****************************************************/
		
	wire [9:0] a_x, b_x, c_x, d_x;
	wire [8:0] a_y, b_y, c_y, d_y;
	wire corners_flag;
	
	object_recognition objr(
		.clk(clock_50mhz),
		.reset(reset),
		.color(color),
		.interesting_x(ntsc_x),
		.interesting_y(ntsc_y),
		.frame_flag(frame_flag_cleaned),
		.interesting_flag(i_flag),
		.a_x(a_x), .a_y(a_y),
		.b_x(b_x), .b_y(b_y),
		.c_x(c_x), .c_y(c_y),
		.d_x(d_x), .d_y(d_y), 
		.corners_flag(corners_flag));
	
	/******************************************
	 ************ LPF & PT BLOCK **************
	 ******************************************/

	wire lpf_wr;
	wire [`LOG_WIDTH-1:0] lpf_x;
	wire [`LOG_HEIGHT-1:0] lpf_y;
	wire [`LOG_MEM-1:0] lpf_pixel_write;
	wire [`LOG_MEM-1:0] lpf_pixel_read;
	
	wire [`LOG_TRUNC-1:0] pixel_out_lpf;
	wire pixel_flag;
	wire request;
	wire [`LOG_TRUNC-1:0] pt_pixel;
	wire [`LOG_WIDTH-1:0] pt_x;
	wire [`LOG_HEIGHT-1:0] pt_y;
	wire pt_wr;
	wire ready_pt;

	// for writing the test pattern	
	wire lpf_testing;
	debounce db4(
		.clock(clock_50mhz), .reset(reset), .noisy(~switch[0]),
		.clean(lpf_testing));
	
	lpf dlpf(
		.clock(clock_50mhz),
		.reset(reset),
		.frame_flag(frame_flag_cleaned),
		.done_lpf(done_lpf),
		.lpf_flag(lpf_flag),
		.lpf_wr(lpf_wr),
		.lpf_x(lpf_x),
		.lpf_y(lpf_y),
		.lpf_pixel_write(lpf_pixel_write),
		.lpf_pixel_read(lpf_pixel_read),
		.request(request),
		.pixel(pixel_out_lpf),
		.pixel_flag(pixel_flag),
		.testing(lpf_testing));
	
	projective_transform_srl pt(
		.clk(clock_50mhz),
		.frame_flag(frame_flag_cleaned),
		.pixel(pixel_out_lpf),
		.pixel_flag(pixel_flag),
		.done_pt(done_pt),
		.a_x(a_x), .a_y(a_y),
		.b_x(b_x), .b_y(b_y),
		.c_x(c_x), .c_y(c_y),
		.d_x(d_x), .d_y(d_y),
		.corners_flag(corners_flag),
		.ptflag(ready_pt),
		.pt_pixel_write(pt_pixel),
		.pt_x(pt_x), .pt_y(pt_y),
		.pt_wr(pt_wr),
		.request_pixel(request));
				

	/*****************************************************
	*********** MEMORY_INTERFACE BLOCK *******************
	******************************************************/

	// default values	
	assign ram0_ce_b = 1'b0;
	assign ram0_oe_b = 1'b0;
	assign ram0_adv_ld = 1'b0;

	assign ram1_ce_b = 1'b0;
	assign ram1_oe_b = 1'b0;
	assign ram1_adv_ld = 1'b0;
	
	// memory_interface	
	wire mem0_wr;
	wire mem1_wr;
	wire [3:0] mem0_bwe;
	wire [3:0] mem1_bwe;
	wire [`LOG_ADDR-1:0] mem0_addr;
	wire [`LOG_ADDR-1:0] mem1_addr;
	wire [`LOG_MEM-1:0] mem0_read;
	wire [`LOG_MEM-1:0] mem1_read;
	wire [`LOG_MEM-1:0] mem0_write;
	wire [`LOG_MEM-1:0] mem1_write;
	wire [7:0] debug_locs;
	wire [3:0] debug_blocks;
	
	wire [`LOG_HCOUNT-1:0] hcount;
	wire [`LOG_VCOUNT-1:0] vcount;

	wire mem0_wrt, mem1_wrt, mem0_wrr, mem1_wrr;
	wire [3:0] mem0_bwer;
	wire [3:0] mem1_bwer;
	wire [35:0] mem0_writet, mem1_writet, mem0_writer, mem1_writer;
	wire [`LOG_ADDR-1:0] mem0_addrr, mem1_addrr, mem0_addrt, mem1_addrt;
	
	wire enable_lpf_pt;
		debounce db5(
		.clock(clock_50mhz), .reset(reset), .noisy(~switch[1]),
		.clean(enable_lpf_pt));

	memory_interface mi(
		.clock(clock_50mhz), .reset(reset), 
		.frame_flag(frame_flag_cleaned), .ntsc_flag(ntsc_flag_cleaned),
		.ntsc_pixel(ntsc_pixels),.done_ntsc(done_ntsc), 
		.vga_flag(vga_flag),.done_vga(done_vga),.vga_pixel(vga_pixel),
		.vcount(vcount), .hcount(hcount), .vsync(vga_out_vsync),
		.mem0_addr(mem0_addrr),.mem1_addr(mem1_addrr), 
		.mem0_read(mem0_read),.mem1_read(mem1_read), 
		.mem0_write(mem0_writer),.mem1_write(mem1_writer), 
		.mem0_wr(mem0_wrr),.mem1_wr(mem1_wrr),
		.mem0_bwe(mem0_bwer),.mem1_bwe(mem1_bwer),
		.ntsc_x(ntsc_x), .ntsc_y(ntsc_y),
		.ready_pt(ready_pt),
		.lpf_flag(lpf_flag & enable_lpf_pt), .lpf_wr(lpf_wr),
		.lpf_pixel_read(lpf_pixel_read),
		.lpf_pixel_write(lpf_pixel_write),
		.done_lpf(done_lpf),
		.lpf_x(lpf_x), .lpf_y(lpf_y),
		.pt_x(pt_x), .pt_y(pt_y),
		.pt_flag(pt_wr & enable_lpf_pt), .pt_pixel(pt_pixel),
		.nwr(nwr), .vwr(vwr), .done_pt(done_pt));

	wire enter_clean;
	debounce db3(
		.clock(clock_50mhz), .reset(reset), .noisy(~button_enter),
		.clean(enter_clean));
   	
	// TEST PATTERN FOR TESTING MEMORY_INTERFACE AND OTHER MODULES
	zbt_test_pattern ztp(
			.clock(clock_50mhz), .reset(reset), .start(enter_clean),
			.mem0_addr(mem0_addrt), .mem1_addr(mem1_addrt),
			.mem0_write(mem0_writet), .mem1_write(mem1_writet),
			.mem0_wr(mem0_wrt), .mem1_wr(mem1_wrt));
   	
	assign mem0_wr = (enter_clean) ? mem0_wrt : mem0_wrr;
	assign mem0_bwe = (enter_clean) ? 4'b1111 : mem0_bwer;
	assign mem0_addr = (enter_clean) ? mem0_addrt : mem0_addrr;
	assign mem0_write = (enter_clean) ? mem0_writet : mem0_writer;
	assign mem1_wr = (enter_clean) ? mem1_wrt : mem1_wrr;
	assign mem1_bwe = (enter_clean) ? 4'b1111 : mem1_bwer;
	assign mem1_addr = (enter_clean) ? mem1_addrt : mem1_addrr;
	assign mem1_write = (enter_clean) ? mem1_writet : mem1_writer;
	
	zbt_map mem0(
		.clock(clock_50mhz), .cen(1'b1), 
		.we(mem0_wr), .bwe(mem0_bwe), .addr(mem0_addr),
		.write_data(mem0_write), .read_data(mem0_read), 
		.ram_we_b(ram0_we_b), .ram_bwe_b(ram0_bwe_b),
		.ram_address(ram0_address), .ram_data(ram0_data),
		.ram_cen_b(ram0_cen_b));
	
	zbt_map mem1(
		.clock(clock_50mhz), .cen(1'b1), 
		.we(mem1_wr), .bwe(mem1_bwe), .addr(mem1_addr),
		.write_data(mem1_write), .read_data(mem1_read), 
		.ram_we_b(ram1_we_b), .ram_bwe_b(ram1_bwe_b),
		.ram_address(ram1_address), .ram_data(ram1_data), 
		.ram_cen_b(ram1_cen_b));
	
	/*************************************
	*******  VGA BLOCK *******************
	**************************************/
	vga_write vga(
		.clock(clock_50mhz), .vclock(clock_25mhz), 
		.reset(reset), .frame_flag(frame_flag_cleaned), 
		.vga_pixel(vga_pixel), 
		.done_vga(done_vga), .vga_flag(vga_flag), 
		.vga_out_red(vga_out_red), 
		.vga_out_green(vga_out_green), 
		.vga_out_blue(vga_out_blue),
		.vga_out_sync_b(vga_out_sync_b), 
		.vga_out_blank_b(vga_out_blank_b), 
		.vga_out_pixel_clock(vga_out_pixel_clock),
		.vga_out_hsync(vga_out_hsync), 
		.vga_out_vsync(vga_out_vsync),
		.clocked_hcount(hcount),
		.clocked_vcount(vcount),
		.a_x(a_x), .a_y(a_y),
		.b_x(b_x), .b_y(b_y),
		.c_x(c_x), .c_y(c_y),
		.d_x(d_x), .d_y(d_y),
		.vga_will_request(vwr),
		.enable_xhairs(enable_highlighting_and_xhairs)); 

	/*************************************
	******* LOGIC_ANALYZER ***************
	**************************************/
	
	assign analyzer1_clock = 1'b1;
	assign analyzer2_clock = 1'b1;
	assign analyzer3_clock = 1'b1;
	assign analyzer4_clock = 1'b1;
	assign analyzer1_data = 16'h0;
	assign analyzer2_data = 16'h0;
	assign analyzer3_data = 16'h0;
	assign analyzer4_data = 16'h0;
endmodule

module debounce (input reset, clock, noisy,
                 output reg clean);

   reg [19:0] count;
   reg new;

   always @(posedge clock)
     if (reset) begin new <= noisy; clean <= noisy; count <= 0; end
     else if (noisy != new) begin new <= noisy; count <= 0; end
     else if (count == 650000) clean <= new;
     else count <= count+1;

endmodule
