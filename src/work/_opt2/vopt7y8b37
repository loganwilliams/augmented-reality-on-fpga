library verilog;
use verilog.vl_types.all;
entity pt_fetcher is
    port(
        clock           : in     vl_logic;
        reset           : in     vl_logic;
        pt_flag         : in     vl_logic;
        pt_x            : in     vl_logic_vector(9 downto 0);
        pt_y            : in     vl_logic_vector(8 downto 0);
        pt_pixel        : in     vl_logic_vector(17 downto 0);
        done_pt         : out    vl_logic;
        ptf_pixel_read  : in     vl_logic_vector(35 downto 0);
        done_ptf        : in     vl_logic;
        ptf_x           : out    vl_logic_vector(9 downto 0);
        ptf_y           : out    vl_logic_vector(8 downto 0);
        ptf_flag        : out    vl_logic;
        ptf_wr          : out    vl_logic;
        ptf_pixel_write : out    vl_logic_vector(35 downto 0)
    );
end pt_fetcher;
