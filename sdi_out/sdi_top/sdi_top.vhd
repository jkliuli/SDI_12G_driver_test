--#######################################################################
--2025/03/04 maojin
--
--sdi_param
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity sdi_top is
generic(
    FRAME_W								: integer:= 11;
    NUM_STREAMS                         : integer:= 4;
    SDI_NUM_USE                         : integer:= 4;
    SDI_NUM_PORT_TURE                   : integer:= 4
);
port(
    sysclk                              : in std_logic;
    nRST                                : in std_logic;

    odck_ref                            : in std_logic;--to sdi IP
    clk_user                            : in std_logic;

    time_ms_en                          : in  std_logic;

    sdi_vidin_start                     : in  std_logic;
    sdi_vidin_end                       : in  std_logic;
    sdi_vidin_wren                      : in  std_logic;
    sdi_vidin_data                      : in  std_logic_vector(191 downto 0);
    sdi_vidin_fifo_wcnt                 : out std_logic_vector(10 downto 0);

    --pbus
    pframe_ss							: in  std_logic;
	ptype								: in  std_logic_vector(7 downto 0);
	pwren								: in  std_logic;
	paddr								: in  std_logic_vector(FRAME_W-1 downto 0);
	pdata								: in  std_logic_vector(7 downto 0);

    tx_rcfg_cal_busy                    : in  std_logic;
    gxb_tx_serial_data                  : out std_logic;
    tx_pll_locked                       : out std_logic;
    gxb_tx_cal_busy                     : out std_logic;
    gxb_tx_ready                        : out std_logic;

    work_LED                            : out std_logic_vector(SDI_NUM_PORT_TURE-1 downto 0)

);
end entity;

architecture behav of sdi_top is
    

--component clk_io is
--port (
--	inclk                               : in  std_logic := 'X'; -- clk
--	outclk                              : out std_logic         -- clk
--);
--end component clk_io;

signal clk_100m                         : std_logic;



component sdi_out_top is
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
end component;
signal work_status                      : std_logic_vector(1 downto 0);

component sdi_vidin_top is
generic(
    SIM                                 : std_logic:= '0'
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;
    format_10bit_vsync                  : out std_logic_vector(1 downto 0);
    format_10bit_src                    : out std_logic   ;

    vidin_start                         : in  std_logic;
    vidin_end                           : in  std_logic;
    vidin_wren                          : in  std_logic;
    vidin_data                          : in  std_logic_vector(191 downto 0);

    vid_vsneg                           : out std_logic;
    vid_stable                          : out std_logic;
    vid_wren                            : out std_logic;
    vid_data                            : out std_logic_vector(192+3-1 downto 0);

    led_forced_ctrl                     : out std_logic;
    led_forced_val                      : out std_logic;
    brightness_manual_en                : out std_logic;
    brightness_manual                   : out std_logic_vector(8-1 downto 0);
    port_area_zero_flag                 : out std_logic
);
end component;

signal vid_vsneg                        : 	std_logic								  := '0'         ;
signal vid_stable                       : 	std_logic								  := '0'         ;
signal vid_wren                         : 	std_logic								  := '0'         ;
signal vid_data                         : 	std_logic_vector(192+3-1 downto 0)        :=(others=>'0');

signal brightness_manual_en             : std_logic;
signal brightness_manual                : std_logic_vector(8-1 downto 0);

signal format_10bit_src                 : std_logic ;
signal format_10bit_vsync               : std_logic_vector(1 downto 0);
signal port_area_zero_flag              : std_logic;
signal led_forced_ctrl                  : std_logic;
signal led_forced_val                   : std_logic;



begin

--clk_io_inst : clk_io
--port map (
--	inclk                               => clk_user                 ,  --  inclk.clk
--	outclk                              => clk_100m                    -- outclk.clk
--);
clk_100m <= clk_user;

sdi_out_top_inst: sdi_out_top
generic map(
    FRAME_W								=> FRAME_W		            ,
    NUM_STREAMS                         => NUM_STREAMS              
)   
port map(   
    sysclk                              => sysclk                   ,
    nRST                                => nRST                     ,

    odck_ref                            => odck_ref                 ,
    clk_100m                            => clk_100m                 ,

    time_ms_en                          => time_ms_en               ,

    vid_vsneg                           => vid_vsneg                ,
    vid_stable                          => vid_stable               ,
    vid_wren                            => vid_wren                 ,
    vid_data                            => vid_data                 ,
    vidsrc_fifo_wcnt                    => sdi_vidin_fifo_wcnt      ,
    
    --sys clock domain 
    format_10bit_src_sysclk             => format_10bit_src         ,
    format_10bit_vsync_sysclk           => format_10bit_vsync       ,
    brightness_manual_en                => brightness_manual_en     ,
    brightness_manual                   => brightness_manual        ,

    --pbus
    pframe_ss							=> pframe_ss	            ,
    ptype								=> ptype		            ,
    pwren								=> pwren		            ,
    paddr								=> paddr		            ,
    pdata								=> pdata		            ,

    work_status                         => work_status              ,

    gxb_tx_serial_data                  => gxb_tx_serial_data       ,
    tx_pll_locked                       => tx_pll_locked            ,     
    gxb_tx_cal_busy                     => gxb_tx_cal_busy          ,   
    gxb_tx_ready                        => gxb_tx_ready             ,      
    tx_rcfg_cal_busy                    => tx_rcfg_cal_busy         

);

sdi_vidin_top_inst: sdi_vidin_top
generic map(
    SIM                                 => '0'
)
port map(
    nRST                                => nRST                     ,
    sysclk                              => sysclk                   ,
    time_ms_en                          => time_ms_en               ,
    format_10bit_src                    => format_10bit_src         ,
    format_10bit_vsync                  => format_10bit_vsync       ,

    vidin_start                         => sdi_vidin_start         ,
    vidin_end                           => sdi_vidin_end           ,
    vidin_wren                          => sdi_vidin_wren          ,
    vidin_data                          => sdi_vidin_data          ,

    vid_vsneg                           => vid_vsneg                ,
    vid_stable                          => vid_stable               ,
    vid_wren                            => vid_wren                 ,
    vid_data                            => vid_data                 ,

    led_forced_ctrl                     => led_forced_ctrl          , 
    led_forced_val                      => led_forced_val           , 
    brightness_manual_en                => brightness_manual_en     ,
    brightness_manual                   => brightness_manual        ,
    port_area_zero_flag                 => port_area_zero_flag      
);






end behav;