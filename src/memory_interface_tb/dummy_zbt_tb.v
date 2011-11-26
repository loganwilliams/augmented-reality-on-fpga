`include "dummy_zbt.v"

module dummy_zbt_tb;

	reg clock;
	reg reset;
	
	reg wr;
	reg [`LOG_ADDR-1:0] addr;
	reg [`LOG_MEM-1:0] write;

	wire [`LOG_MEM-1:0] data;

	dummy_zbt mem(.clock(clock), .reset(reset), .wr(wr), .addr(addr), .write(write), .data(data));

	always #5 clock = !clock;

	integer i;

	initial begin
		clock = 0;
		reset = 1;
		wr = 0;
		addr = 0;
		write = 0;
		#10
		reset = 0;
		// writing
		for (i = 0;i < 30;i=i+1) begin
			#10
			wr = 1;
			addr = i;
			write = 1000-i;
		end
		// reading
		for (i = 0;i < 30;i=i+1) begin
			#10
			wr = 0;
			addr = i;
			write = 0;
		end
		#100
		$stop;
	end

	initial $dumpvars;
endmodule
