
module dummy_ntsc_capture(
			  input 	    clk, // the main system clock
			  input 	    clock_27mhz,
			  input 	    reset, // reset line
			  output 	    tv_in_reset_b, // these are all labkit wires
			  output 	    tv_in_i2c_clock, //   |
			  inout 	    tv_in_i2c_data, //    |
			  input 	    tv_in_line_clock1, // |
			  input [19:0] 	    tv_in_ycrcb, //       |
			  output reg [35:0] ntsc_pixels, // outputs two sets of pixels in Y/Cr/Cb/Y/Cr/Cb format
			  output reg 	    ntsc_flag, // a flag that goes high when a pixel is being output
			  output reg [1:0]  color, // these outputs are for object_recognition. this indicates the color of the recognized pixel
			  output reg [9:0]  interesting_x, // its x locaiton
			  output reg [8:0]  interesting_y, // its y location
			  output reg 	    interesting_flag, // a flag that indicates the data is good
			  output reg 	    frame_flag,
			  output reg [9:0] x,
			  output reg [8:0] y
			  );
   
  // reg [9:0] 				    x = 0;
  // reg [8:0] 				    y = 0;
   
   reg [1:0] 				    state = 0;
   reg [7:0] 				    counter = 0;
   
   always @(posedge clk) begin	     
      if (state == 2'b00) begin
	 ntsc_pixels <= {counter, 10'b0, counter, 10'b0};
	 counter <= counter + 1;

	 if (y > 478) begin
	    y <= 0;
	    x <= 0;
	    frame_flag <= 1;
	    counter <= 0;
	    ntsc_flag <= 0;
	 end else if (x > 638) begin
	    x <= 0;
	    y <= y + 1;
	    frame_flag <= 0;
	    ntsc_flag <= 1;
	 end else begin
	    x <= x + 1;
	    frame_flag <= 0;
	    ntsc_flag <= 1;
	 end
	 
	 state <= state + 1;
      end else begin
	 ntsc_flag <= 0;
	 state <= state + 1;
      end
   end
endmodule
