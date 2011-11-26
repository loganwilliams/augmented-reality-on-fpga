`include "../params.v"
`include "../memory_interface.v"

module tb2;
	`include "tb_template.v"

	initial begin
		frame_flag = 0;
		#1000 frame_flag = 1;
		#10 frame_flag = 0;
		#1000000 frame_flag = 1;
		#10 frame_flag = 0;
	end

	integer i;
	integer j;
	initial begin
		lpf_x = 0;
		lpf_y = 0;
		pt_x = 0;
		pt_y = 0;

		for (i = 0;i < `IMAGE_HEIGHT;i = i+1) begin
			for (j=0;j < `IMAGE_WIDTH;j = j+1) begin
				#10
				lpf_x = j;
				lpf_y = i;
				pt_x = j;
				pt_y = i;
			end
		end
	end

	initial begin
		#6000000 $stop;
	end
endmodule
