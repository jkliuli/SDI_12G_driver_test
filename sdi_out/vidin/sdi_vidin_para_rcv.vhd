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

entity sdi_vidin_para_rcv is
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
end entity;

architecture behav of sdi_vidin_para_rcv is

signal frame_vsync_en           : std_logic;
signal frame_vsync_en_d1        : std_logic;
signal get_vidsrc_en            : std_logic;
signal vidsrc_index             : std_logic_vector(7 downto 0);

component vsync_stable_check is
generic(
    SIM                         : std_logic:= '0'
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    time_ms_en                  : in  std_logic;

    vsync_in                    : in  std_logic;
    vsync_stable                : out std_logic
);
end component;
signal vsync_in                 : std_logic;
signal vsync_stable             : std_logic;

begin

vsync_stable_check_inst: vsync_stable_check
generic map(
    SIM                         => SIM
)
port map(
    nRST                        => nRST        ,
    sysclk                      => sysclk      ,
    time_ms_en                  => time_ms_en  ,

    vsync_in                    => vsync_in    ,
    vsync_stable                => vsync_stable
);

process(nRST,sysclk)
begin
    if nRST = '0' then
        frame_vsync_en <= '0';
        frame_vsync_en_d1 <= '0';
        get_vidsrc_en <= '0';
        vidin_black_en <= '1';
        led_forced_ctrl <= '0';
        led_forced_val <= '0';
    elsif rising_edge(sysclk) then
        if vidin_start = '1' and vidin_wren = '1' and vidin_data(15 downto 0) = x"01fb" then
            frame_vsync_en <= '1';
        elsif vidin_end = '1' and vidin_wren = '1' then
            frame_vsync_en <= '0';
        end if;
        frame_vsync_en_d1 <= frame_vsync_en;

        if vidin_start = '1' and vidin_wren = '1' and vidin_data(15 downto 0) = x"01fb" then
            get_vidsrc_en <= '1';
            led_forced_ctrl <= vidin_data(63);
            led_forced_val  <= vidin_data(56);
        elsif get_vidsrc_en = '1' and vidin_wren = '1' then
            get_vidsrc_en <= '0';
            vidsrc_index <= vidin_data(7 downto 0);
            vidin_black_en <= vidin_data(8*8);
            port_area_zero_flag <= vidin_data(65);

            brightness_manual_en <=vidin_data(64);
            brightness_manual    <=vidin_data(63 downto 56);
        end if;

    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        vsync_in <= '0';
        vidin_vsneg <= '0';
        vidin_stable <= '0';
    elsif rising_edge(sysclk) then
        if frame_vsync_en_d1 = '1' and frame_vsync_en = '0' and vidsrc_index = 0 then
            vsync_in <= '1';
        else
            vsync_in <= '0';
        end if;
        vidin_vsneg <= vsync_in and vsync_stable;
        vidin_stable <= vsync_stable;
    end if;
end process;


end behav;