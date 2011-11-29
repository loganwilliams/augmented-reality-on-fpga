// Logan Williams

module object_recognition(
			  input 	   clk,
			  input [1:0] 	   color,
			  input [9:0] 	   interesting_x,
			  input [8:0] 	   interesting_y,
			  input 	   interesting_flag,
			  input 	   frame_flag
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

   reg [1:0] 				   state; 				   

   reg [31:0] 				   sumx [0:3];
   reg [31:0] 				   sumy [0:3];
   reg [7:0] 				   num [0:3];
   reg [31:0] 				   averagex [0:3]; 
   reg [31:0] 				   averagey [0:3]; 

   reg [20:0] 				   top;
   reg [20:0] 				   bottom;
   reg [20:0] 				   left;
   reg [20:0] 				   right;

   reg [10:0] 				   topd;
   reg [10:0] 				   bottomd;
   reg [10:0] 				   leftd;
   reg [10:0] 				   rightd;		   

   reg 					   startdivs;
   reg [7:0] 				   divsready;
   reg 					   calcdone;
   reg [3:0] 				   sqrtdone;
   reg 					   sqrtstart;

   // STATES
   parameter COUNTING = 2'b00;
   parameter WAITING_FOR_DIVS = 2'b01;
   parameter STARTSQRTS = 2'b10
   parameter WAITING_FOR_SQRT = 2'b11;

   // parallelized dividers
   divider #(.WIDTH(32)) diva(.clk(clk), .ready(divsready[0]), .dividend(sumx[0]),
			      .divider({23'b0,num[0]}), .quotient(averagex[0]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divb(.clk(clk), .ready(divsready[1]), .dividend(sumy[0]),
			      .divider({23'b0,num[0]}), .quotient(averagey[0]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divc(.clk(clk), .ready(divsready[2]), .dividend(sumx[1]),
			      .divider({23'b0,num[1]}), .quotient(averagex[1]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divd(.clk(clk), .ready(divsready[3]), .dividend(sumy[1]),
			      .divider({23'b0,num[1]}), .quotient(averagey[1]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) dive(.clk(clk), .ready(divsready[4]), .dividend(sumx[2]),
			      .divider({23'b0,num[2]}), .quotient(averagex[2]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divf(.clk(clk), .ready(divsready[5]), .dividend(sumy[2]),
			      .divider({23'b0,num[2]}), .quotient(averagey[2]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divg(.clk(clk), .ready(divsready[6]), .dividend(sumx[3]),
			      .divider({23'b0,num[3]}), .quotient(averagex[3]), .sign(1'b0), .start(startdivs));
   divider #(.WIDTH(32)) divh(.clk(clk), .ready(divsready[7]), .dividend(sumy[3]),
			      .divider({23'b0,num[3]}), .quotient(averagey[3]), .sign(1'b0), .start(startdivs));

   // parallelized square rooters
   sqrt #(.NBITS(21)) sqrta(.clk(clk), .start(sqrtstart), .data(top),
			    .answer(topd), .done(sqrtdone[0]));
   sqrt #(.NBITS(21)) sqrta(.clk(clk), .start(sqrtstart), .data(bottom),
			    .answer(bottomd), .done(sqrtdone[1]));
   sqrt #(.NBITS(21)) sqrta(.clk(clk), .start(sqrtstart), .data(left),
			    .answer(leftd), .done(sqrtdone[2]));
   sqrt #(.NBITS(21)) sqrta(.clk(clk), .start(sqrtstart), .data(right),
			    .answer(rightd), .done(sqrtdone[3]));
   
   always @(posedge clk) begin
      corners_flag <= 0;
      start_divs <= 0;
      sqrtstart <= 0;
      

      case state
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
	      a_x <= sumx[0];
	      a_y <= sumy[0];
	      b_x <= sumx[1];
	      b_y <= sumy[1];
	      c_x <= sumx[2];
	      c_y <= sumy[2];
	      d_x <= sumx[3];
	      d_y <= sumy[3];

	      top <= (b_x - a_x) * (b_x - a_x) + (b_y - a_y) * (b_y - a_y);
	      bottom <= (c_x - d_x) * (c_x - d_x) + (c_y - d_y) * (c_y - d_y);
	      left <= (d_x - a_x) * (d_x - a_x) + (d_y - a_y) * (d_y - a_y);
	      right <= (c_x - b_x) * (c_x - b_x) + (c_y - b_y) * (c_y - b_y);

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
