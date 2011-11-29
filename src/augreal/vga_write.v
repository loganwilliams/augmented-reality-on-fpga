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
		output reg vga_out_vsync
	);

	wire [`LOG_HCOUNT-1:0] hcount;
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
	reg hsyncs[0:7];
	reg vsyncs[0:7];
	reg blanks[0:7];
	reg [`LOG_HCOUNT-1:0] hcounts[0:7];
	reg [`LOG_VCOUNT-1:0] vcounts[0:7];
	// clock buffers
	reg [`LOG_MEM-1:0] pixels[0:3];

	// indices for for loops
	integer i;
	integer j;

	// clock states - used for fetching
	reg [1:0] state;
	parameter REQUESTING = 2'd0;
	parameter STANDING_BY = 2'd1;
	parameter READING = 2'd2;
	parameter OUT_OF_BOUNDS = 2'd3;
	
	reg vstate;
	parameter STARTING_UP=1'b0;
	parameter STEADY_STATE=1'b1;

	reg out_of_bounds;
	always @(*) begin
		// whether to request a pixel from memory; !out_of_bounds prevents
		// excessive requesting
		vga_flag = (!reset && !frame_flag && (trunc_vindex - trunc_cindex) > 1 && !out_of_bounds && state == REQUESTING);
	end

	/***** READING FROM MEMORY_INTERFACE ******/
	always @(posedge clock) begin
		// is the current requested pixel outside of screen bounds?
		out_of_bounds <= hcounts[cindex] >= 640 || vcounts[cindex] >= 480;
		// fetcher block
		if (reset) state <= REQUESTING;
		else case (state)
			REQUESTING: begin
				if (vga_flag) state <= STANDING_BY;
				else if (out_of_bounds) state <= OUT_OF_BOUNDS;
				else state <= state;
			end
			STANDING_BY: state <= READING;
			READING, OUT_OF_BOUNDS: state <= REQUESTING;
			default: state <= REQUESTING;
		endcase

		if (reset) cindex <= 0;
		else case (state)
			// set new pixel and increment counter
			READING, OUT_OF_BOUNDS: begin
				pixels[trunc_cindex] <= (out_of_bounds) ? 0 : vga_pixel;
				cindex <= cindex+2;
			end
			// keep current pixels
			REQUESTING, STANDING_BY: begin
				for (i=0;i<4;i=i+1) pixels[i] <= pixels[i];
				cindex <= cindex;
			end
			default: begin
				for (i=0;i<4;i=i+1) pixels[i] <= pixels[i];
				cindex <= cindex;
			end
		endcase
	end
	/****************************************/

	/***** OUTPUT TO VGA CHIP *******/
	wire [`LOG_TRUNC-1:0] pixel_out;
	assign pixel_out = (vindex[0] == 0) ? pixels[trunc_vindex][2*`LOG_TRUNC-1:`LOG_TRUNC] : pixels[trunc_vindex][`LOG_TRUNC-1:0];
	// instantiate pixel module here
	ycbcr2rgb converter(.y({pixel_out[17:12],2'b00}), .cb({pixel_out[11:6],2'b00}), .cr({pixel_out[5:0],2'b00}), .r(vga_out_red), .g(vga_out_green), .b(vga_out_blue));
	// output
	always @(posedge vclock) begin
		if (vstate == STEADY_STATE) begin
			vga_out_sync_b <= 1'b1; // not used
			vga_out_blank_b <= ~blanks[vindex];
			vga_out_pixel_clock <= ~vclock; // TODO: verify whether inversion is necessary
			vga_out_hsync <= hsyncs[vindex];
			vga_out_vsync <= vsyncs[vindex];
		end
		// wait for steady state before streaming
		else begin
			vga_out_sync_b <= 1'bX;
			vga_out_blank_b <= 1'bX;
			vga_out_pixel_clock <= ~vclock;
			vga_out_hsync <= 1'bX;
			vga_out_vsync <= 1'bX;
		end
	end
	/********************************/

	always @(posedge vclock) begin
		if (reset) begin
			vindex <= 0;
			vstate <= STARTING_UP;
		end
		else begin
			// fill up the buffer
			hcounts[vindex] <= hcount;
			vcounts[vindex] <= vcount;
			hsyncs[vindex] <= hsync;
			vsyncs[vindex] <= vsync;
			blanks[vindex] <= blank;
			vindex <= vindex+1;
			if (vindex == 7 && vstate == STARTING_UP)
				vstate <= STEADY_STATE;
			else 
				vstate <= vstate;
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
		if (reset || frame_flag) begin
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
