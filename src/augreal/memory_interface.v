`default_nettype none
// comment out when testing
`include "params.v"
// memory_interface
// handles EVERYTHING ram related
// actual ram modules are instantiated in top module

module memory_interface
	(
		// STANDARD SIGNALS
		input 			   clock,
		input 			   reset,
		// NTSC_CAPTURE
		input 			   frame_flag,
		input 			   ntsc_flag,
		input [`LOG_MEM-1:0] 	   ntsc_pixel,
		output reg 		   done_ntsc,
		input [`LOG_WIDTH-1:0] ntsc_x,
		input [`LOG_HEIGHT-1:0] ntsc_y,
		// LPF
		input 			   lpf_flag,
		input 			   lpf_wr,
		input [`LOG_WIDTH-1:0] 	   lpf_x,
		input [`LOG_HEIGHT-1:0]    lpf_y,
		input [`LOG_MEM-1:0] 	   lpf_pixel_write,
		output reg 		   done_lpf,
		output reg [`LOG_MEM-1:0]  lpf_pixel_read,
		// PROJECTIVE_TRANSFORM
		input 			   pt_flag,
		input [`LOG_WIDTH-1:0] 	   pt_x,
		input [`LOG_HEIGHT-1:0]    pt_y,
		input [`LOG_TRUNC-1:0] 	   pt_pixel,
		output 			   done_pt,
		// VGA_WRITE
		input 			   vga_flag,
		output reg 		   done_vga,
		output reg [`LOG_MEM-1:0]  vga_pixel,
		input 	[`LOG_VCOUNT-1:0]		   vcount,
		input 	[`LOG_HCOUNT-1:0]		   hcount,
	 	input 			   vsync,
		// MEMORY
		// MEM ADDRESSES
		output reg [`LOG_ADDR-1:0] mem0_addr,
		output reg [`LOG_ADDR-1:0] mem1_addr, 
		// MEM READ	
		input [`LOG_MEM-1:0] 	   mem0_read,
		input [`LOG_MEM-1:0] 	   mem1_read,
		// MEM WRITE
		output reg [`LOG_MEM-1:0]  mem0_write,
		output reg [`LOG_MEM-1:0]  mem1_write,
		// WR FLAGS
		output reg 		   mem0_wr,
		output reg 		   mem1_wr,
		// TESTING
		output [3:0] 		   debug_blocks,
		output [7:0] 		   debug_locs
	);

	/******** PARAMETERS ********/
	// READ QUEUE LENGTH
	parameter QUEUE_LENGTH = 2;
	// MODULE ORDINALS
	parameter NTSC = 4'b1000;
	parameter VGA  = 4'b0100;
	parameter LPF  = 4'b0010;
	parameter PTF  = 4'b0001;
	parameter NONE = 4'b0000;
	parameter LOG_ORD = 4;
	/****************************/

	// PT_FETCHER
	wire ptf_flag;
	wire ptf_wr;
	wire [`LOG_WIDTH-1:0] ptf_x;
	wire [`LOG_HEIGHT-1:0] ptf_y;
	wire [`LOG_MEM-1:0] ptf_pixel_write;
	reg done_ptf;
	reg [`LOG_MEM-1:0] ptf_pixel_read;
	// INSTANTIATE pt_fetcher here

	// BLOCK OF SRAM IMAGE IS IN
	reg capt_mem_block;
	reg proc_mem_block;
	reg nexd_mem_block;
	reg disp_mem_block;

	// LOCATIONS OF IMAGES IN EACH BLOCK
	reg [1:0] capt_mem_loc;
	reg [1:0] proc_mem_loc;
	reg [1:0] nexd_mem_loc;	
	reg [1:0] disp_mem_loc;

	// ADDRESSES
	wire [`LOG_ADDR-1:0] ntsc_addr;
	wire [`LOG_ADDR-1:0] vga_addr;
	wire [`LOG_ADDR-1:0] lpf_addr;
	wire [`LOG_ADDR-1:0] ptf_addr;

	// PARTIAL DONE FLAGS
	reg [3:0] mem0_done;
	reg [3:0] mem1_done;
	
	// READ QUEUES
	reg [QUEUE_LENGTH*LOG_ORD-1:0] mem0_read_queue;
	reg [QUEUE_LENGTH*LOG_ORD-1:0] mem1_read_queue;
	reg [QUEUE_LENGTH*LOG_ORD-1:0] next_mem0_read_queue;
	reg [QUEUE_LENGTH*LOG_ORD-1:0] next_mem1_read_queue;
	// ELEMENTS AT END OF QUEUES
	reg [LOG_ORD-1:0] mem0_next_read;
	reg [LOG_ORD-1:0] mem1_next_read;

	// PREVIOUS LPF, VGA, AND PTF READ VALUES
	// (for stable vga_pixel, lpf_pixel_read, and ptf_pixel_read)
	reg [`LOG_MEM-1:0] prev_vga_pixel;
	reg [`LOG_MEM-1:0] prev_lpf_pixel_read;
	reg [`LOG_MEM-1:0] prev_ptf_pixel_read;

	// DEBUG
	assign debug_blocks = {capt_mem_block,proc_mem_block,nexd_mem_block,disp_mem_block};
	assign debug_locs = {capt_mem_loc, proc_mem_loc, nexd_mem_loc, disp_mem_loc};

	always @(*) begin
		// set address & write & done flags
		// assign write value to mem0 & mem1 based on who's writing
		if (!capt_mem_block && ntsc_flag) begin
			mem0_addr = ntsc_addr;
			mem0_write = ntsc_pixel;
			mem0_wr = 1;
			mem0_done = NTSC;
		end
		else if (!disp_mem_block && vga_flag) begin
			mem0_addr = vga_addr;
			mem0_wr = 0;
			mem0_done = VGA;
		end
		else if (!proc_mem_block && lpf_flag) begin
			mem0_addr = lpf_addr;
			mem0_write = lpf_pixel_write;
			mem0_wr = lpf_wr;
			mem0_done = LPF;
		end
		else if (!nexd_mem_block && ptf_flag) begin
			mem0_addr = ptf_addr;
			mem0_write = ptf_pixel_write;
			mem0_wr = ptf_wr;
			mem0_done = PTF;
		end 
		else begin // nothing's happening
			mem0_addr = 0;
			mem0_write = 0;
			mem0_wr = 0;
			mem0_done = NONE;
		end

		if (capt_mem_block && ntsc_flag) begin
			mem1_addr = ntsc_addr;
			mem1_write = ntsc_pixel;
			mem1_wr = 1;
			mem1_done = NTSC;
		end
		else if (disp_mem_block && vga_flag) begin
			mem1_addr = vga_addr;
			mem1_wr = 0;
			mem1_done = VGA;
		end
		else if (proc_mem_block && lpf_flag) begin
			mem1_addr = lpf_addr;
			mem1_write = lpf_pixel_write;
			mem1_wr = lpf_wr;
			mem1_done = LPF;
		end
		else if (nexd_mem_block && ptf_flag) begin
			mem1_addr = ptf_addr;
			mem1_write = ptf_pixel_write;
			mem1_wr = ptf_wr;
			mem1_done = PTF;
		end
		else begin // nothing's happening
			mem1_addr = 0;
			mem1_write = 0;
			mem1_wr = 0;
			mem1_done = NONE;
		end

		// set done flags
		done_ntsc = (mem0_done == NTSC) || (mem1_done == NTSC);
		done_vga  = (mem0_done == VGA)  || (mem1_done == VGA);
		done_lpf  = (mem0_done == LPF)  || (mem1_done == LPF);
		done_ptf  = (mem0_done == PTF)  || (mem1_done == PTF);

		// assign read value to corresponding member of queue
		mem0_next_read = mem0_read_queue[QUEUE_LENGTH*LOG_ORD-1:(QUEUE_LENGTH-1)*LOG_ORD];
		mem1_next_read = mem1_read_queue[QUEUE_LENGTH*LOG_ORD-1:(QUEUE_LENGTH-1)*LOG_ORD];
		
		// LPF's turn in the queue
		if (mem0_next_read == LPF) lpf_pixel_read = mem0_read;
		else if (mem1_next_read == LPF) lpf_pixel_read = mem1_read;
		else lpf_pixel_read = prev_lpf_pixel_read;

		// PTF's turn
		if (mem0_next_read == PTF) ptf_pixel_read = mem0_read;
		else if (mem1_next_read == PTF) ptf_pixel_read = mem1_read;
		else ptf_pixel_read = prev_ptf_pixel_read;

		// VGA's turn
		if (mem0_next_read == VGA) vga_pixel = mem0_read;
		else if (mem1_next_read == VGA) vga_pixel = mem1_read;
		else vga_pixel = prev_vga_pixel;

		// shifting of queue on next cycle
		next_mem0_read_queue[QUEUE_LENGTH*LOG_ORD-1:LOG_ORD] = mem0_read_queue[(QUEUE_LENGTH-1)*LOG_ORD-1:0];
		next_mem1_read_queue[QUEUE_LENGTH*LOG_ORD-1:LOG_ORD] = mem1_read_queue[(QUEUE_LENGTH-1)*LOG_ORD-1:0];

		// add new queue members, if any
		if (mem0_done == VGA) next_mem0_read_queue[LOG_ORD-1:0] = VGA;
		else if (mem0_done == LPF && !lpf_wr) next_mem0_read_queue[LOG_ORD-1:0] = LPF;
		else if (mem0_done == PTF && !ptf_wr) next_mem0_read_queue[LOG_ORD-1:0] = PTF;
		else next_mem0_read_queue[LOG_ORD-1:0] = NONE;

		if (mem1_done == VGA) next_mem1_read_queue[LOG_ORD-1:0] = VGA;
		else if (mem1_done == LPF && !lpf_wr) next_mem1_read_queue[LOG_ORD-1:0] = LPF;
		else if (mem1_done == PTF && !ptf_wr) next_mem1_read_queue[LOG_ORD-1:0] = PTF;
		else next_mem1_read_queue[LOG_ORD-1:0] = NONE;
		// this should be it
	end

	// set addresses of LPF and PTF from (x,y) coordinates
	// addr = y*(image_width/2) + lpf_x/2 + loc*(image_width*image_height/2)
	address_calculator lpf_ac(
		.x(lpf_x), .y(lpf_y), 
		.loc(proc_mem_loc), .addr(lpf_addr));
	address_calculator ptf_ac(
		.x(ptf_x), .y(ptf_y),
		.loc(nexd_mem_loc), .addr(ptf_addr));
	address_calculator vga_ac(
		.x(hcount), .y(vcount),
		.loc(disp_mem_loc), .addr(vga_addr));
	address_calculator ntsc_ac(
		.x(ntsc_x), .y(ntsc_y),
		.loc(capt_mem_loc), .addr(ntsc_addr));

	always @(posedge clock) begin
		// update blocks and locations of images in RAM
		if (reset) begin
			capt_mem_block 	<= 1'b0;
			capt_mem_loc 	<= 2'b00;
			proc_mem_block 	<= 1'b0;
			proc_mem_loc 	<= 2'b01;
			nexd_mem_block 	<= 1'b1;
			nexd_mem_loc 	<= 2'b00;
			disp_mem_block 	<= 1'b1;
			disp_mem_loc <= 2'b01;
		end
		else if (frame_flag) begin
			capt_mem_block 		<= proc_mem_block;
			capt_mem_loc 		<= proc_mem_loc;
			proc_mem_block 		<= disp_mem_block;
			proc_mem_loc 		<= disp_mem_loc;
			nexd_mem_block 		<= capt_mem_block;
			nexd_mem_loc 		<= capt_mem_loc;
			disp_mem_block 		<= nexd_mem_block;
			disp_mem_loc 		<= nexd_mem_loc;
		end
		else begin
			capt_mem_block 		<= capt_mem_block;
			capt_mem_loc		<= capt_mem_loc;
			proc_mem_block		<= proc_mem_block;
			proc_mem_loc		<= proc_mem_loc;
			nexd_mem_block		<= nexd_mem_block;
			nexd_mem_loc		<= nexd_mem_loc;
			disp_mem_block		<= disp_mem_block;
			disp_mem_loc		<= disp_mem_loc;
		end
		
		// update ntsc and vga addresses
		//if (reset || frame_flag) ntsc_addr <= (proc_mem_loc*`IMAGE_LENGTH);
		//else ntsc_addr <= (done_ntsc) ? (ntsc_addr+1) : ntsc_addr;	
		
		// update read queues
		mem0_read_queue <= next_mem0_read_queue;
		mem1_read_queue <= next_mem1_read_queue;

		// retain previous output pixel values
		prev_vga_pixel <= vga_pixel;
		prev_lpf_pixel_read <= lpf_pixel_read;
		prev_ptf_pixel_read <= ptf_pixel_read;
	end
endmodule

module zbt_6111(clk, cen, we, addr, write_data, read_data,
		ram_clk, ram_we_b, ram_address, ram_data, ram_cen_b);

	input clk;			// system clock
	input cen;			// clock enable for gating ZBT cycles
	input we;			// write enable (active HIGH)
	input [18:0] addr;		// memory address
	input [35:0] write_data;	// data to write
	output [35:0] read_data;	// data read from memory
	output 	 ram_clk;	// physical line to ram clock
	output 	 ram_we_b;	// physical line to ram we_b
	output [18:0] ram_address;	// physical line to ram address
	inout [35:0]  ram_data;	// physical line to ram data
	output 	 ram_cen_b;	// physical line to ram clock enable

	// clock enable (should be synchronous and one cycle high at a time)
	wire ram_cen_b = ~cen;

	// create delayed ram_we signal: note the delay is by two cycles!
	// ie we present the data to be written two cycles after we is raised 
	// this means the bus is tri-stated two cycles after we is raised.

	reg [1:0] we_delay;

	always @(posedge clk) begin
		we_delay <= cen ? {we_delay[0],we} : we_delay;
	end

	// create two-stage pipeline for write data
	reg [35:0]  write_data_old1;
	reg [35:0]  write_data_old2;

	always @(posedge clk) begin
		if (cen) {write_data_old2, write_data_old1} <= {write_data_old1, write_data};
	end
	
	// wire to ZBT RAM signals
	assign ram_we_b = ~we;
	assign ram_clk = 1'b0;  // gph 2011-Nov-10
	                              // set to zero as place holder
	//assign      ram_clk = ~clk;     // RAM is not happy with our data hold
                                   // times if its clk edges equal FPGA's
                                   // so we clock it on the falling edges
                                   // and thus let data stabilize longer

	assign ram_address = addr;
	assign ram_data = we_delay[1] ? write_data_old2 : {36{1'bZ}};
	assign read_data = ram_data;
endmodule // zbt_6111

module address_calculator(
		input [`LOG_WIDTH-1:0] x,
		input [`LOG_HEIGHT-1:0] y,
		input [1:0] loc,
		output [`LOG_ADDR-1:0] addr
	);

	wire [17:0] y_offset;
	wire [`LOG_IMAGE_ADDR-1:0] loc_offset;
	loc_lut llut(.loc(loc), .addr_off(loc_offset));
	y_lut ylut(.y(y), .addr_off(y_offset));
	assign addr = {9'd0, x[`LOG_WIDTH-1:1]} + {1'b0, y_offset} + loc_offset;
endmodule

module loc_lut(
	input [1:0] loc,
	output reg [18:0] addr_off
	);

	always @(*) begin
		case (loc)
			2'd0: addr_off = 19'd0;
			2'd1: addr_off = 19'd153600;
			2'd2: addr_off = 19'd307200;
			default: addr_off = 19'd0;
		endcase
	end
endmodule

module y_lut(
	input [8:0] y,
	output reg [17:0] addr_off
	);
	
	always @(*) begin
		case (y)
			9'd0: addr_off = 18'd0;
			9'd1: addr_off = 18'd320;
			9'd2: addr_off = 18'd640;
			9'd3: addr_off = 18'd960;
			9'd4: addr_off = 18'd1280;
			9'd5: addr_off = 18'd1600;
			9'd6: addr_off = 18'd1920;
			9'd7: addr_off = 18'd2240;
			9'd8: addr_off = 18'd2560;
			9'd9: addr_off = 18'd2880;
			9'd10: addr_off = 18'd3200;
			9'd11: addr_off = 18'd3520;
			9'd12: addr_off = 18'd3840;
			9'd13: addr_off = 18'd4160;
			9'd14: addr_off = 18'd4480;
			9'd15: addr_off = 18'd4800;
			9'd16: addr_off = 18'd5120;
			9'd17: addr_off = 18'd5440;
			9'd18: addr_off = 18'd5760;
			9'd19: addr_off = 18'd6080;
			9'd20: addr_off = 18'd6400;
			9'd21: addr_off = 18'd6720;
			9'd22: addr_off = 18'd7040;
			9'd23: addr_off = 18'd7360;
			9'd24: addr_off = 18'd7680;
			9'd25: addr_off = 18'd8000;
			9'd26: addr_off = 18'd8320;
			9'd27: addr_off = 18'd8640;
			9'd28: addr_off = 18'd8960;
			9'd29: addr_off = 18'd9280;
			9'd30: addr_off = 18'd9600;
			9'd31: addr_off = 18'd9920;
			9'd32: addr_off = 18'd10240;
			9'd33: addr_off = 18'd10560;
			9'd34: addr_off = 18'd10880;
			9'd35: addr_off = 18'd11200;
			9'd36: addr_off = 18'd11520;
			9'd37: addr_off = 18'd11840;
			9'd38: addr_off = 18'd12160;
			9'd39: addr_off = 18'd12480;
			9'd40: addr_off = 18'd12800;
			9'd41: addr_off = 18'd13120;
			9'd42: addr_off = 18'd13440;
			9'd43: addr_off = 18'd13760;
			9'd44: addr_off = 18'd14080;
			9'd45: addr_off = 18'd14400;
			9'd46: addr_off = 18'd14720;
			9'd47: addr_off = 18'd15040;
			9'd48: addr_off = 18'd15360;
			9'd49: addr_off = 18'd15680;
			9'd50: addr_off = 18'd16000;
			9'd51: addr_off = 18'd16320;
			9'd52: addr_off = 18'd16640;
			9'd53: addr_off = 18'd16960;
			9'd54: addr_off = 18'd17280;
			9'd55: addr_off = 18'd17600;
			9'd56: addr_off = 18'd17920;
			9'd57: addr_off = 18'd18240;
			9'd58: addr_off = 18'd18560;
			9'd59: addr_off = 18'd18880;
			9'd60: addr_off = 18'd19200;
			9'd61: addr_off = 18'd19520;
			9'd62: addr_off = 18'd19840;
			9'd63: addr_off = 18'd20160;
			9'd64: addr_off = 18'd20480;
			9'd65: addr_off = 18'd20800;
			9'd66: addr_off = 18'd21120;
			9'd67: addr_off = 18'd21440;
			9'd68: addr_off = 18'd21760;
			9'd69: addr_off = 18'd22080;
			9'd70: addr_off = 18'd22400;
			9'd71: addr_off = 18'd22720;
			9'd72: addr_off = 18'd23040;
			9'd73: addr_off = 18'd23360;
			9'd74: addr_off = 18'd23680;
			9'd75: addr_off = 18'd24000;
			9'd76: addr_off = 18'd24320;
			9'd77: addr_off = 18'd24640;
			9'd78: addr_off = 18'd24960;
			9'd79: addr_off = 18'd25280;
			9'd80: addr_off = 18'd25600;
			9'd81: addr_off = 18'd25920;
			9'd82: addr_off = 18'd26240;
			9'd83: addr_off = 18'd26560;
			9'd84: addr_off = 18'd26880;
			9'd85: addr_off = 18'd27200;
			9'd86: addr_off = 18'd27520;
			9'd87: addr_off = 18'd27840;
			9'd88: addr_off = 18'd28160;
			9'd89: addr_off = 18'd28480;
			9'd90: addr_off = 18'd28800;
			9'd91: addr_off = 18'd29120;
			9'd92: addr_off = 18'd29440;
			9'd93: addr_off = 18'd29760;
			9'd94: addr_off = 18'd30080;
			9'd95: addr_off = 18'd30400;
			9'd96: addr_off = 18'd30720;
			9'd97: addr_off = 18'd31040;
			9'd98: addr_off = 18'd31360;
			9'd99: addr_off = 18'd31680;
			9'd100: addr_off = 18'd32000;
			9'd101: addr_off = 18'd32320;
			9'd102: addr_off = 18'd32640;
			9'd103: addr_off = 18'd32960;
			9'd104: addr_off = 18'd33280;
			9'd105: addr_off = 18'd33600;
			9'd106: addr_off = 18'd33920;
			9'd107: addr_off = 18'd34240;
			9'd108: addr_off = 18'd34560;
			9'd109: addr_off = 18'd34880;
			9'd110: addr_off = 18'd35200;
			9'd111: addr_off = 18'd35520;
			9'd112: addr_off = 18'd35840;
			9'd113: addr_off = 18'd36160;
			9'd114: addr_off = 18'd36480;
			9'd115: addr_off = 18'd36800;
			9'd116: addr_off = 18'd37120;
			9'd117: addr_off = 18'd37440;
			9'd118: addr_off = 18'd37760;
			9'd119: addr_off = 18'd38080;
			9'd120: addr_off = 18'd38400;
			9'd121: addr_off = 18'd38720;
			9'd122: addr_off = 18'd39040;
			9'd123: addr_off = 18'd39360;
			9'd124: addr_off = 18'd39680;
			9'd125: addr_off = 18'd40000;
			9'd126: addr_off = 18'd40320;
			9'd127: addr_off = 18'd40640;
			9'd128: addr_off = 18'd40960;
			9'd129: addr_off = 18'd41280;
			9'd130: addr_off = 18'd41600;
			9'd131: addr_off = 18'd41920;
			9'd132: addr_off = 18'd42240;
			9'd133: addr_off = 18'd42560;
			9'd134: addr_off = 18'd42880;
			9'd135: addr_off = 18'd43200;
			9'd136: addr_off = 18'd43520;
			9'd137: addr_off = 18'd43840;
			9'd138: addr_off = 18'd44160;
			9'd139: addr_off = 18'd44480;
			9'd140: addr_off = 18'd44800;
			9'd141: addr_off = 18'd45120;
			9'd142: addr_off = 18'd45440;
			9'd143: addr_off = 18'd45760;
			9'd144: addr_off = 18'd46080;
			9'd145: addr_off = 18'd46400;
			9'd146: addr_off = 18'd46720;
			9'd147: addr_off = 18'd47040;
			9'd148: addr_off = 18'd47360;
			9'd149: addr_off = 18'd47680;
			9'd150: addr_off = 18'd48000;
			9'd151: addr_off = 18'd48320;
			9'd152: addr_off = 18'd48640;
			9'd153: addr_off = 18'd48960;
			9'd154: addr_off = 18'd49280;
			9'd155: addr_off = 18'd49600;
			9'd156: addr_off = 18'd49920;
			9'd157: addr_off = 18'd50240;
			9'd158: addr_off = 18'd50560;
			9'd159: addr_off = 18'd50880;
			9'd160: addr_off = 18'd51200;
			9'd161: addr_off = 18'd51520;
			9'd162: addr_off = 18'd51840;
			9'd163: addr_off = 18'd52160;
			9'd164: addr_off = 18'd52480;
			9'd165: addr_off = 18'd52800;
			9'd166: addr_off = 18'd53120;
			9'd167: addr_off = 18'd53440;
			9'd168: addr_off = 18'd53760;
			9'd169: addr_off = 18'd54080;
			9'd170: addr_off = 18'd54400;
			9'd171: addr_off = 18'd54720;
			9'd172: addr_off = 18'd55040;
			9'd173: addr_off = 18'd55360;
			9'd174: addr_off = 18'd55680;
			9'd175: addr_off = 18'd56000;
			9'd176: addr_off = 18'd56320;
			9'd177: addr_off = 18'd56640;
			9'd178: addr_off = 18'd56960;
			9'd179: addr_off = 18'd57280;
			9'd180: addr_off = 18'd57600;
			9'd181: addr_off = 18'd57920;
			9'd182: addr_off = 18'd58240;
			9'd183: addr_off = 18'd58560;
			9'd184: addr_off = 18'd58880;
			9'd185: addr_off = 18'd59200;
			9'd186: addr_off = 18'd59520;
			9'd187: addr_off = 18'd59840;
			9'd188: addr_off = 18'd60160;
			9'd189: addr_off = 18'd60480;
			9'd190: addr_off = 18'd60800;
			9'd191: addr_off = 18'd61120;
			9'd192: addr_off = 18'd61440;
			9'd193: addr_off = 18'd61760;
			9'd194: addr_off = 18'd62080;
			9'd195: addr_off = 18'd62400;
			9'd196: addr_off = 18'd62720;
			9'd197: addr_off = 18'd63040;
			9'd198: addr_off = 18'd63360;
			9'd199: addr_off = 18'd63680;
			9'd200: addr_off = 18'd64000;
			9'd201: addr_off = 18'd64320;
			9'd202: addr_off = 18'd64640;
			9'd203: addr_off = 18'd64960;
			9'd204: addr_off = 18'd65280;
			9'd205: addr_off = 18'd65600;
			9'd206: addr_off = 18'd65920;
			9'd207: addr_off = 18'd66240;
			9'd208: addr_off = 18'd66560;
			9'd209: addr_off = 18'd66880;
			9'd210: addr_off = 18'd67200;
			9'd211: addr_off = 18'd67520;
			9'd212: addr_off = 18'd67840;
			9'd213: addr_off = 18'd68160;
			9'd214: addr_off = 18'd68480;
			9'd215: addr_off = 18'd68800;
			9'd216: addr_off = 18'd69120;
			9'd217: addr_off = 18'd69440;
			9'd218: addr_off = 18'd69760;
			9'd219: addr_off = 18'd70080;
			9'd220: addr_off = 18'd70400;
			9'd221: addr_off = 18'd70720;
			9'd222: addr_off = 18'd71040;
			9'd223: addr_off = 18'd71360;
			9'd224: addr_off = 18'd71680;
			9'd225: addr_off = 18'd72000;
			9'd226: addr_off = 18'd72320;
			9'd227: addr_off = 18'd72640;
			9'd228: addr_off = 18'd72960;
			9'd229: addr_off = 18'd73280;
			9'd230: addr_off = 18'd73600;
			9'd231: addr_off = 18'd73920;
			9'd232: addr_off = 18'd74240;
			9'd233: addr_off = 18'd74560;
			9'd234: addr_off = 18'd74880;
			9'd235: addr_off = 18'd75200;
			9'd236: addr_off = 18'd75520;
			9'd237: addr_off = 18'd75840;
			9'd238: addr_off = 18'd76160;
			9'd239: addr_off = 18'd76480;
			9'd240: addr_off = 18'd76800;
			9'd241: addr_off = 18'd77120;
			9'd242: addr_off = 18'd77440;
			9'd243: addr_off = 18'd77760;
			9'd244: addr_off = 18'd78080;
			9'd245: addr_off = 18'd78400;
			9'd246: addr_off = 18'd78720;
			9'd247: addr_off = 18'd79040;
			9'd248: addr_off = 18'd79360;
			9'd249: addr_off = 18'd79680;
			9'd250: addr_off = 18'd80000;
			9'd251: addr_off = 18'd80320;
			9'd252: addr_off = 18'd80640;
			9'd253: addr_off = 18'd80960;
			9'd254: addr_off = 18'd81280;
			9'd255: addr_off = 18'd81600;
			9'd256: addr_off = 18'd81920;
			9'd257: addr_off = 18'd82240;
			9'd258: addr_off = 18'd82560;
			9'd259: addr_off = 18'd82880;
			9'd260: addr_off = 18'd83200;
			9'd261: addr_off = 18'd83520;
			9'd262: addr_off = 18'd83840;
			9'd263: addr_off = 18'd84160;
			9'd264: addr_off = 18'd84480;
			9'd265: addr_off = 18'd84800;
			9'd266: addr_off = 18'd85120;
			9'd267: addr_off = 18'd85440;
			9'd268: addr_off = 18'd85760;
			9'd269: addr_off = 18'd86080;
			9'd270: addr_off = 18'd86400;
			9'd271: addr_off = 18'd86720;
			9'd272: addr_off = 18'd87040;
			9'd273: addr_off = 18'd87360;
			9'd274: addr_off = 18'd87680;
			9'd275: addr_off = 18'd88000;
			9'd276: addr_off = 18'd88320;
			9'd277: addr_off = 18'd88640;
			9'd278: addr_off = 18'd88960;
			9'd279: addr_off = 18'd89280;
			9'd280: addr_off = 18'd89600;
			9'd281: addr_off = 18'd89920;
			9'd282: addr_off = 18'd90240;
			9'd283: addr_off = 18'd90560;
			9'd284: addr_off = 18'd90880;
			9'd285: addr_off = 18'd91200;
			9'd286: addr_off = 18'd91520;
			9'd287: addr_off = 18'd91840;
			9'd288: addr_off = 18'd92160;
			9'd289: addr_off = 18'd92480;
			9'd290: addr_off = 18'd92800;
			9'd291: addr_off = 18'd93120;
			9'd292: addr_off = 18'd93440;
			9'd293: addr_off = 18'd93760;
			9'd294: addr_off = 18'd94080;
			9'd295: addr_off = 18'd94400;
			9'd296: addr_off = 18'd94720;
			9'd297: addr_off = 18'd95040;
			9'd298: addr_off = 18'd95360;
			9'd299: addr_off = 18'd95680;
			9'd300: addr_off = 18'd96000;
			9'd301: addr_off = 18'd96320;
			9'd302: addr_off = 18'd96640;
			9'd303: addr_off = 18'd96960;
			9'd304: addr_off = 18'd97280;
			9'd305: addr_off = 18'd97600;
			9'd306: addr_off = 18'd97920;
			9'd307: addr_off = 18'd98240;
			9'd308: addr_off = 18'd98560;
			9'd309: addr_off = 18'd98880;
			9'd310: addr_off = 18'd99200;
			9'd311: addr_off = 18'd99520;
			9'd312: addr_off = 18'd99840;
			9'd313: addr_off = 18'd100160;
			9'd314: addr_off = 18'd100480;
			9'd315: addr_off = 18'd100800;
			9'd316: addr_off = 18'd101120;
			9'd317: addr_off = 18'd101440;
			9'd318: addr_off = 18'd101760;
			9'd319: addr_off = 18'd102080;
			9'd320: addr_off = 18'd102400;
			9'd321: addr_off = 18'd102720;
			9'd322: addr_off = 18'd103040;
			9'd323: addr_off = 18'd103360;
			9'd324: addr_off = 18'd103680;
			9'd325: addr_off = 18'd104000;
			9'd326: addr_off = 18'd104320;
			9'd327: addr_off = 18'd104640;
			9'd328: addr_off = 18'd104960;
			9'd329: addr_off = 18'd105280;
			9'd330: addr_off = 18'd105600;
			9'd331: addr_off = 18'd105920;
			9'd332: addr_off = 18'd106240;
			9'd333: addr_off = 18'd106560;
			9'd334: addr_off = 18'd106880;
			9'd335: addr_off = 18'd107200;
			9'd336: addr_off = 18'd107520;
			9'd337: addr_off = 18'd107840;
			9'd338: addr_off = 18'd108160;
			9'd339: addr_off = 18'd108480;
			9'd340: addr_off = 18'd108800;
			9'd341: addr_off = 18'd109120;
			9'd342: addr_off = 18'd109440;
			9'd343: addr_off = 18'd109760;
			9'd344: addr_off = 18'd110080;
			9'd345: addr_off = 18'd110400;
			9'd346: addr_off = 18'd110720;
			9'd347: addr_off = 18'd111040;
			9'd348: addr_off = 18'd111360;
			9'd349: addr_off = 18'd111680;
			9'd350: addr_off = 18'd112000;
			9'd351: addr_off = 18'd112320;
			9'd352: addr_off = 18'd112640;
			9'd353: addr_off = 18'd112960;
			9'd354: addr_off = 18'd113280;
			9'd355: addr_off = 18'd113600;
			9'd356: addr_off = 18'd113920;
			9'd357: addr_off = 18'd114240;
			9'd358: addr_off = 18'd114560;
			9'd359: addr_off = 18'd114880;
			9'd360: addr_off = 18'd115200;
			9'd361: addr_off = 18'd115520;
			9'd362: addr_off = 18'd115840;
			9'd363: addr_off = 18'd116160;
			9'd364: addr_off = 18'd116480;
			9'd365: addr_off = 18'd116800;
			9'd366: addr_off = 18'd117120;
			9'd367: addr_off = 18'd117440;
			9'd368: addr_off = 18'd117760;
			9'd369: addr_off = 18'd118080;
			9'd370: addr_off = 18'd118400;
			9'd371: addr_off = 18'd118720;
			9'd372: addr_off = 18'd119040;
			9'd373: addr_off = 18'd119360;
			9'd374: addr_off = 18'd119680;
			9'd375: addr_off = 18'd120000;
			9'd376: addr_off = 18'd120320;
			9'd377: addr_off = 18'd120640;
			9'd378: addr_off = 18'd120960;
			9'd379: addr_off = 18'd121280;
			9'd380: addr_off = 18'd121600;
			9'd381: addr_off = 18'd121920;
			9'd382: addr_off = 18'd122240;
			9'd383: addr_off = 18'd122560;
			9'd384: addr_off = 18'd122880;
			9'd385: addr_off = 18'd123200;
			9'd386: addr_off = 18'd123520;
			9'd387: addr_off = 18'd123840;
			9'd388: addr_off = 18'd124160;
			9'd389: addr_off = 18'd124480;
			9'd390: addr_off = 18'd124800;
			9'd391: addr_off = 18'd125120;
			9'd392: addr_off = 18'd125440;
			9'd393: addr_off = 18'd125760;
			9'd394: addr_off = 18'd126080;
			9'd395: addr_off = 18'd126400;
			9'd396: addr_off = 18'd126720;
			9'd397: addr_off = 18'd127040;
			9'd398: addr_off = 18'd127360;
			9'd399: addr_off = 18'd127680;
			9'd400: addr_off = 18'd128000;
			9'd401: addr_off = 18'd128320;
			9'd402: addr_off = 18'd128640;
			9'd403: addr_off = 18'd128960;
			9'd404: addr_off = 18'd129280;
			9'd405: addr_off = 18'd129600;
			9'd406: addr_off = 18'd129920;
			9'd407: addr_off = 18'd130240;
			9'd408: addr_off = 18'd130560;
			9'd409: addr_off = 18'd130880;
			9'd410: addr_off = 18'd131200;
			9'd411: addr_off = 18'd131520;
			9'd412: addr_off = 18'd131840;
			9'd413: addr_off = 18'd132160;
			9'd414: addr_off = 18'd132480;
			9'd415: addr_off = 18'd132800;
			9'd416: addr_off = 18'd133120;
			9'd417: addr_off = 18'd133440;
			9'd418: addr_off = 18'd133760;
			9'd419: addr_off = 18'd134080;
			9'd420: addr_off = 18'd134400;
			9'd421: addr_off = 18'd134720;
			9'd422: addr_off = 18'd135040;
			9'd423: addr_off = 18'd135360;
			9'd424: addr_off = 18'd135680;
			9'd425: addr_off = 18'd136000;
			9'd426: addr_off = 18'd136320;
			9'd427: addr_off = 18'd136640;
			9'd428: addr_off = 18'd136960;
			9'd429: addr_off = 18'd137280;
			9'd430: addr_off = 18'd137600;
			9'd431: addr_off = 18'd137920;
			9'd432: addr_off = 18'd138240;
			9'd433: addr_off = 18'd138560;
			9'd434: addr_off = 18'd138880;
			9'd435: addr_off = 18'd139200;
			9'd436: addr_off = 18'd139520;
			9'd437: addr_off = 18'd139840;
			9'd438: addr_off = 18'd140160;
			9'd439: addr_off = 18'd140480;
			9'd440: addr_off = 18'd140800;
			9'd441: addr_off = 18'd141120;
			9'd442: addr_off = 18'd141440;
			9'd443: addr_off = 18'd141760;
			9'd444: addr_off = 18'd142080;
			9'd445: addr_off = 18'd142400;
			9'd446: addr_off = 18'd142720;
			9'd447: addr_off = 18'd143040;
			9'd448: addr_off = 18'd143360;
			9'd449: addr_off = 18'd143680;
			9'd450: addr_off = 18'd144000;
			9'd451: addr_off = 18'd144320;
			9'd452: addr_off = 18'd144640;
			9'd453: addr_off = 18'd144960;
			9'd454: addr_off = 18'd145280;
			9'd455: addr_off = 18'd145600;
			9'd456: addr_off = 18'd145920;
			9'd457: addr_off = 18'd146240;
			9'd458: addr_off = 18'd146560;
			9'd459: addr_off = 18'd146880;
			9'd460: addr_off = 18'd147200;
			9'd461: addr_off = 18'd147520;
			9'd462: addr_off = 18'd147840;
			9'd463: addr_off = 18'd148160;
			9'd464: addr_off = 18'd148480;
			9'd465: addr_off = 18'd148800;
			9'd466: addr_off = 18'd149120;
			9'd467: addr_off = 18'd149440;
			9'd468: addr_off = 18'd149760;
			9'd469: addr_off = 18'd150080;
			9'd470: addr_off = 18'd150400;
			9'd471: addr_off = 18'd150720;
			9'd472: addr_off = 18'd151040;
			9'd473: addr_off = 18'd151360;
			9'd474: addr_off = 18'd151680;
			9'd475: addr_off = 18'd152000;
			9'd476: addr_off = 18'd152320;
			9'd477: addr_off = 18'd152640;
			9'd478: addr_off = 18'd152960;
			9'd479: addr_off = 18'd153280;
			default: addr_off = 18'd0;
		endcase
	end
endmodule
/* FOR REFERENCE
	// SRAMs
   assign ram0_data = 36'hZ;
   assign ram0_address = 19'h0;
   assign ram0_adv_ld = 1'b0;
   assign ram0_clk = 1'b0;
   assign ram0_cen_b = 1'b1;
   assign ram0_ce_b = 1'b1;
   assign ram0_oe_b = 1'b1;
   assign ram0_we_b = 1'b1;
   assign ram0_bwe_b = 4'hF;
   assign ram1_data = 36'hZ; 
   assign ram1_address = 19'h0;
   assign ram1_adv_ld = 1'b0;
   assign ram1_clk = 1'b0;
   assign ram1_cen_b = 1'b1;
   assign ram1_ce_b = 1'b1;
   assign ram1_oe_b = 1'b1;
   assign ram1_we_b = 1'b1;
   assign ram1_bwe_b = 4'hF;
   assign clock_feedback_out = 1'b0;
*/
