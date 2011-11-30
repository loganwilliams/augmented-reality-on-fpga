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

module labkit (beep, audio_reset_b, ac97_sdata_out, ac97_sdata_in, ac97_synch,
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

	////////////////////////////////////////////////////////////////////////////
	//
	// Clock Assignments
	//
	//////////////////////////////////////////////////////////////////////////// 
  
	wire clock_65mhz; // TODO: decide what to do with this clock	

	// generate 25 mhz clock
	wire clock_25mhz_unbuf,clock_25mhz;
	DCM vclk3(.CLKIN(clock_27mhz),.CLKFX(clock_25mhz_unbuf));
	// synthesis attribute CLKFX_DIVIDE of vclk3 is 15
	// synthesis attribute CLKFX_MULTIPLY of vclk3 is 14
	// synthesis attribute CLK_FEEDBACK of vclk3 is NONE
	// synthesis attribute CLKIN_PERIOD of vclk3 is 37
	BUFG vclk4(.O(clock_25mhz),.I(clock_25mhz_unbuf));

	// generate 65 mhz clock
	wire clock_65mhz_unbuf,clock_65mhz_buf;
	DCM vclk1(.CLKIN(clock_25mhz),.CLKFX(clock_65mhz_unbuf));
	// synthesis attribute CLKFX_DIVIDE of vclk1 is 1
	// synthesis attribute CLKFX_MULTIPLY of vclk1 is 3
	// synthesis attribute CLK_FEEDBACK of vclk1 is NONE
	// synthesis attribute CLKIN_PERIOD of vclk1 is 40
	BUFG vclk2(.O(clock_65mhz_buf),.I(clock_65mhz_unbuf));
  


	wire locked;
	ramclock rc(.ref_clock(clock_65mhz_buf), .fpga_clock(clock_65mhz),
				.ram0_clock(ram0_clk), .ram1_clock(ram1_clk),
				.clock_feedback_in(clock_feedback_in),
				.clock_feedback_out(clock_feedback_out), .locked(locked));

	////////////////////////////////////////////////////////////////////////////
	//
	// I/O Assignments
	//
	////////////////////////////////////////////////////////////////////////////

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

	// LED Displays
	assign disp_blank = 1'b1;
	assign disp_clock = 1'b0;
	assign disp_rs = 1'b0;
	assign disp_ce_b = 1'b1;
	assign disp_reset_b = 1'b0;
	assign disp_data_out = 1'b0;
	// disp_data_in is an input

	// Buttons, Switches, and Individual LEDs
	assign led = 8'hFF;
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
	// OUR MODULES: 		ntsc_capture
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


  
	/*************************************
	******* NTSC BLOCK *******************
	**************************************/

	// tv_in_ycrcb, tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, 
	// tv_in_aef, tv_in_hff, and tv_in_aff are inputs
	
	// use below if NOT using ntsc_capture
	/*assign tv_in_i2c_clock = 1'b0;
	assign tv_in_fifo_read = 1'b0;
	assign tv_in_fifo_clock = 1'b0;
	assign tv_in_iso = 1'b0;
	assign tv_in_reset_b = 1'b0;
	assign tv_in_clock = 1'b0;
	assign tv_in_i2c_data = 1'bZ;*/
	// use above if NOT using ntsc_capture

   	// use below if using ntsc_capture	
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

        // This dummy module should generate a train of pixels with linearly increasing luminosities
        // in the x direction, and a frame_flag every 640*480 pixels
   
	/*
	dummy_ntsc_capture ntsc(.clk(clock_27mhz), .clock_27mhz(clock_27mhz), .reset(reset), 
					  .tv_in_reset_b(tv_in_reset_b),.tv_in_i2c_clock(tv_in_i2c_clock), 
					  .tv_in_i2c_data(tv_in_i2c_data),.tv_in_line_clock1(tv_in_line_clock1),
					  .tv_in_ycrcb(tv_in_ycrcb),.ntsc_pixels(ntsc_pixels), 
					  .ntsc_flag(ntsc_flag),.frame_flag(frame_flag), .x(ntsc_x), .y(ntsc_y));
*/

	ntsc_capture ntsc(.clock_65mhz(clock_65mhz), .clock_27mhz(clock_27mhz), .reset(reset), 
					  .tv_in_reset_b(tv_in_reset_b),.tv_in_i2c_clock(tv_in_i2c_clock), 
					  .tv_in_i2c_data(tv_in_i2c_data),.tv_in_line_clock1(tv_in_line_clock1),
					  .tv_in_ycrcb(tv_in_ycrcb),.ntsc_pixels(ntsc_pixels), 
					  .ntsc_flag(ntsc_flag),.frame_flag(frame_flag), .output_x(ntsc_x), .y(ntsc_y));
					  
	clean nclean(.clock_65mhz(clock_65mhz), .flag(ntsc_flag),
					.clean_flag(ntsc_flag_cleaned));
	
	clean fclean(.clock_65mhz(clock_65mhz), .flag(frame_flag),
		.clean_flag(frame_flag_cleaned));
  
	// use above if using ntsc_capture

	/*************************************
	******* SRAM BLOCK *******************
	**************************************/
	// use below if not using memory_interface
	/*
	assign ram0_data = 36'hZ;
	assign ram0_address = 19'h0;
	assign ram0_adv_ld = 1'b0;
	assign ram0_cen_b = 1'b1;
	assign ram0_ce_b = 1'b1;
	assign ram0_oe_b = 1'b1;
	assign ram0_we_b = 1'b1;
	assign ram0_bwe_b = 4'hF;
	assign ram1_data = 36'hZ; 
	assign ram1_address = 19'h0;
	assign ram1_adv_ld = 1'b0;
	assign ram1_cen_b = 1'b1;
	assign ram1_ce_b = 1'b1;
	assign ram1_oe_b = 1'b1;
	assign ram1_we_b = 1'b1;
	assign ram1_bwe_b = 4'hF;   
	*/
	// use above if not using memory_interface

	// use below if using memory_interface
	
	assign ram0_ce_b = 1'b0;
	assign ram0_oe_b = 1'b0;
	assign ram0_adv_ld = 1'b0;
	assign ram0_bwe_b = 4'h0;

	assign ram1_ce_b = 1'b0;
	assign ram1_oe_b = 1'b0;
	assign ram1_adv_ld = 1'b0;
	assign ram1_bwe_b = 4'h0;
	
		// from memory_interface to zbt_6111 module
	
	wire mem0_wr;
	wire mem1_wr;
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

	memory_interface mi(
		.clock(clock_65mhz), .reset(reset), .frame_flag(frame_flag_cleaned), 
		.ntsc_flag(ntsc_flag_cleaned),.ntsc_pixel(ntsc_pixels),.done_ntsc(done_ntsc), 
		.vga_flag(vga_flag),.done_vga(done_vga),.vga_pixel(vga_pixel),
		.vcount(vcount), .hcount(hcount), .vsync(vga_out_vsync),
		.mem0_addr(mem0_addr),.mem1_addr(mem1_addr), 
		.mem0_read(mem0_read),.mem1_read(mem1_read), 
		.mem0_write(mem0_write),.mem1_write(mem1_write), 
		.mem0_wr(mem0_wr),.mem1_wr(mem1_wr),
		.ntsc_x(ntsc_x), .ntsc_y(ntsc_y));

	zbt_6111 mem0(
		.clk(clock_65mhz), .cen(1'b1), 
		.we(mem0_wr), .addr(mem0_addr),
		.write_data(mem0_write), .read_data(mem0_read), 
		.ram_we_b(ram0_we_b), .ram_address(ram0_address), 
		.ram_data(ram0_data), .ram_cen_b(ram0_cen_b));
	
	zbt_6111 mem1(
		.clk(clock_65mhz), .cen(1'b1), 
		.we(mem1_wr), .addr(mem1_addr),
		.write_data(mem1_write), .read_data(mem1_read), 
		.ram_we_b(ram1_we_b), .ram_address(ram1_address), 
		.ram_data(ram1_data), .ram_cen_b(ram1_cen_b));
	
	// use above if using memory_interface
	/*

   wire [13:0] addra;
   wire [13:0] addrb;
   wire        wea;
   
   
   
	bram_interface bi(.clk(clock_65mhz), .ntsc_flag(ntsc_flag_cleaned), .frame_flag(frame_flag_cleaned),
		.ntsc_pixels(ntsc_pixels), .vga_flag(vga_flag), .vsync(vga_out_vsync), .done_vga(done_vga),
		.vga_pixels(vga_pixel), .addra(addra), .addrb(addrb), .wea(wea));
*/
	/*************************************
	*******  VGA BLOCK *******************
	**************************************/
   	// use below if not using vga
		/*
	assign vga_out_red = 8'h0;
	assign vga_out_green = 8'h0;
	assign vga_out_blue = 8'h0;
	assign vga_out_sync_b = 1'b1;
	assign vga_out_blank_b = 1'b1;
	assign vga_out_pixel_clock = 1'b0;
	assign vga_out_hsync = 1'b0;
	assign vga_out_vsync = 1'b0;*/
	// use above if not using vga
	
	// use below if using vga

   
	vga_write vga(
		.clock(clock_65mhz), .vclock(clock_25mhz), 
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
		.clocked_vcount(vcount));
	// use above if using vga
	
	// use below if testing vga
	//dummy_mem_int dummy(.clock(clock_65mhz), .reset(reset), .frame_flag(frame_flag), .vga_pixel(vga_pixel), .done_vga(done_vga), .vga_flag(vga_flag), .hcount(hcount));
	// use above if testing vga


	/*************************************
	******* LOGIC_ANALYZER ***************
	**************************************/
	// comment & uncomment below as necessary if not used
	//assign analyzer1_clock = 1'b1;
	//assign analyzer2_clock = 1'b1;
	//assign analyzer3_clock = 1'b1;
	//assign analyzer4_clock = 1'b1;
	//assign analyzer1_data = 16'h0;
	//assign analyzer2_data = 16'h0;
	//assign analyzer3_data = 16'h0;
	//assign analyzer4_data = 16'h0;

	// user-defined analyzers

	//	assign analyzer1_data = {frame_flag_cleaned, ntsc_flag_cleaned, dv, vga_flag, done_vga, done_ntsc, fvh, 7'b0};
	//	assign analyzer3_data = {nx[9:0], ntsc_flag, debug_state, 4'b0};

   assign analyzer1_data = {frame_flag_cleaned, ntsc_flag_cleaned, dv, done_vga, done_ntsc, vga_flag,  fvh, 7'b0};
   assign analyzer3_data = {done_vga, ntsc_flag, ntsc_x[9:0], 4'b0};
   assign analyzer2_data = {ntsc_y[8:0], ntsc_pixels[35:28]};
   assign analyzer4_data = {ram0_address[7:0], ram1_address[7:0]};
   
   assign analyzer3_clock = tv_in_line_clock1;
   assign analyzer1_clock = clock_27mhz;
   assign analyzer2_clock = clock_65mhz;
   assign analyzer4_clock = clock_25mhz;
endmodule

// ramclock module
module ramclock(ref_clock, fpga_clock, ram0_clock, ram1_clock, 
	        clock_feedback_in, clock_feedback_out, locked);
   
   input ref_clock;                 // Reference clock input
   output fpga_clock;               // Output clock to drive FPGA logic
   output ram0_clock, ram1_clock;   // Output clocks for each RAM chip
   input  clock_feedback_in;        // Output to feedback trace
   output clock_feedback_out;       // Input from feedback trace
   output locked;                   // Indicates that clock outputs are stable
   
   wire  ref_clk, fpga_clk, ram_clk, fb_clk, lock1, lock2, dcm_reset, ram_clock;

   ////////////////////////////////////////////////////////////////////////////
   
   //To force ISE to compile the ramclock, this line has to be removed.
   //IBUFG ref_buf (.O(ref_clk), .I(ref_clock));
	
	assign ref_clk = ref_clock;
   
   BUFG int_buf (.O(fpga_clock), .I(fpga_clk));

   DCM int_dcm (.CLKFB(fpga_clock),
		.CLKIN(ref_clk),
		.RST(dcm_reset),
		.CLK0(fpga_clk),
		.LOCKED(lock1));
   // synthesis attribute DLL_FREQUENCY_MODE of int_dcm is "LOW"
   // synthesis attribute DUTY_CYCLE_CORRECTION of int_dcm is "TRUE"
   // synthesis attribute STARTUP_WAIT of int_dcm is "FALSE"
   // synthesis attribute DFS_FREQUENCY_MODE of int_dcm is "LOW"
   // synthesis attribute CLK_FEEDBACK of int_dcm  is "1X"
   // synthesis attribute CLKOUT_PHASE_SHIFT of int_dcm is "NONE"
   // synthesis attribute PHASE_SHIFT of int_dcm is 0
   
   BUFG ext_buf (.O(ram_clock), .I(ram_clk));
   
   IBUFG fb_buf (.O(fb_clk), .I(clock_feedback_in));
   
   DCM ext_dcm (.CLKFB(fb_clk), 
		    .CLKIN(ref_clk), 
		    .RST(dcm_reset),
		    .CLK0(ram_clk),
		    .LOCKED(lock2));
   // synthesis attribute DLL_FREQUENCY_MODE of ext_dcm is "LOW"
   // synthesis attribute DUTY_CYCLE_CORRECTION of ext_dcm is "TRUE"
   // synthesis attribute STARTUP_WAIT of ext_dcm is "FALSE"
   // synthesis attribute DFS_FREQUENCY_MODE of ext_dcm is "LOW"
   // synthesis attribute CLK_FEEDBACK of ext_dcm  is "1X"
   // synthesis attribute CLKOUT_PHASE_SHIFT of ext_dcm is "NONE"
   // synthesis attribute PHASE_SHIFT of ext_dcm is 0

   SRL16 dcm_rst_sr (.D(1'b0), .CLK(ref_clk), .Q(dcm_reset),
		     .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
   // synthesis attribute init of dcm_rst_sr is "000F";
   

   OFDDRRSE ddr_reg0 (.Q(ram0_clock), .C0(ram_clock), .C1(~ram_clock),
		      .CE (1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));
   OFDDRRSE ddr_reg1 (.Q(ram1_clock), .C0(ram_clock), .C1(~ram_clock),
		      .CE (1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));
   OFDDRRSE ddr_reg2 (.Q(clock_feedback_out), .C0(ram_clock), .C1(~ram_clock),
		      .CE (1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));

   assign locked = lock1 && lock2;
   
endmodule
