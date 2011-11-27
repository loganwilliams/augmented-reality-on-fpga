// Logan Williams


module pt_fetcher(
		  // STANDARD INPUTS
		  input 		       clock,
		  input 		       reset,
		  // TO AND FROM PROJECTIVE_TRANSFORM
		  input 		       pt_flag,
		  input [`LOG_WIDTH-1:0]       pt_x,
		  input [`LOG_HEIGHT-1:0]      pt_y,
		  input [`LOG_TRUNC-1:0]       pt_pixel,
		  output reg 		       done_pt,
		  // TO AND FROM MEMORY_INTERFACE
		  input [`LOG_MEM-1:0] 	       ptf_pixel_read,
		  input 		       done_ptf,
		  output reg [`LOG_WIDTH-1:0]  ptf_x,
		  output reg [`LOG_HEIGHT-1:0] ptf_y,
		  output reg 		       ptf_flag,
		  output reg 		       ptf_wr,
		  output reg [`LOG_MEM-1:0]    ptf_pixel_write);
   

   reg [17:0] 				       pt_pixel_buffer [0:1];
   reg [9:0] 				       pt_pixel_x [0:1];
   reg [8:0] 				       pt_pixel_y [0:1];
   reg 					       haspixel;
   

   always @(posedge clock) begin
      if (reset) begin
	 // reset everything to its initial state
	 state <= 2b'00;
	 pt_pixel_buffer[0] <= 0;
	 pt_pixel_buffer[1] <= 0;
	 pt_pixel_x[0] <= 0;
	 pt_pixel_x[1] <= 0;
	 pt_pixel_y[0] <= 0;
	 pt_pixel_y[1] <= 0;
	 haspixel <= 0;
	 
      end
      
      case state
	2b'00: begin
	   if (pt_flag) begin
	      pt_pixel_buffer[0] <= pt_pixel_write;
	      pt_pixel_x[0] <= pt_x;
	      pt_pixel_y[0] <= pt_y;
	      haspixel <= 1;
	   end

	   if (done_ptf & haspixel) begin
	      ptf_x <= pt_x;
	      ptf_y <= pt_y;
	      ptf_wr <= 0;
	      ptf_flag <= 1;
	      state <= 2b'01;
	      done_pt <= 1;
	      haspixel <= 0;
	      
	   end else done_pt <= 0;
	end

	2b'01: begin
	   if (pt_flag) begin
	      pt_pixel_buffer[1] <= pt_pixel_write;
	      pt_pixel_x[1] <= pt_x;
	      pt_pixel_y[1] <= pt_y;
	      haspixel <= 1;
	      
	   end

	   if (done_ptf & haspixel) begin
	      ptf_x <= pt_x;
	      ptf_y <= pt_y;
	      ptf_wr <= 0;
	      ptf_flag <= 1;
	      state <= 2b'10;
	      haspixel <= 0;
	      
	      done_pt <= 0;
	   end else done_pt <= 0;
	end

	2b'10: begin
	   done_pt <= 0;

	   
	   // catch the case where both pixels are in the same address
	   if ((pt_pixel_x[0] >> 1) == (pt_pixel_x[1] >> 1) & 
	       (pt_pixel_y[0] == py_pixel_y[1]) & (pt_pixel_x[0] != pt_pixel_x[1])) begin
	      if (pt_pixel_x[0] < pt_pixel_x[1]) begin
		 ptf_pixel_write <= {pt_pixel_buffer[1],pt_pixel_buffer[0]};
		 ptf_x <= pt_pixel_x[0];
		 ptf_y <= pt_pixel_y[0];
	      end else begin
		 ptf_pixel_write <= {pt_pixel_buffer[0],pt_pixel_buffer[1]};
		 ptf_x <= pt_pixel_x[1];
		 ptf_y <= pt_pixel_y[1];
	      end

	      // skip the fourth state
	      state <= 2b'00;
	      ptf_flag <= 1;
	      ptf_wr <= 1;
	      
	      // ``request'' another pixel
	      done_pt <= 1;
	      
	   end else begin // if ((pt_pixel_x[0] >> 1) == (pt_pixel_x[1] >> 1) &...
	      
	      
	      // concatenate normally
	      if (pt_pixel_x[0][0]) ptf_pixel_write <= {pt_pixel_read[35:18], pt_pixel_buffer[0]};
	      else ptf_pixel_write <= {pt_pixel_buffer[0], pt_pixel_read[17:0]};
	      
	      
	      // send write for new pixel pair
	      ptf_x <= pt_pixel_x[0];
	      ptf_y <= pt_pixel_y[0];
	      ptf_flag <= 1;
	      ptf_wr <= 1;
	      
	      // go to next state
	      state <= 2b'11;
	   end
	end

	2b'11: begin
	   // concatenate

	   if (pt_pixel_x[1][0]) ptf_pixel_write <= {pt_pixel_read[35:18], pt_pixel_buffer[1]};
	   else ptf_pixel_write <= {pt_pixel_buffer[1], pt_pixel_read[17:0]};

	   // send write for new pixel pair

	   ptf_x <= pt_pixel_x[0];
	   ptf_y <= pt_pixel_y[0];
	   ptf_flag <= 1;
	   ptf_wr <= 1;

	   state <= 2b'00;
	   ptflag <= 1;
	   done_pt <= 1;
	   
	end
      endcase // case state
   end // always @ (posedge clock)
   
endmodule // pt_fetcher