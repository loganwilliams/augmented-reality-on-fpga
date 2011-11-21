module projective_transform(
			    input 	      clk, // System clock (global ->)
			    input 	      frame_flag, // New frame flag (ntsc_capture ->)
			    input [17:0]      pixel, // Pixel data input (lpf ->)
			    input 	      pixel_flag, // New pixel recieved? (lpf ->)
			    input [9:0]       a_x, // coordinates of the corners
			    input [8:0]       a_y, //  |  (object_recognition ->)
			    input [9:0]       b_x, //  |
			    input [8:0]       b_y, //  |
			    input [9:0]       c_x, //  |
			    input [8:0]       c_y, //  |
			    input [9:0]       d_x, //  |
			    input [8:0]       d_y, //  |
			    input 	      ptflag, // Okay to send new data (memory_interface ->) 
			    output reg [17:0] pt_pixel_write, // Pixel data output (-> memory_interface)
			    output reg [9:0]  pt_x, // Pixel output data location
			    output reg [8:0]  pt_y, //  | (-> memory_interface)
			    output reg 	      pt_wr, // Want to write pixel flag (-> memory_interface)
			    output reg 	      request_pixel // request a pixel to process (-> lpf) 	      
			    );
   
   // a register to store the current state of computation
   reg [?:0] state; // not sure how many states we have yet

   // iterator coordinates for the three iterator points
   // these all have 10 extra bits of resolution to simulate decimals
   // 	(for example 1 is represented by 1 << 10)
   reg [19:0] i_a_x;
   reg [18:0] i_a_y;
   reg [19:0] i_b_x;
   reg [18:0] i_b_y;
   reg [19:0] i_c_x;
   reg [18:0] i_c_y;

   // registers to store calculations of distance (fractional part does not matter)
   reg [9:0]  d_ad;
   reg [9:0]  d_bc;
   reg [9:0]  d_iterators;

   // temporary registers for calculating distances
   reg [19:0] dcalc_temp1;
   reg [19:0] dcalc_temp2;
   reg [20:0] d_sqrt;
   wire [10:0] answer;
   wire        sqrt_done;

   // coordinates iterators in the untransformed images
   reg [9:0]  o_x;
   reg [8:0]  o_y;

   // this is the iterative square rooter used for distance calculations
   // with NBITS = 21, it will take 21 clock cycles to return a result.
   distance_sqrter (NBITS = 21) sqrt(.clk(clk), .start(sqrt_start),
				     .data(d_sqrt), .answer(answer),
				     .done(sqrt_done));
   
   initial state = WAITING_FOR_FRAME_FLAG;
   
   always @(posedge clk) begin
      // this should be made part of the state machine
      if (frame_flag) begin
	 // initialize system parameters
	 state <= CALCULATING_DISTANCE_AD_1;
	 i_a_x <= ax << 10;
	 i_a_y <= ay << 10;
	 i_b_x <= bx << 10;
	 i_b_y <= by << 10;

	 d_ad <= 0;
	 d_bc <= 0;
	 d_iterators <= 0;

	 o_x <= 0;
	 o_y <= 0;
      end

      case(state)
	// once per frame
	CALCULATING_DISTANCE_AD_1: begin
	   dcalc_temp1 <= (ax - dx) * (ax - dx);
	   dcalc_temp2 <= (ay - dy) * (ay - dy);
	   state <= CALCULATING_DISTANCE_AD_2;
	end

	// once per frame
	CALCULATING_DISTANCE_AD_Y: begin
	   d_sqrt <= dcalc_temp1 + dcalc_temp2;
	   sqrt_start <= 1;
	   state <= CALCULATING_DISTANCE_AD_SQRT;
	end

	// once per frame
	CALCULATING_DISTANCE_AD_SQRT: begin
	   sqrt_start <= 0;

	   if (sqrt_done) begin
	      d_ad <= answer;

	      // will need two coregen divider modules
	      delta_a_x = ((d_x - a_x) << 10) / answer;
	      delta_a_y = ((d_y - a_y) << 10) / answer;
	    	      
	      state <= CALCULATING_DISTANCE_BC_1;
	   end
	end

	// once per frame
	CALCULATING_DISTANCE_BC_1: begin
	   dcalc_temp1 <= (bx - cx) * (bx - cx);
	   dcalc_temp2 <= (by - cy) * (by - cy);
	   state <= CALCULATING_DISTANCE_BC_2;
	end

	// once per frame
	CALCULATING_DISTANCE_BC_2: begin
	   dsqrt <= dcalc_temp1 + dcalc_temp2;
	   sqrt_start <= 1;
	   state <= CALCULATING_DISTANCE_BC_SQRT;
	end

	// once per frame
	CALCULATING_DISTANCE_BC_SQRT: begin
	   sqrt_start <= 0;

	   if (sqrt_done) begin
	      d_bc <= answer;

	      // will need two coregen divider modules
	      delta_b_x = ((c_x - b_x) << 10) / answer;
	      delta_b_y = ((c_y - b_y) << 10) / answer;
	      
	      state <= CALCULATING_DISTANCE_ITERATORS_1;
	   end
	end

	// once per LINE
	// the next three state should be optimized to over lap with the end
	// of each horizontal iteration, so that every line doesn't begin with
	// a 20 clk cycle delay while the square root iterator is working
	CALCULATING_DISTANCE_ITERATORS_1: begin
	   dcalc_temp1 <= (i_a_x - i_b_x) * (i_a_x - i_b_x);
	   dcalc_temp2 <= (i_a_y - i_b_y) * (i_a_y - i_b_y);
	   state <= CALCULATING_DISTANCE_ITERATORS_2;
	end

	// once per LINE
	CALCULATING_DISTANCE_ITERATORS_2: begin
	   dsqrt <= dcalc_temp1 + dcalc_temp2;
	   sqrt_start <= 1;
	   state <= CALCULATING_DISTANCE_ITERATORS_SQRT;
	end

	// once per LINE
	CALCULATE_DISTANCE_ITERATORS_SQRT: begin
	   sqrt_start <= 0;

	   if (sqrt_done) begin
	      d_iterators <= answer;
	      
	      delta_c_x <= ((i_b_x - i_a_x) << 10) / answer;
	      delta_c_y <= ((i_b_y - i_a_y) << 10) / answer;
	      
	      state <= WRITE_PIXEL;
	   end
	end


	// ONCE PER PIXEL
	WRITE PIXEL: begin
	   
	end

      endcase
   end
endmodule


// takes integer square root iteratively
module sqrt #(parameter NBITS = 8,  // max 32
              MBITS = (NBITS+1)/2)
   (input wire clk,start,
    input wire [NBITS-1:0] data,
    output reg [MBITS-1:0] answer,
    output wire 	   done);
   
   reg 			   busy;
   reg [4:0] 		   bit;
   // compute answer bit-by-bit, starting at MSB
   wire [MBITS-1:0] 	   trial = answer | (1 << bit);
   
   always @(posedge clk) begin
      if (busy) begin
	 if (bit == 0) busy <= 0;
	 else bit <= bit - 1;
	 if (trial*trial <= data) answer <= trial;
      end
      else if (start) begin
	 busy <= 1;
	 answer <= 0;
	 bit <= MBITS - 1;
      end
   end
   assign done = ~busy;
endmodule