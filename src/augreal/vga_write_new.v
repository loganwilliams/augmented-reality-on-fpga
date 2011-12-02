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

	reg buffer_index;
	reg [35:0] pixel_buffer_0;
	reg [35:0] pixel_buffer_1;
	wire [35:0] pixel_buffer;
	
	reg prev_hcount;
	reg curr_hcount;
	
	wire rising_hcount;
	wire falling_hcount;
	assign rising_hcount = curr_hcount & ~prev_hcount;
	assign falling_hcount = ~curr_hcount & prev_hcount;
	assign vga_flag = rising_hcount;
	
	always @(posedge clock) begin
		curr_hcount <= hcount[0];
		prev_hcount <= reset ? 0 : curr_hcount;
		
		if (reset) begin
			pixel_buffer_0 <= 0;
			pixel_buffer_1 <= 0;
		end
		// set next pixel to vga_pixel
		// keep current pixel
		else if (buffer_index) begin
			pixel_buffer_0 <= vga_pixel;
			pixel_buffer_1 <= pixel_buffer_1;
		end
		else begin
			pixel_buffer_0 <= pixel_buffer_0;
			pixel_buffer_1 <= vga_pixel;
		end
	end

	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
	assign pixel_buffer = ~buffer_index ? pixel_buffer_0 : pixel_buffer_1;
	/*
	ycbcr2rgb transformer( // more than meets the eye
		.y(hcount[0] ? {pixel_buffer[17:10]} : {pixel_buffer[35:28]}),
		.cr(hcount[0]? {pixel_buffer[9:5],  3'd0} : {pixel_buffer[27:23], 3'd0}),
		.cb(hcount[0]? {pixel_buffer[4:0],  3'd0} : {pixel_buffer[22:18], 3'd0}),
		.r(r), .g(g), .b(b));
	*/
	assign r = (hcount[0]) ? pixel_buffer[17:10] : pixel_buffer[35:28];
	assign g = r;
	assign b = g;
	
	always @(posedge vclock) begin
		buffer_index <= reset ? 0 : ~buffer_index;
		vga_out_red <= r;
		vga_out_green <= g;
		vga_out_blue <= b;
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
