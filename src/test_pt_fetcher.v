module test_pt_fetcher();

   reg clk, reset, pt_flag, done_ptf;
   reg [9:0] pt_x;
   reg [8:0] pt_y;
   reg [17:0] pt_pixel;
   reg [35:0] ptf_pixel_read;
   
   wire       done_pt, ptf_flag, ptf_wr;
   wire [9:0] ptf_x;
   wire [8:0] ptf_y;
   wire [35:0] ptf_pixel_write;

   pt_fetcher ptf(.clock(clk), .reset(reset), .pt_flag(pt_flag), .done_ptf(done_ptf),
		  .pt_x(pt_x), .pt_y(pt_y), .pt_pixel(pt_pixel), .ptf_pixel_read(ptf_pixel_read),
		  .done_pt(done_pt), .ptf_flag(ptf_flag), .ptf_wr(ptf_wr), .ptf_x(ptf_x),
		  .ptf_y(ptf_y), .ptf_pixel_write(ptf_pixel_write));
   
   initial forever #10 clk = ~clk;
   
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

      if (ptf_x != 123 || ptf_y != 321 || ptf_wr == 1) begin
	 $display("Not requesting appropriate pixel");
	 $stop();
      end

      // send next pixel
      pt_x = 234;
      pt_y = 432;
      pt_pixel = 23456;
      done_ptf = 0;
      
      #40;
      
      done_ptf = 1;


      #20;

      ptf_pixel_read = 36'b101010101010101010101010101010101010;

      if (done_pt) begin
	 $display("Should tell pt to wait");
	 $stop();
      end

      #20;
      
      if (done_pt) begin
	 $display("Should tell pt to wait");
	 $stop();
      end

      if (ptf_x != 123 || ptf_y != 321 || ptf_wr == 0) begin
	 $display("Not writing appropriate pixel");
	 $stop();
      end

      if (ptf_pixel_write[35:18] != 18'b101010101010101010 ||
	  ptf_pixel_write[17:0] != 12345) begin
	 $display("Did not concatenate pixel correctly.");
	 $stop();
      end
      
      #20;


      if (ptf_x != 234 || ptf_y != 432 || ptf_wr == 0) begin
	 $display("Not writing appropriate pixel");
	 $stop();
      end
      
      if (ptf_pixel_write[17:0] != 18'b101010101010101010 ||
	  ptf_pixel_write[35:18] != 23456) begin
	 $display("Did not concatenate pixel correctly.");
	 $stop();
      end

      $display("Test passed.");
      $stop();
   end

endmodule // test_pt_fetcher
