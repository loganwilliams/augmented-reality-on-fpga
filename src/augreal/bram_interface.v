module bram_interface(
	input clk,
	input ntsc_flag,
	input frame_flag,
	input [35:0] ntsc_pixels,
	input vga_flag,
	input vsync,
	output reg done_vga,
	output reg [35:0] vga_pixels
    );
	 
	 reg [9:0] nx;
	 reg [8:0] ny;
	 
	 reg [9:0] vx;
	 reg [8:0] vy;
	 
	 reg [13:0] addra, addrb;
	 reg [35:0] dina, dinb;
	 wire [35:0] douta, doutb;
	 reg wea, web;
	 
	 reg [1:0] state = 0;
	 reg [35:0] vbuf;
	 
	 bramimage mybram(.clka(clk), .clkb(clk), .addra(addra), .dina(dina), .douta(douta), .wea(wea),
		.addrb(addrb), .dinb(dinb), .doutb(doutb), .web(web));

always @(posedge clk) begin
	if (ntsc_flag & ~frame_flag) begin
		if ((ny < 128) & (nx < 128)) begin
			addra <= 128 * ny + nx;
			dina <= ntsc_pixels;
			wea <= 1;
		end
		
		if (ny == 479) begin
			ny <= 0;
			nx <= 0;
		end else if (nx == 639) begin
			nx <= 0;
			ny <= ny + 1;
		end else begin
			nx <= nx + 1;
		end
	end else wea <= 0;
	
	if (vsync) begin
		vy <= 0;
		vx <= 0;
	end
	
	if (frame_flag) begin
		nx <= 0;
		ny <= 0;
	end
	
	case (state)
		0: begin
			if (vga_flag & ~vsync) begin
				done_vga <= 1;
				if ((vy < 128) & (vx < 128)) begin
					addrb <= 128 * vy + vx;
					web <= 0;
					state <= 1;
				end
				
				if (vy == 479) begin
					vy <= 0;
					vx <= 0;
				end else if (vx == 639) begin
					vx <= 0;
					vy <= vy + 1;
				end else begin
					vx <= vx + 1;
				end
			end else begin
				done_vga <= 0;
			end
		end
		
		1: begin
			if ((vy < 128) & (vx < 128)) begin
				vga_pixels <= 36'b0;
			end else begin
				vga_pixels <= doutb;
			end
			state <= 0;
		end
		
		2: begin
			vga_pixels <= vbuf;
			state <= 0;
		end
	endcase
end
endmodule
