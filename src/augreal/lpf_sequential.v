`default_nettype none
`include "params.v"

module sequential_dumb_lpf(
	input clock,
	input reset,
	input frame_flag,
	// memory_interface
	input done_lpf,
	output reg lpf_flag,
	output lpf_wr,
	output reg [`LOG_WIDTH-1:0] lpf_x,
	output reg [`LOG_HEIGHT-1:0] lpf_y,
	output [`LOG_MEM-1:0] lpf_pixel_write,
	input [`LOG_MEM-1:0] lpf_pixel_read,
	// projective_transform
	input request,
	output reg [`LOG_TRUNC-1:0] pixel,
	output [9:0] x_out,
	output [8:0] y_out,
	output pixel_flag
);

   reg [17:0]  pxbuf;
   wire        delayed_done_lpf;
   
   delay #(.N(3), .LOG(1)) dflag(.clock(clock), .reset(reset),
				 .x(done_lpf), .y(delayed_done_lpf));

   reg 	       x = 0;
   reg 	       y = 0;
   
   reg 	       hasbfd;

   // never writing
	assign lpf_wr = 1'b0;
	assign lpf_pixel_write = `LOG_MEM'd0;
   

   always @(posedge clock) begin
      if (reset | frame_flag) begin
	 x <= 0;
	 y <= 0;
	 hasbfd <= 0;
      end else begin
	 if (request) begin
	    x <= x + 1;
	    
	    if ( ~x[0]) begin
	       lpf_flag <= 1;
	       lpf_x <= x;
	    end else lpf_flag <= 0;

	    if ( x > 638) begin
	       x <= 0;
	       y <= y + 1;
	    end
	 end

	 pixel_flag <= 0;
	 

	 if (delayed_done_lpf) begin
	    pxbuf <= lpf_pixel_read[17:0];
	    pixel <= lpf_pixel_read[35:18];
	    pixel_flag <= 1;
	    x_out <= x - 3;
	    y_out <= y;
	    hasbfd <= 1;
	 end
	 

	 if (hasbfd) begin
	    pixel_flag <= 1;
	    x_out <= x - 3;
	    y_out <= y;
	    hasbfd <= 0;
	    pixel <= pxbuf;
	 end
      end // else: !if(reset | frame_flag)
   end // always @ (posedge clock)
endmodule // dumb_lpf
