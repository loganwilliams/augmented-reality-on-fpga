library verilog;
use verilog.vl_types.all;
entity divider is
    generic(
        WIDTH           : integer := 8
    );
    port(
        ready           : out    vl_logic;
        start           : in     vl_logic;
        quotient        : out    vl_logic_vector;
        remainder       : out    vl_logic_vector;
        dividend        : in     vl_logic_vector;
        divider         : in     vl_logic_vector;
        sign            : in     vl_logic;
        clk             : in     vl_logic
    );
end divider;
