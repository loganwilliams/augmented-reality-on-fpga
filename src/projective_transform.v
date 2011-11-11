module projective_transform(input clk, frame_flag, [17:0] pixel, pixel_flag,
		[9:0] ax, [8:0] ay, [9:0] bx, [8:0] by, [9:0] cx, [8:0] cy,
		[9:0] dx, [8:0] dy, output reg [17:0] pixel_out, [9:0] pixel_x,
		[8:0] pixel_y, pixel_out_flag);
	

	reg [?:0] state; // not sure how big this should be yet

	// iterator coordinates
	reg [19:0] i_a_x;
	reg [18:0] i_a_y;
	reg [19:0] i_b_x;
	reg [18:0] i_b_y;
	reg [19:0] i_c_x;
	reg [18:0] i_c_y;

	// distance stores
	reg [9:0] d_ad;
	reg [9:0] d_bc;
	reg [9:0] d_iterators;

	// temporary registers for calculating distances
	reg [19:0] dcalc_temp1;
	reg [19:0] dcalc_temp2;
	reg [20:0] d_sqrt;

	// coordinates of the untransformed images
	reg [9:0] o_x;
	reg [8:0] o_y;

	wire [4:0] sqrt_output_ad; // output from the sqrt lookup ROM
	wire [4:0] sqrt_output_bc; // ...
	wire [4:0] sqrt_output_iterators; // ...

	always @(posedge clk) begin
		if (frame_flag) begin
			// initialize system parameters
			state <= CALCULATING_DISTANCE_AD_1;
			i_a_x <= ax << 10;
			i_a_y <= ay << 10;
			i_b_x <= bx << 10;
			i_b_y <= by << 10;

			d_ad <= 0;
			d_bc <= 0;
			d_iterators <= 0;

			o_x <= 0;
			o_y <= 0;
		end

		case(state)
			// once per frame
			CALCULATING_DISTANCE_AD_1: begin
				dcalc_temp1 <= (ax - dx) * (ax - dx);
				dcalc_temp2 <= (ay - dy) * (ay - dy);
				state <= CALCULATING_DISTANCE_AD_2;
			end

			// once per frame
			CALCULATING_DISTANCE_AD_Y: begin
				d_sqrt <= dcalc_temp1 + dcalc_temp2;
				sqrt_start <= 1;
				state <= CALCULATING_DISTANCE_AD_SQRT;
			end

			// once per frame
			CALCULATING_DISTANCE_AD_SQRT: begin
				sqrt_start <= 0;

				if (sqrt_done) begin
					d_ad <= answer;
					state <= CALCULATING_DISTANCE_BC_1;
				end
			end

			// once per frame
			CALCULATING_DISTANCE_BC_1: begin
				dcalc_temp1 <= (bx - cx) * (bx - cx);
				dcalc_temp2 <= (by - cy) * (by - cy);
				state <= CALCULATING_DISTANCE_BC_2;
			end

			// once per frame
			CALCULATING_DISTANCE_BC_2: begin
				dsqrt <= dcalc_temp1 + dcalc_temp2;
				sqrt_start <= 1;
				state <= CALCULATING_DISTANCE_BC_SQRT;
			end

			// once per frame
			CALCULATING_DISTANCE_BC_SQRT: begin
				sqrt_start <= 0;

				if (sqrt_done) begin
					d_bc <= answer;
					state <= CALCULATING_DISTANCE_ITERATORS_1;
				end
			end

			// once per LINE
			CALCULATING_DISTANCE_ITERATORS_1: begin
				dcalc_temp1 <= (i_a_x - i_b_x) * (i_a_x - i_b_x);
				dcalc_temp2 <= (i_a_y - i_b_y) * (i_a_y - i_b_y);
				state <= CALCULATING_DISTANCE_ITERATORS_2;
			end

			// once per LINE
			CALCULATING_DISTANCE_ITERATORS_2: begin
				dsqrt <= dcalc_temp1 + dcalc_temp2;
				sqrt_start <= 1;
				state <= CALCULATING_DISTANCE_ITERATORS_SQRT
			end

			// once per LINE
			CALCULATE_DISTANCE_ITERATORS_SQRT: begin
				sqrt_start <= 0;

				if (sqrt_done) begin
					d_iterators <= answer;
					state <= WRITE_PIXEL;
				end
			end


			// ONCE PER PIXEL
			WRITE PIXEL: begin
				
			end

		endcase
	end
endmodule


// takes integer square root iteratively
module sqrt #(parameter NBITS = 8,  // max 32
                        MBITS = (NBITS+1)/2)
            (input wire clk,start,
             input wire [NBITS-1:0] data,
             output reg [MBITS-1:0] answer,
             output wire done);
   
   reg 			 busy;
   reg [4:0] 		 bit;
   // compute answer bit-by-bit, starting at MSB
   wire [MBITS-1:0] 	 trial = answer | (1 << bit);
   always @(posedge clk) begin
      if (busy) begin
	 if (bit == 0) busy <= 0;
	 else bit <= bit - 1;
	 if (trial*trial <= data) answer <= trial;
      end
      else if (start) begin
	 busy <= 1;
	 answer <= 0;
	 bit <= MBITS - 1;
      end
   end
   assign done = ~busy;
endmodule