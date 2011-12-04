`default_nettype none

// converts YCrCb to RGB
module ycbcr2rgb
        (
		input clock,
		input reset,
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
	end

	always @(posedge clock) begin
		// saturation and assignment
		if (reset || R_signed < 0) r <= 8'd0;
		else if (R_signed > 255) r <= 8'd255;
		else r <= R_signed[7:0];

		if (reset || G_signed < 0) g <= 8'd0;
		else if (G_signed > 255) g <= 8'd255;
		else g <= G_signed[7:0];

		if (reset || B_signed < 0) b <= 8'd0;
		else if (B_signed > 255) b <= 8'd255;
		else b <= B_signed[7:0];
	end
endmodule

module ycrcb_lut(
		input [17:0] ycrcb,
		output reg [7:0] r,
		output reg [7:0] g,
		output reg [7:0] b
	);

	wire [7:0] y;
	wire [4:0] cr;
	wire [4:0] cb;

	assign y = ycrcb[17:10];
	assign cr = ycrcb[9:5];
	assign cb = ycrcb[4:0];

	reg signed [9:0] rgb_y;
	reg signed [9:0] r_cr;
	reg signed [9:0] g_cr;
	reg signed [9:0] g_cb;
	reg signed [9:0] b_cb;

	reg signed [10:0] r_big;
	reg signed [10:0] g_big;
	reg signed [10:0] b_big;

	always @(*) begin
		r_big = rgb_y + r_cr;
		g_big = rgb_y - g_cr - g_cb;
		b_big = rgb_y + b_cb;

		if (r_big < 0) r = 8'd0;
		else if (r_big > 255) r = 8'd255;
		else r = r_big[7:0];

		if (g_big < 0) g = 8'd0;
		else if (g_big > 255) g = 8'd255;
		else g = g_big[7:0];

		if (b_big < 0) b = 8'd0;
		else if (b_big > 255) b = 8'd255;
		else b = b_big[7:0];

		case (y)
			8'd0: rgb_y = 10'sd0;
			8'd1: rgb_y = 10'sd0;
			8'd2: rgb_y = 10'sd0;
			8'd3: rgb_y = 10'sd0;
			8'd4: rgb_y = 10'sd0;
			8'd5: rgb_y = 10'sd0;
			8'd6: rgb_y = 10'sd0;
			8'd7: rgb_y = 10'sd0;
			8'd8: rgb_y = 10'sd0;
			8'd9: rgb_y = 10'sd0;
			8'd10: rgb_y = 10'sd0;
			8'd11: rgb_y = 10'sd0;
			8'd12: rgb_y = 10'sd0;
			8'd13: rgb_y = 10'sd0;
			8'd14: rgb_y = 10'sd0;
			8'd15: rgb_y = 10'sd0;
			8'd16: rgb_y = 10'sd0;
			8'd17: rgb_y = 10'sd1;
			8'd18: rgb_y = 10'sd2;
			8'd19: rgb_y = 10'sd3;
			8'd20: rgb_y = 10'sd5;
			8'd21: rgb_y = 10'sd6;
			8'd22: rgb_y = 10'sd7;
			8'd23: rgb_y = 10'sd8;
			8'd24: rgb_y = 10'sd9;
			8'd25: rgb_y = 10'sd10;
			8'd26: rgb_y = 10'sd12;
			8'd27: rgb_y = 10'sd13;
			8'd28: rgb_y = 10'sd14;
			8'd29: rgb_y = 10'sd15;
			8'd30: rgb_y = 10'sd16;
			8'd31: rgb_y = 10'sd17;
			8'd32: rgb_y = 10'sd19;
			8'd33: rgb_y = 10'sd20;
			8'd34: rgb_y = 10'sd21;
			8'd35: rgb_y = 10'sd22;
			8'd36: rgb_y = 10'sd23;
			8'd37: rgb_y = 10'sd24;
			8'd38: rgb_y = 10'sd26;
			8'd39: rgb_y = 10'sd27;
			8'd40: rgb_y = 10'sd28;
			8'd41: rgb_y = 10'sd29;
			8'd42: rgb_y = 10'sd30;
			8'd43: rgb_y = 10'sd31;
			8'd44: rgb_y = 10'sd33;
			8'd45: rgb_y = 10'sd34;
			8'd46: rgb_y = 10'sd35;
			8'd47: rgb_y = 10'sd36;
			8'd48: rgb_y = 10'sd37;
			8'd49: rgb_y = 10'sd38;
			8'd50: rgb_y = 10'sd40;
			8'd51: rgb_y = 10'sd41;
			8'd52: rgb_y = 10'sd42;
			8'd53: rgb_y = 10'sd43;
			8'd54: rgb_y = 10'sd44;
			8'd55: rgb_y = 10'sd45;
			8'd56: rgb_y = 10'sd47;
			8'd57: rgb_y = 10'sd48;
			8'd58: rgb_y = 10'sd49;
			8'd59: rgb_y = 10'sd50;
			8'd60: rgb_y = 10'sd51;
			8'd61: rgb_y = 10'sd52;
			8'd62: rgb_y = 10'sd54;
			8'd63: rgb_y = 10'sd55;
			8'd64: rgb_y = 10'sd56;
			8'd65: rgb_y = 10'sd57;
			8'd66: rgb_y = 10'sd58;
			8'd67: rgb_y = 10'sd59;
			8'd68: rgb_y = 10'sd61;
			8'd69: rgb_y = 10'sd62;
			8'd70: rgb_y = 10'sd63;
			8'd71: rgb_y = 10'sd64;
			8'd72: rgb_y = 10'sd65;
			8'd73: rgb_y = 10'sd66;
			8'd74: rgb_y = 10'sd68;
			8'd75: rgb_y = 10'sd69;
			8'd76: rgb_y = 10'sd70;
			8'd77: rgb_y = 10'sd71;
			8'd78: rgb_y = 10'sd72;
			8'd79: rgb_y = 10'sd73;
			8'd80: rgb_y = 10'sd74;
			8'd81: rgb_y = 10'sd76;
			8'd82: rgb_y = 10'sd77;
			8'd83: rgb_y = 10'sd78;
			8'd84: rgb_y = 10'sd79;
			8'd85: rgb_y = 10'sd80;
			8'd86: rgb_y = 10'sd81;
			8'd87: rgb_y = 10'sd83;
			8'd88: rgb_y = 10'sd84;
			8'd89: rgb_y = 10'sd85;
			8'd90: rgb_y = 10'sd86;
			8'd91: rgb_y = 10'sd87;
			8'd92: rgb_y = 10'sd88;
			8'd93: rgb_y = 10'sd90;
			8'd94: rgb_y = 10'sd91;
			8'd95: rgb_y = 10'sd92;
			8'd96: rgb_y = 10'sd93;
			8'd97: rgb_y = 10'sd94;
			8'd98: rgb_y = 10'sd95;
			8'd99: rgb_y = 10'sd97;
			8'd100: rgb_y = 10'sd98;
			8'd101: rgb_y = 10'sd99;
			8'd102: rgb_y = 10'sd100;
			8'd103: rgb_y = 10'sd101;
			8'd104: rgb_y = 10'sd102;
			8'd105: rgb_y = 10'sd104;
			8'd106: rgb_y = 10'sd105;
			8'd107: rgb_y = 10'sd106;
			8'd108: rgb_y = 10'sd107;
			8'd109: rgb_y = 10'sd108;
			8'd110: rgb_y = 10'sd109;
			8'd111: rgb_y = 10'sd111;
			8'd112: rgb_y = 10'sd112;
			8'd113: rgb_y = 10'sd113;
			8'd114: rgb_y = 10'sd114;
			8'd115: rgb_y = 10'sd115;
			8'd116: rgb_y = 10'sd116;
			8'd117: rgb_y = 10'sd118;
			8'd118: rgb_y = 10'sd119;
			8'd119: rgb_y = 10'sd120;
			8'd120: rgb_y = 10'sd121;
			8'd121: rgb_y = 10'sd122;
			8'd122: rgb_y = 10'sd123;
			8'd123: rgb_y = 10'sd125;
			8'd124: rgb_y = 10'sd126;
			8'd125: rgb_y = 10'sd127;
			8'd126: rgb_y = 10'sd128;
			8'd127: rgb_y = 10'sd129;
			8'd128: rgb_y = 10'sd130;
			8'd129: rgb_y = 10'sd132;
			8'd130: rgb_y = 10'sd133;
			8'd131: rgb_y = 10'sd134;
			8'd132: rgb_y = 10'sd135;
			8'd133: rgb_y = 10'sd136;
			8'd134: rgb_y = 10'sd137;
			8'd135: rgb_y = 10'sd139;
			8'd136: rgb_y = 10'sd140;
			8'd137: rgb_y = 10'sd141;
			8'd138: rgb_y = 10'sd142;
			8'd139: rgb_y = 10'sd143;
			8'd140: rgb_y = 10'sd144;
			8'd141: rgb_y = 10'sd146;
			8'd142: rgb_y = 10'sd147;
			8'd143: rgb_y = 10'sd148;
			8'd144: rgb_y = 10'sd149;
			8'd145: rgb_y = 10'sd150;
			8'd146: rgb_y = 10'sd151;
			8'd147: rgb_y = 10'sd152;
			8'd148: rgb_y = 10'sd154;
			8'd149: rgb_y = 10'sd155;
			8'd150: rgb_y = 10'sd156;
			8'd151: rgb_y = 10'sd157;
			8'd152: rgb_y = 10'sd158;
			8'd153: rgb_y = 10'sd159;
			8'd154: rgb_y = 10'sd161;
			8'd155: rgb_y = 10'sd162;
			8'd156: rgb_y = 10'sd163;
			8'd157: rgb_y = 10'sd164;
			8'd158: rgb_y = 10'sd165;
			8'd159: rgb_y = 10'sd166;
			8'd160: rgb_y = 10'sd168;
			8'd161: rgb_y = 10'sd169;
			8'd162: rgb_y = 10'sd170;
			8'd163: rgb_y = 10'sd171;
			8'd164: rgb_y = 10'sd172;
			8'd165: rgb_y = 10'sd173;
			8'd166: rgb_y = 10'sd175;
			8'd167: rgb_y = 10'sd176;
			8'd168: rgb_y = 10'sd177;
			8'd169: rgb_y = 10'sd178;
			8'd170: rgb_y = 10'sd179;
			8'd171: rgb_y = 10'sd180;
			8'd172: rgb_y = 10'sd182;
			8'd173: rgb_y = 10'sd183;
			8'd174: rgb_y = 10'sd184;
			8'd175: rgb_y = 10'sd185;
			8'd176: rgb_y = 10'sd186;
			8'd177: rgb_y = 10'sd187;
			8'd178: rgb_y = 10'sd189;
			8'd179: rgb_y = 10'sd190;
			8'd180: rgb_y = 10'sd191;
			8'd181: rgb_y = 10'sd192;
			8'd182: rgb_y = 10'sd193;
			8'd183: rgb_y = 10'sd194;
			8'd184: rgb_y = 10'sd196;
			8'd185: rgb_y = 10'sd197;
			8'd186: rgb_y = 10'sd198;
			8'd187: rgb_y = 10'sd199;
			8'd188: rgb_y = 10'sd200;
			8'd189: rgb_y = 10'sd201;
			8'd190: rgb_y = 10'sd203;
			8'd191: rgb_y = 10'sd204;
			8'd192: rgb_y = 10'sd205;
			8'd193: rgb_y = 10'sd206;
			8'd194: rgb_y = 10'sd207;
			8'd195: rgb_y = 10'sd208;
			8'd196: rgb_y = 10'sd210;
			8'd197: rgb_y = 10'sd211;
			8'd198: rgb_y = 10'sd212;
			8'd199: rgb_y = 10'sd213;
			8'd200: rgb_y = 10'sd214;
			8'd201: rgb_y = 10'sd215;
			8'd202: rgb_y = 10'sd217;
			8'd203: rgb_y = 10'sd218;
			8'd204: rgb_y = 10'sd219;
			8'd205: rgb_y = 10'sd220;
			8'd206: rgb_y = 10'sd221;
			8'd207: rgb_y = 10'sd222;
			8'd208: rgb_y = 10'sd223;
			8'd209: rgb_y = 10'sd225;
			8'd210: rgb_y = 10'sd226;
			8'd211: rgb_y = 10'sd227;
			8'd212: rgb_y = 10'sd228;
			8'd213: rgb_y = 10'sd229;
			8'd214: rgb_y = 10'sd230;
			8'd215: rgb_y = 10'sd232;
			8'd216: rgb_y = 10'sd233;
			8'd217: rgb_y = 10'sd234;
			8'd218: rgb_y = 10'sd235;
			8'd219: rgb_y = 10'sd236;
			8'd220: rgb_y = 10'sd237;
			8'd221: rgb_y = 10'sd239;
			8'd222: rgb_y = 10'sd240;
			8'd223: rgb_y = 10'sd241;
			8'd224: rgb_y = 10'sd242;
			8'd225: rgb_y = 10'sd243;
			8'd226: rgb_y = 10'sd244;
			8'd227: rgb_y = 10'sd246;
			8'd228: rgb_y = 10'sd247;
			8'd229: rgb_y = 10'sd248;
			8'd230: rgb_y = 10'sd249;
			8'd231: rgb_y = 10'sd250;
			8'd232: rgb_y = 10'sd251;
			8'd233: rgb_y = 10'sd253;
			8'd234: rgb_y = 10'sd254;
			8'd235: rgb_y = 10'sd255;
			8'd236: rgb_y = 10'sd255;
			8'd237: rgb_y = 10'sd255;
			8'd238: rgb_y = 10'sd255;
			8'd239: rgb_y = 10'sd255;
			8'd240: rgb_y = 10'sd255;
			8'd241: rgb_y = 10'sd255;
			8'd242: rgb_y = 10'sd255;
			8'd243: rgb_y = 10'sd255;
			8'd244: rgb_y = 10'sd255;
			8'd245: rgb_y = 10'sd255;
			8'd246: rgb_y = 10'sd255;
			8'd247: rgb_y = 10'sd255;
			8'd248: rgb_y = 10'sd255;
			8'd249: rgb_y = 10'sd255;
			8'd250: rgb_y = 10'sd255;
			8'd251: rgb_y = 10'sd255;
			8'd252: rgb_y = 10'sd255;
			8'd253: rgb_y = 10'sd255;
			8'd254: rgb_y = 10'sd255;
			8'd255: rgb_y = 10'sd255;
			default: rgb_y = 10'sd0;
		endcase

		case (cr)
			5'd0: r_cr = -10'sd179;
			5'd1: r_cr = -10'sd179;
			5'd2: r_cr = -10'sd179;
			5'd3: r_cr = -10'sd166;
			5'd4: r_cr = -10'sd153;
			5'd5: r_cr = -10'sd140;
			5'd6: r_cr = -10'sd128;
			5'd7: r_cr = -10'sd115;
			5'd8: r_cr = -10'sd102;
			5'd9: r_cr = -10'sd89;
			5'd10: r_cr = -10'sd77;
			5'd11: r_cr = -10'sd64;
			5'd12: r_cr = -10'sd51;
			5'd13: r_cr = -10'sd38;
			5'd14: r_cr = -10'sd26;
			5'd15: r_cr = -10'sd13;
			5'd16: r_cr = 10'sd0;
			5'd17: r_cr = 10'sd13;
			5'd18: r_cr = 10'sd26;
			5'd19: r_cr = 10'sd38;
			5'd20: r_cr = 10'sd51;
			5'd21: r_cr = 10'sd64;
			5'd22: r_cr = 10'sd77;
			5'd23: r_cr = 10'sd89;
			5'd24: r_cr = 10'sd102;
			5'd25: r_cr = 10'sd115;
			5'd26: r_cr = 10'sd128;
			5'd27: r_cr = 10'sd140;
			5'd28: r_cr = 10'sd153;
			5'd29: r_cr = 10'sd166;
			5'd30: r_cr = 10'sd171;
			5'd31: r_cr = 10'sd171;
			default: r_cr = 10'sd0;
		endcase

		case (cr)
			5'd0: g_cr = -10'sd91;
			5'd1: g_cr = -10'sd91;
			5'd2: g_cr = -10'sd91;
			5'd3: g_cr = -10'sd85;
			5'd4: g_cr = -10'sd78;
			5'd5: g_cr = -10'sd72;
			5'd6: g_cr = -10'sd65;
			5'd7: g_cr = -10'sd59;
			5'd8: g_cr = -10'sd52;
			5'd9: g_cr = -10'sd46;
			5'd10: g_cr = -10'sd39;
			5'd11: g_cr = -10'sd33;
			5'd12: g_cr = -10'sd26;
			5'd13: g_cr = -10'sd20;
			5'd14: g_cr = -10'sd13;
			5'd15: g_cr = -10'sd7;
			5'd16: g_cr = 10'sd0;
			5'd17: g_cr = 10'sd7;
			5'd18: g_cr = 10'sd13;
			5'd19: g_cr = 10'sd20;
			5'd20: g_cr = 10'sd26;
			5'd21: g_cr = 10'sd33;
			5'd22: g_cr = 10'sd39;
			5'd23: g_cr = 10'sd46;
			5'd24: g_cr = 10'sd52;
			5'd25: g_cr = 10'sd59;
			5'd26: g_cr = 10'sd65;
			5'd27: g_cr = 10'sd72;
			5'd28: g_cr = 10'sd78;
			5'd29: g_cr = 10'sd85;
			5'd30: g_cr = 10'sd87;
			5'd31: g_cr = 10'sd87;
			default: g_cr = 10'sd0;
		endcase

		case (cb)
			5'd0: g_cb = -10'sd44;
			5'd1: g_cb = -10'sd44;
			5'd2: g_cb = -10'sd44;
			5'd3: g_cb = -10'sd41;
			5'd4: g_cb = -10'sd38;
			5'd5: g_cb = -10'sd34;
			5'd6: g_cb = -10'sd31;
			5'd7: g_cb = -10'sd28;
			5'd8: g_cb = -10'sd25;
			5'd9: g_cb = -10'sd22;
			5'd10: g_cb = -10'sd19;
			5'd11: g_cb = -10'sd16;
			5'd12: g_cb = -10'sd13;
			5'd13: g_cb = -10'sd9;
			5'd14: g_cb = -10'sd6;
			5'd15: g_cb = -10'sd3;
			5'd16: g_cb = 10'sd0;
			5'd17: g_cb = 10'sd3;
			5'd18: g_cb = 10'sd6;
			5'd19: g_cb = 10'sd9;
			5'd20: g_cb = 10'sd13;
			5'd21: g_cb = 10'sd16;
			5'd22: g_cb = 10'sd19;
			5'd23: g_cb = 10'sd22;
			5'd24: g_cb = 10'sd25;
			5'd25: g_cb = 10'sd28;
			5'd26: g_cb = 10'sd31;
			5'd27: g_cb = 10'sd34;
			5'd28: g_cb = 10'sd38;
			5'd29: g_cb = 10'sd41;
			5'd30: g_cb = 10'sd42;
			5'd31: g_cb = 10'sd42;
			default: g_cb = 10'sd0;
		endcase

		case (cb)
			5'd0: b_cb = -10'sd226;
			5'd1: b_cb = -10'sd226;
			5'd2: b_cb = -10'sd226;
			5'd3: b_cb = -10'sd210;
			5'd4: b_cb = -10'sd194;
			5'd5: b_cb = -10'sd177;
			5'd6: b_cb = -10'sd161;
			5'd7: b_cb = -10'sd145;
			5'd8: b_cb = -10'sd129;
			5'd9: b_cb = -10'sd113;
			5'd10: b_cb = -10'sd97;
			5'd11: b_cb = -10'sd81;
			5'd12: b_cb = -10'sd65;
			5'd13: b_cb = -10'sd48;
			5'd14: b_cb = -10'sd32;
			5'd15: b_cb = -10'sd16;
			5'd16: b_cb = 10'sd0;
			5'd17: b_cb = 10'sd16;
			5'd18: b_cb = 10'sd32;
			5'd19: b_cb = 10'sd48;
			5'd20: b_cb = 10'sd65;
			5'd21: b_cb = 10'sd81;
			5'd22: b_cb = 10'sd97;
			5'd23: b_cb = 10'sd113;
			5'd24: b_cb = 10'sd129;
			5'd25: b_cb = 10'sd145;
			5'd26: b_cb = 10'sd161;
			5'd27: b_cb = 10'sd177;
			5'd28: b_cb = 10'sd194;
			5'd29: b_cb = 10'sd210;
			5'd30: b_cb = 10'sd216;
			5'd31: b_cb = 10'sd216;
			default: b_cb = 10'sd0;
		endcase
	end
endmodule
