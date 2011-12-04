`timescale 1ns / 1ps
`include "params.v"

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   03:46:50 12/04/2011
// Design Name:   vga_write_fifo
// Module Name:   /afs/athena.mit.edu/user/c/r/cruz/6.111/augmented-reality-on-fpga/src/augreal/vga_write_fifo_tb.v
// Project Name:  augreal
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vga_write_fifo
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module vga_write_fifo_tb;

	// Inputs
	reg clock;
	reg vclock;
	reg reset;
	reg frame_flag;
	wire [35:0] vga_pixel;
	wire done_vga;

	// Outputs
	wire vga_flag;
	wire [7:0] vga_out_red;
	wire [7:0] vga_out_green;
	wire [7:0] vga_out_blue;
	wire vga_out_sync_b;
	wire vga_out_blank_b;
	wire vga_out_pixel_clock;
	wire vga_out_hsync;
	wire vga_out_vsync;
	wire [9:0] clocked_hcount;
	wire [9:0] clocked_vcount;

	// Instantiate the Unit Under Test (UUT)
	vga_write_fifo uut (
		.clock(clock), 
		.vclock(vclock), 
		.reset(reset), 
		.frame_flag(frame_flag), 
		.vga_pixel(vga_pixel), 
		.done_vga(done_vga), 
		.vga_flag(vga_flag), 
		.vga_out_red(vga_out_red), 
		.vga_out_green(vga_out_green), 
		.vga_out_blue(vga_out_blue), 
		.vga_out_sync_b(vga_out_sync_b), 
		.vga_out_blank_b(vga_out_blank_b), 
		.vga_out_pixel_clock(vga_out_pixel_clock), 
		.vga_out_hsync(vga_out_hsync), 
		.vga_out_vsync(vga_out_vsync), 
		.clocked_hcount(clocked_hcount), 
		.clocked_vcount(clocked_vcount)
	);
	
	test_mem_int tmi(
		.clock(clock),
		.reset(reset),
		.hcount(clocked_hcount),
		.vcount(clocked_vcount),
		.vga_flag(vga_flag),
		.done_vga(done_vga),
		.pixel(vga_pixel)
	);

	initial begin
		// Initialize Inputs
		$dumpvars;
		clock = 0;
		vclock = 0;
		reset = 1;
		frame_flag = 0;

		// Wait 100 ns for global reset to finish
		#100;
		reset = 0;
        
		// Add stimulus here
		#3000000;
		$stop;
	end
   
	always #7 clock = ~clock;
	always #21 vclock = ~vclock;
endmodule

module test_mem_int(
	input clock,
	input reset,
	input [9:0] hcount,
	input [9:0] vcount,
	input vga_flag,
	output reg done_vga,
	output reg [35:0] pixel
	);
	
	reg [35:0] pixel_buf;
	reg [35:0] count;
	
	always @(*) begin
		done_vga = vga_flag;
	end
	
	always @(posedge clock) begin
		if (reset) begin
			pixel <= 0;
			pixel_buf <= 0;
			count <= 0;
		end
		else begin
			if (vga_flag) begin
				pixel_buf <= count;
				pixel <= pixel_buf;
				count <= count+1;
			end
			else begin
				pixel_buf <= pixel_buf;
				pixel <= pixel_buf;
				count <= count;
			end
		end
	end
endmodule