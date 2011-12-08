`include "pa

module dumb_lpf(
	// standard
	input clock,
	input reset,
	input frame_flag,
	// memory_interface
	input done_lpf,
	output [`LOG_WIDTH-1:0] 
