`include "params.v"

module address_calculator(
	input [8:0] x,
	input [9:0] y,
	input [1:0] loc,
	output [18:0] addr);
	
	wire [18:0] of1, of2;
	
	loc_lut ll(.loc(loc), .addr_off(of1));
	y_lut yl(.y(y), .addr_off(of2));
	
	assign addr = of1 + of2 + x;
endmodule

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

   reg [1:0] 			   state = 0;
   reg [8:0] 			   y;
   reg [9:0] 			   x;
	wire [18:0] addr;
	reg [1:0] loc;
	
	address_calculator test_ac(
		.x(x), .y(y), 
		.loc(loc), .addr(addr));
   
   always @(posedge clock) begin
      case (state)
	0: begin
	   mem0_wr <= 0;
	   mem1_wr <= 0;
	   
	   if (start) begin
	      state <= 1;
	      x <= 0;
	      y <= 0;
			loc <= 0;
	   end
	end

	1: begin
	   mem0_addr <= addr;
	   mem1_addr <= addr;
	   mem0_wr <= 1;
	   mem1_wr <= 1;
	   if ((x[4] & ~y[4]) || (~x[4] & y[4])) begin
	      mem0_write <= 36'b111111111100011000111111111100011000;
	      mem1_write <= 36'b111111111000010000111111111000010000;
	   end else begin
	      mem0_write <= 36'b000000001000010000000000001000010000;
	      mem1_write <= 36'b000000001000010000000000001000010000;
	   end

	   if (y == 479 && x == 639) begin
	      state <= 2;
			loc <= 1;
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
	   mem0_addr <= addr;
	   mem1_addr <= addr;
	   mem0_wr <= 1;
	   mem1_wr <= 1;
	   if ((x[5] & ~y[5]) || (~x[5] & y[5])) begin
	      mem0_write <= 36'b111111111100011000111111111100011000;
	      mem1_write <= 36'b111111111000010000111111111000010000;
	   end else begin
	      mem0_write <= 36'b000000001000010000000000001000010000;
	      mem1_write <= 36'b000000001000010000000000001000010000;
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
