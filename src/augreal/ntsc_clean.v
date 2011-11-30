module clean(
	input clock_65mhz, 
	input flag, 
	output reg clean_flag);

reg state;

always @(posedge clock_65mhz) begin
	if (flag & ~state) begin
		clean_flag <= 1;
		state <= 1;
	end
	
	if (clean_flag) clean_flag <= 0;
	
	if (~flag) state <= 0;
end

endmodule
