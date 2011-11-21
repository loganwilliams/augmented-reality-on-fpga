module projective_transform(input clk, frame_flag, [17:0] pixel, pixel_flag,
			    [9:0] ax, [8:0] ay, [9:0] bx, [8:0] by, [9:0] cx, [8:0] cy,
			    [9:0] dx, [8:0] dy, corners_flag, output reg [17:0] pixel_out, [9:0] pixel_x,
			    [8:0] pixel_y, pixel_out_flag), wants_pixel;
   

   reg [2:0] state = 0;

   // iterator coordinates
   reg [19:0] i_a_x;
   reg [18:0] i_a_y;
   reg [19:0] i_b_x;
   reg [18:0] i_b_y;
   reg [19:0] i_c_x;
   reg [18:0] i_c_y;

   // distance stores
   reg [9:0]  d_ad;
   reg [9:0]  d_bc;
   reg [9:0]  d_iterators;

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
   

   // coordinates of the untransformed images
   reg [9:0]  o_x;
   reg [8:0]  o_y;

   parameter WAIT_FOR_CORNERS = 0;
   parameter CALC_INIT_DIST_MULT = 1;
   parameter WAIT_FOR_SQRT = 2;
   parameter WAIT_FOR_DIVIDERS = 3;
   parameter WAIT_FOR_PIXEL = 4;
   parameter CALC_NEXT_DIST = 5;
   

   // this is the iterative square rooter used for distance calculations
   // with NBITS = 21, it will take 21 clock cycles to return a result.
   sqrta (NBITS = 21) sqrt(.clk(clk), .start(sqrt_start_a),
			   .data(d_sqrt_a), .answer(answer_a),
			   .done(sqrt_done_a));

   sqrtb (NBITS = 21) sqrt(.clk(clk), .start(sqrt_start_b),
			   .data(d_sqrt_b), .answer(answer_b),
			   .done(sqrt_done_b));

   sqrtc (NBITS = 21) sqrt(.clk(clk), .start(sqrt_start_c),
			   .data(d_sqrt_c), .answer(answer_c),
			   .done(sqrt_done_c));

   // three dividers, for parallelization. these are used to calculate
   // iteration "deltas"
   diva divider(.clk(clk), .rfd(rfd_a), .dividend(dividend_a),
		.divisor(divisor_a), .quotient(quotient_a));

   divb divider(.clk(clk), .rfd(rfd_b), .dividend(dividend_b),
		.divisor(divisor_b), .quotient(quotient_b));
   
   divc divider(.clk(clk), .rfd(rfd_c), .dividend(dividend_c),
		.divisor(divisor_c), .quotient(quotient_c));

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

	      // update state
	      state <= WAIT_FOR_DIVIDERS;
	   end // if (sqrt_done_a && sqrt_done_b && sqrt_done_c)
	end // case: WAIT_FOR_SQRT

	WAIT_FOR_DIVIDERS: begin
	   if (dividers are done???) begin
	      wants_pixel <= 1;

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
	   if (pixel_flag) begin

	      // we are getting close to the end of this line. begin calculating the
	      // next lines deltas and distances. 	   
	      if (o_x == 600) begin
	      end
	   
	      // the end of the line
	      if (o_x == 640 && o_y < 480) begin
	      end

	      // the end of the frame
	      if (o_x == 640 && o_y == 480) begin
		 // reset everything
		 state <= WAIT_FOR_CORNERS;
	      end
	   end // if (pixel_flag)

	   if (sqrt_done_a) begin
	      // start divider
	   end

	   if (dividers a and b are done) begin
	      // save deltas
	   end
	   
	end // case: WAIT_FOR_PIXEL
	
	   
	CALC_NEXT_DIST: begin
	end

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
