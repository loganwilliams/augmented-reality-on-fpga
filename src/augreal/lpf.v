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
	output reg pixel_flag
);

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
		pixel_flag = done_lpf | pixel_flag_odd;

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

	always @(*) begin
		pixel = (x_out[0] == 1'b0) ? lpf_pixel_read[`LOG_MEM-1:`LOG_TRUNC] : lpf_pixel_read[`LOG_TRUNC-1:0];
	end
endmodule

module lpf(
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
	output reg pixel_flag
);

	parameter FILTER_LENGTH=41;
	parameter CENTER_LOC = 9'd20;
	parameter FILTER_COEFF_WIDTH=10;
	reg [FILTER_LENGTH*FILTER_COEFF_WIDTH-1:0] col_coeffs;
	reg [FILTER_LENGTH*FILTER_COEFF_WIDTH-1:0] row_coeffs;

	reg [2:0] state;
	parameter COLS   = 3'd0;
	parameter ROWS   = 3'd4;

	reg [FILTER_LENGTH*`LOG_MEM-1:0] read_cols[0:3];

	reg [(FILTER_LENGTH+8)*`LOG_TRUNC-1:0] next_sample_cols;

	reg [`LOG_WIDTH-1:0] request_x;
	reg [`LOG_HEIGHT-1:0] request_y;
	wire [`LOG_WIDTH-1:0] del_request_x;
	wire [`LOG_HEIGHT-1:0] del_request_y;
	reg [`LOG_WIDTH-1:0] read_x;
	reg [`LOG_HEIGHT-1:0] read_y;
	reg [`LOG_WIDTH-1:0] write_x;
	reg [`LOG_HEIGHT-1:0] write_y;

	wire del_done_lpf;
	wire del_lpf_wr;
	delay #(.N(4)) dw(.clock(clock), .reset(reset), .x(lpf_wr), .y(del_lpf_wr));
	delay #(.N(3)) dp(.clock(clock), .reset(reset), .x(done_lpf), .y(del_done_lpf));
	delay #(.N(4), .LOG(`LOG_WIDTH)) dx(.clock(clock), .reset(reset), .

	// fetching pixels from RAM
	always @(posedge clock) begin
		if (!del_lpf_wr && del_done_lpf) begin
			next_sample_cols <= {next_sample_cols[(FILTER_LENGTH+8)*`LOG_TRUNC-1:2*`LOG_TRUNC], lpf_pixel};
			// TODO: update based on whether near the end
			read_x <= read_x;
			read_y <= read_y+2;
		end
		else begin
			next_sample_cols <= next_sample_cols;
			read_x <= read_x;
			read_y <= read_y;
		end
	end

	// carry out mirroring here
	always @(posedge clock) begin

	end

	// decide whether to change states here
	always @(posedge clock) begin
	end

	// decide whether to read, write, and request
	always @(posedge clock) begin
		case (state)
			COLS: begin
				// stall if memory_interface is busy
				if (lpf_flag == 1'b1 && done_lpf == 1'b0) begin
					lpf_flag <= lpf_flag;
					lpf_wr <= lpf_wr;
					lpf_x <= lpf_x;
					lpf_y <= lpf_y;
					lpf_pixel_write <= lpf_pixel_write;
					write_y <= write_y;
					write_x <= write_x;
					request_y <= request_y;
					request_x <= request_x;
				end
				// write a pixel if ready
				else if ((read_y-write_y) >= CENTER_LOC) begin
					lpf_flag <= 1;
					lpf_wr <= 1;
					lpf_x <= write_x;
					lpf_y <= write_y;
					lpf_pixel_write <= {next_sample_cols[;
					write_y <= write_y+1;
					write_x <= write_x;
					request_y <= request_y;
					request_x <= request_x;
				end
				// request a pixel if the buffer isn't full
				else if ((request_y-read_y) < 8) begin
					lpf_flag <= 1;
					lpf_wr <= 0;
					lpf_x <= request_x;
					lpf_y <= request_y;
					lpf_pixel_write <= lpf_pixel_write;
					write_y <= write_y;
					write_x <= write_x;
					request_y <= request_y+2;
					request_x <= request_x;
				end
				// doing nothing
				else begin
					lpf_flag <= 1'b0;
					lpf_wr <= 1'b0;
					lpf_x <= lpf_x;
					lpf_y <= lpf_y;
					lpf_pixel_write <= lpf_pixel_write;
					write_y <= write_y;
					write_x <= write_x;
					request_y <= request_y;
					request_x <= request_x;
				end
			end	
			ROWS: begin
				// stall if memory_interface is busy
				if (lpf_flag == 1'b1 && done_lpf == 1'b0) begin
					lpf_flag <= lpf_flag;
					lpf_wr <= lpf_wr;
					lpf_x <= lpf_x;
					lpf_y <= lpf_y;
					lpf_pixel_write <= lpf_pixel_write;
					write_y <= write_y;
					write_x <= write_x;
					request_y <= request_y;
					request_x <= request_x;
				end
				// write a pixel if ready
				else if ((read_x-write_x) >= CENTER_LOC) begin
					lpf_flag <= 1;
					lpf_wr <= 1;
					lpf_x <= write_x;
					lpf_y <= write_y;
					lpf_pixel_write <= {next_sample_cols[;
					write_y <= write_y;
					write_x <= write_x+1;
					request_y <= request_y;
					request_x <= request_x;
				end
				// request a pixel if the buffer isn't full
				else if ((request_x-read_x) < 8) begin
					lpf_flag <= 1;
					lpf_wr <= 0;
					lpf_x <= request_x;
					lpf_y <= request_y;
					lpf_pixel_write <= lpf_pixel_write;
					write_y <= write_y;
					write_x <= write_x;
					request_y <= request_y;
					request_x <= request_x+2;
				end
				// doing nothing
				else begin
					lpf_flag <= 1'b0;
					lpf_wr <= 1'b0;
					lpf_x <= lpf_x;
					lpf_y <= lpf_y;
					lpf_pixel_write <= lpf_pixel_write;
					write_y <= write_y;
					write_x <= write_x;
					request_y <= request_y;
					request_x <= request_x;
				end
			end
		endcase
	end
endmodule
