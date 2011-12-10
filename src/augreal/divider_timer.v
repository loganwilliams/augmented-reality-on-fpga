// Tested, operational 10/13
module counter #(parameter PERIOD=26999999) (input clock, reset, output reg enable);
  reg [24:0] c;
  
  always @ (posedge clock) begin
    if (c === PERIOD) begin
      c <= 0;
      enable <= 1;
    end else begin
      c <= c + 1;
      enable <= 0;
    end
    
    if (reset) begin
		c <= 0;
		enable <= 0;
	 end
  end
endmodule

// Tested, operational 10/13
module timer(
  input clock_27mhz, // system clock
  input enable, // one second enable signal from Part A
  input start, // start timer
  input reset, // system reset
  input [3:0] value, // timer values from 0-15 seconds
  output expire, // pulse high when timer value is reach.
  output [3:0] debug
);

  reg [3:0] current_timer;
  reg state;
  reg expire_wait;
  reg del_timer;
  
  initial begin
    state = 0;
    current_timer = 0;
  end
  
  always @ (posedge clock_27mhz) begin
    del_timer <= ~(current_timer == 0);
    
    if (reset) begin
      state <= 0;
    end
    
    if (start == 1) begin
      state <= 1;
      current_timer <= value;
      del_timer <= 1;
    end
    
    if (enable) begin
      if (state == 1) begin
        if (current_timer == 0) begin
          state <= 0;
        end else begin
          current_timer <= current_timer - 1;
        end
      end
    end
  end
  
  assign expire = ((current_timer == 0) & del_timer);
  assign debug = current_timer;
endmodule

module test_counter_and_timer();
  reg clk;
  reg reset;
  wire enable;
  wire expire;
  reg [3:0] value;
  reg start;
  
  initial begin
    clk = 0;
    forever #19 clk = ~clk;
  end
  
  counter testcounter(.clock(clk), .reset(reset), .enable(enable));
  timer testtimer(.clock_27mhz(clk), .reset(reset), .enable(enable), .start(start), .value(value), .expire(expire));
  
  initial begin
    reset = 1;
    #38
    reset = 0;
    value = 'd15;
    start = 1;
    #38
    start = 0;
    
    $display("Value = 15");
    $display("Expire after 1 clock cycle: %b", expire);
    
    #1710
    
    $display("Expire after 15 \"1Hz\" cycles: %b", expire);
    
    #38
    
    $display("Expire after 1 more clock cycle: %b", expire);
    
    reset = 1;
    #38
    reset = 0;
    value = 'd0;
    start = 1;
    #38
    start = 0;
    
    $display("Value = 0");
    $display("Expire after 1 clock cycle: %b", expire);
    
    #114
    
    $display("Expire after 1 \"1 Hz\" cycle: %b", expire);
    
    #38
    
    $display("Expire after 1 more clock cycle: %b", expire);
    
    reset = 1;
    #38
    reset = 0;
    value = 'd1;
    start = 1;
    #38
    start = 0;
     
    $display("Value = 1");
     
    $display("Expire after 1 clock cycle: %b", expire);
     
    #114
     
    $display("Expire after 1 \"1 Hz\" clock cycle: %b", expire);
     
    #38
     
    $display("Expire after 1 more clock cycle: %b", expire);
  end
endmodule
