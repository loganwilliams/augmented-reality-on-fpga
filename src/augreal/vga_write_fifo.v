`include "params.v"
//`include "fifo/fpga_to_vga.v"
//`include "fifo/vga_to_fpga.v"
//`include "ycbcr2rgb.v"
//`default_nettype none

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
		output vga_flag,
		// VGA
		output [7:0] vga_out_red,
		output [7:0] vga_out_green,
		output [7:0] vga_out_blue,
		output  vga_out_sync_b,
		output  vga_out_blank_b,
		output  vga_out_pixel_clock,
		output  vga_out_hsync,
		output  vga_out_vsync,
		// DEBUG
		output  [`LOG_HCOUNT-1:0] clocked_hcount,
		output  [`LOG_VCOUNT-1:0] clocked_vcount
	);

	wire v2f_empty;
	wire v2f_full;
	wire v2f_rd_en;
	wire v2f_wr_en;
	wire [23:0] v2f_din;
	wire [23:0] v2f_dout;

	wire f2v_empty;
	wire f2v_full;
	wire f2v_rd_en;
	wire f2v_wr_en;
	wire [63:0] f2v_din;
	wire [63:0] f2v_dout;

	vga_write_clock vwc(
		.clock(clock), .reset(reset), .frame_flag(frame_flag),
		.vga_pixel(vga_pixel), .done_vga(done_vga), .vga_flag(vga_flag),
		.hcount(clocked_hcount), .vcount(clocked_vcount),
		.v2f_empty(v2f_empty), .f2v_full(f2v_full), .v2f_rd_en(v2f_rd_en),
		.f2v_wr_en(f2v_wr_en), .v2f_dout(v2f_dout), .f2v_din(f2v_din));

	vga_write_vclock vwv(
		.vclock(vclock), .reset(reset), .f2v_empty(f2v_empty), .v2f_full(v2f_full),
		.f2v_rd_en(f2v_rd_en), .v2f_wr_en(v2f_wr_en), .f2v_dout(f2v_dout), .v2f_din(v2f_din),
		.vga_out_red(vga_out_red), .vga_out_green(vga_out_green), .vga_out_blue(vga_out_blue),
		.vga_out_sync_b(vga_out_sync_b), .vga_out_blank_b(vga_out_blank_b),
		.vga_out_pixel_clock(vga_out_pixel_clock), .vga_out_hsync(vga_out_hsync),
		.vga_out_vsync(vga_out_vsync));

	// FIFOs
	fpga_to_vga f2v(
		.din(f2v_din), .rd_clk(vclock), .rd_en(f2v_rd_en), .rst(reset),
		.wr_clk(clock), .wr_en(f2v_wr_en), .dout(f2v_dout), .empty(f2v_empty),
		.full(f2v_full));

	vga_to_fpga v2f(
		.din(v2f_din), .rd_clk(clock), .rd_en(v2f_rd_en), .rst(reset),
		.wr_clk(vclock), .wr_en(v2f_wr_en), .dout(v2f_dout), .empty(v2f_empty),
		.full(v2f_full));
endmodule

module vga_write_clock
	(
		input clock,
		input reset,
		input frame_flag,
		// MEMORY_INTERFACE
		input [`LOG_MEM-1:0] vga_pixel,
		input done_vga,
		output reg vga_flag,
		// MEMORY_INTERFACE ADDRESSING
		output reg [`LOG_HCOUNT-1:0] hcount,
		output reg [`LOG_VCOUNT-1:0] vcount,
		// FIFO
		input v2f_empty,
		input f2v_full,
		output reg v2f_rd_en,
		output reg f2v_wr_en,
		input [23:0] v2f_dout,
		output reg [63:0] f2v_din
	);
	
	reg hsync;
	reg vsync;
	reg blank;

	reg [`LOG_HCOUNT-1:0] del_hcount[0:1];
	reg [`LOG_VCOUNT-1:0] del_vcount[0:1];
	reg del_hsync[0:1];
	reg del_vsync[0:1];
	reg del_blank[0:1];

	reg del_vga_flag[0:1];
	reg del_v2f_rd_en[0:2];

	reg out_of_bounds;
	reg [`LOG_MEM-1:0] pixel;

	always @(*) begin
		out_of_bounds = del_hcount[1] >= 640 || del_vcount[1] >= 480;
		pixel = out_of_bounds ? 36'd0 : vga_pixel;

		// always read when the queue is not empty
		v2f_rd_en = ~v2f_empty;
		
		// extract info from FIFO
		hcount = v2f_dout[23:14];
		vcount = v2f_dout[13:4];
		hsync = v2f_dout[3];
		vsync = v2f_dout[2];
		blank = v2f_dout[1];

		// wait for hcount, vcount to be available
		// only request every even pixel
		vga_flag = (del_v2f_rd_en[0] && hcount[0] == 0 && hcount < 640 && vcount < 480);

		// write three cycles after the correspoding rd_en pulse
		// 3 cycles instead of 2 due to the additional 1 cycle read delay
		f2v_wr_en = del_v2f_rd_en[2];
		f2v_din[63:54] = del_hcount[1];
		f2v_din[53:44] = del_vcount[1];
		f2v_din[43]    = del_hsync[1];
		f2v_din[42]    = del_vsync[1];
		f2v_din[41]    = del_blank[1];
		f2v_din[40:5]  = pixel;
		f2v_din[4]     = reset;
		f2v_din[3]     = frame_flag;
		f2v_din[2:0]   = 3'b0;
	end

	always @(posedge clock) begin
		// delay flag, vcount, hcount by 2 clock cycles due to RAM delay
		if (reset) begin
			del_vga_flag[0] <= 0;
			del_vga_flag[1] <= 0;
			
			del_hcount[0] <= 0;
			del_hcount[1] <= 0;
			
			del_vcount[0] <= 0;
			del_vcount[1] <= 0;
			
			del_v2f_rd_en[0] <= 0;
			del_v2f_rd_en[1] <= 0;
			del_v2f_rd_en[2] <= 0;
		end
		else begin
			del_vga_flag[0] <= vga_flag;
			del_vga_flag[1] <= del_vga_flag[0];

			del_hcount[0] <= hcount;
			del_hcount[1] <= del_hcount[0];

			del_vcount[0] <= vcount;
			del_vcount[1] <= del_vcount[0];

			del_hsync[0] <= hsync;
			del_hsync[1] <= del_hsync[0];

			del_vsync[0] <= vsync;
			del_vsync[1] <= del_vsync[0];

			del_blank[0] <= blank;
			del_blank[1] <= del_blank[0];

			del_v2f_rd_en[0] <= v2f_rd_en;
			del_v2f_rd_en[1] <= del_v2f_rd_en[0];
			del_v2f_rd_en[2] <= del_v2f_rd_en[1];
		end
	end
endmodule

module vga_write_vclock
	(
		input vclock,
		input reset,
		// FIFO
		input f2v_empty,
		input v2f_full,
		output reg f2v_rd_en,
		output reg v2f_wr_en,
		input [63:0] f2v_dout,
		output reg [23:0] v2f_din,
		// TO VGA CHIP
		output [7:0] vga_out_red,
		output [7:0] vga_out_green,
		output [7:0] vga_out_blue,
		output reg vga_out_sync_b,
		output reg vga_out_blank_b,
		output reg vga_out_pixel_clock,
		output reg vga_out_hsync,
		output reg vga_out_vsync
	);

	// from FIFO
	reg [`LOG_HCOUNT-1:0] input_hcount;
	reg [`LOG_VCOUNT-1:0] input_vcount;
	reg [`LOG_MEM-1:0] input_pixel;
	reg input_hsync;
	reg input_vsync;
	reg input_blank;
	reg input_reset;
	reg frame_flag;

	// to FIFO
	wire [`LOG_HCOUNT-1:0] output_hcount;
	wire [`LOG_VCOUNT-1:0] output_vcount;
	wire output_hsync;
	wire output_vsync;
	wire output_blank;

	xvga xvga_i(
		.vclock(vclock), .reset(reset), .frame_flag(frame_flag),
		.hcount(output_hcount), .vcount(output_vcount),
		.vsync(output_vsync), .hsync(output_hsync), .blank(output_blank));

	// ycbcr2rgb
	// making this part combinational because we're operating at 25MHz
	// and only with simple LUTs, adders -- no multipliers
	ycrcb_lut ycc(
		.ycrcb(input_hcount[0] ? input_pixel[35:18] : input_pixel[17:0]),
		.r(vga_out_red), .g(vga_out_green), .b(vga_out_blue));

	always @(*) begin
		vga_out_sync_b  = 1'b1;
		vga_out_blank_b = ~input_blank;
		vga_out_hsync   = input_hsync;
		vga_out_vsync   = input_vsync;
		vga_out_pixel_clock = ~vclock;
	end

	always @(posedge vclock) begin
		// writes every cycle
		v2f_wr_en      <= 1'b1;
		v2f_din[23:14] <= output_hcount;
		v2f_din[13:4]  <= output_vcount;
		v2f_din[3]     <= output_hsync;
		v2f_din[2]     <= output_vsync;
		v2f_din[1]     <= output_blank;	
		v2f_din[0]     <= 1'b0;

		f2v_rd_en    <= 1'b1;
		input_hcount <= f2v_dout[63:54];
		input_vcount <= f2v_dout[53:44];
		input_hsync  <= f2v_dout[43];
		input_vsync  <= f2v_dout[42];
		input_blank  <= f2v_dout[41];
		input_pixel  <= f2v_dout[40:5];
		input_reset  <= f2v_dout[4];
		frame_flag   <= f2v_dout[3];
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
