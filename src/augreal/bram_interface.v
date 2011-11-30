module bram_interface(
		      input 		clk,
		      input 		ntsc_flag,
		      input 		frame_flag,
		      input [35:0] 	ntsc_pixels,
		      input 		vga_flag,
		      input 		vsync,
		      output 		done_vga,
		      output reg [35:0] vga_pixels,
		      output reg [13:0] addra, 
		      output reg [13:0] addrb,
		      output reg 	wea
		      );
   
   reg [9:0] 				nx;
   reg [8:0] 				ny;
   
   reg [9:0] 				vx;
   reg [8:0] 				vy;
   
   //reg [13:0] 			addra, addrb;
   reg [35:0] 				dina, dinb;
   wire [35:0] 				douta, doutb;
   //reg 					wea;
   
   reg [1:0] 				state = 0;
   reg [35:0] 				vbuf;
   
   bramimage mybram(.clka(clk), .clkb(clk), .addra(addra), .dina(dina), .douta(douta), .wea(wea),
		    .addrb(addrb), .dinb(dinb), .doutb(doutb), .web(1'b1));

   assign done_vga = vga_flag;
   
   always @(posedge clk) begin
      if (ntsc_flag & ~frame_flag) begin
	 if ((ny < 128) & (nx < 128)) begin
	    addra <= addra + 1;
	    dina <= ntsc_pixels;
	    wea <= 1;
	 end else wea <= 0;
	 
	 if (nx == 639) begin
	    nx <= 0;
	    ny <= ny + 1;
	 end else begin
	    nx <= nx + 1;
	 end
      end else wea <= 0;
      
      if (vsync) begin
	 vx <= 0;
	 vy <= 0;
	 addrb <= 0;
      end
      
      if (frame_flag) begin
	 nx <= 0;
	 ny <= 0;
	 addra <= 0;
      end
      
      case (state)
	0: begin
	   if (vga_flag & ~vsync) begin
	      if ((vy < 128) & (vx < 128)) begin
		 addrb <= addrb + 1;
		 state <= 1;
	      end
	      
	      if (vx == 639) begin
		 vx <= 0;
		 vy <= vy + 1;
	      end else begin
		 vx <= vx + 1;
	      end
	      
	   end // if (vga_flag & ~vsync)
	end
	
	1: begin
	   if ((vy < 128) & (vx < 128)) begin
	      vga_pixels <= doutb;
	      vbuf <= doutb;
	   end else begin
	      vga_pixels <= 36'b0;
	      vbuf <= 36'b0;
	   end
	   
	   state <= 2;
	end
	
	2: begin
	   vga_pixels <= vbuf;
	   state <= 0;
	end
      endcase
   end
endmodule
