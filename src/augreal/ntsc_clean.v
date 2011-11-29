module ntsc_clean(input clock_65mhz, input ntsc_flag, output reg clean_ntsc_flag, output reg state);

//reg state;

always @(posedge clock_65mhz) begin
	if (ntsc_flag & ~state) begin
		clean_ntsc_flag <= 1;
		state <= 1;
	end
	
	if (clean_ntsc_flag) clean_ntsc_flag <= 0;
	
	if (~ntsc_flag) state <= 0;
end
endmodule
