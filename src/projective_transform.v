`include "divider.v"

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
			    input 	      corners_flag, // (object_recognition ->)
			  
			    
			    input 	      ptflag, // Okay to send new data (memory_interface ->) 
			    output reg [17:0] pt_pixel_write, // Pixel data output (-> memory_interface)
			    output reg [9:0]  pt_x, // Pixel output data location
			    output reg [8:0]  pt_y, //  | (-> memory_interface)
			    output reg 	      pt_wr, // Want to write pixel flag (-> memory_interface)
			    output reg 	      request_pixel // request a pixel to process (-> lpf) 	      
			    );
   

   reg [2:0] state = 0;

   // iterator coordinates for the three iterator points
   // these all have 10 extra bits of resolution to simulate decimals
   // 	(for example 1 is represented by 1 << 10)
   reg [19:0] i_a_x;
   reg [18:0] i_a_y;
   reg [19:0] i_b_x;
   reg [18:0] i_b_y;
   reg [19:0] i_c_x;
   reg [18:0] i_c_y;

   // iterator incrementors
   reg [19:0] delta_a_x;
   reg [19:0] delta_a_y;
   reg [19:0] delta_b_x;
   reg [19:0] delta_b_y;
   reg [19:0] delta_c_x;
   reg [19:0] delta_c_y;
   reg [19:0] delta_c_x_next;
   reg [19:0] delta_c_y_next;
   

   // registers to store calculations of distance (fractional part does not matter)
   reg [9:0]  d_ad;
   reg [9:0]  d_bc;
   reg [9:0]  d_iterators;
   reg [9:0]  d_next_iterators;
   

   // temporary registers for calculating distances
   reg [19:0] temp1a;
   reg [19:0] temp2a;
   reg [19:0] temp1b;
   reg [19:0] temp2b;
   reg [19:0] temp1c;
   reg [19:0] temp2c;

   // wires/registers for sqrting
   reg 	      sqrt_start_a;
   reg 	      sqrt_start_b;
   reg 	      sqrt_start_c;
   
   reg [20:0] d_sqrt_a;
   reg [20:0] d_sqrt_b;
   reg [20:0] d_sqrt_c;
   
   wire [10:0] answer_a;
   wire [10:0] answer_b;
   wire [10:0] answer_c;
   
   wire        sqrt_done_a;
   wire        sqrt_done_c;
   wire        sqrt_done_b;

   // wires/registers for diving
   wire        rfd_a;
   wire        rfd_b;
   wire        rfd_c;
   wire        rfd_d;
   wire        rfd_e;
   wire        rfd_f;

   reg [19:0]  dividend_a;
   reg [19:0]  dividend_b;
   reg [19:0]  dividend_c;
   reg [19:0]  dividend_d;
   reg [19:0]  dividend_e;
   reg [19:0]  dividend_f;

   reg [9:0]   divisor_a;
   reg [9:0]   divisor_b;
   reg [9:0]   divisor_c;
   reg [9:0]   divisor_d;
   reg [9:0]   divisor_e;
   reg [9:0]   divisor_f;

   wire [19:0] quotient_a;
   wire [19:0] quotient_b;
   wire [19:0] quotient_c;
   wire [19:0] quotient_d;
   wire [19:0] quotient_e;
   wire [19:0] quotient_f;

   // coordinates iterators in the untransformed images
   reg [9:0]  o_x;
   reg [8:0]  o_y;

   reg [4:0]  counter;
   reg 	      counting = 0;

   // create some registers for dealing with possible delays
   // in memory_write
   reg [17:0] pixel_save;
   reg 	      waiting_for_write;

   parameter WAIT_FOR_CORNERS = 0;
   parameter CALC_INIT_DIST_MULT = 1;
   parameter WAIT_FOR_SQRT = 2;
   parameter WAIT_FOR_DIVIDERS = 3;
   parameter WAIT_FOR_PIXEL = 4;
   parameter CALC_NEXT_DIST = 5;
   

   // this is the iterative square rooter used for distance calculations
   // with NBITS = 21, it will take 21 clock cycles to return a result.
   sqrt #(.NBITS(21)) sqrta(.clk(clk), .start(sqrt_start_a),
			   .data(d_sqrt_a), .answer(answer_a),
			   .done(sqrt_done_a));

   sqrt #(.NBITS(21)) sqrtb(.clk(clk), .start(sqrt_start_b),
			   .data(d_sqrt_b), .answer(answer_b),
			   .done(sqrt_done_b));

   sqrt #(.NBITS(21)) sqrtc(.clk(clk), .start(sqrt_start_c),
			   .data(d_sqrt_c), .answer(answer_c),
			   .done(sqrt_done_c));

   // three dividers, for parallelization. these are used to calculate
   // iteration "deltas"
   divider diva(.clk(clk), .rfd(rfd_a), .dividend(dividend_a),
		.divisor(divisor_a), .quotient(quotient_a));

   divider divb(.clk(clk), .rfd(rfd_b), .dividend(dividend_b),
		.divisor(divisor_b), .quotient(quotient_b));
   
   divider divc(.clk(clk), .rfd(rfd_c), .dividend(dividend_c),
		.divisor(divisor_c), .quotient(quotient_c));

   divider divd(.clk(clk), .rfd(rfd_d), .dividend(dividend_d),
		.divisor(divisor_d), .quotient(quotient_e));

   divider dive(.clk(clk), .rfd(rfd_e), .dividend(dividend_e),
		.divisor(divisor_e), .quotient(quotient_d));
   
   div divf(.clk(clk), .rfd(rfd_f), .dividend(dividend_f),
		.divisor(divisor_f), .quotient(quotient_f));

   always @(posedge clk) begin
      case(state)
	WAIT_FOR_CORNERS: begin
	   if (corners_flag) begin
	      // calculate distances squared
	      temp1a <= (a_x - d_x) * (a_x - d_x);
	      temp2a <= (a_y - d_y) * (a_y - d_y);
	      temp1b <= (b_x - c_x) * (b_x - c_x);
	      temp2b <= (b_y - c_y) * (b_y - c_y);
	      temp1c <= (a_x - b_x) * (a_x - b_x);
	      temp2c <= (a_y - b_y) * (a_y - b_y);

	      // change state
	      state <= CALC_INIT_DIST_MULT;
	   end // if (corners_flag)
	end // case: WAIT_FOR_CORNERS

	CALC_INIT_DIST_MULT: begin
	   // start square rooters
	   d_sqrt_a <= temp1a + temp2a;
	   d_sqrt_b <= temp1b + temp2b;
	   d_sqrt_c <= temp1c + temp2c;
	   sqrt_start_a <= 1;
	   sqrt_start_b <= 1;
	   sqrt_start_c <= 1;

	   // go to the wait for sqrt state;
	   state <= WAIT_FOR_SQRT;
	end // case: CALC_INIT_DIST_MULT

	WAIT_FOR_SQRT: begin
	   sqrt_start_a <= 0;
	   sqrt_start_b <= 0;
	   sqrt_start_c <= 0;

	   if (sqrt_done_a && sqrt_done_b && sqrt_done_c) begin
	      //save distances 
	      d_ad <= answer_a;
	      d_bc <= answer_b;
	      d_iterators <= answer_c;

	      //start dividers
	      dividend_a <= (c_x - b_x) << 10;
	      dividend_b <= (c_y - b_y) << 10;
	      dividend_c <= (d_x - a_x) << 10;
	      dividend_d <= (d_y - a_y) << 10;
	      dividend_e <= (i_b_x - i_a_x) << 10;
	      dividend_f <= (i_b_y - i_a_y) << 10;

	      divisor_a <= answer_a;
	      divisor_b <= answer_a;
	      divisor_c <= answer_b;
	      divisor_d <= answer_b;
	      divisor_e <= answer_c;
	      divisor_f <= answer_c;

	      counter <= 0;

	      // update state
	      state <= WAIT_FOR_DIVIDERS;
	   end // if (sqrt_done_a && sqrt_done_b && sqrt_done_c)
	end // case: WAIT_FOR_SQRT

	WAIT_FOR_DIVIDERS: begin
	   counter <= counter + 1;

	   // if divider is done (divider delay = M + 4)
	   // M = dividend width = 20 in this case
	   if (counter > 24) begin
	      request_pixel <= 1;

	      delta_a_x <= quotient_a;
	      delta_a_y <= quotient_b;
	      delta_b_x <= quotient_c;
	      delta_b_y <= quotient_d;
	      delta_c_x <= quotient_e;
	      delta_c_y <= quotient_f;

	      // update state
	      state <= WAIT_FOR_PIXEL;
	   end
	end

	// This is the state where the bulk of the module is accomplished.
	// This waits for LPF to send a new pixel value to projective_transform,
	// then echoes that value and new coords to the memory management module.
	// then it increments the iterators accordingly.
	WAIT_FOR_PIXEL: begin
	   // a new pixel has arrived, process accordingly
	   if (pixel_flag || waiting_for_write) begin
	      if (ptflag) begin
		 waiting_for_write <= 0;
		 request_pixel <= 1;
		 
		 
		 // output the new pixel coordinates
		 if (waiting_for_write) begin
		    pt_pixel_write <= pixel_save;
		 end else begin
		    pt_pixel_write <= pixel;
		 end
		    
		 pt_x <= i_c_x >> 10;
		 pt_y <= i_c_y >> 10;
		 pt_wr <= 1;

		 // increment iterators
		 i_c_x <= i_c_x + delta_c_x;
		 i_c_y <= i_c_y + delta_c_y;
		 o_x <= o_x + 1;

		 // we are getting close to the end of this line. begin calculating the
		 // next lines deltas and distances. 	   
		 if (o_x == 600) begin
		    // calculate distance squared
		    temp1a <= (i_a_x + delta_a_x - (i_b_x + delta_b_x)) * (i_a_x + delta_a_x - (i_b_x + delta_b_x));
		    temp1b <= (i_a_y + delta_a_y - (i_b_y + delta_b_y)) * (i_a_y + delta_a_y - (i_b_y + delta_b_y));
		 end

		 // after distance calculation has been completed
		 if (o_x == 601) begin
		    d_sqrt_a <= temp1a + temp1b;
		    sqrt_start_a <= 1;
		 end
	   
		 // the end of the line
		 if (o_x == 640 && o_y < 480) begin
		    // increment iterators
		    o_y <= o_y + 1;
		    i_a_x <= i_a_x + delta_a_x;
		    i_a_y <= i_a_y + delta_a_y;
		    i_b_x <= i_b_x + delta_b_x;
		    i_b_y <= i_b_y + delta_b_y;
		    
		    // reset I_C to the new location of I_A
		    i_c_x <= i_a_x + delta_a_x;
		    i_c_y <= i_c_y + delta_a_y;

		    // update the deltas
		    delta_c_x <= delta_c_x_next;
		    delta_c_y <= delta_c_y_next;

		    // reset o_x 
		    o_x <= 0;
		 end
		 
		 // the end of the frame
		 if (o_x == 640 && o_y == 480) begin
		    // reset the iterator variables
		    o_x <= 0;
		    o_y <= 0;

		    // the other iterators will be reset when new corners arrive
		 
		    // go back to waiting
		    state <= WAIT_FOR_CORNERS;
		 end
	      end else begin // if (ptflag)
		 waiting_for_write <= 1; // set a flag
		 pixel_save <= pixel; // store the current pixel data
		 request_pixel <= 0; // memory_interface is delayed, we do not
		                   // want to deal with new pixels right now
		 
	      end // else: !if(ptflag)
		 
	   end // if (pixel_flag)

	   // if the square root operation is done, we can star the divisions
	   if (sqrt_done_a) begin
	      // save distnace
	      d_next_iterators <= answer_a;

	      // start dividers
	      divisor_a <= answer_a;
	      divisor_b <= answer_a;

	      dividend_a <= ((i_b_x + delta_b_x) - (i_a_x + delta_a_x)) << 10;
	      dividend_a <= ((i_b_y + delta_b_y) - (i_a_y + delta_a_y)) << 10;

	      // reset counter;
	      counter <= 0;
	      // start counting;
	      counting <= 1;
	      
	      
	   end // if (sqrt_done_a)

	   if (counting) counter <= counter + 1;

	   // if the divider is done
	   if (counter > 24) begin
	      // save deltas
	      delta_c_x_next <= quotient_a;
	      delta_c_y_next <= quotient_b;
	      counter <= 0; //reset counter
	      counting <= 0; //stop counting
	   end
	   
	end // case: WAIT_FOR_PIXEL
	
      endcase // case (state)
   end // always @ (posedge clk)    
endmodule // projective_transform

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
