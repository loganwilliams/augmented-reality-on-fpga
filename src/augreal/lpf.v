`default_nettype none
`include "params.v"

module dumb_lpf(
	input clock,
	input reset,
	input frame_flag,
	// memory_interface
	input done_lpf,
	output reg lpf_flag,
	output reg lpf_wr,
	output reg [`LOG_WIDTH-1:0] lpf_x,
	output reg [`LOG_HEIGHT-1:0] lpf_y,
	output reg [`LOG_MEM-1:0] lpf_pixel_write,
	input [`LOG_MEM-1:0] lpf_pixel_read,
	// projective_transform
	input request,
	output reg [`LOG_TRUNC-1:0] pixel,
	output reg [9:0] x_out,
	output reg [8:0] y_out,
	output pixel_flag
);

	reg advanced_pixel_flag;
	reg [`LOG_WIDTH-1:0] x;
	reg [`LOG_HEIGHT-1:0] y;
	reg pixel_flag_odd;

	// never writing
	always @(*) begin
		lpf_wr = 1'b0;
		lpf_pixel_write = `LOG_MEM'd0;
	end

	always @(*) begin
		// pulse lpf_flag only when x is even and a pixel is requested
		lpf_flag = request & ~lpf_x[0];
		// pulse pixel flag when done_lpf is high and x[0] is even
		// or 1 cycle after request when lpf_x is odd
		advanced_pixel_flag = done_lpf | pixel_flag_odd;

		// x and y are the next set of coordinates
		if (reset || frame_flag) begin
			x = 0;
			y = 0;
		end
		else if (!pixel_flag) begin
			x = lpf_x;
			y = lpf_y;
		end
		else if (lpf_x == `IMAGE_WIDTH-1) begin
			x = `LOG_WIDTH'd0;
			y = lpf_y+1;
		end
		else begin
			x = lpf_x+1;
			y = lpf_y;
		end
	end

	always @(posedge clock) begin
		// update lpf_x and lpf_y
		lpf_x <= x;
		lpf_y <= y;
		pixel_flag_odd <= request & lpf_x[0];
	end

	// delay lpf_x, lpf_y | module is located in vga_write_new.v
	delay #(.N(4), .LOG(1)) dx(.clock(clock), .reset(reset), .x(lpf_x), .y(x_out));
	delay #(.N(4), .LOG(1)) dy(.clock(clock), .reset(reset), .x(lpf_y), .y(y_out));
	delay #(.N(3), .LOG(1)) df(.clock(clock), .reset(reset), .x(advanced_pixel_flag), .y(pixel_flag));

	always @(*) begin
		pixel = (x_out[0] == 1'b0) ? lpf_pixel_read[`LOG_MEM-1:`LOG_TRUNC] : lpf_pixel_read[`LOG_TRUNC-1:0];
	end
endmodule
