`include "params.v"
`default_nettype none

module vga_write
	(
		// STANDARD INPUTS
		input clock,
		input vclock,
		input reset,
		input frame_flag,
		// MEMORY_INTERFACE
		input [`LOG_MEM-1:0] vga_pixel,
		input done_vga,
		output reg vga_flag,
		// VGA
		output [7:0] vga_out_red,
		output [7:0] vga_out_green,
		output [7:0] vga_out_blue,
		output reg vga_out_sync_b,
		output reg vga_out_blank_b,
		output reg vga_out_pixel_clock,
		output reg vga_out_hsync,
		output reg vga_out_vsync,
		// DEBUG
		output [`LOG_HCOUNT-1:0] hcount
	);

//	wire [`LOG_HCOUNT-1:0] hcount;
	wire [`LOG_VCOUNT-1:0] vcount;
	wire hsync, vsync, blank;

	xvga xvga1(.vclock(vclock), .reset(reset), .hcount(hcount), .vcount(vcount), .vsync(vsync), .hsync(hsync), .blank(blank));

	// buffer indices
	reg [2:0] vindex;
	reg [2:0] cindex;
	wire [1:0] trunc_vindex;
	wire [1:0] trunc_cindex;
	assign trunc_vindex = vindex[2:1];
	assign trunc_cindex = cindex[2:1];

	// vclock buffers
	reg [7:0] hsyncs;
	reg [7:0] vsyncs;
	reg [7:0] blanks;
	reg [8*`LOG_HCOUNT-1:0] hcounts;
	reg [8*`LOG_VCOUNT-1:0] vcounts;
	// clock buffers
	reg [4*`LOG_MEM-1:0] pixels;

	reg out_of_bounds;
	reg [`LOG_MEM-1:0] next_pixel;

	wire [7:0] ihsyncs;
	wire [7:0] ivsyncs;
	wire [7:0] iblanks;
	wire [8*`LOG_HCOUNT-1:0] ihcounts;
	wire [8*`LOG_VCOUNT-1:0] ivcounts;
	wire [4*`LOG_MEM-1:0] ipixels;

	insert8 #(.S(1)) insert_hsyncs(hsyncs, hsync, vindex, ihsyncs);
	insert8 #(.S(1)) insert_vsyncs(vsyncs, vsync, vindex, ivsyncs);
	insert8 #(.S(1)) insert_blanks(blanks, blank, vindex, iblanks);
	insert8 #(.S(`LOG_HCOUNT)) insert_hcounts(hcounts, hcount, vindex, ihcounts);
	insert8 #(.S(`LOG_VCOUNT)) insert_vcounts(vcounts, vcount, vindex, ivcounts);
	insert4 #(.S(`LOG_MEM)) insert_pixels(pixels, next_pixel, trunc_cindex, ipixels);

	// clock states - used for fetching
	reg [1:0] state;
	// TODO reg waiting_for_frame_flag;
	parameter REQUESTING = 2'd0;
	parameter STANDING_BY = 2'd1;
	parameter READING = 2'd2;
	parameter OUT_OF_BOUNDS = 2'd3;

	wire [`LOG_HCOUNT-1:0] chcount;
	wire [`LOG_VCOUNT-1:0] cvcount;
	extract8 #(.S(`LOG_HCOUNT)) exth(.x(hcounts), .i(cindex), .y(chcount));
	extract8 #(.S(`LOG_VCOUNT)) extv(.x(vcounts), .i(cindex), .y(cvcount));
	always @(*) begin
		// is the current requested pixel outside of screen bounds?
		out_of_bounds = chcount >= 640 || cvcount >= 480;
		// whether to request a pixel from memory; !out_of_bounds prevents
		// excessive requesting
		vga_flag = (!reset && !frame_flag && (trunc_vindex - trunc_cindex) > 1 && !out_of_bounds && state == REQUESTING);
		next_pixel = (out_of_bounds) ? `LOG_MEM'd0 : vga_pixel;
	end

	/***** READING FROM MEMORY_INTERFACE ******/
	always @(posedge clock) begin
		// fetcher block
		if (reset) state <= REQUESTING;
		else case (state)
			REQUESTING: begin
				if (vga_flag) state <= STANDING_BY;
				else if (out_of_bounds) state <= OUT_OF_BOUNDS;
				else state <= state;
			end
			STANDING_BY: state <= READING;
			default: state <= REQUESTING;
		endcase

		if (reset) begin
			pixels <= 0;
			cindex <= 0;
		end
		else case (state)
			// set new pixel and increment counter
			READING, OUT_OF_BOUNDS: begin
				pixels <= ipixels;
				cindex <= cindex+2;
			end
			// keep current pixels
			default: begin
				pixels <= pixels;
				cindex <= cindex;
			end
		endcase
	end
	/****************************************/

	reg vstate;
	parameter STARTING_UP=1'b0;
	parameter STEADY_STATE=1'b1;

	/***** OUTPUT TO VGA CHIP *******/
	wire [`LOG_MEM-1:0] pixel_tuple;
	wire [`LOG_TRUNC-1:0] pixel_out;
	extract4 #(.S(`LOG_MEM)) tuple(pixels, trunc_vindex, pixel_tuple);
		assign pixel_out = (vindex[0] == 0) ? pixel_tuple[2*`LOG_TRUNC-1:`LOG_TRUNC] : pixel_tuple[`LOG_TRUNC-1:0];
	// ycbcr2rgb converter(.y({pixel_out[17:12],2'b00}), .cb({pixel_out[11:6],2'b00}), .cr({pixel_out[5:0],2'b00}), .r(vga_out_red), .g(vga_out_green), .b(vga_out_blue));
	//assign pixel_out = (hcount[5:4] + vcount[5:4])<<12;
	assign vga_out_red = {hcount[5:4], 4'b00};
	assign vga_out_green = {vcount[5:4], 4'b00};
	assign vga_out_blue = {6'b111111, 2'b00};
	// output
	always @(*) begin
		if (vstate == STEADY_STATE) begin
			vga_out_sync_b = 1'b1; // not used
			vga_out_blank_b = ~blanks[vindex];
			vga_out_pixel_clock = ~vclock; // TODO: verify whether inversion is necessary
			vga_out_hsync = hsyncs[vindex];
			vga_out_vsync = vsyncs[vindex];
		end
		// wait for steady state before streaming
		else begin
			vga_out_sync_b = 1'bX;
			vga_out_blank_b = 1'bX;
			vga_out_pixel_clock = ~vclock;
			vga_out_hsync = 1'bX;
			vga_out_vsync = 1'bX;
		end
	end
	/********************************/

	always @(posedge vclock) begin
		if (reset) begin
			hcounts <= 0;
			vcounts <= 0;
			hsyncs <= 0;
			vsyncs <= 0;
			blanks <= 0;
			vindex <= 0;
			vstate <= STARTING_UP;
		end
		else begin
			// fill up the buffer
			hcounts <= ihcounts;
			vcounts <= ivcounts;
			hsyncs <= ihsyncs;
			vsyncs <= ivsyncs;
			blanks <= iblanks;
			vindex <= vindex+1;
			if (vindex == 7 && vstate == STARTING_UP) vstate <= STEADY_STATE;
			else vstate <= vstate;
		end
	end
endmodule

////////////////////////////////////////////////////////////////////////////////
//
// xvga: Generate XVGA display signals (640 x 480 @ 60Hz)
//
////////////////////////////////////////////////////////////////////////////////
module xvga
	(
		input vclock,
		input reset,
		input frame_flag,
		output reg [`LOG_HCOUNT-1:0] hcount,    // pixel number on current line
		output reg [`LOG_VCOUNT-1:0] vcount,	 // line number
		output reg vsync, hsync, blank
	);

	// horizontal: 800 pixels total
	// display 640 pixels per line
	reg hblank,vblank;
	wire hsyncon,hsyncoff,hreset,hblankon;
	assign hblankon = (hcount == `VGA_HBLANKON);    
	assign hsyncon = (hcount == `VGA_HSYNCON); // activated at end of front porch
	assign hsyncoff = (hcount == `VGA_HSYNCOFF); // activated at end of sync interval
	assign hreset = (hcount == `VGA_HRESET); // activated at end of 

	// vertical: 524 lines total
	// display 480 lines
	wire vsyncon,vsyncoff,vreset,vblankon;
	assign vblankon = hreset & (vcount == `VGA_VBLANKON);    
	assign vsyncon = hreset & (vcount == `VGA_VSYNCON);
	assign vsyncoff = hreset & (vcount == `VGA_VSYNCOFF);
	assign vreset = hreset & (vcount == `VGA_VRESET);

	// sync and blanking
	wire next_hblank,next_vblank;
	assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
	assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   
	always @(posedge vclock) begin
		// TODO: revise this section
		// is it necessary?
		if (reset) begin
			hcount <= 0;
			hblank <= 0;
			hsync <= 1;

			vcount <= 0;
			vblank <= 0;
			vsync <= 1;

			blank <= 0;
		end
		else begin
			hcount <= hreset ? 0 : hcount + 1;
			hblank <= next_hblank;
			hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low

			vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
			vblank <= next_vblank;
			vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low

			blank <= next_vblank | (next_hblank & ~hreset);
		end
   	end
endmodule

// verilog, I hate you
module insert8
	#(
		parameter S=1
	) (
		input [8*S-1:0] x,       // input list
		input [S-1:0] e,         // element to be inserted
		input [2:0] i,     // index of insertion (0..N-1)
		output reg [8*S-1:0] y   // output list
	);
	parameter N=8;
	parameter LOG_N=3;

	always @(*) begin
		case (i)
			0: y = {x[N*S-1:1*S], e};
			1: y = {x[N*S-1:2*S], e, x[1*S-1:0]};
			2: y = {x[N*S-1:3*S], e, x[2*S-1:0]};
			3: y = {x[N*S-1:4*S], e, x[3*S-1:0]};
			4: y = {x[N*S-1:5*S], e, x[4*S-1:0]};
			5: y = {x[N*S-1:6*S], e, x[5*S-1:0]};
			6: y = {x[N*S-1:7*S], e, x[6*S-1:0]};
			7: y = {e, x[7*S-1:0]};
		endcase
	end
endmodule

module insert4
	#(
		parameter S=1
	) (
		input [4*S-1:0] x,       // input list
		input [S-1:0] e,         // element to be inserted
		input [1:0] i,     // index of insertion (0..N-1)
		output reg [4*S-1:0] y   // output list
	);
	parameter N=4;
	parameter LOG_N=2;

	always @(*) begin
		case (i)
			0: y = {x[N*S-1:S], e};
			1: y = {x[N*S-1:2*S], e, x[S-1:0]};
			2: y = {x[N*S-1:3*S], e, x[2*S-1:0]};
			3: y = {e, x[3*S-1:0]};
		endcase
	end
endmodule

module extract8
	#(
		parameter S=1
	) (
		input [8*S-1:0] x,
		input [2:0] i,
		output reg [S-1:0] y
	);

	always @(*) begin
		case (i)
			0: y = x[1*S-1:0*S];
			1: y = x[2*S-1:1*S];
			2: y = x[3*S-1:2*S];
			3: y = x[4*S-1:3*S];
			4: y = x[5*S-1:4*S];
			5: y = x[6*S-1:5*S];
			6: y = x[7*S-1:6*S];
			7: y = x[8*S-1:5*S];
		endcase
	end
endmodule

module extract4
	#(
		parameter S=1
	) (
		input [4*S-1:0] x,
		input [1:0] i,
		output reg [S-1:0] y
	);

	always @(*) begin
		case (i)
			0: y = x[1*S-1:0*S];
			1: y = x[2*S-1:1*S];
			2: y = x[3*S-1:2*S];
			3: y = x[4*S-1:3*S];
		endcase
	end
endmodule
