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

        reg signed [8:0] y_fixed, cb_fixed, cr_fixed;

        // fix y, cb, cr values, to ensure that they're in valid ranges
        always @(*) begin
                if (y < 8'd16) y_fixed[8:0] = 9'sd16;
                else if (y > 8'd235) y_fixed[8:0] = 9'sd235;
                else y_fixed[8:0] = {1'b0, y};

                if (cb < 8'd16) cb_fixed[8:0] = 9'sd16;
                else if (cb > 8'd235) cb_fixed[8:0] = 9'sd235;
                else cb_fixed[8:0] = {1'b0, cb};

                if (cr < 8'd16) cr_fixed[8:0] = 9'sd16;
                else if (cr > 8'd235) cr_fixed[8:0] = 9'sd235;
                else cr_fixed[8:0] = {1'b0, cr};
        end

        // constants used in multiplication (*2^11)
        parameter RGB_Y = 14'sd2383; // 1.164

        parameter R_CR  = 14'sd3269; // 1.596
        parameter G_CR  = 14'sd1665; // 0.813

        parameter G_CB  = 14'sd803;  // 0.392
        parameter B_CB  = 14'sd4131;// 2.017

	// outputs of multiplications bitwidth=14+9+1 due to possible overflow
        reg signed [23:0] R_scaled;
	reg signed [23:0] G_scaled;
	reg signed [23:0] B_scaled;

	reg signed [9:0] R_signed;
	reg signed [9:0] G_signed;
	reg signed [9:0] B_signed;

	always @(*) begin
		// transformation
		R_scaled = RGB_Y*(y_fixed-9'sd16) + R_CR*(cr_fixed-9'sd128);
		G_scaled = RGB_Y*(y_fixed-9'sd16) - G_CR*(cr_fixed-9'sd128) - G_CB*(cb_fixed-9'sd128);
		B_scaled = RGB_Y*(y_fixed-9'sd16) + B_CB*(cb_fixed-9'sd128);
		
		// scaling down
		R_signed = R_scaled >>> 11;
		G_signed = G_scaled >>> 11;
		B_signed = B_scaled >>> 11;

		// saturation and assignment
		if (R_signed < 0) r = 8'd0;
		else if (R_signed > 255) r = 8'd255;
		else r = R_signed[7:0];

		if (G_signed < 0) g = 8'd0;
		else if (G_signed > 255) g = 8'd255;
		else g = G_signed[7:0];

		if (B_signed < 0) b = 8'd0;
		else if (B_signed > 255) b = 8'd255;
		else b = B_signed[7:0];
	end
endmodule
