module test_pt_fetcher();

   reg clk, reset, pt_flag, done_ptf;
   reg [`LOG_WIDTH-1:0] pt_x;
   reg [`LOG_HEIGHT-1:0] pt_y;
   reg [`LOG_TRUNC-1:0]  pt_pixel;
   reg [`LOG_MEM-1:0] 	 ptf_pixel_read;
   
   wire 		 done_pt, ptf_flag, ptf_wr;
   wire [`LOG_WIDTH-1:0] ptf_x;
   wire [`LOG_HEIGHT-1:0] ptf_y;
   wire [`LOG_MEM-1:0] 	  ptf_pixel_write;

   pt_fetcher ptf(.clock(clk), .reset(reset), .pt_flag(pt_flag), .done_ptf(done_ptf),
		  .pt_x(pt_x), .pt_y(pt_y), .pt_pixel(pt_pixel), .ptf_pixel_read(ptf_pixel_read),
		  .done_pt(done_pt), .ptf_flag(ptf_flag), .ptf_wr(ptf_wr), .ptf_x(ptf_x),
		  .ptf_y(ptf_y), .ptf_pixel_write(ptf_pixel_write));

   forever #10 clk = ~clk;
   
   initial begin
      reset = 0;
      clk = 0;
      pt_flag = 0;
      done_ptf = 0;
      pt_x = 0;
      pt_y = 0;
      pt_pixel = 0;
      ptf_pixel_read = 0;

      #20;

      reset = 1;

      #20;

      reset = 0;
      pt_flag = 1;
      pt_x = 123;
      pt_y = 321;
      pt_pixel = 12345;
      done_ptf = 1;

      #20;

      pt_x = 234;
      pt_y = 432;
      pt_pixel = 23456;

      #20;

      

      
   end

endmodule // test_pt_fetcher
