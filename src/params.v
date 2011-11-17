// clock frequencies
`define FPGA_CLOCK 26'd60000000
`define  VGA_CLOCK 26'd25175000
`define NTSC_CLOCK 25'd12587500

// bitwidth of clock frequencies (-1)
`define LOG_FPGA_CLOCK 25
`define LOG_VGA_CLOCK  25
`define LOG_NTSC_CLOCK 24

// image sizes
`define TOTAL_PIXELS 20'd307200
`define IMAGE_WIDTH  10'd640
`define IMAGE_HEIGHT  9'd480

// bitwidth of image sizes (-1)
`define LOG_TOTAL_PIXELS 19
`define LOG_WIDTH         9
`define LOG_HEIGHT 		  8

// memory sizes
`define IMAGE_LENGTH 153600

// memory bitwidths (-1)
`define LOG_IMAGE_ADDR	18
`define LOG_MEM			35
`define LOG_ADDR		18

// pixel bitwidths (-1)
`define LOG_TRUNC	17
`define LOG_FULL	23
