// clock frequencies
`define FPGA_CLOCK 26'd60000000
`define  VGA_CLOCK 26'd25175000
`define NTSC_CLOCK 25'd12587500

// bitwidth of clock frequencies
`define LOG_FPGA_CLOCK 26
`define LOG_VGA_CLOCK  26
`define LOG_NTSC_CLOCK 25

// image sizes
`define TOTAL_PIXELS 	19'd307200
`define IMAGE_WIDTH  	10'd640
`define IMAGE_WIDTH_D2   9'd320
`define IMAGE_HEIGHT  	 9'd480

// bitwidth of image sizes
`define LOG_TOTAL_PIXELS 19
`define LOG_WIDTH        10
`define LOG_WIDTH_D2	  9
`define LOG_HEIGHT 		  9

// memory sizes
`define IMAGE_LENGTH 153600
`define MEM_ADDR     524288

// memory bitwidths
`define LOG_IMAGE_ADDR	19
`define LOG_MEM			36
`define LOG_ADDR		19

// pixel bitwidths
`define LOG_TRUNC	18
`define LOG_FULL	24

// VGA (640x480@60Hz)
`define VGA_HBLANKON 	10'd639
`define VGA_HSYNCON  	10'd645
`define VGA_HSYNCOFF	10'd751
`define VGA_HRESET		10'd799
`define VGA_VBLANKON    10'd479
`define VGA_VSYNCON		10'd490
`define VGA_VSYNCOFF	10'd492
`define VGA_VRESET		10'd523

// VGA  bitwidths
`define LOG_HCOUNT	10
`define LOG_VCOUNT	10
