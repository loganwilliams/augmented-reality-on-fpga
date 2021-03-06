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
		output vga_out_sync_b,
		output reg vga_out_blank_b,
		output vga_out_pixel_clock,
		output reg vga_out_hsync,
		output reg vga_out_vsync,
		// ADDRESSING
		output reg [`LOG_HCOUNT-1:0] clocked_hcount,
		output reg [`LOG_VCOUNT-1:0] clocked_vcount,
		
		input [9:0] a_x, b_x, c_x, d_x,
		input [8:0] a_y, b_y, c_y, d_y,
		
		output reg vga_will_request,
		
		input enable_xhairs
	);

	// generate hcount, vcount, syncs, and blank
	wire [`LOG_HCOUNT-1:0] hcount;
	wire [`LOG_VCOUNT-1:0] vcount;
	wire hsync, vsync, blank;
	stupid_xvga xvga1(
		.vclock(vclock), .reset(reset), .hcount(hcount),
		.vcount(vcount), .vsync(vsync), .hsync(hsync), .blank(blank));

	// account for delay in memory
	wire [9:0] del_hcount;
	wire [9:0] del_vcount;
	wire del_vsync, del_hsync, del_blank;
	parameter DELAY=2;
	delay2 #(.LOG(10)) dhc(.clock(vclock), .reset(reset), .x(hcount), .y(del_hcount));
	delay2 #(.LOG(10)) dvc(.clock(vclock), .reset(reset), .x(vcount), .y(del_vcount));
	delay2 #(.LOG(1)) dhs(.clock(vclock), .reset(reset), .x(hsync), .y(del_hsync));
	delay2 #(.LOG(1)) dvs(.clock(vclock), .reset(reset), .x(vsync), .y(del_vsync));
	delay2 #(.LOG(1)) db(.clock(vclock), .reset(reset), .x(blank), .y(del_blank));
	
	// assign color based on pixel fetched from memory
	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
	reg [35:0] pixel;
	ycrcb_lut ycc(
		.clock(vclock),
		.ycrcb(del_hcount[0] ? pixel[35:18] : pixel[17:0]),
		.r(r), .g(g), .b(b));

	reg [1:0] count;
	always @(posedge clock) begin
		// start count when both clock and vclock are rising (in sync)
		if (count != 2'd0) count <= count+1;
		else if (!vclock && hcount[0]) count <= 1;
		else count <= 2'd0;

		// grab pixel right before it changes
		if (count == 2'd3) pixel <= vga_pixel;
		else pixel <= pixel;
		
		// assign address of next pixel
		// generate vga_flag 1 out of every 4 clock cycles
		if (count == 2'd2) begin
			vga_flag <= 1;
			clocked_hcount[9:0] <= hcount[9:0];
			clocked_vcount[9:0] <= vcount[9:0];
		end
		else begin
			vga_flag <= 0;
			clocked_hcount[9:0] <= clocked_hcount[9:0];
			clocked_vcount[9:0] <= clocked_vcount[9:0];
		end

		vga_will_request <= (count == 2'd2);
	end

	// pipeline crosshair calculations
	reg [3:0] pre_crosshairs;
	reg [3:0] crosshairs;
	always @(posedge vclock) begin
		pre_crosshairs[0] <= enable_xhairs & (del_hcount == a_x | del_vcount == a_y);
		pre_crosshairs[1] <= enable_xhairs & (del_hcount == b_x | del_vcount == b_y);
		pre_crosshairs[2] <= enable_xhairs & (del_hcount == c_x | del_vcount == c_y);
		pre_crosshairs[3] <= enable_xhairs & (del_hcount == d_x | del_vcount == d_y);
		crosshairs <= pre_crosshairs;
	end
	
	// delay blank, hsync, vsync to account for r,g,b 2 cycle delay
	wire out_hsync;
	wire out_vsync;
	wire out_blank;
	delay2 #(.LOG(1)) dhso(.clock(vclock), .reset(reset), .x(del_hsync), .y(out_hsync));
	delay2 #(.LOG(1)) dvso(.clock(vclock), .reset(reset), .x(del_vsync), .y(out_vsync));
	delay2 #(.LOG(1)) dbo(.clock(vclock), .reset(reset), .x(del_blank), .y(out_blank));

	// assign outputs to VGA chip
	always @(posedge vclock) begin
		if (out_blank) begin
			vga_out_red[7:0] <= 8'd0;
			vga_out_green[7:0] <= 8'd0;
			vga_out_blue[7:0] <= 8'd0;
		end else if (crosshairs[0]) begin
			vga_out_red[7:0] <= 8'hFF;
			vga_out_green[7:0] <= 8'h00;
			vga_out_blue[7:0] <= 8'hFF;
		end else if (crosshairs[1]) begin
			vga_out_red[7:0] <= 8'hFF;
			vga_out_green[7:0] <= 8'hFF;
			vga_out_blue[7:0] <= 8'h00;
		end else if (crosshairs[2]) begin
			vga_out_red[7:0] <= 8'h00;
			vga_out_green[7:0] <= 8'hFF;
			vga_out_blue[7:0] <= 8'hFF;
		end else if (crosshairs[3]) begin
			vga_out_red[7:0] <= 8'hFF;
			vga_out_green[7:0] <= 8'h00;
			vga_out_blue[7:0] <= 8'h00;
		end else begin
			vga_out_red[7:0] <= r[7:0];
			vga_out_green[7:0] <= g[7:0];
			vga_out_blue[7:0] <= b[7:0];
		end

		vga_out_blank_b <= ~out_blank;
		vga_out_hsync <= out_hsync;
		vga_out_vsync <= out_vsync;
	end
	/*
	// generate video clock
	wire vga_out_pixel_clk;
	wire lock_vga;
	BUFG bufgv1(.O(vga_out_pixel_clock), .I(vga_out_pixel_clk));
	DCM vga_dcm (
		.CLKIN(vclock),
		.CLK180(vga_out_pixel_clk),
		.LOCKED(lock_vga));
   // synthesis attribute DLL_FREQUENCY_MODE of vga_dcm is "LOW"
   // synthesis attribute DUTY_CYCLE_CORRECTION of vga_dcm is "TRUE"
   // synthesis attribute STARTUP_WAIT of vga_dcm is "FALSE"
   // synthesis attribute DFS_FREQUENCY_MODE of vga_dcm is "LOW"
   // synthesis attribute CLK_FEEDBACK of vga_dcm  is "NONE"
   // synthesis attribute CLKOUT_PHASE_SHIFT of vga_dcm is "NONE"
   // synthesis attribute PHASE_SHIFT of vga_dcm is 0
	*/
	assign vga_out_pixel_clock = ~vclock;
	assign vga_out_sync_b = 1'b1;
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
			hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync; // active low

			vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
			vblank <= next_vblank;
			vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync; // active low

			blank <= next_vblank | (next_hblank & ~hreset);
		end
	end
endmodule

module delay2 #(parameter LOG=1)
	(
		input clock,
		input reset,
		input [LOG-1:0] x,
		output reg [LOG-1:0] y
	);
	
	reg [LOG-1:0] d;
	
	always @(posedge clock) begin
		if(reset) begin
			d <= 0;
			y <= 0;
		end
		else begin
			d <= x;
			y <= d;
		end
	end
endmodule

module delay #(parameter N=3, LOG=1) 
	(
		input clock,
		input reset,
		input [LOG-1:0] x,
		output reg [LOG-1:0] y
	);

	reg [(N-1)*LOG-1:0] d;

	always @(posedge clock) begin
		if (reset) begin
			d <= 0;
			y <= 0;
		end
		else begin
			d[LOG-1:0] <= x[LOG-1:0];
			d[(N-1)*LOG-1:LOG] <= d[(N-2)*LOG-1:0];
			y[LOG-1:0] <= d[(N-1)*LOG-1:(N-2)*LOG];
		end
	end
endmodule
