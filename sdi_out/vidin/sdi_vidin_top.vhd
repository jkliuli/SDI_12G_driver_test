----------------------------------------------------------------------------------
-- Create Date: 9:35 2022/10/9
--
-- Engineer: lijb
--
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sdi_vidin_top is
generic(
    SIM                         : std_logic:= '0'
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    time_ms_en                  : in  std_logic;

    vidin_start                 : in  std_logic;
    vidin_end                   : in  std_logic;
    vidin_wren                  : in  std_logic;
    vidin_data                  : in  std_logic_vector(191 downto 0);

    vid_vsneg                   : out std_logic;
    vid_stable                  : out std_logic;
    format_10bit_src            : out std_logic ;
    format_10bit_vsync          : out std_logic_vector(1 downto 0);
 
    vid_wren                    : out std_logic;
    vid_data                    : out std_logic_vector(192+3-1 downto 0);

    led_forced_ctrl             : out std_logic;
    led_forced_val              : out std_logic;
    brightness_manual_en        : out std_logic;
    brightness_manual           : out std_logic_vector(8-1 downto 0);
    port_area_zero_flag         : out std_logic
);
end entity;

architecture behav of sdi_vidin_top is

component sdi_vidin_para_rcv is
generic(
    SIM                         : std_logic:= '0'
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    time_ms_en                  : in  std_logic;

    vidin_start                 : in  std_logic;
    vidin_end                   : in  std_logic;
    vidin_wren                  : in  std_logic;
    vidin_data                  : in  std_logic_vector(191 downto 0);

    vidin_vsneg                 : out std_logic;
    vidin_stable                : out std_logic;
    vidin_black_en              : out std_logic;

    led_forced_ctrl             : out std_logic;
    led_forced_val              : out std_logic;
    brightness_manual_en        : out std_logic;
    brightness_manual           : out std_logic_vector(8-1 downto 0);
    port_area_zero_flag         : out std_logic
);
end component;
signal vidin_black_en           : std_logic;


component sdi_vidin_data_rcv is
generic(
    SIM                         : std_logic:= '0'
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    time_ms_en                  : in  std_logic;
    
   

    vidin_start                 : in  std_logic;
    vidin_end                   : in  std_logic;
    vidin_wren                  : in  std_logic;
    vidin_data                  : in  std_logic_vector(191 downto 0);

    vidin_black_en              : in  std_logic;
    format_10bit_src            : out std_logic ;
    format_10bit_vsync          : out std_logic_vector(1 downto 0);
 
    vid_wren                    : out std_logic;
    vid_data                    : out std_logic_vector(192+3-1 downto 0)
);
end component;


begin


sdi_vidin_para_rcv_inst: sdi_vidin_para_rcv
generic map(
    SIM                         => SIM
)
port map(
    nRST                        => nRST                 ,
    sysclk                      => sysclk               ,
    time_ms_en                  => time_ms_en           ,

    vidin_start                 => vidin_start          ,
    vidin_end                   => vidin_end            ,
    vidin_wren                  => vidin_wren           ,
    vidin_data                  => vidin_data           ,

    vidin_vsneg                 => vid_vsneg            ,
    vidin_stable                => vid_stable           ,
    vidin_black_en              => vidin_black_en       ,

    led_forced_ctrl             => led_forced_ctrl      , 
    led_forced_val              => led_forced_val       , 
    brightness_manual_en        => brightness_manual_en ,
    brightness_manual           => brightness_manual    ,
    port_area_zero_flag         => port_area_zero_flag  
);


sdi_vidin_data_rcv_inst: sdi_vidin_data_rcv
generic map(
    SIM                         => SIM
)
port map(
    nRST                        => nRST                 ,
    sysclk                      => sysclk               ,
    time_ms_en                  => time_ms_en           ,

    vidin_start                 => vidin_start          ,
    vidin_end                   => vidin_end            ,
    vidin_wren                  => vidin_wren           ,
    vidin_data                  => vidin_data           ,
    
 
    vidin_black_en              => vidin_black_en       ,
    format_10bit_src            => format_10bit_src     ,
    format_10bit_vsync          => format_10bit_vsync   ,
    vid_wren                    => vid_wren             ,
    vid_data                    => vid_data
);


end behav;