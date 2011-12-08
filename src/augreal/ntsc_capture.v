`default_nettype none
// comment out when testing
`include "params.v"

module ntsc_capture(
		    input 	      clock_65mhz, // the main system clock
		    input 	      clock_27mhz,
		    input 	      reset, // reset line
		    output 	      tv_in_reset_b, // these are all labkit wires
		    output 	      tv_in_i2c_clock, //   |
		    inout 	      tv_in_i2c_data, //    |
		    input 	      tv_in_line_clock1, // |
		    input [19:0]      tv_in_ycrcb, //       |
		    output reg [35:0] ntsc_pixels, // outputs two sets of pixels in Y/Cr/Cb/Y/Cr/Cb format
		    output reg 	      ntsc_flag, // a flag that goes high when a pixel is being output
		    output reg [1:0] o_color, // these outputs are for object_recognition. this indicates the color of the recognized pixel
		    output reg 	      o_i_flag, // a flag that indicates the data is good
		    output reg 	      o_frame_flag,
		    output reg [9:0]  o_x,
		    output reg [8:0] o_y,
			 output empty,
			 output reg wr_en,
			 output read_state_out,
			 output [3:0] ntsc_raw,
			 output reg [9:0] midcr,
			 output reg [9:0] midcb,
			 output reg [9:0] midy
		    ); // a flag that indicates when a new frame begins

   // initialize the adv7185 video ADC
   adv7185init adv7185(.reset(reset), .clock_27mhz(clock_27mhz), .source(1'b0),
		       .tv_in_reset_b(tv_in_reset_b), .tv_in_i2c_clock(tv_in_i2c_clock),
		       .tv_in_i2c_data(tv_in_i2c_data));

   wire [29:0] 			     ycrcb;
   wire [2:0] 			     fvh;
   
   wire 			     dv;

   reg [63:0] 			     din;
   //reg 				     wr_en = 0;
   wire 			     rd_en;
   wire [63:0] 			     dout;
   wire 			     full, valid;

   reg [17:0] 			     pixel_buffer;

   reg 				     read_state;
   assign read_state_out = read_state;
   
   //wire 			     bufclock;
   
   
   //BUFG invclock(.I(clock_65mhz), .O(bufclock));

   ntf n2f(.din(din), .rd_clk(clock_65mhz), .rd_en(rd_en),
		    .rst(reset), .wr_clk(tv_in_line_clock1), .wr_en(wr_en),
		    .dout(dout), .empty(empty), .full(full), .valid(valid)
		    );
   
	

   // this module decodes the data and outputs the ycrcb pair
   ntsc_decode decode(.clk(tv_in_line_clock1), .reset(reset),
		      .tv_in_ycrcb(tv_in_ycrcb[19:10]), .ycrcb(ycrcb),
		      .v(fvh[1]), .h(fvh[0]), .data_valid(dv), .f(fvh[2]));

   reg 				     state = 0;
   reg [9:0] 			     x = 0;
   reg [8:0] 			     y = 0;
   
   wire 			     sv;
   wire 			     sh;
   reg 				     rh;
   reg 				     rv;
   
   reg 				     pulseonce;

   // create some convenience variables
   wire [9:0] 			     cr, cb, lum;
   wire 			     f, v, h;
   
   assign cr = ycrcb[19:10];
   assign cb = ycrcb[9:0];
   assign lum = ycrcb[29:20];

   assign f = fvh[2];
   assign v = fvh[1];
   assign h = fvh[0];

   wire [8:0] 			     corrected_y;

   assign corrected_y = y - 25;
   
   assign ntsc_raw = din[28:25];

   synchronize syncv(.sig(v), .syncsig(sv), .reset(rv));
   synchronize synch(.sig(h), .syncsig(sh), .reset(rh));

   // synchronize to the external video line clock
   always @ (posedge tv_in_line_clock1) begin
      
      if (sv) begin
	 y <= f;
	 x <= 0;
	 rv <= 1;
      end else rv <= 0;
      
      if (sh) begin
	 y <= y + 2;
	 x <= 0;
	 rh <= 1;
      end else begin
	 rh <= 0;
      end
      
      if (((y > 504) | v) & f & ~pulseonce) begin
	 din[26] <= 1;
	 din[27] <= 0;
	 
	 wr_en <= 1;
	 
	 pulseonce <= 1;
      end else begin
	 wr_en <= 0;
	 
      end
      
	 if (~f) begin
	    pulseonce <= 0;
	 end
      
      if (dv) begin

	 if (y >= 25 && y < 505 && x < 640) begin // above 480 lines are blanked
	    
	    if (x == 320 && y == 265) begin
	       midcr <= cr;
	       midcb <= cb;
	       midy <= ycrcb[29:20];
	    end
	    
	    if (state == 0) begin
	       
	       // ORANGE
	       if ((cb < `ORANGE_CB_MAX) & 
		   (cr > `ORANGE_CR_MIN) & 
		   (lum > `ORANGE_LUM_MIN)) begin
		  
		  pixel_buffer[17:10] <= 8'b11111111;
		  pixel_buffer[9:5]<= 5'b11111;
		  pixel_buffer[4:0] <= 5'b00000;

		  // we have detected a pixel, so spit out an interesting flag, and
		  // the current coordinates
		  din[27] <= 0;
		  
		  din[4] <= 1;
		  din[6:5] <= 0;
		  din[25:16] <= x;
		  din[15:7] <= corrected_y;
		 
		  wr_en <= 1;
		  
		  // GREEN
	       end else if (
			    (lum < `GREEN_LUM_MAX) & 
				 (lum > `GREEN_LUM_MIN) &
			    (cr > `GREEN_CR_MIN) & 
				 (cr < `GREEN_CR_MAX) &
			    (cb > `GREEN_CB_MIN) &
				 (cb < `GREEN_CB_MAX)) begin

		  pixel_buffer[17:10] <= 8'b11111111;
		  pixel_buffer[9:5] <= 5'b11000;
		  pixel_buffer[4:0] <= 5'b00000;
		  din[27] <= 0;
		  
		  din[4] <= 1;
		  din[6:5] <= 2'b11;
		  din[25:16] <= x;
		  din[15:7] <= corrected_y;
		 
		  wr_en <= 1;

		  
		  // PINK
	       end else if ((cb > `PINK_CB_MIN) & 
			    (cr > `PINK_CR_MIN) & 
			    (lum > `PINK_LUM_MIN)) begin
		  
		  pixel_buffer[17:10] <= 8'b11111111;
		  pixel_buffer[9:5] <= 5'b11111;
		  pixel_buffer[4:0] <= 5'b11111;
		  din[27] <= 0;
		  
		  din[4] <= 1;
		  din[6:5] <= 2'b01;
		  din[25:16] <= x;
		  din[15:7] <= corrected_y;
		  wr_en <= 1;

		  
		  // BLUE
	       end else if ((cb > `BLUE_CB_MIN) & 
			    (cr < `BLUE_CR_MAX) & 
			    (lum > `BLUE_LUM_MIN)) begin
		  
		  pixel_buffer[17:10] <= 8'b11111111;
		  pixel_buffer[9:5] <= 5'b00000;
		  pixel_buffer[4:0] <= 5'b11111;
		  din[27] <= 0;
		  
		  din[4] <= 1;
		  din[6:5] <=2'b10;
		  din[25:16] <= x;
		  din[15:7] <= corrected_y;
		  wr_en <= 1;

		  
	       end else begin 
		  pixel_buffer[17:10] <= ycrcb[29:22];
		  pixel_buffer[9:5] <= ycrcb[19:15];
		  pixel_buffer[4:0] <= ycrcb[9:5];
		  wr_en <= 0;
	       end
			 
			 

	       state <= 1;

	       // we only output on state 0 if interesting pixels have been
	       // detected
	       
	    end else begin
	       state <= 0;

	       din[63:46] <= pixel_buffer;


	       // ORANGE
	       if ((cb < `ORANGE_CB_MAX) & 
		   (cr > `ORANGE_CR_MIN) & 
		   (lum > `ORANGE_LUM_MIN)) begin
		  din[45:38] <= 8'b11111111;
		  din[37:33] <= 5'b11111;
		  din[32:28] <= 5'b00000;
		  din[4] <= 1;
		  din[6:5] <= 2'b00;

		  // GREEN
	       end else if ((cb < `GREEN_CB_MAX) & 
			    (cr < `GREEN_CR_MAX) & 
			    (lum > `GREEN_LUM_MIN) &
			    (lum < `GREEN_LUM_MAX) & 
			    (cr > `GREEN_CR_MIN) & 
			    (cb > `GREEN_CB_MIN)) begin
		  
		  din[45:38] <= 8'b11111111;
		  din[37:33] <= 5'b11000;
		  din[32:28] <= 5'b00000;
		  din[4] <= 1;
		  din[6:5] <= 2'b11;


		  // PINK
	       end else if ((cb > `PINK_CB_MIN) & 
			    (cr > `PINK_CR_MIN) & 
			    (lum > `PINK_LUM_MIN)) begin
		  
		  
		  din[45:38] <= 8'b11111111;
		  din[37:33] <= 5'b11111;
		  din[32:28] <= 5'b11111;
		  din[4] <= 1;
		  din[6:5] <= 2'b01;


		  // BLUE
	       end else if ((cb > `BLUE_CB_MIN) & 
			    (cr < `BLUE_CR_MAX) & 
			    (lum > `BLUE_LUM_MIN)) begin
		  
		  din[45:38] <= 8'b11111111;
		  din[37:33] <= 5'b00000;
		  din[32:28] <= 5'b11111;	
		  din[4] <= 1;
		  din[6:5] <= 2'b10;
		  
	       end else begin // if ((cb > BLUE_CB_MIN) &...
		  
		  din[45:38] <= ycrcb[29:22];
		  din[37:33] <= ycrcb[19:15];
		  din[32:28] <= ycrcb[9:5];
		  din[6:5] <= 2'b00;
		  din[4] <= 1'b0;
		  
	       end // else: !if((cb > BLUE_CB_MIN) &...
	       
	       
	       
	       din[27] <= 1;
	       din[26] <= 0;
	       din[25:16] <= x;
	       din[15:7] <= corrected_y;

	       wr_en <= 1;
	       
	    end // else: !if(state == 0)

	    x <= x + 1; // increment the x coordinate
	 end // if (y < 480 && x < 640)
      end // if (dv)
      

      if (reset) begin
	 state <= 0;
	 x<= 0;
	 y <= 0;
      end   
   end // always @ (posedge tv_in_line_clock1)

   assign rd_en = ~empty;
	reg undelntsc;
   
   // Synchronize outputs to main system clock
   always @ (posedge clock_65mhz) begin
      // if the FIFO is not empty
      if (rd_en) begin
	 read_state <= 1;
      end else begin
	 read_state <= 0;
      end
      // we have data
      if (read_state) begin
	 ntsc_pixels <= dout[63: 28];
	 ntsc_flag <= dout[27];
	 o_frame_flag <= dout[26];
	 o_x <= dout[25:16];
	 o_y <= dout[15:7];
	 o_color <= dout[6:5];
	 o_i_flag <= dout[4];
	 
      end else begin
	 ntsc_pixels <= 0;
	 ntsc_flag <= 0;
	 o_frame_flag <= 0;
	 o_x <= 0;
	 o_y <= 0;
	 o_color <= 0;
	 o_i_flag <= 0;
      end
      
   end   

endmodule // ntsc_capture


// This module takes an input (sig), and produces an output (syncsig),
// that goes high as soon as sig does, and stays high until reset goes high.
module synchronize(
		   input      sig,
		   input      reset,
		   output reg syncsig);
   
   always @(*) begin
      if (sig) syncsig <= 1;
      if (reset) syncsig <= 0;
   end
endmodule


// These modules are used to grab input NTSC video data from the RCA
// phono jack on the right hand side of the 6.111 labkit (connect
// the camera to the LOWER jack).
//

/////////////////////////////////////////////////////////////////////////////
//
// NTSC decode - 16-bit CCIR656 decoder
// By Javier Castro
// This module takes a stream of LLC data from the adv7185
// NTSC/PAL video decoder and generates the corresponding pixels,
// that are encoded within the stream, in YCrCb format.

// Make sure that the adv7185 is set to run in 16-bit LLC2 mode.

module ntsc_decode(clk, reset, tv_in_ycrcb, ycrcb, f, v, h, data_valid);
   
   // clk - line-locked clock (in this case, LLC1 which runs at 27Mhz)
   // reset - system reset
   // tv_in_ycrcb - 10-bit input from chip. should map to pins [19:10]
   // ycrcb - 24 bit luminance and chrominance (8 bits each)
   // f - field: 1 indicates an even field, 0 an odd field
   // v - vertical sync: 1 means vertical sync
   // h - horizontal sync: 1 means horizontal sync
   
   input clk;
   input reset;
   input [9:0] tv_in_ycrcb; // modified for 10 bit input - should be P[19:10]
   output [29:0] ycrcb;
   output 	 f;
   output 	 v;
   output 	 h;
   output 	 data_valid;
   // output [4:0] state;

   parameter 	SYNC_1 = 0;
   parameter 	SYNC_2 = 1;
   parameter 	SYNC_3 = 2;
   parameter 	SAV_f1_cb0 = 3;
   parameter 	SAV_f1_y0 = 4;
   parameter 	SAV_f1_cr1 = 5;
   parameter 	SAV_f1_y1 = 6;
   parameter 	EAV_f1 = 7;
   parameter 	SAV_VBI_f1 = 8;
   parameter 	EAV_VBI_f1 = 9;
   parameter 	SAV_f2_cb0 = 10;
   parameter 	SAV_f2_y0 = 11;
   parameter 	SAV_f2_cr1 = 12;
   parameter 	SAV_f2_y1 = 13;
   parameter 	EAV_f2 = 14;
   parameter 	SAV_VBI_f2 = 15;
   parameter 	EAV_VBI_f2 = 16;

   
   
   
   // In the start state, the module doesn't know where
   // in the sequence of pixels, it is looking.

   // Once we determine where to start, the FSM goes through a normal
   // sequence of SAV process_YCrCb EAV... repeat

   // The data stream looks as follows
   // SAV_FF | SAV_00 | SAV_00 | SAV_XY | Cb0 | Y0 | Cr1 | Y1 | Cb2 | Y2 | ... | EAV sequence
   // There are two things we need to do:
   //   1. Find the two SAV blocks (stands for Start Active Video perhaps?)
   //   2. Decode the subsequent data

   reg [4:0] 	 current_state = 5'h00;
   reg [9:0] 	 y = 10'h000;  // luminance
   reg [9:0] 	 cr = 10'h000; // chrominance
   reg [9:0] 	 cb = 10'h000; // more chrominance
   
   //assign 	state = current_state;
   
   always @ (posedge clk)
     begin
	if (reset)
	  begin

	  end
	else
	  begin
	     // these states don't do much except allow us to know where we are in the stream.
	     // whenever the synchronization code is seen, go back to the sync_state before
	     // transitioning to the new state
	     case (current_state)
	       SYNC_1: current_state <= (tv_in_ycrcb == 10'h000) ? SYNC_2 : SYNC_1;
	       SYNC_2: current_state <= (tv_in_ycrcb == 10'h000) ? SYNC_3 : SYNC_1;
	       SYNC_3: current_state <= (tv_in_ycrcb == 10'h200) ? SAV_f1_cb0 :
					(tv_in_ycrcb == 10'h274) ? EAV_f1 :
					(tv_in_ycrcb == 10'h2ac) ? SAV_VBI_f1 :
					(tv_in_ycrcb == 10'h2d8) ? EAV_VBI_f1 :
					(tv_in_ycrcb == 10'h31c) ? SAV_f2_cb0 :
					(tv_in_ycrcb == 10'h368) ? EAV_f2 :
					(tv_in_ycrcb == 10'h3b0) ? SAV_VBI_f2 :
					(tv_in_ycrcb == 10'h3c4) ? EAV_VBI_f2 : SYNC_1;
	       
	       SAV_f1_cb0: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f1_y0;
	       SAV_f1_y0: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f1_cr1;
	       SAV_f1_cr1: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f1_y1;
	       SAV_f1_y1: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f1_cb0;

	       SAV_f2_cb0: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f2_y0;
	       SAV_f2_y0: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f2_cr1;
	       SAV_f2_cr1: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f2_y1;
	       SAV_f2_y1: current_state <= (tv_in_ycrcb == 10'h3ff) ? SYNC_1 : SAV_f2_cb0;

	       // These states are here in the event that we want to cover these signals
	       // in the future. For now, they just send the state machine back to SYNC_1
	       EAV_f1: current_state <= SYNC_1;
	       SAV_VBI_f1: current_state <= SYNC_1;
	       EAV_VBI_f1: current_state <= SYNC_1;
	       EAV_f2: current_state <= SYNC_1;
	       SAV_VBI_f2: current_state <= SYNC_1;
	       EAV_VBI_f2: current_state <= SYNC_1;

	     endcase
	  end
     end // always @ (posedge clk)

   // implement our decoding mechanism

   wire y_enable;
   wire cr_enable;
   wire cb_enable;

   // if y is coming in, enable the register
   // likewise for cr and cb
   assign y_enable = (current_state == SAV_f1_y0) || 
	             (current_state == SAV_f1_y1) ||
	             (current_state == SAV_f2_y0) || 
	             (current_state == SAV_f2_y1);
   assign cr_enable = (current_state == SAV_f1_cr1) ||
	              (current_state == SAV_f2_cr1);
   assign cb_enable = (current_state == SAV_f1_cb0) ||
	              (current_state == SAV_f2_cb0);

   // f, v, and h only go high when active
   assign {v,h} = (current_state == SYNC_3) ? tv_in_ycrcb[7:6] : 2'b00;

   // data is valid when we have all three values: y, cr, cb
   assign data_valid = y_enable;
   assign ycrcb = {y,cr,cb};

   reg 	f = 0;
   
   always @ (posedge clk)
     begin
	y <= y_enable ? tv_in_ycrcb : y;
	cr <= cr_enable ? tv_in_ycrcb : cr;
	cb <= cb_enable ? tv_in_ycrcb : cb;
	f <= (current_state == SYNC_3) ? tv_in_ycrcb[8] : f;
     end
   
endmodule



///////////////////////////////////////////////////////////////////////////////
//
// 6.111 FPGA Labkit -- ADV7185 Video Decoder Configuration Init
//
// Created:
// Author: Nathan Ickes
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Register 0
///////////////////////////////////////////////////////////////////////////////

`define INPUT_SELECT                            4'h0
// 0: CVBS on AIN1 (composite video in)
// 7: Y on AIN2, C on AIN5 (s-video in)
// (These are the only configurations supported by the 6.111 labkit hardware)
`define INPUT_MODE                              4'h0
// 0: Autodetect: NTSC or PAL (BGHID), w/o pedestal
// 1: Autodetect: NTSC or PAL (BGHID), w/pedestal
// 2: Autodetect: NTSC or PAL (N), w/o pedestal
// 3: Autodetect: NTSC or PAL (N), w/pedestal
// 4: NTSC w/o pedestal
// 5: NTSC w/pedestal
// 6: NTSC 4.43 w/o pedestal
// 7: NTSC 4.43 w/pedestal
// 8: PAL BGHID w/o pedestal
// 9: PAL N w/pedestal
// A: PAL M w/o pedestal
// B: PAL M w/pedestal
// C: PAL combination N
// D: PAL combination N w/pedestal
// E-F: [Not valid]

`define ADV7185_REGISTER_0 {`INPUT_MODE, `INPUT_SELECT}

///////////////////////////////////////////////////////////////////////////////
// Register 1
///////////////////////////////////////////////////////////////////////////////

`define VIDEO_QUALITY                           2'h0
// 0: Broadcast quality
// 1: TV quality
// 2: VCR quality
// 3: Surveillance quality
`define SQUARE_PIXEL_IN_MODE                    1'b0
// 0: Normal mode
// 1: Square pixel mode
`define DIFFERENTIAL_INPUT                      1'b0
// 0: Single-ended inputs
// 1: Differential inputs
`define FOUR_TIMES_SAMPLING                     1'b0
// 0: Standard sampling rate
// 1: 4x sampling rate (NTSC only)
`define BETACAM                                 1'b0
// 0: Standard video input
// 1: Betacam video input
`define AUTOMATIC_STARTUP_ENABLE                1'b1
// 0: Change of input triggers reacquire
// 1: Change of input does not trigger reacquire

`define ADV7185_REGISTER_1 {`AUTOMATIC_STARTUP_ENABLE, 1'b0, `BETACAM, `FOUR_TIMES_SAMPLING, `DIFFERENTIAL_INPUT, `SQUARE_PIXEL_IN_MODE, `VIDEO_QUALITY}

///////////////////////////////////////////////////////////////////////////////
// Register 2
///////////////////////////////////////////////////////////////////////////////

`define Y_PEAKING_FILTER                        3'h4
// 0: Composite =  4.5dB,  s-video =  9.25dB
// 1: Composite =  4.5dB,  s-video =  9.25dB
// 2: Composite =  4.5dB,  s-video =  5.75dB
// 3: Composite =  1.25dB, s-video =  3.3dB
// 4: Composite =  0.0dB,  s-video =  0.0dB
// 5: Composite = -1.25dB, s-video = -3.0dB
// 6: Composite = -1.75dB, s-video = -8.0dB
// 7: Composite = -3.0dB,  s-video = -8.0dB
`define CORING                                  2'h0
// 0: No coring
// 1: Truncate if Y < black+8
// 2: Truncate if Y < black+16
// 3: Truncate if Y < black+32

`define ADV7185_REGISTER_2 {3'b000, `CORING, `Y_PEAKING_FILTER}

///////////////////////////////////////////////////////////////////////////////
// Register 3
///////////////////////////////////////////////////////////////////////////////

`define INTERFACE_SELECT                        2'h0
// 0: Philips-compatible
// 1: Broktree API A-compatible
// 2: Broktree API B-compatible
// 3: [Not valid]
`define OUTPUT_FORMAT                           4'h0
// 0: 10-bit @ LLC, 4:2:2 CCIR656
// 1: 20-bit @ LLC, 4:2:2 CCIR656
// 2: 16-bit @ LLC, 4:2:2 CCIR656
// 3: 8-bit @ LLC, 4:2:2 CCIR656
// 4: 12-bit @ LLC, 4:1:1
// 5-F: [Not valid]
// (Note that the 6.111 labkit hardware provides only a 10-bit interface to
// the ADV7185.)
`define TRISTATE_OUTPUT_DRIVERS                 1'b0
// 0: Drivers tristated when ~OE is high
// 1: Drivers always tristated
`define VBI_ENABLE                              1'b0
// 0: Decode lines during vertical blanking interval
// 1: Decode only active video regions

`define ADV7185_REGISTER_3 {`VBI_ENABLE, `TRISTATE_OUTPUT_DRIVERS, `OUTPUT_FORMAT, `INTERFACE_SELECT}

///////////////////////////////////////////////////////////////////////////////
// Register 4
///////////////////////////////////////////////////////////////////////////////

`define OUTPUT_DATA_RANGE                       1'b0
// 0: Output values restricted to CCIR-compliant range
// 1: Use full output range
`define BT656_TYPE                              1'b0
// 0: BT656-3-compatible
// 1: BT656-4-compatible

`define ADV7185_REGISTER_4 {`BT656_TYPE, 3'b000, 3'b110, `OUTPUT_DATA_RANGE}

///////////////////////////////////////////////////////////////////////////////
// Register 5
///////////////////////////////////////////////////////////////////////////////


`define GENERAL_PURPOSE_OUTPUTS                 4'b0000
`define GPO_0_1_ENABLE                          1'b0
// 0: General purpose outputs 0 and 1 tristated
// 1: General purpose outputs 0 and 1 enabled
`define GPO_2_3_ENABLE                          1'b0
// 0: General purpose outputs 2 and 3 tristated
// 1: General purpose outputs 2 and 3 enabled
`define BLANK_CHROMA_IN_VBI                     1'b1
// 0: Chroma decoded and output during vertical blanking
// 1: Chroma blanked during vertical blanking
`define HLOCK_ENABLE                            1'b0
// 0: GPO 0 is a general purpose output
// 1: GPO 0 shows HLOCK status

`define ADV7185_REGISTER_5 {`HLOCK_ENABLE, `BLANK_CHROMA_IN_VBI, `GPO_2_3_ENABLE, `GPO_0_1_ENABLE, `GENERAL_PURPOSE_OUTPUTS}

///////////////////////////////////////////////////////////////////////////////
// Register 7
///////////////////////////////////////////////////////////////////////////////

`define FIFO_FLAG_MARGIN                        5'h10
// Sets the locations where FIFO almost-full and almost-empty flags are set
`define FIFO_RESET                              1'b0
// 0: Normal operation
// 1: Reset FIFO. This bit is automatically cleared
`define AUTOMATIC_FIFO_RESET                    1'b0
// 0: No automatic reset
// 1: FIFO is autmatically reset at the end of each video field
`define FIFO_FLAG_SELF_TIME                     1'b1
// 0: FIFO flags are synchronized to CLKIN
// 1: FIFO flags are synchronized to internal 27MHz clock

`define ADV7185_REGISTER_7 {`FIFO_FLAG_SELF_TIME, `AUTOMATIC_FIFO_RESET, `FIFO_RESET, `FIFO_FLAG_MARGIN}

///////////////////////////////////////////////////////////////////////////////
// Register 8
///////////////////////////////////////////////////////////////////////////////

`define INPUT_CONTRAST_ADJUST                         8'h80

`define ADV7185_REGISTER_8 {`INPUT_CONTRAST_ADJUST}

///////////////////////////////////////////////////////////////////////////////
// Register 9
///////////////////////////////////////////////////////////////////////////////

`define INPUT_SATURATION_ADJUST                       8'h8C

`define ADV7185_REGISTER_9 {`INPUT_SATURATION_ADJUST}

///////////////////////////////////////////////////////////////////////////////
// Register A
///////////////////////////////////////////////////////////////////////////////

`define INPUT_BRIGHTNESS_ADJUST                       8'h00

`define ADV7185_REGISTER_A {`INPUT_BRIGHTNESS_ADJUST}

///////////////////////////////////////////////////////////////////////////////
// Register B
///////////////////////////////////////////////////////////////////////////////

`define INPUT_HUE_ADJUST                              8'h00

`define ADV7185_REGISTER_B {`INPUT_HUE_ADJUST}

///////////////////////////////////////////////////////////////////////////////
// Register C
///////////////////////////////////////////////////////////////////////////////

`define DEFAULT_VALUE_ENABLE                    1'b0
// 0: Use programmed Y, Cr, and Cb values
// 1: Use default values
`define DEFAULT_VALUE_AUTOMATIC_ENABLE          1'b0
// 0: Use programmed Y, Cr, and Cb values
// 1: Use default values if lock is lost
`define DEFAULT_Y_VALUE                         6'h0C
// Default Y value

`define ADV7185_REGISTER_C {`DEFAULT_Y_VALUE, `DEFAULT_VALUE_AUTOMATIC_ENABLE, `DEFAULT_VALUE_ENABLE}

///////////////////////////////////////////////////////////////////////////////
// Register D
///////////////////////////////////////////////////////////////////////////////

`define DEFAULT_CR_VALUE                        4'h8
// Most-significant four bits of default Cr value
`define DEFAULT_CB_VALUE                        4'h8
// Most-significant four bits of default Cb value

`define ADV7185_REGISTER_D {`DEFAULT_CB_VALUE, `DEFAULT_CR_VALUE}

///////////////////////////////////////////////////////////////////////////////
// Register E
///////////////////////////////////////////////////////////////////////////////

`define TEMPORAL_DECIMATION_ENABLE              1'b0
// 0: Disable
// 1: Enable
`define TEMPORAL_DECIMATION_CONTROL             2'h0
// 0: Supress frames, start with even field
  // 1: Supress frames, start with odd field
  // 2: Supress even fields only
  // 3: Supress odd fields only
`define TEMPORAL_DECIMATION_RATE                4'h0
  // 0-F: Number of fields/frames to skip

`define ADV7185_REGISTER_E {1'b0, `TEMPORAL_DECIMATION_RATE, `TEMPORAL_DECIMATION_CONTROL, `TEMPORAL_DECIMATION_ENABLE}

///////////////////////////////////////////////////////////////////////////////
// Register F
///////////////////////////////////////////////////////////////////////////////

`define POWER_SAVE_CONTROL                      2'h0
  // 0: Full operation
  // 1: CVBS only
  // 2: Digital only
  // 3: Power save mode
`define POWER_DOWN_SOURCE_PRIORITY              1'b0
  // 0: Power-down pin has priority
  // 1: Power-down control bit has priority
`define POWER_DOWN_REFERENCE                    1'b0
  // 0: Reference is functional
  // 1: Reference is powered down
`define POWER_DOWN_LLC_GENERATOR                1'b0
  // 0: LLC generator is functional
  // 1: LLC generator is powered down
`define POWER_DOWN_CHIP                         1'b0
  // 0: Chip is functional
  // 1: Input pads disabled and clocks stopped
`define TIMING_REACQUIRE                        1'b0
  // 0: Normal operation
  // 1: Reacquire video signal (bit will automatically reset)
`define RESET_CHIP                              1'b0
  // 0: Normal operation
  // 1: Reset digital core and I2C interface (bit will automatically reset)

`define ADV7185_REGISTER_F {`RESET_CHIP, `TIMING_REACQUIRE, `POWER_DOWN_CHIP, `POWER_DOWN_LLC_GENERATOR, `POWER_DOWN_REFERENCE, `POWER_DOWN_SOURCE_PRIORITY, `POWER_SAVE_CONTROL}

///////////////////////////////////////////////////////////////////////////////
// Register 33
///////////////////////////////////////////////////////////////////////////////

`define PEAK_WHITE_UPDATE                       1'b1
  // 0: Update gain once per line
  // 1: Update gain once per field
`define AVERAGE_BIRIGHTNESS_LINES               1'b1
  // 0: Use lines 33 to 310
  // 1: Use lines 33 to 270
`define MAXIMUM_IRE                             3'h0
  // 0: PAL: 133, NTSC: 122
  // 1: PAL: 125, NTSC: 115
  // 2: PAL: 120, NTSC: 110
  // 3: PAL: 115, NTSC: 105
  // 4: PAL: 110, NTSC: 100
  // 5: PAL: 105, NTSC: 100
  // 6-7: PAL: 100, NTSC: 100
`define COLOR_KILL                              1'b1
  // 0: Disable color kill
  // 1: Enable color kill
  
`define ADV7185_REGISTER_33 {1'b1, `COLOR_KILL, 1'b1, `MAXIMUM_IRE, `AVERAGE_BIRIGHTNESS_LINES, `PEAK_WHITE_UPDATE}

`define ADV7185_REGISTER_10 8'h00
`define ADV7185_REGISTER_11 8'h00  
`define ADV7185_REGISTER_12 8'h00
`define ADV7185_REGISTER_13 8'h45
`define ADV7185_REGISTER_14 8'h18
`define ADV7185_REGISTER_15 8'h60
`define ADV7185_REGISTER_16 8'h00
`define ADV7185_REGISTER_17 8'h01
`define ADV7185_REGISTER_18 8'h00
`define ADV7185_REGISTER_19 8'h10
`define ADV7185_REGISTER_1A 8'h10
`define ADV7185_REGISTER_1B 8'hF0
`define ADV7185_REGISTER_1C 8'h16
`define ADV7185_REGISTER_1D 8'h01
`define ADV7185_REGISTER_1E 8'h00
`define ADV7185_REGISTER_1F 8'h3D
`define ADV7185_REGISTER_20 8'hD0
`define ADV7185_REGISTER_21 8'h09
`define ADV7185_REGISTER_22 8'h8C
`define ADV7185_REGISTER_23 8'hE2
`define ADV7185_REGISTER_24 8'h1F
`define ADV7185_REGISTER_25 8'h07
`define ADV7185_REGISTER_26 8'hC2
`define ADV7185_REGISTER_27 8'h58
`define ADV7185_REGISTER_28 8'h3C
`define ADV7185_REGISTER_29 8'h00
`define ADV7185_REGISTER_2A 8'h00
`define ADV7185_REGISTER_2B 8'hA0
`define ADV7185_REGISTER_2C 8'hCE
`define ADV7185_REGISTER_2D 8'hF0
`define ADV7185_REGISTER_2E 8'h00
`define ADV7185_REGISTER_2F 8'hF0
`define ADV7185_REGISTER_30 8'h00
`define ADV7185_REGISTER_31 8'h70
`define ADV7185_REGISTER_32 8'h00
`define ADV7185_REGISTER_34 8'h0F
`define ADV7185_REGISTER_35 8'h01
`define ADV7185_REGISTER_36 8'h00      
`define ADV7185_REGISTER_37 8'h00
`define ADV7185_REGISTER_38 8'h00
`define ADV7185_REGISTER_39 8'h00
`define ADV7185_REGISTER_3A 8'h00
`define ADV7185_REGISTER_3B 8'h00

`define ADV7185_REGISTER_44 8'h41
`define ADV7185_REGISTER_45 8'hBB

`define ADV7185_REGISTER_F1 8'hEF
`define ADV7185_REGISTER_F2 8'h80


module adv7185init (reset, clock_27mhz, source, tv_in_reset_b, 
		    tv_in_i2c_clock, tv_in_i2c_data);

   input reset;
   input clock_27mhz;
   output tv_in_reset_b; // Reset signal to ADV7185
   output tv_in_i2c_clock; // I2C clock output to ADV7185
   output tv_in_i2c_data; // I2C data line to ADV7185
   input source; // 0: composite, 1: s-video
   
   initial begin
      $display("ADV7185 Initialization values:");
      $display("  Register 0:  0x%X", `ADV7185_REGISTER_0);
      $display("  Register 1:  0x%X", `ADV7185_REGISTER_1);
      $display("  Register 2:  0x%X", `ADV7185_REGISTER_2);
      $display("  Register 3:  0x%X", `ADV7185_REGISTER_3);
      $display("  Register 4:  0x%X", `ADV7185_REGISTER_4);
      $display("  Register 5:  0x%X", `ADV7185_REGISTER_5);
      $display("  Register 7:  0x%X", `ADV7185_REGISTER_7);
      $display("  Register 8:  0x%X", `ADV7185_REGISTER_8);
      $display("  Register 9:  0x%X", `ADV7185_REGISTER_9);
      $display("  Register A:  0x%X", `ADV7185_REGISTER_A);
      $display("  Register B:  0x%X", `ADV7185_REGISTER_B);
      $display("  Register C:  0x%X", `ADV7185_REGISTER_C);
      $display("  Register D:  0x%X", `ADV7185_REGISTER_D);
      $display("  Register E:  0x%X", `ADV7185_REGISTER_E);
      $display("  Register F:  0x%X", `ADV7185_REGISTER_F);
      $display("  Register 33: 0x%X", `ADV7185_REGISTER_33);
   end

   //
   // Generate a 1MHz for the I2C driver (resulting I2C clock rate is 250kHz)
   //
   
   reg [7:0] clk_div_count, reset_count;
   reg clock_slow;
   wire reset_slow;
   
   initial
     begin
	clk_div_count <= 8'h00;
	// synthesis attribute init of clk_div_count is "00";
	clock_slow <= 1'b0;
	// synthesis attribute init of clock_slow is "0";
     end
   
   always @(posedge clock_27mhz)
     if (clk_div_count == 26)
       begin
	  clock_slow <= ~clock_slow;
	  clk_div_count <= 0;
       end
     else
       clk_div_count <= clk_div_count+1;

   always @(posedge clock_27mhz)
     if (reset)
       reset_count <= 100;
     else
       reset_count <= (reset_count==0) ? 0 : reset_count-1;

   assign reset_slow = reset_count != 0;
   
   //
   // I2C driver
   //
   
   reg load;
   reg [7:0] data;
   wire ack, idle;
   
   i2c i2c(.reset(reset_slow), .clock4x(clock_slow), .data(data), .load(load),
	   .ack(ack), .idle(idle), .scl(tv_in_i2c_clock),
	   .sda(tv_in_i2c_data));
   
   //
   // State machine
   //
   
   reg [7:0] state;
   reg tv_in_reset_b;
   reg old_source;
   
   always @(posedge clock_slow)
      if (reset_slow)
	begin
	   state <= 0;
	   load <= 0;
	   tv_in_reset_b <= 0;
	   old_source <= 0;
	end
      else
	case (state)
	  8'h00:
	    begin
	       // Assert reset
	       load <= 1'b0;
	       tv_in_reset_b <= 1'b0;
	       if (!ack)
		 state <= state+1;
	    end
	  8'h01:
	    state <= state+1;
	  8'h02:
	    begin
	       // Release reset
	       tv_in_reset_b <= 1'b1;
	       state <= state+1;
	      	    end
	  8'h03:
	    begin
	       // Send ADV7185 address
	       data <= 8'h8A;
	       load <= 1'b1;
	       if (ack)
		 state <= state+1;
	    end
	  8'h04:
	    begin
	       // Send subaddress of first register
	       data <= 8'h00;
	       if (ack)
		 state <= state+1;
	    end
	  8'h05:
	    begin
	       // Write to register 0
	       data <= `ADV7185_REGISTER_0 | {5'h00, {3{source}}};
	       if (ack)
		 state <= state+1;
	    end
	  8'h06:
	    begin
	       // Write to register 1
	       data <= `ADV7185_REGISTER_1;
	       if (ack)
		 state <= state+1;
	    end
	  8'h07:
	    begin
	       // Write to register 2
	       data <= `ADV7185_REGISTER_2;
	       if (ack)
		 state <= state+1;
	    end
	  8'h08:
	    begin
	       // Write to register 3
	       data <= `ADV7185_REGISTER_3;
	       if (ack)
		 state <= state+1;
	    end
	  8'h09:
	    begin
	       // Write to register 4
	       data <= `ADV7185_REGISTER_4;
	       if (ack)
		 state <= state+1;
	    end
	  8'h0A:
	    begin
	       // Write to register 5
	       data <= `ADV7185_REGISTER_5;
	       if (ack)
		 state <= state+1;
	    end
	  8'h0B:
	    begin
	       // Write to register 6
	       data <= 8'h00; // Reserved register, write all zeros
	       if (ack)
		 state <= state+1;
	    end
	  8'h0C:
	    begin
	       // Write to register 7
	       data <= `ADV7185_REGISTER_7;
	       if (ack)
		 state <= state+1;
	    end
	  8'h0D:
	    begin
	       // Write to register 8
	       data <= `ADV7185_REGISTER_8;
	       if (ack)
		 state <= state+1;
	    end
	  8'h0E:
	    begin
	       // Write to register 9
	       data <= `ADV7185_REGISTER_9;
	       if (ack)
		 state <= state+1;
	    end
	  8'h0F: begin
	     // Write to register A
	     data <= `ADV7185_REGISTER_A;
	   if (ack)
	     state <= state+1;
	  end
	  8'h10:
	    begin
	       // Write to register B
	       data <= `ADV7185_REGISTER_B;
	       if (ack)
		 state <= state+1;
	    end
	  8'h11:
	    begin
	       // Write to register C
	       data <= `ADV7185_REGISTER_C;
	       if (ack)
		 state <= state+1;
	    end
	  8'h12:
	    begin
	       // Write to register D
	       data <= `ADV7185_REGISTER_D;
	       if (ack)
		 state <= state+1;
	    end
	  8'h13:
	    begin
	       // Write to register E
	       data <= `ADV7185_REGISTER_E;
	       if (ack)
		 state <= state+1;
	    end
	  8'h14:
	    begin
	       // Write to register F
	       data <= `ADV7185_REGISTER_F;
	       if (ack)
		 state <= state+1;
	    end
	  8'h15:
	    begin
	       // Wait for I2C transmitter to finish
	       load <= 1'b0;
	       if (idle)
		 state <= state+1;
	    end
	  8'h16:
	    begin
	       // Write address
	       data <= 8'h8A;
	       load <= 1'b1;
	       if (ack)
		 state <= state+1;
	    end
	  8'h17:
	    begin
	       data <= 8'h33;
	       if (ack)
		 state <= state+1;
	    end
	  8'h18:
	    begin
	       data <= `ADV7185_REGISTER_33;
	       if (ack)
		 state <= state+1;
	    end
	  8'h19:
	    begin
	       load <= 1'b0;
	       if (idle)
		 state <= state+1;
	    end
	  
	  8'h1A: begin
	     data <= 8'h8A;
	     load <= 1'b1;
	     if (ack)
	       state <= state+1;
	  end
	  8'h1B:
	    begin
	       data <= 8'h33;
	       if (ack)
		 state <= state+1;
	    end
	  8'h1C:
	    begin
	       load <= 1'b0;
	       if (idle)
		 state <= state+1;
	    end
	  8'h1D:
	    begin
	       load <= 1'b1;
	       data <= 8'h8B;
	       if (ack)
		 state <= state+1;
	    end
	  8'h1E:
	    begin
	       data <= 8'hFF;
	       if (ack)
		 state <= state+1;
	    end
	  8'h1F:
	    begin
	       load <= 1'b0;
	       if (idle)
		 state <= state+1;
	    end
	  8'h20:
	    begin
	       // Idle
	       if (old_source != source) state <= state+1;
	       old_source <= source;
	    end
	  8'h21: begin
	     // Send ADV7185 address
	     data <= 8'h8A;
	     load <= 1'b1;
	     if (ack) state <= state+1;
	  end
	  8'h22: begin
	     // Send subaddress of register 0
	     data <= 8'h00;
	     if (ack) state <= state+1;
	  end
	  8'h23: begin
	     // Write to register 0
	     data <= `ADV7185_REGISTER_0 | {5'h00, {3{source}}};
	     if (ack) state <= state+1;
	  end
	  8'h24: begin
	     // Wait for I2C transmitter to finish
	     load <= 1'b0;
	     if (idle) state <= 8'h20;
	  end
       endcase
   
endmodule

// i2c module for use with the ADV7185

module i2c (reset, clock4x, data, load, idle, ack, scl, sda);

   input reset;
   input clock4x;
   input [7:0] data;
   input load;
   output ack;
   output idle;
   output scl;
   output sda;

   reg [7:0] ldata;
   reg ack, idle;
   reg scl;
   reg sdai;
   
   reg [7:0] state;

   assign sda = sdai ? 1'bZ : 1'b0;
   
   always @(posedge clock4x)
     if (reset)
       begin
	  state <= 0;
	  ack <= 0;
       end
     else
       case (state)
	 8'h00: // idle
	   begin
	      scl <= 1'b1;
	      sdai <= 1'b1;
	      ack <= 1'b0;
	      idle <= 1'b1;
	      if (load)
		begin
		   ldata <= data;
		   ack <= 1'b1;
		   state <= state+1;
		end
	   end
	 8'h01: // Start
	   begin
	      ack <= 1'b0;
	      idle <= 1'b0;
	      sdai <= 1'b0;
	      state <= state+1;
	   end
	 8'h02:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h03: // Send bit 7
	   begin
	      ack <= 1'b0;
	      sdai <= ldata[7];
	      state <= state+1;
	   end
	 8'h04:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h05:
	   begin
	      state <= state+1;
	   end
	 8'h06:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h07:
	   begin
	      sdai <= ldata[6];
	      state <= state+1;
	   end
	 8'h08:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h09:
	   begin
	      state <= state+1;
	   end
	 8'h0A:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h0B:
	   begin
	      sdai <= ldata[5];
	      state <= state+1;
	   end
	 8'h0C:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h0D:
	   begin
	      state <= state+1;
	   end
	 8'h0E:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h0F:
	   begin
	      sdai <= ldata[4];
	      state <= state+1;
	   end
	 8'h10:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h11:
	   begin
	      state <= state+1;
	   end
	 8'h12:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h13:
	   begin
	      sdai <= ldata[3];
	      state <= state+1;
	   end
	 8'h14:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h15:
	   begin
	      state <= state+1;
	   end
	 8'h16:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h17:
	   begin
	      sdai <= ldata[2];
	      state <= state+1;
	   end
	 8'h18:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h19:
	   begin
	      state <= state+1;
	   end
	 8'h1A:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h1B:
	   begin
	      sdai <= ldata[1];
	      state <= state+1;
	   end
	 8'h1C:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h1D:
	   begin
	      state <= state+1;
	   end
	 8'h1E:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h1F:
	   begin
	      sdai <= ldata[0];
	      state <= state+1;
	   end
	 8'h20:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h21:
	   begin
	      state <= state+1;
	   end
	 8'h22:
	   begin
	      scl <= 1'b0;
	      state <= state+1;
	   end
	 8'h23: // Acknowledge bit
	   begin
	      state <= state+1;
	   end
	 8'h24:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h25:
	   begin
	      state <= state+1;
	   end
	 8'h26:
	   begin
	      scl <= 1'b0;
	      if (load)
		begin
		   ldata <= data;
		   ack <= 1'b1;
		   state <= 3;
		end
	      else
		state <= state+1;
	   end
	 8'h27:
	   begin
	      sdai <= 1'b0;
	      state <= state+1;
	   end
	 8'h28:
	   begin
	      scl <= 1'b1;
	      state <= state+1;
	   end
	 8'h29:
	   begin
	      sdai <= 1'b1;
	      state <= 0;
	   end
       endcase

endmodule

	
