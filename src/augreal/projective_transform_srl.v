module projective_transform_srl(
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

			    input done_pt,
			    


			    input 	      ptflag, // Okay to send new data (memory_interface ->) 
			    output reg [17:0] pt_pixel_write, // Pixel data output (-> memory_interface)
			    output reg [9:0]  pt_x, // Pixel output data location
			    output reg [8:0]  pt_y, //  | (-> memory_interface)
			    output reg 	      pt_wr, // Want to write pixel flag (-> memory_interface)
			    output reg 	      request_pixel = 0 // request a pixel to process (-> lpf) 	      
			    );
   

   reg [1:0] 				      state = 0;


   // signed numbers for computation with coordinates
   wire signed [10:0] 			      sa_x;
   wire signed [10:0] 			      sa_y;
   wire signed [10:0] 			      sb_x;
   wire signed [10:0] 			      sb_y;
   wire signed [10:0] 			      sc_x;
   wire signed [10:0] 			      sc_y;
   wire signed [10:0] 			      sd_x;
   wire signed [10:0] 			      sd_y;

   assign sa_x = {1'b0, a_x};
   assign sa_y = {2'b0, a_y};
   assign sb_x = {1'b0, b_x};
   assign sb_y = {2'b0, b_y};
   assign sc_x = {1'b0, c_x};
   assign sc_y = {2'b0, c_y};
   assign sd_x = {1'b0, d_x};
   assign sd_y = {2'b0, d_y};

   // iterator coordinates for the three iterator points
   // these all have 10 extra bits of resolution to simulate decimals
   // 	(for example 1 is represented by 1 << 10)
   reg [40:0] 				      i_a_x;
   reg [40:0] 				      i_a_y;
   reg [40:0] 				      i_b_x;
   reg [40:0] 				      i_b_y;
   reg [40:0] 				      i_c_x;
   reg [40:0] 				      i_c_y;

   // iterator incrementors
   reg signed [41:0] 			      delta_a_x;
   reg signed [41:0] 			      delta_a_y;
   reg signed [41:0] 			      delta_b_x;
   reg signed [41:0] 			      delta_b_y;
   reg signed [41:0] 			      delta_c_x;
   reg signed [41:0] 			      delta_c_y;
   reg signed [41:0] 			      delta_c_x_next;
   reg signed [41:0] 			      delta_c_y_next;
   
   // wires/registers for diving
   wire 				      rfd_a;
   wire 				      rfd_b;
   wire 				      rfd_c;
   wire 				      rfd_d;
   wire 				      rfd_e;
   wire 				      rfd_f;

   reg signed [41:0] 			      dividend_a;
   reg signed [41:0] 			      dividend_b;
   reg signed [41:0] 			      dividend_c;
   reg signed [41:0] 			      dividend_d;
   reg signed [41:0] 			      dividend_e;
   reg signed [41:0] 			      dividend_f;

   reg signed [41:0] 				      divisor_a;
   reg signed [41:0] 				      divisor_b;
   reg signed [41:0] 				      divisor_c;
   reg signed [41:0] 				      divisor_d;
   reg signed [41:0] 				      divisor_e;
   reg signed [41:0] 				      divisor_f;

   wire signed [41:0] 			      quotient_a;
   wire signed [41:0] 			      quotient_b;
   wire signed [41:0] 			      quotient_c;
   wire signed [41:0] 			      quotient_d;
   wire signed [41:0] 			      quotient_e;
   wire signed [41:0] 			      quotient_f;
   
   reg 					      startdivs;

   // coordinates iterators in the untransformed images
   reg [9:0] 				      o_x;
   reg [8:0] 				      o_y;

   // create some registers for dealing with possible delays
   // in memory_write
   reg [17:0] 				      pixel_save [0:15];
   reg [3:0] 				      waiting_for_write = 0;
   
   parameter WAIT_FOR_CORNERS = 0;
   parameter WAIT_FOR_DIVIDERS = 1;
   parameter WAIT_FOR_PIXEL = 2;

   // six dividers, for parallelization. these are used to calculate
   // iteration "deltas"
   divider #(.WIDTH(42)) diva(.clk(clk), .ready(rfd_a), .dividend(dividend_a),
			      .divider(divisor_a), .quotient(quotient_a), .sign(1'b1), .start(startdivs));

   divider #(.WIDTH(42)) divb(.clk(clk), .ready(rfd_b), .dividend(dividend_b),
			      .divider(divisor_b), .quotient(quotient_b), .sign(1'b1), .start(startdivs));
   
   divider #(.WIDTH(42)) divc(.clk(clk), .ready(rfd_c), .dividend(dividend_c),
			      .divider(divisor_c), .quotient(quotient_c), .sign(1'b1), .start(startdivs));

   divider #(.WIDTH(42)) divd(.clk(clk), .ready(rfd_d), .dividend(dividend_d),
			      .divider(divisor_d), .quotient(quotient_d), .sign(1'b1), .start(startdivs));

   divider #(.WIDTH(42)) dive(.clk(clk), .ready(rfd_e), .dividend(dividend_e),
			      .divider(divisor_e), .quotient(quotient_e), .sign(1'b1), .start(startdivs));
   
   divider #(.WIDTH(42)) divf(.clk(clk), .ready(rfd_f), .dividend(dividend_f),
			      .divider(divisor_f), .quotient(quotient_f), .sign(1'b1), .start(startdivs));

   wire [17:0] 				      buffered_pixel;
   
   
   shift18 buffer(.clock(clk), .ce(pixel_flag), .dout(buffered_pixel), .length(waiting_for_write),
		  .din(pixel));
   
   always @(posedge clk) begin
      case(state)
	WAIT_FOR_CORNERS: begin
	   o_x <= 0;
	   o_y <= 0;
	   
	   if (corners_flag) begin
	      
	      i_a_x <= a_x << 30;
	      i_a_y <= a_y << 30;
	      i_b_x <= b_x << 30;
	      i_b_y <= b_y << 30;
	      i_c_x <= a_x << 30;
	      i_c_y <= a_y << 30;
	      
	      //start dividers
	      dividend_a <= (sd_x - sa_x) << 30;
	      dividend_b <= (sd_y - sa_y) << 30;
	      dividend_c <= (sc_x - sb_x) << 30;
	      dividend_d <= (sc_y - sb_y) << 30;
	      dividend_e <= (sb_x - sa_x) << 30;
	      dividend_f <= (sb_y - sa_y) << 30;

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
	   if (pixel_flag || (|waiting_for_write)) begin
	      if (ptflag) begin
		 
		 //pt_pixel_write <= buffered_pixel;
		 pt_pixel_write <= {18{o_x[3]}};
		 
		 
		 if (~pixel_flag) begin
		    waiting_for_write <= waiting_for_write - 1;
		 end

		 if (waiting_for_write < 4) begin
		    request_pixel <= 1;
		 end else begin
		    request_pixel <= 0;
		 end
		 
		 
		 pt_x <= (i_c_x >> 30);
		 pt_y <= (i_c_y >> 30);
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
		 if ((o_x == 639 && o_y == 479)) begin
		    // reset the iterator variables
		    o_x <= 0;
		    o_y <= 0;

		    // the other iterators will be reset when new corners arrive
		    
		    // go back to waiting
		    state <= WAIT_FOR_CORNERS;
		    pt_wr <= 0;
		    request_pixel <= 0;
		    
		 end
	      end else begin // if (ptflag)
		 if (pixel_flag) begin
		    waiting_for_write <= waiting_for_write + 1; // set a flag
		 end
		 
		 request_pixel <= 0; // memory_interface is delayed, we do not
		 // want to deal with new pixels right now

		 pt_wr <= 0;
	      end
	      
	   end else pt_wr <= 0; // if (pixel_flag || (waiting_for_write > 0))

	   // if the divider is done
	   if (rfd_a & rfd_b) begin
	      // save deltas
	      delta_c_x_next <= quotient_a;
	      delta_c_y_next <= quotient_b;
	   end

	   if (frame_flag) begin
	      state <= WAIT_FOR_CORNERS;
	      pt_wr <= 0;
	      o_x <= 0;

	      o_y <= 0;
	   end
 
	   
	end // case: WAIT_FOR_PIXEL
	
      endcase // case (state)
   end // always @ (posedge clk)    
endmodule // projective_transform

module shift18(input [17:0] din,
	       input [3:0] length,
	       output [17:0] dout,
	       input clock,
	       input ce);

   SRL16E s1(.CLK(clock), .CE(ce), .D(din[0]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[0]));
   SRL16E s2(.CLK(clock), .CE(ce), .D(din[1]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[1]));
   SRL16E s3(.CLK(clock), .CE(ce), .D(din[2]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[2]));
   SRL16E s4(.CLK(clock), .CE(ce), .D(din[3]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[3]));
   SRL16E s5(.CLK(clock), .CE(ce), .D(din[4]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[4]));
   SRL16E s6(.CLK(clock), .CE(ce), .D(din[5]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[5]));
   SRL16E s7(.CLK(clock), .CE(ce), .D(din[6]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[6]));
   SRL16E s8(.CLK(clock), .CE(ce), .D(din[7]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[7]));
   SRL16E s9(.CLK(clock), .CE(ce), .D(din[8]),
	     .A0(length[0]), .A1(length[1]), 
	     .A2(length[2]), .A3(length[3]),
	     .Q(dout[8]));
   SRL16E s10(.CLK(clock), .CE(ce), .D(din[9]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[9]));
   SRL16E s11(.CLK(clock), .CE(ce), .D(din[10]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[10]));
   SRL16E s12(.CLK(clock), .CE(ce), .D(din[11]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[11]));
   SRL16E s13(.CLK(clock), .CE(ce), .D(din[12]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[12]));
   SRL16E s14(.CLK(clock), .CE(ce), .D(din[13]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[13]));
   SRL16E s15(.CLK(clock), .CE(ce), .D(din[14]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[14]));
   SRL16E s16(.CLK(clock), .CE(ce), .D(din[15]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[15]));
   SRL16E s17(.CLK(clock), .CE(ce), .D(din[16]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[16]));
   SRL16E s18(.CLK(clock), .CE(ce), .D(din[17]),
	      .A0(length[0]), .A1(length[1]), 
	      .A2(length[2]), .A3(length[3]),
	      .Q(dout[17]));
   
endmodule // shift18
