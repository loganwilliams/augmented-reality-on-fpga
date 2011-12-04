`include "params.v"
`default_nettype none

/*
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
		output reg  vga_out_sync_b,
		output reg  vga_out_blank_b,
		output  vga_out_pixel_clock,
		output  vga_out_hsync,
		output  vga_out_vsync,
		// DEBUG
		output reg  [`LOG_HCOUNT-1:0] clocked_hcount,
		output reg  [`LOG_VCOUNT-1:0] clocked_vcount
	 );
	 
	 wire [`LOG_HCOUNT-1:0] hcount;
	 wire [`LOG_VCOUNT-1:0] vcount;

	//wire [`LOG_HCOUNT-1:0] hcount;
	//wire [`LOG_VCOUNT-1:0] vcount;
	wire hsync, vsync, blank;

	stupid_xvga xvga1(.vclock(vclock), .reset(reset), .hcount(hcount),
					.vcount(vcount), .vsync(vsync), .hsync(hsync), .blank(blank));

	reg buffer_index;
	reg [35:0] pixel_buffer_0;
	reg [35:0] pixel_buffer_1;
	wire [35:0] pixel_buffer;
	reg c_buffer_index;
	wire out_of_bounds;
	assign out_of_bounds = (clocked_hcount >= 640) || (clocked_vcount >= 480);
	//assign vga_flag = rising_hcount;
	
	always @(posedge clock) begin
		// hcount[0] & curr_hcount & ~done_vga;
		if (reset) begin
			clocked_hcount <= 0;
			clocked_vcount <= 0;
			vga_flag <= 0;
			c_buffer_index <= 0;
		end
		// set next pixel to vga_pixel
		// keep current pixel
		else if (c_buffer_index == buffer_index) begin
			clocked_hcount <= hcount;
			clocked_vcount <= vcount;
			vga_flag <= 0;
			c_buffer_index <= c_buffer_index;
		end
		else begin
			clocked_hcount <= clocked_hcount;
			clocked_vcount <= clocked_vcount;
			vga_flag <= ~out_of_bounds;
			c_buffer_index <= ~c_buffer_index;
		end
		
		if (out_of_bounds) begin
			pixel_buffer_0 <= (c_buffer_index) ? pixel_buffer_0 : 24'd0;
			pixel_buffer_1 <= (c_buffer_index) ? 24'd0 : pixel_buffer_1;
		end
		else if (!reset) begin
			pixel_buffer_0 <= (c_buffer_index) ? pixel_buffer_0 : vga_pixel;
			pixel_buffer_1 <= (c_buffer_index) ? vga_pixel : pixel_buffer_1;
		end
	end

	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
	assign pixel_buffer = ~buffer_index ? pixel_buffer_0 : pixel_buffer_1;
	wire [23:0] pixel;
	assign pixel = hcount[0] ? vga_pixel[17:0] : vga_pixel[35:18];
	ycrcb_lut transformer( // more than meets the eye
		.ycrcb(pixel), .r(r), .g(g), .b(b));
	/*
	ycbcr2rgb transformer( // more than meets the eye
		.clock(vclock), .reset(reset),
		.y(hcount[0] ? {pixel_buffer[17:10]} : {pixel_buffer[35:28]}),
		.cr(hcount[0]? {pixel_buffer[9:5],  3'd0} : {pixel_buffer[27:23], 3'd0}),
		.cb(hcount[0]? {pixel_buffer[4:0],  3'd0} : {pixel_buffer[22:18], 3'd0}),
		.r(r), .g(g), .b(b));
	*/
	/*
	assign r = (hcount[0]) ? pixel_buffer[17:10] : pixel_buffer[35:28];
	assign g = r;
	assign b = g;
	*/
	/*
	always @(posedge vclock) begin
		if (hcount > 639 || vcount > 479) begin
			vga_out_red <= 8'd0;
			vga_out_green <= 8'd0;
			vga_out_blue <= 8'd0;
		end
		else begin
			vga_out_red <= r;
			vga_out_green <= g;
			vga_out_blue <= b;
		end
	end
	
	always @(posedge vclock) begin
		buffer_index <= reset ? 0 : ~buffer_index;
		//vga_out_red <= r;
		//vga_out_green <= g;
		//vga_out_blue <= b;
		vga_out_blank_b <= ~blank;
		vga_out_sync_b <= 1'b1;
	end
	
	assign vga_out_pixel_clock = ~vclock;
	assign vga_out_hsync = hsync;
	assign vga_out_vsync = vsync;
endmodule
*/

module vga_write_fifo
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
		output reg  vga_out_sync_b,
		output reg  vga_out_blank_b,
		output  vga_out_pixel_clock,
		output  vga_out_hsync,
		output  vga_out_vsync,
		// DEBUG
		output reg  [`LOG_HCOUNT-1:0] clocked_hcount,
		output reg  [`LOG_VCOUNT-1:0] clocked_vcount
	);
	
	reg [63:0] f2v_din;
	reg f2v_rd_en;
	reg f2v_wr_en;
	wire [63:0] f2v_dout;
	wire f2v_empty;
	wire f2v_full;
	
	fpga_to_vga f2v (
        .din(f2v_din), // Bus [63 : 0]
        .rd_clk(vclock),
        .rd_en(f2v_rd_en),
        .rst(reset),
        .wr_clk(clock),
        .wr_en(f2v_wr_en),
        .dout(f2v_dout), // Bus [63 : 0]
        .empty(f2v_empty),
        .full(f2v_full),
        //.valid(valid),
        //.wr_ack(wr_ack)
	);
	
	reg [63:0] f2v_hcount;
	reg [63:0] f2v_vcount;
	reg [63:0] prev_f2v_hcount;
	reg [63:0] prev_f2v_vcount;
	reg prev_f2v_empty;
	always @(*) begin
		f2v_rd_en = !f2v_empty;
		if (!prev_f2v_empty) begin
			f2v_hcount = f2v_dout[63:54];
			f2v_vcount = f2v_dout[53:44];
		end
		else begin
			f2v_hcount = prev_f2v_hcount;
			f2v_vcount = prev_f2v_vcount;
		end
	end
	// reading
	always @(vclock) begin
		prev_f2v_empty <= f2v_empty;
		prev_f2v_hcount <= f2v_hcount;
		prev_f2v_vcount <= f2v_vcount;
	end
	
	always @(clock) begin
		
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
