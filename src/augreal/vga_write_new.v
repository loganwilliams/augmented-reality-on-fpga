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
		output reg vga_flag,
		// VGA
		output reg [7:0] vga_out_red,
		output reg [7:0] vga_out_green,
		output reg [7:0] vga_out_blue,
		output reg vga_out_sync_b,
		output reg vga_out_blank_b,
		output reg vga_out_pixel_clock,
		output reg vga_out_hsync,
		output reg vga_out_vsync,
		// DEBUG
		output reg [`LOG_HCOUNT-1:0] clocked_hcount,
		output reg [`LOG_VCOUNT-1:0] clocked_vcount
	);
	wire [`LOG_HCOUNT-1:0] hcount;
	wire [`LOG_VCOUNT-1:0] vcount;
	wire hsync, vsync, blank;

	reg [`LOG_HCOUNT-1:0] del_hcount;
	reg [`LOG_VCOUNT-1:0] del_vcount;
	reg del_vsync, del_hsync, del_blank;

	stupid_xvga xvga1(
		.vclock(vclock), .reset(reset), .hcount(hcount),
		.vcount(vcount), .vsync(vsync), .hsync(hsync), .blank(blank));

	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
	
	reg [35:0] pixel;
	
	ycrcb_lut ycc(
		.ycrcb(del_hcount[0] ? pixel[35:18] : pixel[17:0]),
		.r(r), .g(g), .b(b));
	
	always @(posedge clock) begin
		if (reset) vga_flag <= 0;
		else if (!hcount[0]) vga_flag <= 0;
		else if (~done_vga) vga_flag <= 1;
		else vga_flag <= 0;
	end

	always @(posedge vclock) begin
		pixel <= vga_pixel;

		if (hcount[0]) clocked_hcount[9:0] <= hcount[9:0];
		else clocked_hcount[9:0] <= clocked_hcount[9:0];
		clocked_vcount[9:0] <= vcount[9:0];

		del_hcount[9:0] <= hcount[9:0];
		del_vcount[9:0] <= vcount[9:0];
		del_hsync  <= hsync;
		del_vsync  <= vsync;
		del_blank  <= blank;
	end

	always @(*) begin
		vga_out_red[7:0] = del_blank ? 8'd0 : r[7:0];
		vga_out_green[7:0] = del_blank ? 8'd0 : g[7:0];
		vga_out_blue[7:0] = del_blank ? 8'd0 : b[7:0];
		vga_out_blank_b = ~del_blank;
		vga_out_sync_b = 1'b1;
		vga_out_pixel_clock = ~vclock;
		vga_out_hsync = del_hsync;
		vga_out_vsync = del_vsync;
	end
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
		output reg [`LOG_HCOUNT-1:0] hcount, // pixel number on current line
		output reg [`LOG_VCOUNT-1:0] vcount, // line number
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
			hcount <= 2;
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
			hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync; // active low

			vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
			vblank <= next_vblank;
			vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync; // active low

			blank <= next_vblank | (next_hblank & ~hreset);
		end
	end
endmodule
