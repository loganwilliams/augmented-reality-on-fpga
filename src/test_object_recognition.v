`include "object_recognition.v";
`include "divider.v";

module test_object_recognition();
   reg clk;
   reg [1:0] color;
   reg [9:0] ix;
   reg [8:0] iy;
   reg 	     int_flag;
   reg 	     frame_flag;
   
   wire [9:0] m_x;
   wire [8:0] m_y;
   wire [9:0] a_x;
   wire [8:0] a_y;
   wire [9:0] b_x;
   wire [8:0] b_y;
   wire [9:0] c_x;
   wire [8:0] c_y;
   wire [9:0] d_x;
   wire [8:0] d_y;
   wire       corners_flag;

   integer 	      i;
   reg reset;

   object_recognition obrec(.clk(clk), .color(color), .interesting_x(ix),
			     .interesting_y(iy), .interesting_flag(int_flag),
			     .frame_flag(frame_flag), .m_x(m_x), .m_y(m_y),
			     .a_x(a_x), .a_y(a_y), .b_x(b_x), .b_y(b_y), .c_x(c_x),
			     .c_y(c_y), .d_x(d_x), .d_y(d_y), .corners_flag(corners_flag), .reset(reset));

   initial begin
      clk = 0;
      frame_flag = 0;
      int_flag = 0;
      
      forever #10 clk = ~clk;
   end

   initial begin
      #20;
      
      reset = 1;
      
      #20
      
      reset = 0;
      frame_flag = 0;

      #20;

      for (i = 0; i < 20; i = i + 1) begin
	 int_flag = 1;
	 color = 0;
	 ix = i;
	 iy = i;

	 #20;

	 color = 1;
	 ix = i*2;
	 iy = i*2;

	 #20;

	 color = 2;

	 ix = i*3;
	 iy = i*3;

	 #20;

	 color = 3;

	 ix = i*4;
	 iy = i*4;

	 #20;
      end // for (i = 0; i < 20; i = i + 1)

      frame_flag = 1;

      #1000;

      $display("Average values:");
      $display("a_x: %d", a_x);
      $display("a_y: %d", a_y);
      $display("b_x: %d", b_x);
      $display("b_y: %d", b_y);
      $display("c_x: %d", c_x);
      $display("c_y: %d", c_y);
      $display("d_x: %d", d_x);
      $display("d_y: %d", d_y);

      $display("Min distances:");
      $display("m_x: %d", m_x);
      $display("m_y: %d", m_y);
   end // initial begin
endmodule // test_object_recognition
