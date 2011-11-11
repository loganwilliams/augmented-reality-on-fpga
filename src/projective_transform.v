module projective_transform(input clk, frame_flag, [17:0] pixel, pixel_flag,
		[9:0] ax, [8:0] ay, [9:0] bx, [8:0] by, [9:0] cx, [8:0] cy,
		[9:0] dx, [8:0] dy, output reg [17:0] pixel_out, [9:0] pixel_x,
		[8:0] pixel_y, pixel_out_flag);
	
	parameter WAITING_FOR_PIXEL = 0;

	reg [?:0] state; // not sure how big this should be 
	reg [9:0] i_a_x;
	reg [8:0] i_a_y;
	reg [9:0] i_b_x;
	reg [8:0] i_b_y;

	reg [9:0] d_ad;
	reg [9:0] d_bc;
	reg [9:0] d_iterators;

	reg [9:0] o_x;
	reg [8:0] o_y;

	wire [4:0] sqrt_output_ad; // output from the sqrt lookup ROM
	wire [4:0] sqrt_output_bc; // ...
	wire [4:0] sqrt_output_iterators; // ...

	always @(posedge clk) begin
		if (frame_flag) begin
			// initialize system parameters
			state <= CALCULATING_DISTANCE_AD_X;
			i_a_x <= ax;
			i_a_y <= ay;
			i_b_x <= bx;
			i_b_y <= by;

			d_ad <= 0;
			d_bc <= 0;
			d_iterators <= 0;
		end

		case(state)
			// once per frame
			CALCULATING_DISTANCE_AD_X: begin
				d_ad <= (ax - dx) * (ax - dx);
				state <= CALCULATING_DISTANCE_AD_Y;
			end

			// once per frame
			CALCULATING_DISTANCE_AD_Y: begin
				d_ad <= d_ad + (ay - dy) * (ay - dy);
				state <= CALCULATING_DISTANCE_AD_SQRT;
			end

			// once per frame
			CALCULATING_DISTANCE_AD_SQRT: begin
				d_ad <= sqrt_output_ad;
				state <= CALCULATING_DISTANCE_BC_X;
			end

			// once per frame
			CALCULATING_DISTANCE_BC_X: begin
				d_bc <= (bx - cx) * (bx - cx);
				state <= CALCULATING_DISTANCE_BC_Y;
			end

			// once per frame
			CALCULATING_DISTANCE_BC_Y: begin
				d_bc <= d_bc + (by - cy) * (by - cdy);
				state <= CALCULATING_DISTANCE_BC_SQRT;
			end

			// once per frame
			CALCULATING_DISTANCE_BC_SQRT: begin
				d_bc <= sqrt_output_bc;
				state <= CALCULATING_DISTANCE_ITERATORS_X;
			end

			// once per LINE
			CALCULATING_DISTANCE_ITERATORS_X: begin
				d_iterators <= (i_a_x - i_b_x) * (i_a_x - i_b_x);
				state <= CALCULATING_DISTANCE_ITERATORS_Y: begin
			end

			// once per LINE
			CALCULATING_DISTANCE_ITERATORS_Y: begin
				d_iterators <= d_iterators + (i_a_y - i_b_y) * (i_a_x - i_b_x);
				state <= CALCULATE_DISTANCE_ITERATORS_SQRT;
			end

			// once per LINE
			CALCULATE_DISTANCE_ITERATORS_SQRT: begin
				d_iterators <= sqrt_output_iterators;
				state <= WRITE_PIXEL;
			end


			// ONCE PER PIXEL
			WRITE PIXEL: begin
				// ???
				state <= ITERATE_IC;
			end




		endcase
	end
endmodule