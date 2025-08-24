--#######################################################################
--2025/02/25 maojin
--2025/08/06 LS 
--sdi_param
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity sdi_param is
generic(
    FRAME_W								: integer:= 11
);
port(
    sysclk                              : in std_logic;
    nRST                                : in std_logic;

    --sys clock domain 
    format_10bit_src_sysclk             : in  std_logic; --'0': from 2C frames, 1: FROM SERDES
    format_10bit_vsync_sysclk           : in  std_logic_vector(1 downto 0);  --sysclk domain 

    --pbus
    pframe_ss							: in  std_logic;
	ptype								: in  std_logic_vector(7 downto 0);
	pwren								: in  std_logic;
	paddr								: in  std_logic_vector(FRAME_W-1 downto 0);
	pdata								: in  std_logic_vector(7 downto 0);

    --for test
    format_select                       : in std_logic_vector(4 downto 0);
    tx_std                              : in std_logic_vector(2 downto 0);
    ntsc_paln                           : in std_logic; 

    nRST_sdi                            : in std_logic;
    sdi_clk                             : in std_logic;

    --sdi_message
--    config_done                         : out std_logic;

    sdi_tx_std                          : out std_logic_vector(2 downto 0); 
    words_per_active_line               : out std_logic_vector(12 downto 0);  --Total words in active part of line  pixel
    words_per_total_line                : out std_logic_vector(12 downto 0);  --Total words per line
    lines_per_frame                     : out std_logic_vector(10 downto 0);  --Total lines per frame
    line_hanc_word                      : out std_logic_vector(11 downto 0);  --hanc words per line
    sd_hanc_y_word                      : out std_logic_vector(7 downto 0);   --sd hanc y words per line
    --F V
    f_rise_line                         : out std_logic_vector(10 downto 0);--defualt is 0
    f_fall_line                         : out std_logic_vector(10 downto 0);--defualt is 0
    v_fall_line_1                       : out std_logic_vector(10 downto 0);-- Line number when V falls for first field
    v_rise_line_1                       : out std_logic_vector(10 downto 0);-- Line number when V rises for first field
    v_fall_line_2                       : out std_logic_vector(10 downto 0);-- defualt is 0
    v_rise_line_2                       : out std_logic_vector(10 downto 0);-- defualt is 0

    vpid_line_f0                        : out std_logic_vector(10 downto 0);--how much line to insert vpid 
    vpid_line_f1                        : out std_logic_vector(10 downto 0);

    vpid_byte1                          : out std_logic_vector(7 downto 0);
    vpid_byte2                          : out std_logic_vector(7 downto 0);
    vpid_byte3                          : out std_logic_vector(7 downto 0);
    vpid_byte4                          : out std_logic_vector(7 downto 0);
    vpid_byte1_b                        : out std_logic_vector(7 downto 0);
    vpid_byte2_b                        : out std_logic_vector(7 downto 0);
    vpid_byte3_b                        : out std_logic_vector(7 downto 0);
    vpid_byte4_b                        : out std_logic_vector(7 downto 0);

    format_10bit_en                     : out std_logic;
    format_bt601_en                     : out std_logic_vector(2 downto 0); --colormetiry input defualt 0
    
    param_bright_local                  : out std_logic_vector(7 downto 0);
    param_chroma_r                      : out std_logic_vector(7 downto 0);
    param_chroma_g                      : out std_logic_vector(7 downto 0);
    param_chroma_b                      : out std_logic_vector(7 downto 0)

);
end entity;

architecture behav of sdi_param is

component cross_domain is 
generic (
    DATA_WIDTH							: integer:=8 
);
port 
(   
    clk0      							: in  std_logic;
    nRst0     							: in  std_logic;		
    datain    							: in  std_logic_vector(DATA_WIDTH-1 downto 0);
    datain_req							: in  std_logic;

    clk1								: in  std_logic;
    nRst1								: in  std_logic;
    data_out							: out std_logic_vector(DATA_WIDTH-1 downto 0);
    dataout_valid						: out std_logic  ---just pulse only
);
end component;

signal frame_colorbits_set_en           : std_logic;
signal format_colorbits                 : std_logic_vector(1 downto 0);
signal format_10bit_en_sys              : std_logic;
signal format_10bit_en_cross            : std_logic_vector(1 downto 0);

signal format_10bit_vsync_lock          : std_logic_vector(1 downto 0) ;
signal color_depth_change_en            : std_logic ;

signal frame_brightness_set             : std_logic;
signal brightness_type                  : std_logic_vector(7 downto 0);
signal brightness_type_hit              : std_logic;
signal bright_set_value                 : std_logic_vector(7 downto 0);
signal chroma_r_set_value               : std_logic_vector(7 downto 0);
signal chroma_g_set_value               : std_logic_vector(7 downto 0);
signal chroma_b_set_value               : std_logic_vector(7 downto 0);

signal format_bt601_en_sys              : std_logic_vector(2 downto 0); --colormetiry input defualt 0

TYPE   arrray_16_187bit is array (21 downto 0) of std_logic_vector(186 downto 0);
signal format_test                      : arrray_16_187bit;
signal index_format                     : integer := 12;  

signal rdata1                           : std_logic_vector(3 downto 0) := (others => '0');
signal rdata2                           : std_logic_vector(3 downto 0) := (others => '0');
signal vpid_part                        : std_logic_vector(3 downto 0) := (others => '0');
signal int_vpid_byte2_a                 : std_logic_vector(7 downto 0) := (others => '0'); 
signal int_vpid_byte2                   : std_logic_vector(7 downto 0) := (others => '0');
signal int_vpid_byte1                   : std_logic_vector(7 downto 0) := (others => '0');

begin

process(nRST,sysclk)
begin
    if nRST = '0' then
        frame_colorbits_set_en <= '0';
        format_colorbits <= (others => '0');
        format_10bit_en_sys <= '0';
        format_10bit_vsync_lock <= (others => '0');
        color_depth_change_en <= '0';
    elsif rising_edge(sysclk) then
        if pframe_ss = '1' and ptype = x"2c" then frame_colorbits_set_en <= '1';
        else                                      frame_colorbits_set_en <= '0';
        end if;

        if frame_colorbits_set_en = '1' then
            if pwren = '1' then
                if paddr = 3 then format_colorbits <= pdata(1 downto 0); end if;
            end if;
        end if;

        format_10bit_vsync_lock <= format_10bit_vsync_sysclk;

        if format_10bit_src_sysclk = '0' THEN --FROM 2c FRAME  
            if    format_colorbits = "00" then format_10bit_en_sys <= '0';--8bit
            elsif format_colorbits = "01" then format_10bit_en_sys <= '1';--10bit
            elsif format_colorbits = "10" then format_10bit_en_sys <= '1';--12bit
            else                               format_10bit_en_sys <= '0';
            end if;
        ELSE --FROM SERDES 
             if    format_10bit_vsync_sysclk = "00" then  format_10bit_en_sys <= '0';--8bit
            elsif format_10bit_vsync_sysclk = "01" then   format_10bit_en_sys <= '1';--10bit
            elsif format_10bit_vsync_sysclk = "10" then   format_10bit_en_sys <= '1';--12bit
            else                                   format_10bit_en_sys <= '0';
            end if;
            ---format_10bit_en_sys <= format_10bit_vsync_sysclk;
        END IF;

        if(format_10bit_src_sysclk = '1')then
            if(format_10bit_vsync_lock /= format_10bit_vsync_sysclk)then
                color_depth_change_en <= '1';
            else
                color_depth_change_en <= '0';
            end if;
        else
            color_depth_change_en <= frame_colorbits_set_en;
        end if;
    end if;
end process;
    
process(nRST_sdi,sdi_clk)
begin
    if nRST_sdi = '0' then
        format_10bit_en_cross <= (others => '0');
        format_10bit_en <= '0';
    elsif rising_edge(sdi_clk) then
        format_10bit_en_cross <= format_10bit_en_cross(0)&format_10bit_en_sys;
        format_10bit_en <= format_10bit_en_cross(1);
    end if;
end process;

format_bt601_en <= format_bt601_en_sys;
process(nRST_sdi,sdi_clk)
begin
    if nRST_sdi = '0' then
        format_bt601_en_sys <= (others=>'0');
    elsif rising_edge(sdi_clk) then
        format_bt601_en_sys <= (others=>'0');
    end if;
end process;

process(nRST_sdi,sdi_clk)
begin
    if nRST_sdi = '0' then
        sdi_tx_std <= "011";--default is 3G
    elsif rising_edge(sdi_clk) then
        sdi_tx_std <= tx_std;
    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        frame_brightness_set <= '0';
        brightness_type <= (others => '0');
        brightness_type_hit <= '0';
        bright_set_value <= (others => '1');
        chroma_r_set_value <= (others => '1');
        chroma_g_set_value <= (others => '1');
        chroma_b_set_value <= (others => '1');
    elsif rising_edge(sysclk) then
        if pframe_ss = '1' and ptype = x"80" then frame_brightness_set <= '1';
        else                                      frame_brightness_set <= '0';
        end if;

        if frame_brightness_set = '1' then
            if pwren = '1' then
                if paddr = 0 then brightness_type <= pdata; end if;

                --bright_set_value
                if (paddr = 5)then           
                    if brightness_type_hit = '1' then
                        bright_set_value <= pdata;
                    end if;
                end if;

                --chroma_r_set_value
                if (paddr = 6) then
                    if brightness_type_hit = '1' then
                        chroma_r_set_value <= pdata;
                    end if;
                end if;
                --chroma_g_set_value
                if (paddr = 7) then
                    if brightness_type_hit = '1' then
                        chroma_g_set_value <= pdata;
                    end if;
                end if;
                --chroma_b_set_value
                if (paddr = 8) then
                    if brightness_type_hit = '1' then
                        chroma_b_set_value <= pdata;
                    end if;
                end if;
            end if;
        end if;

        if brightness_type = x"02" or brightness_type = x"ff" then
            brightness_type_hit <= '1';
        else
            brightness_type_hit <= '0';
        end if;
    end if;
end process;


cross_brightness_inst : cross_domain  
generic map(
    DATA_WIDTH	=> 8
)
port map(   
    clk0      							=> sysclk,
    nRst0     							=> nRST,
    datain    							=> bright_set_value,
    datain_req							=> '1',

    clk1								=> sdi_clk,
    nRst1								=> nRST_sdi,
    data_out							=> param_bright_local,
    dataout_valid						=> open
);


cross_r_inst : cross_domain  
generic map(
    DATA_WIDTH	=> 8
)
port map(   
    clk0      							=> sysclk,
    nRst0     							=> nRST,
    datain    							=> chroma_r_set_value,
    datain_req							=> '1',

    clk1								=> sdi_clk,
    nRst1								=> nRST_sdi,
    data_out							=> param_chroma_r,
    dataout_valid						=> open
);


cross_g_inst : cross_domain  
generic map(
    DATA_WIDTH	=> 8
)
port map(   
    clk0      							=> sysclk,
    nRst0     							=> nRST,
    datain    							=> chroma_g_set_value,
    datain_req							=> '1',

    clk1								=> sdi_clk,
    nRst1								=> nRST_sdi,
    data_out							=> param_chroma_g,
    dataout_valid						=> open
);


cross_b_inst : cross_domain  
generic map(
    DATA_WIDTH	=> 8
)
port map(   
    clk0      							=> sysclk,
    nRst0     							=> nRST,
    datain    							=> chroma_b_set_value,
    datain_req							=> '1',

    clk1								=> sdi_clk,
    nRst1								=> nRST_sdi,
    data_out							=> param_chroma_b,
    dataout_valid						=> open
);





----param gen
process(sdi_clk)
begin
	if rising_edge(sdi_clk) then
        -- format_test <= (others => '0'); 
        --SD NTSC 720*480
        format_test(0)(186 downto 0) <= 
            conv_std_logic_vector(134, 8)                        &  -- 8                  sd_hanc_y_word
            conv_std_logic_vector(0, 12)                         &  -- 12                 hanc_word
            conv_std_logic_vector(525, 11)                       &  -- 11                 line_per_frame
            conv_std_logic_vector(720, 13)                       &  -- 13                 active_line
            conv_std_logic_vector(858, 13)                       &  -- 13                 total_line
            conv_std_logic_vector(266, 11)                       &  -- 11                 f_rise_line
            conv_std_logic_vector(4, 11)                         &  -- 11                 f_fall_line
            conv_std_logic_vector(20, 11)                        &  -- 11                 v_fall_line1
            conv_std_logic_vector(264, 11)                       &  -- 11                 v_rise_line1
            conv_std_logic_vector(283, 11)                       &  -- 11                 v_fall_line2
            conv_std_logic_vector(1, 11)                         &  -- 11                 v_rise_line2
            conv_std_logic_vector(140, 11)                       &  -- 11                 patho_change_line_1
            conv_std_logic_vector(400, 11)                       &  -- 11                 patho_change_line_2  
            conv_std_logic_vector(1, 4)                          &  -- 4                  vpid_byte1 HD    42bi
            conv_std_logic_vector(0, 4)                          &  -- 4                  vpid_byte1 3GA
            conv_std_logic_vector(0, 4)                          &  -- 4                  vpid_byte1 3GB
            conv_std_logic_vector(6, 8)                          &  -- 8                  vpid_byte2 
            conv_std_logic_vector(13, 11)                        &  -- 11                 vpid_ln_h
            conv_std_logic_vector(276, 11);                         -- 11                 vpid_ln_l
        --SD PAL 720*576
        format_test(1)(186 downto 0) <= 
            conv_std_logic_vector(140, 8)                        &  -- 8'd0
            conv_std_logic_vector(0, 12)                         &  -- 12'd268
            conv_std_logic_vector(625, 11)                       &  -- 11'd1125
            conv_std_logic_vector(720, 13)                       &  -- 13'd1920
            conv_std_logic_vector(864, 13)                       &  -- 13'd2200
            conv_std_logic_vector(313, 11)                       &  -- 11'd0
            conv_std_logic_vector(1, 11)                         &  -- 11'd0
            conv_std_logic_vector(23, 11)                        &  -- 11'd42
            conv_std_logic_vector(311, 11)                       &  -- 11'd1122
            conv_std_logic_vector(336, 11)                       &  -- 11'd0
            conv_std_logic_vector(624, 11)                       &  -- 11'd0
            conv_std_logic_vector(160, 11)                       &  -- 11'd581
            conv_std_logic_vector(470, 11)                       &  -- 11'd0
            conv_std_logic_vector(1, 4)                          &  -- 4'h5
            conv_std_logic_vector(0, 4)                          &  -- 4'h9
            conv_std_logic_vector(0, 4)                          &  -- 4'hC
            conv_std_logic_vector(5, 8)                          &  -- 8'hC7
            conv_std_logic_vector(9, 11)                         &  -- 11'd10
            conv_std_logic_vector(322, 11);                           -- 11'd0 --3GA(60/59.94)
        --6G 1920x1080p 30/29.7 used
        format_test(2)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(2468, 12)                      &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(1920, 13)                      &  -- 13'd1920
            conv_std_logic_vector(4400, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(199, 8)                        &  -- 8'hC7 --30
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 
        --6G 1920x1080p 24/23.9
        format_test(3)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(3568, 12)                      &  --   hanc_word  12'd268
            conv_std_logic_vector(1125, 11)                      &  --   line_per_frame  11'd1125
            conv_std_logic_vector(1920, 13)                      &  --   active_line  13'd1920
            conv_std_logic_vector(5500, 13)                      &  --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         &  --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         &  --   f_fall_line  11'd0
            conv_std_logic_vector(42, 11)                        &  --   v_fall_line1  11'd42
            conv_std_logic_vector(1122, 11)                      &  --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         &  --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         &  --   v_rise_line2  11'd0
            conv_std_logic_vector(581, 11)                       &  --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         &  --   patho_change_line_2    11'd0
            conv_std_logic_vector(5, 4)                          &  --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(9, 4)                          &  --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(12, 4)                         &  --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(195, 8)                        &  --   vpid_byte2   8'hC3
            conv_std_logic_vector(10, 11)                        &  --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                           --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1980x1080i 60/59.94  used
        format_test(4)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(268, 12)                       & --   hanc_word  12'd268
            conv_std_logic_vector(1125, 11)                      & --   line_per_frame  11'd1125
            conv_std_logic_vector(1920, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(2200, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(564, 11)                       & --   f_rise_line   11'd0
            conv_std_logic_vector(1, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(21, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(561, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(584, 11)                       & --   v_fall_line2  11'd0
            conv_std_logic_vector(1124, 11)                      & --   v_rise_line2  11'd0
            conv_std_logic_vector(290, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(853, 11)                       & --   patho_change_line_2    11'd0
            conv_std_logic_vector(5, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(9, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(12, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(7, 8)                          & --   vpid_byte2   8'hC7
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(572, 11);                        --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1980x1080i 50  used         
        format_test(5)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(708, 12)                       & --   hanc_word  12'd268
            conv_std_logic_vector(1125, 11)                      & --   line_per_frame  11'd1125
            conv_std_logic_vector(1920, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(2640, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(564, 11)                       & --   f_rise_line   11'd0
            conv_std_logic_vector(1, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(21, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(561, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(584, 11)                       & --   v_fall_line2  11'd0
            conv_std_logic_vector(1124, 11)                      & --   v_rise_line2  11'd0
            conv_std_logic_vector(290, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(853, 11)                       & --   patho_change_line_2    11'd0
            conv_std_logic_vector(5, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(9, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(12, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(5, 8)                          & --   vpid_byte2   8'hC7
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(572, 11);                        --   vpid_ln_l  11'd0 --3GA(60/59.94)
          --1080p24/23.98  used
        format_test(6)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(818, 12)                       & --   hanc_word  12'd268
            conv_std_logic_vector(1125, 11)                      & --   line_per_frame  11'd1125
            conv_std_logic_vector(1920, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(2750, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(42, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(1122, 11)                      & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(581, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(5, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(9, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(12, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(195, 8)                        & --   vpid_byte2   8'hC3
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1280x720p 60/59.94 used
        format_test(7)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(358, 12)                       & --   hanc_word  12'd268
            conv_std_logic_vector(750, 11)                       & --   line_per_frame  11'd1125
            conv_std_logic_vector(1280, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(1650, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(26, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(746, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(385, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(4, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(8, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(11, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(75, 8)                         & --   vpid_byte2   8'h4b
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1280x720p 50 used
        format_test(8)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(688, 12)                       & --   hanc_word  12'd268
            conv_std_logic_vector(750, 11)                       & --   line_per_frame  11'd1125
            conv_std_logic_vector(1280, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(1980, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(26, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(746, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(385, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(4, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(8, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(11, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(73, 8)                         & --   vpid_byte2   8'h49
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1280x720p 30/29.97 used
        format_test(9)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(2008, 12)                      & --   hanc_word  12'd268
            conv_std_logic_vector(750, 11)                       & --   line_per_frame  11'd1125
            conv_std_logic_vector(1280, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(3300, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(26, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(746, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(385, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(4, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(8, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(11, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(71, 8)                         & --   vpid_byte2   8'h47
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1280x720p 25 used
        format_test(10)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(2668, 12)                      & --   hanc_word  12'd268
            conv_std_logic_vector(750, 11)                       & --   line_per_frame  11'd1125
            conv_std_logic_vector(1280, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(3960, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(26, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(746, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(385, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(4, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(8, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(11, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(69, 8)                         & --   vpid_byte2   8'h45
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --1280x720p 24/23.98 used
        format_test(11)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0             
            conv_std_logic_vector(2833, 12)                      & --   hanc_word  12'd268
            conv_std_logic_vector(750, 11)                       & --   line_per_frame  11'd1125
            conv_std_logic_vector(1280, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(4125, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(26, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(746, 11)                       & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(385, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(4, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(8, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(11, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(67, 8)                         & --   vpid_byte2   8'h43
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --(1920/3840)x1080p30/29.97,60/59.94 used
        format_test(12)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          & --   sd_hanc_y_word  8'd0            
            conv_std_logic_vector(268, 12)                       & --   hanc_word  12'd268
            conv_std_logic_vector(1125, 11)                      & --   line_per_frame  11'd1125
            conv_std_logic_vector(1920, 13)                      & --   active_line  13'd1920
            conv_std_logic_vector(2200, 13)                      & --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         & --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         & --   f_fall_line  11'd0
            conv_std_logic_vector(42, 11)                        & --   v_fall_line1  11'd42
            conv_std_logic_vector(1122, 11)                      & --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         & --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         & --   v_rise_line2  11'd0
            conv_std_logic_vector(581, 11)                       & --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         & --   patho_change_line_2    11'd0
            conv_std_logic_vector(5, 4)                          & --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(9, 4)                          & --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(12, 4)                         & --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(199, 8)                        & --   vpid_byte2   8'hc7
            conv_std_logic_vector(10, 11)                        & --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                          --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --(1920/3840)x1080p25,50 used
        format_test(13)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  --   sd_hanc_y_word  8'd0            
            conv_std_logic_vector(708, 12)                       &  --   hanc_word  12'd268
            conv_std_logic_vector(1125, 11)                      &  --   line_per_frame  11'd1125
            conv_std_logic_vector(1920, 13)                      &  --   active_line  13'd1920
            conv_std_logic_vector(2640, 13)                      &  --   total_line  13'd2200
            conv_std_logic_vector(0, 11)                         &  --   f_rise_line   11'd0
            conv_std_logic_vector(0, 11)                         &  --   f_fall_line  11'd0
            conv_std_logic_vector(42, 11)                        &  --   v_fall_line1  11'd42
            conv_std_logic_vector(1122, 11)                      &  --   v_rise_line1  11'd1122
            conv_std_logic_vector(0, 11)                         &  --   v_fall_line2  11'd0
            conv_std_logic_vector(0, 11)                         &  --   v_rise_line2  11'd0
            conv_std_logic_vector(581, 11)                       &  --   patho_change_line_1  11'd581
            conv_std_logic_vector(0, 11)                         &  --   patho_change_line_2    11'd0
            conv_std_logic_vector(5, 4)                          &  --   vpid_byte1 HD    42bi  4'h5
            conv_std_logic_vector(9, 4)                          &  --   vpid_byte1 3GA  4'h9
            conv_std_logic_vector(12, 4)                         &  --   vpid_byte1 3GB  4'hC
            conv_std_logic_vector(197, 8)                        &  --   vpid_byte2   8'hc5
            conv_std_logic_vector(10, 11)                        &  --   vpid_ln_h  11'd10
            conv_std_logic_vector(0, 11);                           --   vpid_ln_l  11'd0 --3GA(60/59.94)
        --6G 1920x1080p 25 used
        format_test(14)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(3348, 12)                      &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(1920, 13)                      &  -- 13'd1920
            conv_std_logic_vector(5280, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(197, 8)                        &  -- 8'hc5
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --reserved not used
        format_test(15)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(0, 12)                         &  -- 12'd268
            conv_std_logic_vector(0, 11)                         &  -- 11'd1125
            conv_std_logic_vector(0, 13)                         &  -- 13'd1920
            conv_std_logic_vector(0, 13)                         &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd42
            conv_std_logic_vector(0, 11)                         &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 4)                          &  -- 4'h5
            conv_std_logic_vector(0, 4)                          &  -- 4'h9
            conv_std_logic_vector(0, 4)                          &  -- 4'hC
            conv_std_logic_vector(0, 8)                          &  -- 8'hC7
            conv_std_logic_vector(0, 11)                         &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --(2048x1080) p30/29.97 --6G
        format_test(16)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(2340, 12)                      &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(2048, 13)                      &  -- 13'd1920
            conv_std_logic_vector(4400, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(199, 8)                        &  -- 8'hC7
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --2048x1080 p24/23.98 --6G
        format_test(17)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(3440, 12)                      &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(2048, 13)                      &  -- 13'd1920
            conv_std_logic_vector(5500, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(195, 8)                        &  -- 8'hC3
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --2048x1080 p25  --6G
        format_test(18)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(3220, 12)                      &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(2048, 13)                      &  -- 13'd1920
            conv_std_logic_vector(5280, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(197, 8)                        &  -- 8'hC5
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --2048x1080 p60/59.94  --12G
        format_test(19)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(140, 12)                       &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(2048, 13)                      &  -- 13'd1920
            conv_std_logic_vector(2200, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(203, 8)                        &  -- 8'hCB
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --2048x1080 p50  --12G
        format_test(20)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(580, 12)                       &  -- 12'd268
            conv_std_logic_vector(1125, 11)                      &  -- 11'd1125
            conv_std_logic_vector(2048, 13)                      &  -- 13'd1920
            conv_std_logic_vector(2640, 13)                      &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(42, 11)                        &  -- 11'd42
            conv_std_logic_vector(1122, 11)                      &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(581, 11)                       &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(5, 4)                          &  -- 4'h5
            conv_std_logic_vector(9, 4)                          &  -- 4'h9
            conv_std_logic_vector(12, 4)                         &  -- 4'hC
            conv_std_logic_vector(201, 8)                        &  -- 8'hC9
            conv_std_logic_vector(10, 11)                        &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
        --reserved not used
        format_test(21)(186 downto 0) <= 
            conv_std_logic_vector(0, 8)                          &  -- 8'd0
            conv_std_logic_vector(0, 12)                         &  -- 12'd268
            conv_std_logic_vector(0, 11)                         &  -- 11'd1125
            conv_std_logic_vector(0, 13)                         &  -- 13'd1920
            conv_std_logic_vector(0, 13)                         &  -- 13'd2200
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd42
            conv_std_logic_vector(0, 11)                         &  -- 11'd1122
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 11)                         &  -- 11'd581
            conv_std_logic_vector(0, 11)                         &  -- 11'd0
            conv_std_logic_vector(0, 4)                          &  -- 4'h5
            conv_std_logic_vector(0, 4)                          &  -- 4'h9
            conv_std_logic_vector(0, 4)                          &  -- 4'hC
            conv_std_logic_vector(0, 8)                          &  -- 8'hC7
            conv_std_logic_vector(0, 11)                         &  -- 11'd10
            conv_std_logic_vector(0, 11);                           -- 11'd0 --3GA(60/59.94)
	end if;

end process;

process(sdi_clk,nRST_sdi)
begin
    if nRST_sdi = '0' then
        index_format <= 12;
    elsif rising_edge(sdi_clk) then
        case format_select is
            when "00000" => index_format <= 0; --sd     
            when "00001" => index_format <= 1; --sd
            when "00010" => index_format <= 2; --1080p 30/29.7 --6G
            when "00011" => index_format <= 3; --1080p 24/23.9 --6G
            when "00100" => index_format <= 4; --1080i 60
            when "00101" => index_format <= 5; --1080i 50 720p 60
            when "00110" => index_format <= 6; --1080p 24/23.98
            when "00111" => index_format <= 7; --720p 60/59.94
            when "01000" => index_format <= 8; --720p 50 
            when "01001" => index_format <= 9; --720p 30/29.97 
            when "01010" => index_format <= 10;--720p 25
            when "01011" => index_format <= 11;--720p 24/23.98 
            when "01100" => index_format <= 12;--1080p 30/29.97 60/59.94
            when "01101" => index_format <= 13;--1080p 25 /50
            when "01110" => index_format <= 14;--1080p 25 --6G
            when "01111" => index_format <= 15;--reserved
            when "10000" => index_format <= 16;--(2048x1080) p30/29.97 --6G
            when "10001" => index_format <= 17;--(2048x1080) p24/23.98 --6G
            when "10010" => index_format <= 18;--(2048x1080) p25       --6G
            when "10011" => index_format <= 19;--(2048x1080) p60/59.94 --12G
            when "10100" => index_format <= 20;--(2048x1080) p50       --12G
            when "10101" => index_format <= 21;
            when others => index_format <= 12;
        end case;
    end if;
end process;


process(sdi_clk,nRST_sdi)
begin
    if nRST_sdi = '0' then
        sd_hanc_y_word        <= (others => '0');
        line_hanc_word        <= (others => '0');
        lines_per_frame       <= (others => '0');
        words_per_active_line <= (others => '0');
        words_per_total_line  <= (others => '0');
        f_rise_line           <= (others => '0');
        f_fall_line           <= (others => '0');
        v_fall_line_1         <= (others => '0');
        v_rise_line_1         <= (others => '0');
        v_fall_line_2         <= (others => '0');
        v_rise_line_2         <= (others => '0');

        vpid_line_f0          <= (others => '0');
        vpid_line_f1          <= (others => '0');

        vpid_byte1            <= (others => '0');                     
        vpid_byte2            <= (others => '0');                  
        vpid_byte3            <= (others => '0');                
        vpid_byte4            <= (others => '0');     


        vpid_byte1_b          <= (others => '0');                             
        vpid_byte2_b          <= (others => '0');                                   
        vpid_byte3_b          <= (others => '0');                   
        vpid_byte4_b          <= (others => '0');

	elsif rising_edge(sdi_clk) then
        
        sd_hanc_y_word        <= format_test(index_format)(186 downto 179);
        line_hanc_word        <= format_test(index_format)(178 downto 167);
        lines_per_frame       <= format_test(index_format)(166 downto 156);
        words_per_active_line <= format_test(index_format)(155 downto 143);
        words_per_total_line  <= format_test(index_format)(142 downto 130);
        f_rise_line           <= format_test(index_format)(129 downto 119);
        f_fall_line           <= format_test(index_format)(118 downto 108);
        v_fall_line_1         <= format_test(index_format)(107 downto 97 );
        v_rise_line_1         <= format_test(index_format)(96  downto 86 );
        v_fall_line_2         <= format_test(index_format)(85  downto 75 );
        v_rise_line_2         <= format_test(index_format)(74  downto 64 );

        vpid_line_f0          <= format_test(index_format)(21  downto 11 );
        vpid_line_f1          <= format_test(index_format)(10  downto 0  );

        vpid_byte1            <=  int_vpid_byte1;                     
        vpid_byte2            <=  int_vpid_byte2;  

        vpid_byte3            <=  X"00";--YCBCR422                
        vpid_byte4            <=  X"01";--bit 10     


        vpid_byte1_b  <=  X"89";                             
        vpid_byte2_b  <=  X"CB";       

        vpid_byte3_b  <=  X"00";--YCBCR422                      
        vpid_byte4_b  <=  X"01";--bit 10          
        end if;

end process;

process(sdi_clk,nRST_sdi)
begin
    if(nRST_sdi = '0') then
        rdata1 <= (others => '0');
    elsif rising_edge(sdi_clk) then
        case tx_std is
            when "000" =>  rdata1 <= format_test(index_format)(41 downto 38); --sd hd
            when "001" =>  rdata1 <= format_test(index_format)(41 downto 38); --hd
            when "011" =>  rdata1 <= format_test(index_format)(37 downto 34); --3GA
            when others => rdata1 <= format_test(index_format)(33 downto 30); --others
        end case;
    end if;
end process;

process(sdi_clk,nRST_sdi)
begin
    if(nRST_sdi = '0') then
        int_vpid_byte1 <= (others => '0');
    elsif rising_edge(sdi_clk) then
        case tx_std is
            when "111" => int_vpid_byte1 <= X"CE";       --12g
            when "100" => int_vpid_byte1 <= X"C0";       --6g
            when "101" => int_vpid_byte1 <= X"C0";       --6g
            when others => int_vpid_byte1 <= (X"8" & rdata1);--others
        end case;
    end if;
end process;

process(sdi_clk,nRST_sdi)
begin
    if(nRST_sdi = '0') then
        rdata2  <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if (index_format = 4 or index_format = 5 or tx_std = "000" ) then
            rdata2 <= X"0";
        else
            rdata2 <= X"C";
        end if;
    end if;
end process;

process(sdi_clk,nRST_sdi)
begin
    if(nRST_sdi = '0') then
        vpid_part  <= (others => '0');
    elsif rising_edge(sdi_clk) then        
        case index_format is
            when 12 => vpid_part <= X"B";
            when 13 => vpid_part <= X"9";
            when others => vpid_part <= format_test(index_format)(25 downto 22);
        end case;
    end if;
end process;

process(sdi_clk,nRST_sdi)
begin
    if(nRST_sdi = '0') then
        int_vpid_byte2_a  <= (others => '0');
    elsif rising_edge(sdi_clk) then    
        case tx_std is
            when "111" => int_vpid_byte2_a <= rdata2 & vpid_part;
            when "011" => int_vpid_byte2_a <= rdata2 & vpid_part;
--            when "100" => int_vpid_byte2_a <= rdata2 & vpid_part;
--            when "101" => int_vpid_byte2_a <= rdata2 & vpid_part;
            when others => int_vpid_byte2_a <= rdata2 & format_test(index_format)(25 downto 22);
        end case;
    end if;
end process;
    
process(sdi_clk,nRST_sdi)    
begin
    if(nRST_sdi = '0') then
        int_vpid_byte2 <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if ntsc_paln = '1' then 
            case int_vpid_byte2_a(3 downto 0) is
                when "0011" => int_vpid_byte2 <= int_vpid_byte2_a(7 downto 4) & X"2";
                when "0111" => int_vpid_byte2 <= int_vpid_byte2_a(7 downto 4) & X"6";
                when "1011" => int_vpid_byte2 <= int_vpid_byte2_a(7 downto 4) & X"A";
                when others  => int_vpid_byte2 <= int_vpid_byte2_a;
            end case;
        else
            int_vpid_byte2 <= int_vpid_byte2_a;
        end if;
    end if;
end process;

end behav;