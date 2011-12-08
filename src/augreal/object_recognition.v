// Logan Williams


module object_recognition(
			  input 	   clk,
			  input reset,
			  input [1:0] 	   color,
			  input [9:0] 	   interesting_x,
			  input [8:0] 	   interesting_y,
			  input 	   interesting_flag,
			  input 	   frame_flag,
			  output reg [9:0] m_x,
			  output reg [8:0] m_y,
			  output reg [9:0] a_x,
			  output reg [8:0] a_y,
			  output reg [9:0] b_x,
			  output reg [8:0] b_y,
			  output reg [9:0] c_x,
			  output reg [8:0] c_y,
			  output reg [9:0] d_x,
			  output reg [8:0] d_y,
			  output reg 	   corners_flag);

   // Geometric averaging parameter
   //     n = 1 / (2 ^ G)

   parameter G = 3;
   
   reg [1:0] 				   state; 				   

   reg [31:0] 				   sumx [0:3];
   reg [31:0] 				   sumy [0:3];
   reg [31:0] 				   num [0:3];
   wire [31:0] 				   averagex [0:3]; 
   wire [31:0] 				   averagey [0:3]; 

   reg [20:0] 				   top;
   reg [20:0] 				   bottom;
   reg [20:0] 				   left;
   reg [20:0] 				   right;

   wire [10:0] 				   topd;
   wire [10:0] 				   bottomd;
   wire [10:0] 				   leftd;
   wire [10:0] 				   rightd;		   

   reg 					   startdivs;
   wire [7:0] 				   divsready;
   reg 					   calcdone;
   wire [3:0] 				   sqrtdone;
   reg 					   sqrtstart;

   // STATES
   parameter COUNTING = 2'b00;
   parameter WAITING_FOR_DIVS = 2'b01;
   parameter STARTSQRTS = 2'b10;
   parameter WAITING_FOR_SQRT = 2'b11;

   // parallelized dividers
   divider #(.WIDTH(32)) diva(.clk(clk), .ready(divsready[0]), .dividend(sumx[0]),
			      .divider(num[0]), .quotient(averagex[0]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divb(.clk(clk), .ready(divsready[1]), .dividend(sumy[0]),
			      .divider(num[0]), .quotient(averagey[0]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divc(.clk(clk), .ready(divsready[2]), .dividend(sumx[1]),
			      .divider(num[1]), .quotient(averagex[1]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divd(.clk(clk), .ready(divsready[3]), .dividend(sumy[1]),
			      .divider(num[1]), .quotient(averagey[1]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) dive(.clk(clk), .ready(divsready[4]), .dividend(sumx[2]),
			      .divider(num[2]), .quotient(averagex[2]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divf(.clk(clk), .ready(divsready[5]), .dividend(sumy[2]),
			      .divider(num[2]), .quotient(averagey[2]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divg(.clk(clk), .ready(divsready[6]), .dividend(sumx[3]),
			      .divider(num[3]), .quotient(averagex[3]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divh(.clk(clk), .ready(divsready[7]), .dividend(sumy[3]),
			      .divider(num[3]), .quotient(averagey[3]), .sign(1'b0), .start(startdivs));

   // parallelized square rooters
   sqrt #(.NBITS(21)) sqrta(.clk(clk), .start(sqrtstart), .data(top),
			    .answer(topd), .done(sqrtdone[0]));
   sqrt #(.NBITS(21)) sqrtb(.clk(clk), .start(sqrtstart), .data(bottom),
			    .answer(bottomd), .done(sqrtdone[1]));
   sqrt #(.NBITS(21)) sqrtc(.clk(clk), .start(sqrtstart), .data(left),
			    .answer(leftd), .done(sqrtdone[2]));
   sqrt #(.NBITS(21)) sqrtd(.clk(clk), .start(sqrtstart), .data(right),
			    .answer(rightd), .done(sqrtdone[3]));
   
   always @(posedge clk) begin
      corners_flag <= 0;
      startdivs <= 0;
      sqrtstart <= 0;
      
      if (reset) begin
        sumx[0] <= 0;
        sumy[0] <= 0;
        num[0] <= 0;
        sumx[1] <= 0;
        sumy[1] <= 0;
        num[1] <= 0;
        sumx[2] <= 0;
        sumy[2] <= 0;
        num[2] <= 0;
        sumx[3] <= 0;
        sumy[3] <= 0;
        num[3] <= 0;
        state <= COUNTING;
    end
      

      case (state)
	COUNTING: begin
	   if (interesting_flag && state == COUNTING) begin
	      sumx[color] <= sumx[color] + interesting_x;
	      sumy[color] <= sumy[color] + interesting_y;
	      num[color] <= num[color] + 1;
	   end
      
	   if (frame_flag) begin
	      startdivs <= 1;
	      state <= WAITING_FOR_DIVS;
	   end
	end

	WAITING_FOR_DIVS: begin
	   // if all of the dividers are done
	   if (&divsready) begin
		/*
	      a_x <= ({a_x, {G{1'b0}}} - a_x) >> G + (averagex[0] >> G);
	      a_y <= ({a_y, {G{1'b0}}} - a_y) >> G + (averagey[0] >> G);
	      b_x <= ({b_x, {G{1'b0}}} - b_x) >> G + (averagex[1] >> G);
	      b_y <= ({b_y, {G{1'b0}}} - b_y) >> G + (averagey[1] >> G);
	      c_x <= ({c_x, {G{1'b0}}} - c_x) >> G + (averagex[2] >> G);
	      c_y <= ({c_y, {G{1'b0}}} - c_y) >> G + (averagey[2] >> G);
	      d_x <= ({d_x, {G{1'b0}}} - d_x) >> G + (averagex[3] >> G);
	      d_y <= ({d_y, {G{1'b0}}} - d_y) >> G + (averagey[3] >> G);
			*/
			
			a_x <= averagex[0] >> 2 + a_x >> 2 + a_x >> 1;
			b_x <= averagex[1] >> 2 + b_x >> 2 + b_x >> 1;
			c_x <= averagex[2] >> 2 + c_x >> 2 + c_x >> 1;
			d_x <= averagex[3] >> 2 + d_x >> 2 + d_x >> 1;
			a_y <= averagey[0] >> 2 + a_y >> 2 + a_y >> 1;
			b_y <= averagey[1] >> 2 + b_y >> 2 + b_y >> 1;
			c_y <= averagey[2] >> 2 + c_y >> 2 + c_y >> 1;
			d_y <= averagey[3] >> 2 + d_y >> 2 + d_y >> 1;

	      top <= (averagex[1] - averagex[0]) * (averagex[1] - averagex[0]) + (averagey[1] - averagey[0]) * (averagey[1] - averagey[0]);
	      bottom <= (averagex[2] - averagex[3]) * (averagex[2] - averagex[3]) + (averagey[2] - averagey[3]) * (averagey[2] - averagey[3]);
	      left <= (averagex[3] - averagex[0]) * (averagex[3] - averagex[0]) + (averagey[3] - averagey[0]) * (averagey[3] - averagey[0]);
	      right <= (averagex[2] - averagex[1]) * (averagex[2] - averagex[1]) + (averagey[2] - averagey[1]) * (averagey[2] - averagey[1]);

	      state <= STARTSQRTS;
	      
	   end // if (&divsready)
	end // case: WAITING_FOR_DIVS

	STARTSQRTS: begin
	   sqrtstart <= 1;
	   state <= WAITING_FOR_SQRT;
	end

	WAITING_FOR_SQRT: begin
	   // if all sqrts are done;
	   if (&sqrtdone) begin
	      if (topd < bottomd) m_x <= topd;
	      else m_x <= bottomd;

	      if (leftd < rightd) m_y <= leftd;
	      else m_y <= rightd;

	      corners_flag <= 1;
	   end

	   // if the vsync is over
	   if (~frame_flag) begin
	      state <= COUNTING;
			sumx[0] <= 0;
        sumy[0] <= 0;
        num[0] <= 0;
        sumx[1] <= 0;
        sumy[1] <= 0;
        num[1] <= 0;
        sumx[2] <= 0;
        sumy[2] <= 0;
        num[2] <= 0;
        sumx[3] <= 0;
        sumy[3] <= 0;
        num[3] <= 0;
	   end
	end // case: WAITING_FOR_SQRT
	   
      endcase // case state
   end // always @ (posedge clk)
endmodule // object_recognition


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
endmodule // sqrt
