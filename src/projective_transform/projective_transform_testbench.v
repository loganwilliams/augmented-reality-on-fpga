`timescale 1ns / 100ps 

`include "projective_transform.v"

  module projective_transform_test();
   // registers and wires for connection to the PT module
   reg clk;
   reg frame_flag;
   reg [17:0] pixel;
   reg 	      pixel_flag;
   reg [9:0]  a_x;
   reg [8:0]  a_y;
   reg [9:0]  b_x;
   reg [8:0]  b_y;
   reg [9:0]  c_x;
   reg [8:0]  c_y;
   reg [9:0]  d_x;
   reg [8:0]  d_y;
   reg 	      ptflag;

   wire [17:0] pixel_output;
   wire [9:0]  new_x;
   wire [8:0]  new_y;
   wire        wr;
   wire        request_pixel;

   // instantiate the projective_transform module
   projective_transform pt(.clk(clk), .frame_flag(frame_flag), .pixel(pixel),
			   .pixel_flag(pixel_flag), .a_x(a_x), .a_y(a_y), .b_x(b_x),
			   .b_y(b_y), .c_x(c_x), .c_y(c_y), .d_x(d_x), .d_y(d_y),
			   .ptflag(ptflag), .pt_pixel_write(pixel_output),
			   .pt_x(new_x), .pt_y(new_y), .pt_wr(wr), 
			   .request_pixel(request_pixel));

   integer     fin, fout;

   initial begin
      // open a file that contains a 640x480 image, stored linearly.
      // it really contains:
      //     [0]  [1]  [2]  [3] .... [639]
      //     [640][641][642][643] .... [1279]
      //       :
      //     [44576] ..................[45055] (it has wrapped around after getting
      //                                        to 2^17, but it still linearly
      //                                        incrementing)
      fin = $fopen("sample_image.image","r");

      // create a file for output. this will contain the coordinates and pixel value
      // of each processed input pixel. this file can be read by MATLAB and displayed
      // to ensure that projective_transform is operating correctly.
      fout = $fopen("sample_output.image","w");

      if (fin == 0 || fout == 0) begin
	 $display("Can't open file.");
	 $stop;
      end

      // set register default values
      clk = 0;
      frame_flag = 0;
      pixel_flag = 0;
      ptflag = 1;

      #1000

      // send some made up frame values
      a_x = 0;
      a_y = 0;

      b_x = 300;
      b_y = 100;

      c_x = 250;
      c_y = 150;

      d_x = 50;
      d_y = 200;

      // set a frame flag
      frame_flag = 1;
      
   end // initial begin

   // generate a 50 Mhz clock
   always #10 clk = ~clk;

   always @(posedge clk) begin
      if (request_pixel) begin
	 pixel = $fscanf(fin, "%d", x);
	 pixel_flag = 1;

	 if (wr) $fdisplay(fout, "%d", pixel_output);
	 
      end else begin
	 pixel_flag = 0;
	 
      end
      
	 
   end

endmodule // projective_transform_test
