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
			    output reg 	      request_pixel = 0 // request a pixel to process (-> lpf) 	      
			    );
   

   reg [1:0] 				      state = 0;

   // iterator coordinates for the three iterator points
   // these all have 10 extra bits of resolution to simulate decimals
   // 	(for example 1 is represented by 1 << 10)
   reg [19:0] 				      i_a_x;
   reg [18:0] 				      i_a_y;
   reg [19:0] 				      i_b_x;
   reg [18:0] 				      i_b_y;
   reg [19:0] 				      i_c_x;
   reg [18:0] 				      i_c_y;

   // iterator incrementors
   reg [19:0] 				      delta_a_x;
   reg [19:0] 				      delta_a_y;
   reg [19:0] 				      delta_b_x;
   reg [19:0] 				      delta_b_y;
   reg [19:0] 				      delta_c_x;
   reg [19:0] 				      delta_c_y;
   reg [19:0] 				      delta_c_x_next;
   reg [19:0] 				      delta_c_y_next;
   
   // wires/registers for diving
   wire 				      rfd_a;
   wire 				      rfd_b;
   wire 				      rfd_c;
   wire 				      rfd_d;
   wire 				      rfd_e;
   wire 				      rfd_f;

   reg signed [20:0] 			      dividend_a;
   reg signed [20:0] 			      dividend_b;
   reg signed [20:0] 			      dividend_c;
   reg signed [20:0] 			      dividend_d;
   reg signed [20:0] 			      dividend_e;
   reg signed [20:0] 			      dividend_f;

   reg [9:0] 				      divisor_a;
   reg [9:0] 				      divisor_b;
   reg [9:0] 				      divisor_c;
   reg [9:0] 				      divisor_d;
   reg [9:0] 				      divisor_e;
   reg [9:0] 				      divisor_f;

   wire [19:0] 				      quotient_a;
   wire [19:0] 				      quotient_b;
   wire [19:0] 				      quotient_c;
   wire [19:0] 				      quotient_d;
   wire [19:0] 				      quotient_e;
   wire [19:0] 				      quotient_f;
   
   reg 					      startdivs;

   // coordinates iterators in the untransformed images
   reg [9:0] 				      o_x;
   reg [8:0] 				      o_y;

   reg [4:0] 				      counter;
   reg 					      counting = 0;

   // create some registers for dealing with possible delays
   // in memory_write
   reg [17:0] 				      pixel_save [0:5];
   reg [2:0] 					      waiting_for_write = 0;
   reg [2:0] 					      waiting_for_write_max = 0;
   
   
   parameter WAIT_FOR_CORNERS = 0;
   parameter WAIT_FOR_DIVIDERS = 1;
   parameter WAIT_FOR_PIXEL = 2;

   // six dividers, for parallelization. these are used to calculate
   // iteration "deltas"
   divider #(.WIDTH(20)) diva(.clk(clk), .ready(rfd_a), .dividend(dividend_a),
			      .divider({10'b0,divisor_a}), .quotient(quotient_a), .sign(1'b1), .start(startdivs));

   divider #(.WIDTH(20)) divb(.clk(clk), .ready(rfd_b), .dividend(dividend_b),
			      .divider({10'b0,divisor_b}), .quotient(quotient_b), .sign(1'b1), .start(startdivs));
   
   divider #(.WIDTH(20)) divc(.clk(clk), .ready(rfd_c), .dividend(dividend_c),
			      .divider({10'b0,divisor_c}), .quotient(quotient_c), .sign(1'b1), .start(startdivs));

   divider #(.WIDTH(20)) divd(.clk(clk), .ready(rfd_d), .dividend(dividend_d),
			      .divider({10'b0,divisor_d}), .quotient(quotient_d), .sign(1'b1), .start(startdivs));

   divider #(.WIDTH(20)) dive(.clk(clk), .ready(rfd_e), .dividend(dividend_e),
			      .divider({10'b0,divisor_e}), .quotient(quotient_e), .sign(1'b1), .start(startdivs));
   
   divider #(.WIDTH(20)) divf(.clk(clk), .ready(rfd_f), .dividend(dividend_f),
			      .divider({10'b0,divisor_f}), .quotient(quotient_f), .sign(1'b1), .start(startdivs));

   always @(posedge clk) begin
      case(state)
	WAIT_FOR_CORNERS: begin
	   o_x <= 0;
	   o_y <= 0;
	   
	   if (corners_flag) begin
	      
	      i_a_x <= a_x << 10;
	      i_a_y <= a_y << 10;
	      i_b_x <= b_x << 10;
	      i_b_y <= b_y << 10;
	      i_c_x <= a_x << 10;
	      i_c_y <= a_y << 10;
	      
	      //start dividers
	      dividend_a <= (d_x - a_x) << 10;
	      dividend_b <= (d_y - a_y) << 10;
	      dividend_c <= (c_x - b_x) << 10;
	      dividend_d <= (c_y - b_y) << 10;
	      dividend_e <= (b_x - a_x) << 10;
	      dividend_f <= (b_y - a_y) << 10;

	      divisor_a <= 480;
	      divisor_b <= 480;
	      divisor_c <= 480;
	      divisor_d <= 480;
	      divisor_e <= 640;
	      divisor_f <= 640;
	      
	      startdivs <= 1;

	      // update state
	      state <= WAIT_FOR_DIVIDERS;

	   end // if (corners_flag)
	end // case: WAIT_FOR_CORNERS

	WAIT_FOR_DIVIDERS: begin
	   startdivs <= 0;

	   // if divider is done (divider delay = M + 4)
	   // M = dividend width = 20 in this case
	   if (rfd_a & rfd_b & rfd_c & rfd_d & rfd_e & rfd_f) begin
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
	   if (pixel_flag || (waiting_for_write > 0)) begin
	      if (ptflag) begin
		 request_pixel <= 1;
		 
		 if (waiting_for_write > 0) begin
		    waiting_for_write <= waiting_for_write - 1;
		    
		    if (waiting_for_write == 1) begin
		       waiting_for_write_max <= 0;
		    end
		 end
		 
		 // output the new pixel coordinates
		 if (waiting_for_write > 0) begin
		    pt_pixel_write <= pixel_save[waiting_for_write_max - waiting_for_write];
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
		 if (o_x == 500) begin
		    // start dividers
		    divisor_a <= 640;
		    divisor_b <= 640;

		    dividend_a <= ((i_b_x + delta_b_x) - (i_a_x + delta_a_x));
		    dividend_b <= ((i_b_y + delta_b_y) - (i_a_y + delta_a_y));
		    
		    startdivs <= 1;

		 end else startdivs <= 0;

		 // the end of the line
		 if (o_x == 639 && o_y < 479) begin
		    // increment iterators
		    o_y <= o_y + 1;
		    i_a_x <= i_a_x + delta_a_x;
		    i_a_y <= i_a_y + delta_a_y;
		    i_b_x <= i_b_x + delta_b_x;
		    i_b_y <= i_b_y + delta_b_y;
		    
		    // reset I_C to the new location of I_A
		    i_c_x <= i_a_x + delta_a_x;
		    i_c_y <= i_a_y + delta_a_y;

		    // update the deltas
		    delta_c_x <= delta_c_x_next;
		    delta_c_y <= delta_c_y_next;

		    // reset o_x 
		    o_x <= 0;
		 end
		 
		 // the end of the frame
		 if (o_x == 639 && o_y == 479) begin
		    // reset the iterator variables
		    o_x <= 0;
		    o_y <= 0;

		    // the other iterators will be reset when new corners arrive
		    
		    // go back to waiting
		    state <= WAIT_FOR_CORNERS;
		 end
	      end else if (pixel_flag) begin // if (ptflag)
		 waiting_for_write <= waiting_for_write + 1; // set a flag
		 waiting_for_write_max <= waiting_for_write + 1;
		 
     		 pixel_save[waiting_for_write] <= pixel; // store the current pixel data
		 request_pixel <= 0; // memory_interface is delayed, we do not
		 // want to deal with new pixels right now

		 pt_wr <= 0;
		 
		 
	      end // else: !if(ptflag)
	      
	   end // if (pixel_flag)

	   // if the divider is done
	   if (rfd_a & rfd_b) begin
	      // save deltas
	      delta_c_x_next <= quotient_a;
	      delta_c_y_next <= quotient_b;
	   end
	   
	end // case: WAIT_FOR_PIXEL
	
      endcase // case (state)
   end // always @ (posedge clk)    
endmodule // projective_transform

// The divider module divides one number by another. It
// produces a signal named "ready" when the quotient output
// is ready, and takes a signal named "start" to indicate
// the the input dividend and divider is ready.
//    sign -- 0 for unsigned, 1 for twos complement

// It uses a simple restoring divide algorithm.
// http://en.wikipedia.org/wiki/Division_(digital)#Restoring_division
module divider #(parameter WIDTH = 8) (ready, start, quotient, 
				       remainder, dividend, 
				       divider, sign, clk);

   input         clk;
   input         sign;
   input 	 start;
   input [WIDTH-1:0] dividend, divider;
   output [WIDTH-1:0] quotient, remainder;
   output 	      ready;

   reg [WIDTH-1:0]    quotient, quotient_temp;
   reg [WIDTH*2-1:0]  dividend_copy, divider_copy, diff;
   reg 		      negative_output;
   
   wire [WIDTH-1:0]   remainder = (!negative_output) ? 
                      dividend_copy[31:0] : 
                      ~dividend_copy[31:0] + 1'b1;

   reg [5:0] 	      bit; 
   reg 		      del_ready = 1;
   wire 	      ready = (!bit) & ~del_ready;

   wire [WIDTH-2:0]   zeros = 0;
   initial bit = 0;
   initial negative_output = 0;

   always @( posedge clk ) begin
      del_ready <= !bit;
      if( start ) begin

         bit = WIDTH;
         quotient = 0;
         quotient_temp = 0;
         dividend_copy = (!sign || !dividend[WIDTH-1]) ? 
                         {1'b0,zeros,dividend} : 
                         {1'b0,zeros,~dividend + 1'b1};
         divider_copy = (!sign || !divider[WIDTH-1]) ? 
			{1'b0,divider,zeros} : 
			{1'b0,~divider + 1'b1,zeros};

         negative_output = sign &&
                           ((divider[WIDTH-1] && !dividend[WIDTH-1]) 
                            ||(!divider[WIDTH-1] && dividend[WIDTH-1]));
         
      end 
      else if ( bit > 0 ) begin

         diff = dividend_copy - divider_copy;

         quotient_temp = quotient_temp << 1;

         if( !diff[WIDTH*2-1] ) begin

            dividend_copy = diff;
            quotient_temp[0] = 1'd1;

         end

         quotient = (!negative_output) ? 
                    quotient_temp : 
                    ~quotient_temp + 1'b1;

         divider_copy = divider_copy >> 1;
         bit = bit - 1'b1;

      end
   end
endmodule

