module vga_write_tb;

reg clock;
reg vclock;
reg reset;
reg frame_flag;
reg [17:0] count;

wire vga_flag;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;

vga_write dut(.clock(clock), .vclock(vclock), .reset(reset), .frame_flag(frame_flag), .vga_pixel({count,count+1'b1}), .done_vga(1'b1), .vga_flag(vga_flag), .vga_out_red(red), .vga_out_green(green), .vga_out_blue(blue));

always begin
	#10 clock = ~clock;
end
always begin
	#20 vclock = ~vclock;
end

initial begin
	$dumpvars;
	clock = 0;
	vclock = 0;
	reset = 1;
	#25 reset = 0;
end

always @(posedge clock) begin
	if (reset) count <= 0;
	else if (vga_flag) count <= count+2;
	else count <= count;

	if (count == 18'd30000) begin
		$stop;
	end
end

endmodule
