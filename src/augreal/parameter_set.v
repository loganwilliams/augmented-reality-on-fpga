// parameter_set
// used for setting the parameters used by NTSC
// in order to detect "interesting" pixels
module parameter_set(
	input clock, reset,	
	input [4:0] switch,
	output [63:0] hex_output,

	output reg [9:0] GREEN_LUM_MAX,
	output reg [9:0] GREEN_LUM_MIN,
	output reg [9:0] GREEN_CR_MAX,
	output reg [9:0] GREEN_CR_MIN,
	output reg [9:0] GREEN_CB_MAX,
	output reg [9:0] GREEN_CB_MIN,
	
	output reg [9:0] ORANGE_LUM_MAX,
	output reg [9:0] ORANGE_LUM_MIN,
	output reg [9:0] ORANGE_CR_MAX,
	output reg [9:0] ORANGE_CR_MIN,
	output reg [9:0] ORANGE_CB_MAX,
	output reg [9:0] ORANGE_CB_MIN,
	
	output reg [9:0] PINK_LUM_MAX,
	output reg [9:0] PINK_LUM_MIN,
	output reg [9:0] PINK_CR_MAX,
	output reg [9:0] PINK_CR_MIN,
	output reg [9:0] PINK_CB_MAX,
	output reg [9:0] PINK_CB_MIN,
	
	output reg [9:0] BLUE_LUM_MAX,
	output reg [9:0] BLUE_LUM_MIN,
	output reg [9:0] BLUE_CR_MAX,
	output reg [9:0] BLUE_CR_MIN,
	output reg [9:0] BLUE_CB_MAX,
	output reg [9:0] BLUE_CB_MIN
);

	wire SELECT_LUM_MAX;
	wire SELECT_LUM_MIN;
	wire SELECT_CR_MAX;
	wire SELECT_CR_MIN;
	wire SELECT_CB_MAX;
	wire SELECT_CB_MIN;

	wire [2:0] SELECT;
	reg [9:0] selected_parameter;
	wire [1:0] selected_color;
	
	reg [9:0] LUM_MAX;
	reg [9:0] LUM_MIN;
	reg [9:0] CR_MAX;
	reg [9:0] CR_MIN;
	reg [9:0] CB_MAX;
	reg [9:0] CB_MIN;

	wire b_clock;
	counter #(.PERIOD(2000000)) bclk(.clock(clock), .reset(reset),
		.enable(b_clock));
	
	debounce dbc1(.clock(clock), .reset(reset), .noisy(switch[4]), .clean(SELECT[2]));
	debounce dbc2(.clock(clock), .reset(reset), .noisy(switch[3]), .clean(SELECT[1]));
	debounce dbc3(.clock(clock), .reset(reset), .noisy(switch[2]), .clean(SELECT[0]));
	debounce dbc4(.clock(clock), .reset(reset), .noisy(switch[1]), .clean(selected_color[1]));
	debounce dbc5(.clock(clock), .reset(reset), .noisy(switch[0]), .clean(selected_color[0]));

	assign hex_output = {2'd0, selected_color, 4'd0, 5'd0, SELECT, 6'd0, selected_parameter, 32'h0},

	always @(*) begin
		case (selected_color)
		2'd0: begin
			LUM_MAX = GREEN_LUM_MAX;
			LUM_MIN = GREEN_LUM_MIN;
			CR_MAX = GREEN_CR_MAX;
			CR_MIN = GREEN_CR_MIN;
			CB_MAX = GREEN_CB_MAX;
			CB_MIN = GREEN_CB_MIN;
		end
		2'd1: begin
			LUM_MAX = ORANGE_LUM_MAX;
			LUM_MIN = ORANGE_LUM_MIN;
			CR_MAX = ORANGE_CR_MAX;
			CR_MIN = ORANGE_CR_MIN;
			CB_MAX = ORANGE_CB_MAX;
			CB_MIN = ORANGE_CB_MIN;
		end
		2'd2: begin
			LUM_MAX = PINK_LUM_MAX;
			LUM_MIN = PINK_LUM_MIN;
			CR_MAX = PINK_CR_MAX;
			CR_MIN = PINK_CR_MIN;
			CB_MAX = PINK_CB_MAX;
			CB_MIN = PINK_CB_MIN;
		end
		2'd3: begin
			LUM_MAX = BLUE_LUM_MAX;
			LUM_MIN = BLUE_LUM_MIN;
			CR_MAX = BLUE_CR_MAX;
			CR_MIN = BLUE_CR_MIN;
			CB_MAX = BLUE_CB_MAX;
			CB_MIN = BLUE_CB_MIN;
		end
		endcase

		case (SELECT)
		3'd7: selected_parameter = LUM_MAX;
		3'd6: selected_parameter = LUM_MIN;
		3'd5: selected_parameter = CR_MAX;
		3'd4: selected_parameter = CR_MIN;
		3'd3: selected_parameter = CB_MAX;
		3'd2: selected_parameter = CB_MIN;
		default: selected_parameter = 10'd0;
		endcase
	end

	always @(posedge b_clock) begin
		if (reset) begin
			GREEN_LUM_MAX <= `GREEN_LUM_MAX;
			GREEN_LUM_MIN <= `GREEN_LUM_MIN;
			GREEN_CR_MAX <= `GREEN_CR_MAX;
			GREEN_CR_MIN <= `GREEN_CR_MIN;
			GREEN_CB_MAX <= `GREEN_CB_MAX;
			GREEN_CB_MIN <= `GREEN_CB_MIN;
	
			ORANGE_LUM_MAX <= `ORANGE_LUM_MAX;
			ORANGE_LUM_MIN <= `ORANGE_LUM_MIN;
			ORANGE_CR_MAX <= `ORANGE_CR_MAX;
			ORANGE_CR_MIN <= `ORANGE_CR_MIN;
			ORANGE_CB_MAX <= `ORANGE_CB_MAX;
			ORANGE_CB_MIN <= `ORANGE_CB_MIN;
			
			PINK_LUM_MAX <= `PINK_LUM_MAX;
			PINK_LUM_MIN <= `PINK_LUM_MIN;
			PINK_CR_MAX <= `PINK_CR_MAX;
			PINK_CR_MIN <= `PINK_CR_MIN;
			PINK_CB_MAX <= `PINK_CB_MAX;
			PINK_CB_MIN <= `PINK_CB_MIN;

			BLUE_LUM_MAX <= `BLUE_LUM_MAX;
			BLUE_LUM_MIN <= `BLUE_LUM_MIN;
			BLUE_CR_MAX <= `BLUE_CR_MAX;
			BLUE_CR_MIN <= `BLUE_CR_MIN;
			BLUE_CB_MAX <= `BLUE_CB_MAX;
			BLUE_CB_MIN <= `BLUE_CB_MIN;
		end
		else if(~button_up) begin
			case (selected_color)
			2'd0:
				case (SELECT)
				3'd7: GREEN_LUM_MAX <= GREEN_LUM_MAX+4'b1000;
				3'd6: GREEN_LUM_MIN <= GREEN_LUM_MIN+4'b1000;
				3'd5: GREEN_CR_MAX <= GREEN_CR_MAX+4'b1000;
				3'd4: GREEN_CR_MIN <= GREEN_CR_MIN+4'b1000;
				3'd3: GREEN_CB_MAX <= GREEN_CB_MAX+4'b1000;
				3'd2: GREEN_CB_MIN <= GREEN_CB_MIN+4'b1000;
				endcase
			2'd1:
				case (SELECT)
				3'd7: ORANGE_LUM_MAX <= ORANGE_LUM_MAX+4'b1000;
				3'd6: ORANGE_LUM_MIN <= ORANGE_LUM_MIN+4'b1000;
				3'd5: ORANGE_CR_MAX <= ORANGE_CR_MAX+4'b1000;
				3'd4: ORANGE_CR_MIN <= ORANGE_CR_MIN+4'b1000;
				3'd3: ORANGE_CB_MAX <= ORANGE_CB_MAX+4'b1000;
				3'd2: ORANGE_CB_MIN <= ORANGE_CB_MIN+4'b1000;
				endcase
			2'd2:	
				case (SELECT)
				3'd7: PINK_LUM_MAX <= PINK_LUM_MAX+4'b1000;
				3'd6: PINK_LUM_MIN <= PINK_LUM_MIN+4'b1000;
				3'd5: PINK_CR_MAX <= PINK_CR_MAX+4'b1000;
				3'd4: PINK_CR_MIN <= PINK_CR_MIN+4'b1000;
				3'd3: PINK_CB_MAX <= PINK_CB_MAX+4'b1000;
				3'd2: PINK_CB_MIN <= PINK_CB_MIN+4'b1000;
				endcase
			2'd3:
				case (SELECT)
				3'd7: BLUE_LUM_MAX <= BLUE_LUM_MAX+4'b1000;
				3'd6: BLUE_LUM_MIN <= BLUE_LUM_MIN+4'b1000;
				3'd5: BLUE_CR_MAX <= BLUE_CR_MAX+4'b1000;
				3'd4: BLUE_CR_MIN <= BLUE_CR_MIN+4'b1000;
				3'd3: BLUE_CB_MAX <= BLUE_CB_MAX+4'b1000;
				3'd2: BLUE_CB_MIN <= BLUE_CB_MIN+4'b1000;
				endcase
			endcase
		end
		else if(~button_down) begin
			case (selected_color)
			2'd0:
				case (SELECT)
				3'd7: GREEN_LUM_MAX <= GREEN_LUM_MAX-4'b1000;
				3'd6: GREEN_LUM_MIN <= GREEN_LUM_MIN-4'b1000;
				3'd5: GREEN_CR_MAX <= GREEN_CR_MAX-4'b1000;
				3'd4: GREEN_CR_MIN <= GREEN_CR_MIN-4'b1000;
				3'd3: GREEN_CB_MAX <= GREEN_CB_MAX-4'b1000;
				3'd2: GREEN_CB_MIN <= GREEN_CB_MIN-4'b1000;
				endcase
			2'd1:
				case (SELECT)
				3'd7: ORANGE_LUM_MAX <= ORANGE_LUM_MAX-4'b1000;
				3'd6: ORANGE_LUM_MIN <= ORANGE_LUM_MIN-4'b1000;
				3'd5: ORANGE_CR_MAX <= ORANGE_CR_MAX-4'b1000;
				3'd4: ORANGE_CR_MIN <= ORANGE_CR_MIN-4'b1000;
				3'd3: ORANGE_CB_MAX <= ORANGE_CB_MAX-4'b1000;
				3'd2: ORANGE_CB_MIN <= ORANGE_CB_MIN-4'b1000;
				endcase
			2'd2:	
				case (SELECT)
				3'd7: PINK_LUM_MAX <= PINK_LUM_MAX-4'b1000;
				3'd6: PINK_LUM_MIN <= PINK_LUM_MIN-4'b1000;
				3'd5: PINK_CR_MAX <= PINK_CR_MAX-4'b1000;
				3'd4: PINK_CR_MIN <= PINK_CR_MIN-4'b1000;
				3'd3: PINK_CB_MAX <= PINK_CB_MAX-4'b1000;
				3'd2: PINK_CB_MIN <= PINK_CB_MIN-4'b1000;
				endcase
			2'd3:
				case (SELECT)
				3'd7: BLUE_LUM_MAX <= BLUE_LUM_MAX-4'b1000;
				3'd6: BLUE_LUM_MIN <= BLUE_LUM_MIN-4'b1000;
				3'd5: BLUE_CR_MAX <= BLUE_CR_MAX-4'b1000;
				3'd4: BLUE_CR_MIN <= BLUE_CR_MIN-4'b1000;
				3'd3: BLUE_CB_MAX <= BLUE_CB_MAX-4'b1000;
				3'd2: BLUE_CB_MIN <= BLUE_CB_MIN-4'b1000;
				endcase
			endcase
		end
	end
endmodule
