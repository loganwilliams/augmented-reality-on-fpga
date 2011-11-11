module projective_transform(input clk, [17:0] pixel, pixel_flag,
		[9:0] ax, [8:0] ay, [9:0] bx, [8:0] by, [9:0] cx, [8:0] cy,
		[9:0] dx, [8:0] dy, output reg [17:0] pixel_out, [9:0] pixel_x,
		[8:0] pixel_y, pixel_out_flag);
	
	parameter WAITING_FOR_PIXEL = 0;

	reg [?:0] state;


	always @(posedge clk) begin
	end
endmodule