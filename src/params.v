// clock frequencies
`define FPGA_CLOCK 26'd60000000
`define  VGA_CLOCK 26'd25175000
`define NTSC_CLOCK 25'd12587500

// bitwidth of clock frequencies
`define LOG_FPGA_CLOCK 26
`define LOG_VGA_CLOCK  26
`define LOG_NTSC_CLOCK 25

// image sizes
`define TOTAL_PIXELS 20'd307200
`define IMAGE_WIDTH  10'd640
`define IMAGE_HEIGHT  9'd480

// bitwidth of image sizes
`define LOG_TOTAL_PIXELS 20
`define LOG_WIDTH        10
`define LOG_HEIGHT 		  9

// memory sizes
`define IMAGE_LENGTH 153600

// memory bitwidths
`define LOG_IMAGE_ADDR	19
`define LOG_MEM			36
`define LOG_ADDR		19

// pixel bitwidths (-1)
`define LOG_TRUNC	18
`define LOG_FULL	24
