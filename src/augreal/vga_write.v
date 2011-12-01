`include "params.v"
`default_nettype none

module vga_write
	(
		// STANDARD INPUTS
		input clock,
		input vclock,
		input reset,
		input frame_flag,
		// MEMORY_INTERFACE
		input [`LOG_MEM-1:0] vga_pixel,
		input done_vga,
		output reg vga_flag,
		// VGA
		output reg [7:0] vga_out_red,
		output reg [7:0] vga_out_green,
		output reg [7:0] vga_out_blue,
		output reg vga_out_sync_b,
		output reg vga_out_blank_b,
		output reg vga_out_pixel_clock,
		output reg vga_out_hsync,
		output reg vga_out_vsync,
		// DEBUG
		output [`LOG_HCOUNT-1:0] clocked_hcount,
		output [`LOG_VCOUNT-1:0] clocked_vcount
	 );

	wire [`LOG_HCOUNT-1:0] hcount;
	wire [`LOG_VCOUNT-1:0] vcount;
	wire hsync, vsync, blank;

	xvga xvga1(.vclock(vclock), .reset(reset), .hcount(hcount), .vcount(vcount), .vsync(vsync), .hsync(hsync), .blank(blank));

	// indices
	reg [2:0] v_index;
	reg [2:0] c_index;

	// write enables
	reg v_we;
	reg c_we;

	// read by cindex
	wire c_hsync;
	wire c_vsync;
	wire c_blank;
	wire [`LOG_HCOUNT-1:0] c_hcount;
	wire [`LOG_VCOUNT-1:0] c_vcount;
	wire [`LOG_FULL-1:0] c_pixel;

	// read by vindex
	wire v_hsync;
	wire v_vsync;
	wire v_blank;
	wire [`LOG_HCOUNT-1:0] v_hcount;
	wire [`LOG_VCOUNT-1:0] v_vcount;
	wire [`LOG_FULL-1:0] v_pixel;

	// written by vindex
	reg w_hsync;
	reg w_vsync;
	reg w_blank;
	reg [`LOG_HCOUNT-1:0] w_hcount;
	reg [`LOG_VCOUNT-1:0] w_vcount;

	// written by cindex
	reg [`LOG_FULL-1:0] w_pixel;

	// vclock mems
	arsw_mem8 #(.S(1)) hsync_buf(
		.reset(reset), .clock(vclock), .we(v_we), .write_index(v_index), 
		.read1_index(c_index), .read2_index(v_index), 
		.read1_data(c_hsync), .read2_data(v_hsync), .write_data(w_hsync));
	arsw_mem8 #(.S(1)) vsync_buf(
		.reset(reset), .clock(vclock), .we(v_we), .write_index(v_index), 
		.read1_index(c_index), .read2_index(v_index), 
		.read1_data(c_vsync), .read2_data(v_vsync), .write_data(w_vsync));
	arsw_mem8 #(.S(1)) blank_buf(
		.reset(reset), .clock(vclock), .we(v_we), .write_index(v_index), 
		.read1_index(c_index), .read2_index(v_index), 
		.read1_data(c_blank), .read2_data(v_blank), .write_data(w_blank));
	arsw_mem8 #(.S(`LOG_HCOUNT)) hcount_buf(
		.reset(reset), .clock(vclock), .we(v_we), .write_index(v_index), 
		.read1_index(c_index), .read2_index(v_index), 
		.read1_data(c_hcount), .read2_data(v_hcount), .write_data(w_hcount));
	arsw_mem8 #(.S(`LOG_VCOUNT)) vcount_buf(
		.reset(reset), .clock(vclock), .we(v_we), .write_index(v_index), 
		.read1_index(c_index), .read2_index(v_index), 
		.read1_data(c_vcount), .read2_data(v_vcount),. write_data(w_vcount));
	// clock mem
	arsw_mem8 #(.S(`LOG_FULL)) pixel_buf(
		.reset(reset), .clock(clock), .we(c_we), .write_index(c_index), 
		.read1_index(c_index), .read2_index(v_index), 
		.read1_data(c_pixel), .read2_data(v_pixel), .write_data(w_pixel));

	// clock state variables
	reg [1:0] c_state;
	reg write_next;
	parameter REQUESTING 	= 2'd0;
	parameter WAITING	 	= 2'd1;
	parameter READING 		= 2'd2;
	parameter OUT_OF_BOUNDS	= 2'd3;

	// vclock state variables
	reg v_state;
	parameter STARTING_UP 	= 1'b0;
	parameter STEADY_STATE 	= 1'b1;

	reg out_of_bounds;

	always @(*) begin
		out_of_bounds = c_hcount >= 640 || c_vcount >= 480;
		vga_flag = (!reset && !frame_flag && !out_of_bounds 
					&& c_state == REQUESTING && (v_index-c_index) > 2);
		if (out_of_bounds) w_pixel = `LOG_FULL'b0;
		else if (!write_next) w_pixel = {vga_pixel[`LOG_MEM-1:`LOG_TRUNC], 6'b00};
		else w_pixel = {vga_pixel[`LOG_TRUNC-1:0], 6'b00};
		c_we = (c_state == READING) || (c_state == OUT_OF_BOUNDS) || (write_next);
	end

	always @(posedge clock) begin
		if (reset) begin
			c_state <= REQUESTING;
			c_index <= 3'd0;
			write_next <= 0;
		end
		else case (c_state)
			REQUESTING: begin
				if (vga_flag) c_state <= WAITING;
				else if (out_of_bounds) c_state <= OUT_OF_BOUNDS;
				else c_state <= c_state;
				
				if (write_next) c_index <= c_index+1;
				else c_index <= c_index;
				
				write_next <= 0;
			end
			WAITING: begin
				c_state <= READING;
				c_index <= c_index;
				write_next <= 0;
			end
			READING, OUT_OF_BOUNDS: begin
				c_state <= REQUESTING;
				c_index <= c_index+1;
				write_next <= 1;
			end
			default: begin
				c_state <= REQUESTING;
				c_index <= 3'd0;
				write_next <= 0;
			end
		endcase
	end

	always @(*) begin
		w_hsync = hsync;
		w_vsync = vsync;
		w_blank = blank;
		w_hcount = hcount;
		w_vcount = vcount;
		case (v_state)
			STEADY_STATE: begin
				vga_out_sync_b = 1'b1;
				vga_out_pixel_clock = ~vclock;
			end
			STARTING_UP: begin
				vga_out_sync_b = 1'bX;
				vga_out_pixel_clock = 1'b0;
			end
	end
	always @(posedge vclock) begin
		case (v_state)
			STEADY_STATE: begin
				//vga_out_red = v_pixel[23:16];
				//vga_out_green = v_pixel[15:8];
				//vga_out_blue = v_pixel[7:0];
				vga_out_red <= v_pixel[23:16];
				vga_out_blue <= v_pixel[23:16];
				vga_out_green <= v_pixel[23:16];
				vga_out_blank_b <= ~v_blank;
				vga_out_hsync <= v_hsync;
				vga_out_vsync <= v_vsync;
			end
			STARTING_UP: begin
				vga_out_red <= 8'hX;
				vga_out_green <= 8'hX;
				vga_out_blue <= 8'hX;
				vga_out_blank_b <= 1'bX;
				vga_out_hsync <= 1'bX;
				vga_out_vsync <= 1'bX;
			end
		endcase
	end

	always @(posedge vclock) begin
		if (reset) begin
			v_we <= 1'b1;
			v_index <= 3'd0;
			v_state <= STARTING_UP;
		end
		else begin
			v_we <= 1'b1;
			v_index <= v_index+1;
			case (v_state)
				STARTING_UP:
					v_state <= (v_index == 7) ? STEADY_STATE : STARTING_UP;
				default:
					v_state <= v_state;
			endcase
		end
	end

	// DEBUGGING
	assign clocked_hcount = c_hcount;
	assign clocked_vcount = c_vcount;
endmodule

////////////////////////////////////////////////////////////////////////////////
//
// xvga: Generate XVGA display signals (640 x 480 @ 60Hz)
//
////////////////////////////////////////////////////////////////////////////////
module xvga
	(
		input vclock,
		input reset,
		input frame_flag,
		output reg [`LOG_HCOUNT-1:0] hcount,    // pixel number on current line
		output reg [`LOG_VCOUNT-1:0] vcount,	 // line number
		output reg vsync, hsync, blank
	);

	// horizontal: 800 pixels total
	// display 640 pixels per line
	reg hblank,vblank;
	wire hsyncon,hsyncoff,hreset,hblankon;
	assign hblankon = (hcount == `VGA_HBLANKON);    
	assign hsyncon = (hcount == `VGA_HSYNCON); // activated at end of front porch
	assign hsyncoff = (hcount == `VGA_HSYNCOFF); // activated at end of sync interval
	assign hreset = (hcount == `VGA_HRESET); // activated at end of 

	// vertical: 524 lines total
	// display 480 lines
	wire vsyncon,vsyncoff,vreset,vblankon;
	assign vblankon = hreset & (vcount == `VGA_VBLANKON);    
	assign vsyncon = hreset & (vcount == `VGA_VSYNCON);
	assign vsyncoff = hreset & (vcount == `VGA_VSYNCOFF);
	assign vreset = hreset & (vcount == `VGA_VRESET);

	// sync and blanking
	wire next_hblank,next_vblank;
	assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
	assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   
	always @(posedge vclock) begin
		// TODO: revise this section
		// is it necessary?
		if (reset) begin
			hcount <= 0;
			hblank <= 0;
			hsync <= 1;

			vcount <= 0;
			vblank <= 0;
			vsync <= 1;

			blank <= 0;
		end
		else begin
			hcount <= hreset ? 0 : hcount + 1;
			hblank <= next_hblank;
			hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low

			vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
			vblank <= next_vblank;
			vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low

			blank <= next_vblank | (next_hblank & ~hreset);
		end
   	end
endmodule

// dual async read, sync write memory
module arsw_mem8 #(parameter S=1) 
	(
		input reset,
		input clock,
		input we,
		input [2:0] write_index,
		input [2:0] read1_index,
		input [2:0] read2_index,
		output reg [S-1:0] read1_data,
		output reg [S-1:0] read2_data,
		input [S-1:0] write_data
	);

	reg [8*S-1:0] data;

	always @(*) begin
		case (read1_index)
			0: read1_data = data[1*S-1:0*S];
			1: read1_data = data[2*S-1:1*S];
			2: read1_data = data[3*S-1:2*S];
			3: read1_data = data[4*S-1:3*S];
			4: read1_data = data[5*S-1:4*S];
			5: read1_data = data[6*S-1:5*S];
			6: read1_data = data[7*S-1:6*S];
			7: read1_data = data[8*S-1:7*S];
		endcase

		case (read2_index)
			0: read2_data = data[1*S-1:0*S];
			1: read2_data = data[2*S-1:1*S];
			2: read2_data = data[3*S-1:2*S];
			3: read2_data = data[4*S-1:3*S];
			4: read2_data = data[5*S-1:4*S];
			5: read2_data = data[6*S-1:5*S];
			6: read2_data = data[7*S-1:6*S];
			7: read2_data = data[8*S-1:7*S];
		endcase
	end

	always @(posedge clock) begin
		if (reset) begin
			data <= {(8*S){1'b0}};
		end
		else case (write_index)
			0: data <= {data[8*S-1:1*S], write_data};
			1: data <= {data[8*S-1:2*S], write_data, data[1*S-1:0]};
			2: data <= {data[8*S-1:3*S], write_data, data[2*S-1:0]};
			3: data <= {data[8*S-1:4*S], write_data, data[3*S-1:0]};
			4: data <= {data[8*S-1:5*S], write_data, data[4*S-1:0]};
			5: data <= {data[8*S-1:6*S], write_data, data[5*S-1:0]};
			6: data <= {data[8*S-1:7*S], write_data, data[6*S-1:0]};
			7: data <= 					{write_data, data[7*S-1:0]};
		endcase
	end
endmodule
