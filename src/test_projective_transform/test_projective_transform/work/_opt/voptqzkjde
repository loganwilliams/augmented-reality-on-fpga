library verilog;
use verilog.vl_types.all;
entity projective_transform is
    generic(
        WAIT_FOR_CORNERS: integer := 0;
        WAIT_FOR_DIVIDERS: integer := 1;
        WAIT_FOR_PIXEL  : integer := 2
    );
    port(
        clk             : in     vl_logic;
        frame_flag      : in     vl_logic;
        pixel           : in     vl_logic_vector(17 downto 0);
        pixel_flag      : in     vl_logic;
        a_x             : in     vl_logic_vector(9 downto 0);
        a_y             : in     vl_logic_vector(8 downto 0);
        b_x             : in     vl_logic_vector(9 downto 0);
        b_y             : in     vl_logic_vector(8 downto 0);
        c_x             : in     vl_logic_vector(9 downto 0);
        c_y             : in     vl_logic_vector(8 downto 0);
        d_x             : in     vl_logic_vector(9 downto 0);
        d_y             : in     vl_logic_vector(8 downto 0);
        corners_flag    : in     vl_logic;
        ptflag          : in     vl_logic;
        pt_pixel_write  : out    vl_logic_vector(17 downto 0);
        pt_x            : out    vl_logic_vector(9 downto 0);
        pt_y            : out    vl_logic_vector(8 downto 0);
        pt_wr           : out    vl_logic;
        request_pixel   : out    vl_logic
    );
end projective_transform;
