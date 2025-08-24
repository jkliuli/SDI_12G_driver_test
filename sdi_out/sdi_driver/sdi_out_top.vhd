--#######################################################################
--2025/02/25 maojin
--2025/08/12 LS
--sdi_top
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity sdi_out_top is
generic(
    FRAME_W								: integer:= 11;
    NUM_STREAMS                         : integer:= 4
);
port(
    sysclk                              : in std_logic;
    nRST                                : in std_logic;

    odck_ref                            : in std_logic;--to sdi IP
    clk_100m                            : in std_logic;

    time_ms_en                          : in  std_logic;

    vid_vsneg                           : in  std_logic;
    vid_stable                          : in  std_logic;
    vid_wren                            : in  std_logic;
    vid_data                            : in  std_logic_vector(192+3-1 downto 0);
    vidsrc_fifo_wcnt                    : out std_logic_vector(10 downto 0);

    --sys clock domain 
    format_10bit_src_sysclk             : in  std_logic; --'0': from 2C frames, 1: FROM SERDES
    format_10bit_vsync_sysclk           : in  std_logic_vector(1 downto 0);  --sysclk domain 
    brightness_manual_en                : in  std_logic;
    brightness_manual                   : in  std_logic_vector(8-1 downto 0);

    --pbus
    pframe_ss							: in  std_logic;
	ptype								: in  std_logic_vector(7 downto 0);
	pwren								: in  std_logic;
	paddr								: in  std_logic_vector(FRAME_W-1 downto 0);
	pdata								: in  std_logic_vector(7 downto 0);

    work_status                         : out std_logic_vector(1 downto 0);

    gxb_tx_serial_data                  : out std_logic;
    tx_pll_locked                       : out std_logic;
    gxb_tx_cal_busy                     : out std_logic;
    gxb_tx_ready                        : out std_logic;
    tx_rcfg_cal_busy                    : in  std_logic

);
end entity;

architecture behav of sdi_out_top is

attribute keep : boolean;

signal nRST_sdi                         : std_logic;
signal sdi_clk                          : std_logic:= '0';
signal tx_enable                        : std_logic;

signal ntsc_paln                        : std_logic:= '0';
signal format_select                    : std_logic_vector(3 downto 0):= "1100"; --1080p60
signal tx_std                           : std_logic_vector(2 downto 0):= "101"; --3G A


attribute keep of nRST_sdi         : signal is true;
attribute keep of sdi_clk          : signal is true;
attribute keep of tx_enable        : signal is true;
attribute keep of ntsc_paln        : signal is true;
attribute keep of format_select    : signal is true;
attribute keep of tx_std           : signal is true;

signal sdi_tx_enable                     : std_logic;   
signal sdi_tx_std                        : std_logic_vector(2 downto 0);  
signal sdi_tx_trs                        : std_logic; 
signal sdi_tx_ln                         : std_logic_vector(NUM_STREAMS*11-1 downto 0);    
signal sdi_tx_ln_b                       : std_logic_vector(NUM_STREAMS*11-1 downto 0);      
signal sdi_tx_data                       : std_logic_vector(NUM_STREAMS*20-1 downto 0); 
signal sdi_tx_vld                        : std_logic:='0'; 
signal viout_anc                         : std_logic;--Just to check the ANC signal. attribute keep

signal vidout_din_en                    : std_logic;---to req data in
signal vidout_data                      : std_logic_vector(NUM_STREAMS*20-1 downto 0);--YCBCR
signal vidout_data_vld                  : std_logic;
signal vidout_vs                        : std_logic;
signal vidout_word_cnt                  : std_logic_vector(12 downto 0);

signal vid_rden                         : std_logic;
signal vid_q                            : std_logic_vector(192+3-1 downto 0);


signal words_per_active_line            : std_logic_vector(12 downto 0);  --Total words in active part of line  pixel
signal words_per_total_line             : std_logic_vector(12 downto 0);  --Total words per line
signal lines_per_frame                  : std_logic_vector(10 downto 0);  --Total lines per frame
signal line_hanc_word                   : std_logic_vector(11 downto 0);  --hanc words per line
signal sd_hanc_y_word                   : std_logic_vector(7 downto  0);  --sd hanc y words per line
signal f_rise_line                      : std_logic_vector(10 downto 0);--defualt is 0
signal f_fall_line                      : std_logic_vector(10 downto 0);--defualt is 0
signal v_fall_line_1                    : std_logic_vector(10 downto 0);-- Line number when V falls for first field
signal v_rise_line_1                    : std_logic_vector(10 downto 0);-- Line number when V rises for first field
signal v_fall_line_2                    : std_logic_vector(10 downto 0);-- defualt is 0
signal v_rise_line_2                    : std_logic_vector(10 downto 0);-- defualt is 0
signal vpid_line_f0                     : std_logic_vector(10 downto 0);--how much line to insert vpid 
signal vpid_line_f1                     : std_logic_vector(10 downto 0);
signal vpid_byte1                       : std_logic_vector(7 downto 0);
signal vpid_byte2                       : std_logic_vector(7 downto 0);
signal vpid_byte3                       : std_logic_vector(7 downto 0);
signal vpid_byte4                       : std_logic_vector(7 downto 0);
signal vpid_byte1_b                     : std_logic_vector(7 downto 0);
signal vpid_byte2_b                     : std_logic_vector(7 downto 0);
signal vpid_byte3_b                     : std_logic_vector(7 downto 0);
signal vpid_byte4_b                     : std_logic_vector(7 downto 0);
signal format_10bit_en                  : std_logic;
signal format_bt601_en                  : std_logic_vector(2 downto 0); --colormetiry input defualt 0
signal param_bright_local               : std_logic_vector(7 downto 0);
signal param_chroma_r                   : std_logic_vector(7 downto 0);
signal param_chroma_g                   : std_logic_vector(7 downto 0);
signal param_chroma_b                   : std_logic_vector(7 downto 0);

signal ref_vs                           : std_logic;
signal ref_de                           : std_logic;

component sdi_makeframe is
generic(
    NUM_STREAMS                         : integer:= 4

);
port(
    sdi_clk                             : in  std_logic;
    sdi_nRST                            : in  std_logic;--vsync

    --from sdi_ip
    tx_enable                           : in  std_logic;  --from mapping

    sdi_tx_std                          : in  std_logic_vector(2 downto 0); 
    sdi_tx_trs                          : out std_logic;
    sdi_tx_ln                           : out std_logic_vector(NUM_STREAMS*11-1 downto 0);   
    sdi_tx_ln_b                         : out std_logic_vector(NUM_STREAMS*11-1 downto 0);       
    sdi_tx_data                         : out std_logic_vector(NUM_STREAMS*20-1 downto 0);
    sdi_tx_vld                          : out std_logic;

    --from ctrl
    vidout_din_en                       : out std_logic;---to req data in
    vidout_data                         : in  std_logic_vector(NUM_STREAMS*20-1 downto 0);--YCBCR
    vidout_data_vld                     : in  std_logic;
    viout_anc                           : out std_logic;--Just to check the ANC signal.
    vidout_word_cnt                     : out std_logic_vector(12 downto 0);
    vidout_vs                           : in std_logic;
    
    words_per_active_line               : in  std_logic_vector(12 downto 0);  --Total words in active part of line  pixel
    words_per_total_line                : in  std_logic_vector(12 downto 0);  --Total words per line
    lines_per_frame                     : in  std_logic_vector(10 downto 0);  --Total lines per frame
    line_hanc_word                      : in  std_logic_vector(11 downto 0);  --hanc words per line
    sd_hanc_y_word                      : in  std_logic_vector(7 downto  0);  --sd hanc y words per line
    --F V
    f_rise_line                         : in  std_logic_vector(10 downto 0);--defualt is 0
    f_fall_line                         : in  std_logic_vector(10 downto 0);--defualt is 0
    v_fall_line_1                       : in  std_logic_vector(10 downto 0);-- Line number when V falls for first field
    v_rise_line_1                       : in  std_logic_vector(10 downto 0);-- Line number when V rises for first field
    v_fall_line_2                       : in  std_logic_vector(10 downto 0);-- defualt is 0
    v_rise_line_2                       : in  std_logic_vector(10 downto 0);-- defualt is 0

    vpid_line_f0                        : in  std_logic_vector(10 downto 0);--how much line to insert vpid 
    vpid_line_f1                        : in  std_logic_vector(10 downto 0);

    vpid_byte1                          : in  std_logic_vector(7 downto 0);
    vpid_byte2                          : in  std_logic_vector(7 downto 0);
    vpid_byte3                          : in  std_logic_vector(7 downto 0);
    vpid_byte4                          : in  std_logic_vector(7 downto 0);
    vpid_byte1_b                        : in  std_logic_vector(7 downto 0);
    vpid_byte2_b                        : in  std_logic_vector(7 downto 0);
    vpid_byte3_b                        : in  std_logic_vector(7 downto 0);
    vpid_byte4_b                        : in  std_logic_vector(7 downto 0)

);
end component;




attribute keep of sdi_tx_enable : signal is true;
attribute keep of sdi_tx_std    : signal is true;
attribute keep of sdi_tx_trs    : signal is true;
attribute keep of sdi_tx_ln     : signal is true;
attribute keep of sdi_tx_ln_b   : signal is true;
attribute keep of sdi_tx_data   : signal is true;
attribute keep of sdi_tx_vld    : signal is true;

component sdi_mapping is
generic(
    NUM_STREAMS                         : integer:= 4 
);
port(
    nRST_sdi                            : in std_logic;
    sdi_clk                             : in std_logic;

    --sdi_makeframe
    tx_enable                           : out std_logic;

    vidout_din_en                       : in  std_logic;---to req data in
    vidout_data                         : out std_logic_vector(NUM_STREAMS*20-1 downto 0);--YCBCR
    vidout_data_vld                     : out std_logic;
    vidout_vs                           : out std_logic;
    vidout_word_cnt                     : in  std_logic_vector(12 downto 0);

    --for test
    words_per_active_line               : in  std_logic_vector(12 downto 0);  --Total words in active part of line  pixel

    --sdi_ip
    sdi_tx_enable                       : in  std_logic;
    sdi_tx_std                          : in  std_logic_vector(2 downto 0); 

    --from ctrl 
    vid_rden                            : out std_logic;
    vid_q                               : in  std_logic_vector(192+3-1 downto 0);

    format_10bit_en                     : in  std_logic;
    format_bt601_en                     : in  std_logic_vector(2 downto 0); --colormetiry input defualt 0

    ref_vs                              : in  std_logic;
    ref_de                              : in  std_logic;

    brightness_manual_en                : in std_logic;--this is black_en in LCD, so There is no use
    brightness_manual                   : in std_logic_vector(8-1 downto 0);
    
    param_bright_local                  : in  std_logic_vector(7 downto 0);
    param_chroma_r                      : in  std_logic_vector(7 downto 0);
    param_chroma_g                      : in  std_logic_vector(7 downto 0);
    param_chroma_b                      : in  std_logic_vector(7 downto 0)

);
end component;



component sdi_param is
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
    format_select                       : in std_logic_vector(3 downto 0); --1080p60
    tx_std                              : in std_logic_vector(2 downto 0); --3G A
    ntsc_paln                           : in std_logic; --1/1.001 flag


    nRST_sdi                            : in std_logic;
    sdi_clk                             : in std_logic;

    sdi_tx_std                          : out std_logic_vector(2 downto 0); 
    words_per_active_line               : out std_logic_vector(12 downto 0);  --Total words in active part of line  pixel
    words_per_total_line                : out std_logic_vector(12 downto 0);  --Total words per line
    lines_per_frame                     : out std_logic_vector(10 downto 0);  --Total lines per frame
    line_hanc_word                      : out std_logic_vector(11 downto 0);  --hanc words per line
    sd_hanc_y_word                      : out std_logic_vector(7 downto  0);  --sd hanc y words per line
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
end component;




attribute keep of words_per_active_line     : signal is true;
attribute keep of words_per_total_line      : signal is true;
attribute keep of lines_per_frame           : signal is true;
attribute keep of line_hanc_word            : signal is true;
attribute keep of sd_hanc_y_word            : signal is true;
attribute keep of f_rise_line               : signal is true;
attribute keep of f_fall_line               : signal is true;
attribute keep of v_fall_line_1             : signal is true;
attribute keep of v_rise_line_1             : signal is true;
attribute keep of v_fall_line_2             : signal is true;
attribute keep of v_rise_line_2             : signal is true;
attribute keep of vpid_line_f0              : signal is true;
attribute keep of vpid_line_f1              : signal is true;
attribute keep of vpid_byte1                : signal is true;
attribute keep of vpid_byte2                : signal is true;
attribute keep of vpid_byte3                : signal is true;
attribute keep of vpid_byte4                : signal is true;
attribute keep of vpid_byte1_b              : signal is true;
attribute keep of vpid_byte2_b              : signal is true;
attribute keep of vpid_byte3_b              : signal is true;
attribute keep of vpid_byte4_b              : signal is true;
attribute keep of format_10bit_en           : signal is true;
attribute keep of format_bt601_en           : signal is true;
attribute keep of param_bright_local        : signal is true;
attribute keep of param_chroma_r            : signal is true;
attribute keep of param_chroma_g            : signal is true;
attribute keep of param_chroma_b            : signal is true;


component sdi_timing is
generic(
    NUM_STREAMS                         : integer:= 4 
);
port(
    nRST_sdi                            : in std_logic;
    sdi_clk                             : in std_logic;

    sdi_tx_std                          : in std_logic_vector(2 downto 0); 
    disp_en                             : in  std_logic;

    words_per_active_line               : in  std_logic_vector(12 downto 0);--Total words in active part of line  pixel
    words_per_total_line                : in  std_logic_vector(12 downto 0);--Total words per line
    lines_per_frame                     : in  std_logic_vector(10 downto 0);--Total lines per frame
    line_hanc_word                      : in  std_logic_vector(11 downto 0);--hanc words per line
    --F V
    f_rise_line                         : in  std_logic_vector(10 downto 0);--defualt is 0
    f_fall_line                         : in  std_logic_vector(10 downto 0);--defualt is 0
    v_fall_line_1                       : in  std_logic_vector(10 downto 0);-- Line number when V falls for first field
    v_rise_line_1                       : in  std_logic_vector(10 downto 0);-- Line number when V rises for first field
    v_fall_line_2                       : in  std_logic_vector(10 downto 0);-- defualt is 0
    v_rise_line_2                       : in  std_logic_vector(10 downto 0);-- defualt is 0

    ref_vs                              : out  std_logic;
    ref_de                              : out  std_logic

);
end component;




component sdi_dispctrl is
generic(
    SIM                                 : std_logic:= '0'
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;

    source_vsync                        : in  std_logic;--sysclk domain
    source_stable                       : in  std_logic;--sysclk domain
    work_status                         : out std_logic_vector(1 downto 0);--sysclk domain

    odck_ref                            : in  std_logic;
    sink_vsync                          : in  std_logic;--odck domain

    nRST_odck_out                       : out std_logic ;
    port_disable                        : in  std_logic;
    format_reset_sys                    : in  std_logic;
    disp_en                             : out std_logic --odck domain
);      
end component;  

signal disp_en                          : std_logic:= '1';
signal nRST_odck_out                    : std_logic:= '1';
signal port_disable                     : std_logic:= '0';
signal format_reset_sys                 : std_logic:= '0';


component tx_top is
generic(
    NUM_STREAMS                         : integer:= 4
);
port(
    
    tx_pll_refclk                       : in  std_logic;
    tx_rcfg_mgmt_clk                    : in  std_logic;
    tx_resetn                           : in  std_logic;
    tx_rcfg_mgmt_resetn                 : in  std_logic;
    tx_vid_data                         : in  std_logic_vector(NUM_STREAMS*20-1 downto 0);
    tx_vid_datavalid                    : in  std_logic;
    tx_vid_std                          : in  std_logic_vector(2 downto 0); 
    tx_vid_trs                          : in  std_logic;
    tx_vid_clkout                       : out std_logic;

    sdi_tx_enable_crc                   : in  std_logic;
    sdi_tx_enable_ln                    : in  std_logic;
    sdi_tx_ln                           : in  std_logic_vector(NUM_STREAMS*11-1 downto 0);
    sdi_tx_ln_b                         : in  std_logic_vector(NUM_STREAMS*11-1 downto 0);
    sdi_tx_datavalid                    : out std_logic;

    tx_rcfg_cal_busy                    : in  std_logic;
    tx_pll_locked                       : out std_logic;
    gxb_tx_cal_busy                     : out std_logic;
    gxb_tx_serial_data                  : out std_logic;
    gxb_tx_ready                        : out std_logic
);
end component;

component clk_mea_top is  
generic (
        CLK_NUM: integer:= 1
);
    port 
    (  
       nRST_sys                         :   in  std_logic ;
       sysclk                           :   in  std_logic ; ---200M 
       
       clk_set                          :   in  std_logic_vector(CLK_NUM-1 downto 0);
       
       clk_cnt_o                        :  out std_logic_vector(CLK_NUM*32-1 downto 0);
       done_val_o                       :  out std_logic_vector(CLK_NUM -1 downto 0);
       mask_out_o                       :  out std_logic
    
    );
end component;
signal clk_set                          : std_logic_vector(0 downto 0);

component fifo_195bit_2048 is
port (
    data                                : in  std_logic_vector(194 downto 0) := (others => 'X'); -- datain
    wrreq                               : in  std_logic                      := 'X';             -- wrreq
    rdreq                               : in  std_logic                      := 'X';             -- rdreq
    wrclk                               : in  std_logic                      := 'X';             -- wrclk
    rdclk                               : in  std_logic                      := 'X';             -- rdclk
    aclr                                : in  std_logic                      := 'X';             -- aclr
    q                                   : out std_logic_vector(194 downto 0);                    -- dataout
    rdusedw                             : out std_logic_vector(10 downto 0);                     -- rdusedw
    wrusedw                             : out std_logic_vector(10 downto 0);                     -- wrusedw
    rdempty                             : out std_logic;                                         -- rdempty
    wrfull                              : out std_logic                                          -- wrfull
);
end component fifo_195bit_2048;
signal vidsrc_fifo_rst                  : std_logic;
signal vidsrc_fifo_data                 : std_logic_vector(194 downto 0);
signal vidsrc_fifo_wren                 : std_logic;
signal vidsrc_fifo_rden                 : std_logic;
signal vidsrc_fifo_q                    : std_logic_vector(194 downto 0);
signal vidsrc_fifo_full                 : std_logic;
signal vidsrc_fifo_empty                : std_logic;
signal vidsrc_fifo_rcnt                 : std_logic_vector(10 downto 0);
-- signal vidsrc_fifo_wcnt                 : std_logic_vector(10 downto 0);
signal vidsrc_fifo_wren_p               : std_logic;
signal vidsrc_fifo_rden_p               : std_logic;
constant VIDSRC_FIFO_RST_CNT_MAX        : integer:= 3+2;
signal vidsrc_fifo_rst_cnt              : std_logic_vector(VIDSRC_FIFO_RST_CNT_MAX-1 downto 0);

signal test_vs                          : std_logic;
signal ref_vs_dly                       : std_logic_vector(100 downto 0);--sysclk domain
signal p_1                              : std_logic_vector(23 downto 0);
signal p_2                              : std_logic_vector(23 downto 0);
signal p_3                              : std_logic_vector(23 downto 0);                        
signal p_4                              : std_logic_vector(23 downto 0);
signal p_5                              : std_logic_vector(23 downto 0);
signal p_6                              : std_logic_vector(23 downto 0);
signal p_7                              : std_logic_vector(23 downto 0);
signal p_8                              : std_logic_vector(23 downto 0);
signal cnt                              : std_logic_vector(7 downto 0);
signal de_neg                           : std_logic;

begin

nRST_sdi      <= nRST;
nRST_odck_out <= nRST;

fifo_195bit_2048_inst : fifo_195bit_2048
port map (
    data                        => vidsrc_fifo_data     ,    --  fifo_input.datain
    wrreq                       => vidsrc_fifo_wren_p   ,   --            .wrreq
    rdreq                       => vidsrc_fifo_rden_p   ,   --            .rdreq
    wrclk                       => sysclk               ,   --            .wrclk
    rdclk                       => sdi_clk              ,   --            .rdclk
    aclr                        => vidsrc_fifo_rst      ,    --            .aclr
    q                           => vidsrc_fifo_q        ,       -- fifo_output.dataout
    rdusedw                     => vidsrc_fifo_rcnt     , --            .rdusedw
    wrusedw                     => vidsrc_fifo_wcnt     , --            .wrusedw
    rdempty                     => vidsrc_fifo_empty    , --            .rdempty
    wrfull                      => vidsrc_fifo_full        --            .wrfull
);

vidsrc_fifo_wren_p <= vidsrc_fifo_wren when vidsrc_fifo_full  = '0' else '0';
vidsrc_fifo_rden_p <= vidsrc_fifo_rden when vidsrc_fifo_empty = '0' else '0';
vidsrc_fifo_wren   <= vid_wren;
vidsrc_fifo_data   <= vid_data;
vidsrc_fifo_rden   <= vid_rden;
vid_q              <= vidsrc_fifo_q;
-- vid_q              <= (others => '1');
-- vid_q	<= X"111111111111111000001111111111000000000011110000"&"000";
-- process(nRST_sdi, sdi_clk)
-- begin
--     if ref_vs = '1' then
--         cnt <= (others => '0');  
--         de_neg <= '0';
--         vid_q<= (others => '0'); 
--     elsif rising_edge(sdi_clk) then
--         de_neg <= ref_de;
--         if(de_neg = '1' and ref_de = '0')then
--             cnt <= (others => '0'); 
--         elsif vid_rden = '1' then
--             cnt <= cnt + 8;
--         end if;
--         p_1 <= (cnt + 0)&(cnt + 0)&(cnt + 0);
--         p_2 <= (cnt + 1)&(cnt + 1)&(cnt + 1);
--         p_3 <= (cnt + 2)&(cnt + 2)&(cnt + 2);
--         p_4 <= (cnt + 3)&(cnt + 3)&(cnt + 3);
--         p_5 <= (cnt + 4)&(cnt + 4)&(cnt + 4);
--         p_6 <= (cnt + 5)&(cnt + 5)&(cnt + 5);
--         p_7 <= (cnt + 6)&(cnt + 6)&(cnt + 6);
--         p_8 <= (cnt + 7)&(cnt + 7)&(cnt + 7);

--         if(vid_rden = '1')then
--             vid_q <= "000"&p_8&p_7&p_6&p_5&p_4&p_3&p_2&p_1;
                    
--         end if;
--     end if;
-- end process;


process(nRST,sysclk)
begin
    if nRST = '0' then
        vidsrc_fifo_rst_cnt <= (others => '1');
        vidsrc_fifo_rst <= '1';
    elsif rising_edge(sysclk) then
        if vid_vsneg = '1' then
            vidsrc_fifo_rst_cnt <= (others => '1');
        else
            if vidsrc_fifo_rst_cnt(VIDSRC_FIFO_RST_CNT_MAX-1) = '1' then
                vidsrc_fifo_rst_cnt <= vidsrc_fifo_rst_cnt - '1';
            end if;
        end if;
        vidsrc_fifo_rst <= vidsrc_fifo_rst_cnt(VIDSRC_FIFO_RST_CNT_MAX-1);
    end if;
end process;

--test


sdi_param_inst: sdi_param
generic map(
    FRAME_W								=> FRAME_W
)
port map(
    sysclk                              => sysclk                       ,
    nRST                                => nRST                         ,

    --sys clock domain 
    format_10bit_src_sysclk             => format_10bit_src_sysclk      ,
    format_10bit_vsync_sysclk           => format_10bit_vsync_sysclk    ,

    --pbus
    pframe_ss							=> pframe_ss	                ,
    ptype								=> ptype		                ,
    pwren								=> pwren		                ,
    paddr								=> paddr		                ,
    pdata								=> pdata		                ,

    --for test
    format_select                       => format_select                , 
    tx_std                              => tx_std                       , 
    ntsc_paln                           => ntsc_paln                    , 

    nRST_sdi                            => nRST_odck_out                ,
    sdi_clk                             => sdi_clk                      ,

    sdi_tx_std                          => sdi_tx_std                   ,
    words_per_active_line               => words_per_active_line        ,
    words_per_total_line                => words_per_total_line         ,
    lines_per_frame                     => lines_per_frame              ,
    line_hanc_word                      => line_hanc_word               ,
    sd_hanc_y_word                      => sd_hanc_y_word               ,
    --F V
    f_rise_line                         => f_rise_line                  ,
    f_fall_line                         => f_fall_line                  ,
    v_fall_line_1                       => v_fall_line_1                ,
    v_rise_line_1                       => v_rise_line_1                ,
    v_fall_line_2                       => v_fall_line_2                ,
    v_rise_line_2                       => v_rise_line_2                ,

    vpid_line_f0                        => vpid_line_f0                 ,
    vpid_line_f1                        => vpid_line_f1                 ,

    vpid_byte1                          => vpid_byte1                   ,
    vpid_byte2                          => vpid_byte2                   ,
    vpid_byte3                          => vpid_byte3                   ,
    vpid_byte4                          => vpid_byte4                   ,
    vpid_byte1_b                        => vpid_byte1_b                 ,
    vpid_byte2_b                        => vpid_byte2_b                 ,
    vpid_byte3_b                        => vpid_byte3_b                 ,
    vpid_byte4_b                        => vpid_byte4_b                 ,

    format_10bit_en                     => format_10bit_en              ,
    format_bt601_en                     => format_bt601_en              ,
    
    param_bright_local                  => param_bright_local           ,
    param_chroma_r                      => param_chroma_r               ,
    param_chroma_g                      => param_chroma_g               ,
    param_chroma_b                      => param_chroma_b               

);

sdi_dispctrl_inst: sdi_dispctrl
generic map(
    SIM                                 => '0'
)
port map(
    nRST                                => nRST                   ,
    sysclk                              => sysclk                 ,
    time_ms_en                          => time_ms_en             ,

    source_vsync                        => vid_vsneg              ,--sysclk domain
    source_stable                       => vid_stable             ,--sysclk domain
    work_status                         => work_status            ,--sysclk domain

    odck_ref                            => sdi_clk                ,
    sink_vsync                          => ref_vs                 ,--odck domain

  --  nRST_odck_out                       => nRST_odck_out          ,
    nRST_odck_out                       => open                   , --test
    port_disable                        => port_disable           ,--sysclk domain
    format_reset_sys                    => format_reset_sys       ,--sysclk domain
    disp_en                             => disp_en                 --odck domain
);


sdi_timing_inst: sdi_timing
generic map(
    NUM_STREAMS                         => NUM_STREAMS 
)
port map(
    nRST_sdi                            => nRST_odck_out                ,
    sdi_clk                             => sdi_clk                      ,

    sdi_tx_std                          => sdi_tx_std                   ,
    disp_en                             => '0'                      ,

    words_per_active_line               => words_per_active_line        ,
    words_per_total_line                => words_per_total_line         ,
    lines_per_frame                     => lines_per_frame              ,
    line_hanc_word                      => line_hanc_word               ,
    --F V
    f_rise_line                         => f_rise_line                  ,
    f_fall_line                         => f_fall_line                  ,
    v_fall_line_1                       => v_fall_line_1                ,
    v_rise_line_1                       => v_rise_line_1                ,
    v_fall_line_2                       => v_fall_line_2                ,
    v_rise_line_2                       => v_rise_line_2                ,

    ref_vs                              => ref_vs                       ,
    ref_de                              => ref_de                       
);

sdi_mapping_inst: sdi_mapping
generic map(
    NUM_STREAMS                         => NUM_STREAMS
)
port map(
    nRST_sdi                            => nRST_odck_out                ,
    sdi_clk                             => sdi_clk                      ,

    --sdi_makeframe
    vidout_din_en                       => vidout_din_en                ,
    vidout_data                         => vidout_data                  ,
    vidout_data_vld                     => vidout_data_vld              ,
    vidout_vs                           => vidout_vs                    ,
    vidout_word_cnt                     => vidout_word_cnt              ,
    
    --for test 
    words_per_active_line               => words_per_active_line        ,  
    tx_enable                           => tx_enable                    ,--sdi_makeframe
    --sdi_ip
    sdi_tx_enable                       => sdi_tx_enable                ,
    sdi_tx_std                          => sdi_tx_std                   ,
    
    --from ctrl 
    vid_rden                            => vid_rden                     ,
    vid_q                               => vid_q                        ,

    format_10bit_en                     => format_10bit_en              ,
    format_bt601_en                     => format_bt601_en              ,

    ref_vs                              => ref_vs                       ,
    ref_de                              => ref_de                       ,

    brightness_manual_en                => brightness_manual_en         ,
    brightness_manual                   => brightness_manual            ,
    
    param_bright_local                  => param_bright_local           ,
    param_chroma_r                      => param_chroma_r               ,
    param_chroma_g                      => param_chroma_g               ,
    param_chroma_b                      => param_chroma_b               

);

sdi_makeframe_inst: sdi_makeframe
generic map(
    NUM_STREAMS                         => NUM_STREAMS
)
port map(
    sdi_clk                             => sdi_clk                      ,
    sdi_nRST                            => nRST_odck_out                ,

    --from sdi_ip
    tx_enable                           => sdi_tx_enable                    ,

    sdi_tx_std                          => sdi_tx_std                   ,
    sdi_tx_trs                          => sdi_tx_trs                   ,
    sdi_tx_ln                           => sdi_tx_ln                    ,
    sdi_tx_ln_b                         => sdi_tx_ln_b                  ,
    sdi_tx_data                         => sdi_tx_data                  ,
    sdi_tx_vld                          => sdi_tx_vld                   ,

    --from ctrl
    vidout_din_en                       => vidout_din_en                ,
    vidout_data                         => vidout_data                  ,
    vidout_data_vld                     => vidout_data_vld              ,
    viout_anc                           => viout_anc                    ,
    vidout_word_cnt                     => vidout_word_cnt              ,
    vidout_vs                           => vidout_vs                    ,
    
    words_per_active_line               => words_per_active_line        ,
    words_per_total_line                => words_per_total_line         ,
    lines_per_frame                     => lines_per_frame              ,
    line_hanc_word                      => line_hanc_word               ,
    sd_hanc_y_word                      => sd_hanc_y_word               ,
    --F V
    f_rise_line                         => f_rise_line                  ,
    f_fall_line                         => f_fall_line                  ,
    v_fall_line_1                       => v_fall_line_1                ,
    v_rise_line_1                       => v_rise_line_1                ,
    v_fall_line_2                       => v_fall_line_2                ,
    v_rise_line_2                       => v_rise_line_2                ,

    vpid_line_f0                        => vpid_line_f0                 ,
    vpid_line_f1                        => vpid_line_f1                 ,

    vpid_byte1                          => vpid_byte1                   ,
    vpid_byte2                          => vpid_byte2                   ,
    vpid_byte3                          => vpid_byte3                   ,
    vpid_byte4                          => vpid_byte4                   ,
    vpid_byte1_b                        => vpid_byte1_b                 ,
    vpid_byte2_b                        => vpid_byte2_b                 ,
    vpid_byte3_b                        => vpid_byte3_b                 ,
    vpid_byte4_b                        => vpid_byte4_b                 

);



tx_top_inst: tx_top
generic map(
    NUM_STREAMS                         => NUM_STREAMS
)
port map(
    tx_pll_refclk                       => odck_ref                     ,--297Mhz
    tx_rcfg_mgmt_clk                    => clk_100m                     ,--100M
    tx_resetn                           => nRST                         , 
    tx_rcfg_mgmt_resetn                 => nRST                         , 

    tx_vid_data                         => sdi_tx_data                  , 
    tx_vid_datavalid                    => sdi_tx_vld                   , 
    tx_vid_std                          => sdi_tx_std                   ,
    tx_vid_trs                          => sdi_tx_trs                   ,
    tx_vid_clkout                       => sdi_clk                      ,

    sdi_tx_enable_crc                   => '1'                          ,
    sdi_tx_enable_ln                    => '1'                          ,
    sdi_tx_ln                           => sdi_tx_ln                    ,
    sdi_tx_ln_b                         => sdi_tx_ln_b                  ,
    sdi_tx_datavalid                    => sdi_tx_enable                ,

    tx_rcfg_cal_busy                    => tx_rcfg_cal_busy             ,--
--    tx_rcfg_cal_busy                    => '0'                          ,
    tx_pll_locked                       => tx_pll_locked                ,
    gxb_tx_cal_busy                     => gxb_tx_cal_busy              ,
    gxb_tx_serial_data                  => gxb_tx_serial_data           ,
    gxb_tx_ready                        => gxb_tx_ready                 
);




---!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!test  simulation!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- sdi_clk  <= not sdi_clk after 10 ns;
-- sdi_tx_enable<= '1';
clk_set(0) <= sdi_clk;
CLK_MEA :clk_mea_top 
    port map 
    (  
        nRST_sys                         => nRST     ,
        sysclk                           => sysclk   ,    
        clk_set                          => clk_set  ,    
        clk_cnt_o                        => open     ,
        done_val_o                       => open     ,
        mask_out_o                       => open
    );

end behav;