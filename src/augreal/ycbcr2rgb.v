`default_nettype none

// converts YCrCb to RGB
module ycbcr2rgb
	(
		input [7:0] y,
		input [7:0] cb,
		input [7:0] cr,
		output reg [7:0] r,
		output reg [7:0] g,
		output reg [7:0] b
	);

	parameter SCALE=11;

	// scaled by 2^11
	parameter RGB_y = 14'sd2384;
	parameter R_cr = 14'sd3269;
	parameter G_cb = 14'sd803;
	parameter G_cr = 14'sd1665;
	parameter B_cb = 14'sd4131;

	wire signed [21:0] RGB_y_comp;
	wire signed [21:0] R_scaled;
	wire signed [21:0] G_scaled;
	wire signed [21:0] B_scaled;

	wire signed [8:0] Yoff;
	wire signed [8:0] Croff;
	wire signed [8:0] Cboff;

	assign Yoff = y-16;
	assign Croff = cr-128;
	assign Cboff = cb-128;

	assign RGB_y_comp = RGB_y*Yoff;
	assign R_scaled = RGB_y_comp + R_cr*Croff;
	assign G_scaled = RGB_y_comp - G_cr*Croff - G_cb*Cboff;
	assign B_scaled = RGB_y_comp + B_cb*Cboff;

	reg [8:0] R;
	reg [8:0] G;
	reg [8:0] B;

	always @(*) begin
		if (R_scaled < 0) R = 0;
		else R = R_scaled[SCALE+8:SCALE];

		if (G_scaled < 0) G = 0;
		else G = G_scaled[SCALE+8:SCALE];

		if (B_scaled < 0) B = 0;
		else B = B_scaled[SCALE+8:SCALE];

		if (R > 255) r = 8'd255;
		else r = R[7:0];
	
		if (G > 255) g = 8'd255;
		else g = G[7:0];

		if (B > 255) b = 8'd255;
		else b = B[7:0];
	end
endmodule
