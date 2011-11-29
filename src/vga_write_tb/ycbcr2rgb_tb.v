`default_nettype none

module ycbcr_tb();
	reg clock;
	reg finish;
	reg [7:0] y;
	reg [7:0] cb;
	reg [7:0] cr;
	reg [63:0] count;
	reg reset;
	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
	integer fin, fout, code1, code2, code3;

	initial begin
		$dumpvars;
		fin = $fopen("ycbcr.data", "r");
		fout = $fopen("rgb.data", "w");

		if (fin == 0 || fout == 0) begin
			$display("can't open file...");
			$stop;
		end
	end

	initial begin
		finish = 0;
		clock = 0;
		reset = 1;
		#10 reset = 0;
	end

	always begin
		#5 clock = ~clock;
	end

	always @(posedge clock) begin
		if (reset) count <= 1;
		else count <= count+1;

		code1 = $fscanf(fin, "%d", y);
		code2 = $fscanf(fin, "%d", cb);
		code3 = $fscanf(fin, "%d", cr);
	
		#3	
		$fdisplay(fout, "%d", r);
		$fdisplay(fout, "%d", g);
		$fdisplay(fout, "%d", b);
		
		if (code1 != 1 || code2 != 1 || code3 != 1) begin
			finish <= 1;
		end

		if (finish) begin
			$fclose(fout);
			$stop;
		end
	end

	ycbcr2rgb dut(.y(y), .cb(cb), .cr(cr), .r(r), .g(g), .b(b));

endmodule	
