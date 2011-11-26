`define TESTING
`include "../params.v"
`default_nettype none

module dummy_zbt
	(
		input clock, reset,
		input wr,
		input [`LOG_ADDR-1:0] addr,
		input [`LOG_MEM-1:0] write,
		output reg [`LOG_MEM-1:0] data
	);

	reg [`LOG_MEM-1:0] mem[`MEM_ADDR-1:0];
	reg [`LOG_ADDR-1:0] addr_queue;
	reg [`LOG_MEM-1:0] write_queue;
	reg wr_queue; // 1 - writing, 0 - reading
	
	integer i;
	always @(posedge clock) begin
		// setting memory cells
		if (reset) begin
			for (i=0;i < `MEM_ADDR;i=i+1)
				mem[i] <= `LOG_MEM'd0;
		end
		// writing
		else if (wr_queue) begin
			mem[addr_queue] <= write_queue;
		end

		// updating the queues
		if (reset) begin
			addr_queue <= {`LOG_MEM{1'b0}};
			write_queue <= {`LOG_ADDR{1'b0}};
			wr_queue <= 1'b0;
		end
		else begin
			addr_queue <= addr;
			write_queue <= write;
			wr_queue <= wr;
		end

		// data signal
		if (reset) data <= {`LOG_MEM{1'b0}};
		// output on next cycle what was just written
		else if (wr_queue) data <= write_queue;
		// output what's to be read in the queue
		else data <= mem[addr_queue];
	end
endmodule
