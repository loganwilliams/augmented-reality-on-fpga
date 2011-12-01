`include "params.v"
`default_nettype none

module stupid_vga_write
	(
		// STANDARD INPUTS
		input clock,
		input vclock,
		input reset,
		input frame_flag,
		// MEMORY_INTERFACE
		input [`LOG_MEM-1:0] vga_pixel,
		input done_vga,
		output vga_flag,
		// VGA
		output reg [7:0] vga_out_red,
		output reg [7:0] vga_out_green,
		output reg [7:0] vga_out_blue,
		output reg  vga_out_sync_b,
		output reg  vga_out_blank_b,
		output  vga_out_pixel_clock,
		output  vga_out_hsync,
		output  vga_out_vsync,
		// DEBUG
		output  [`LOG_HCOUNT-1:0] hcount,
		output  [`LOG_VCOUNT-1:0] vcount
	 );

	//wire [`LOG_HCOUNT-1:0] hcount;
	//wire [`LOG_VCOUNT-1:0] vcount;
	wire hsync, vsync, blank;

	stupid_xvga xvga1(.vclock(vclock), .reset(reset), .hcount(hcount),
					.vcount(vcount), .vsync(vsync), .hsync(hsync), .blank(blank));

	reg [35:0] pixel_buffer;
	reg delayed_vclock;
	reg d1f;
	reg d2f;
	reg everyother;
	
	assign vga_flag = vclock & ~delayed_vclock & everyother;
	
	always @(posedge clock) begin
		delayed_vclock <= vclock;
		d1f <= vga_flag;
		d2f <= vga_flag;
		
		if (d2f) begin
			pixel_buffer <= vga_pixel;
		end
	end
	
	always @(posedge vclock) begin
		everyother <= ~everyother;
		if (hcount[0]) begin
			vga_out_red <= pixel_buffer[17:10];
			vga_out_blue <= pixel_buffer[17:10];
			vga_out_green <= pixel_buffer[17:10];
		end else begin
			vga_out_red <= pixel_buffer[35:28];
			vga_out_blue <= pixel_buffer[35:28];
			vga_out_green <= pixel_buffer[35:28];
		end
		vga_out_blank_b <= ~blank;
		vga_out_sync_b <= 1'b1;
	end
	
	assign vga_out_pixel_clock = ~vclock;
	assign vga_out_hsync = hsync;
	assign vga_out_vsync = vsync;
endmodule

////////////////////////////////////////////////////////////////////////////////
//
// xvga: Generate XVGA display signals (640 x 480 @ 60Hz)
//
////////////////////////////////////////////////////////////////////////////////
module stupid_xvga
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
