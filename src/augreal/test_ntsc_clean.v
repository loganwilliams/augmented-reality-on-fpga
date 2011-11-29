`timescale 1ns / 1ps
`include "ntsc_clean.v"

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:08:00 11/29/2011
// Design Name:   ntsc_clean
// Module Name:   /afs/athena.mit.edu/user/l/o/loganw/Documents/6.111/augmented-reality-on-fpga/src/augreal/test_ntsc_clean.v
// Project Name:  augreal
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ntsc_clean
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_ntsc_clean;

	// Inputs
	reg clock_65mhz;
	reg ntsc_flag;
	reg [35:0] ntsc_pixels;

	// Outputs
	wire clean_ntsc_flag;
	wire [35:0] clean_ntsc_pixels;

	// Instantiate the Unit Under Test (UUT)
	ntsc_clean uut (
		.clock_65mhz(clock_65mhz), 
		.ntsc_flag(ntsc_flag), 
		.ntsc_pixels(ntsc_pixels), 
		.clean_ntsc_flag(clean_ntsc_flag), 
		.clean_ntsc_pixels(clean_ntsc_pixels)
	);

	initial begin
		// Initialize Inputs
		clock_65mhz = 0;
		ntsc_flag = 0;
		ntsc_pixels = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

