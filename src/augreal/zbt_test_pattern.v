`include "params.v"

module zbt_test_pattern(
			input clock,
			input reset,
			input start,
			output reg [`LOG_ADDR-1:0] mem0_addr,
			output reg [`LOG_ADDR-1:0] mem1_addr,
			output reg [`LOG_MEM-1:0] mem0_write,
			output reg [`LOG_MEM-1:0] mem1_write,
			output reg mem0_wr,
			output reg mem1_wr);

   reg [2:0] 			   state = 0;
   reg [8:0] 			   y;
   reg [9:0] 			   x;
   
   always @(posedge clock) begin
      case (state)
	0: begin
	   mem0_wr <= 0;
	   mem1_wr <= 0;
	   
	   if (start) begin
	      state <= 1;
	      x <= 0;
	      y <= 0;
	   end
	end

	1: begin
	   mem0_addr <= y*320 + x + 0;
	   mem1_addr <= y*320 + x + 0;
	   mem0_wr <= 1;
	   mem1_wr <= 1;
	   if ((x[5] & ~y[5]) || (~x[5] & y[5])) begin
	      mem0_write <= 36'b111111111111111111111111111111111111;
	      mem1_write <= 36'b111111111111111111111111111111111111;
	   end else begin
	      mem0_write <= 36'b0;
	      mem1_write <= 36'b0;
	   end

	   if (y == 479 && x == 639) begin
	      state <= 2;
	      mem0_wr <= 0;
	      mem1_wr <= 0;
	      x <= 0;
	      y <= 0;
	   end else if (x == 639) begin
	      x <= 0;
	      y <= y + 1;
	   end else x <= x + 1;
	end // case: 1

	2: begin
	   mem0_addr <= y*320 + x + 19'd153600;
	   mem1_addr <= y*320 + x + 19'd153600;
	   mem0_wr <= 1;
	   mem1_wr <= 1;
	   if ((x[5] & ~y[5]) || (~x[5] & y[5])) begin
	      mem0_write <= 36'b111111111111111111111111111111111111;
	      mem1_write <= 36'b111111111111111111111111111111111111;
	   end else begin
	      mem0_write <= 36'b0;
	      mem1_write <= 36'b0;
	   end

	   if (y == 479 && x == 639) begin
	      state <= 0;
	      mem0_wr <= 0;
	      mem1_wr <= 0;
	      x <= 0;
	      y <= 0;
	   end else if (x == 639) begin
	      x <= 0;
	      y <= y + 1;
	   end else x <= x + 1;
	end // case: 2

	default: state <= 0;
      endcase // case state
   end // always @ (posedge clock)
endmodule // zbt_test_pattern
