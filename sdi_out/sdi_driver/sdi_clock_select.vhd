----------------------------------------------------------------------------------
-- 2025/08/14 LS
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity sdi_clock_select is
port(
    --sys
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic; --100Mhz
    --sdi
    refclk0                     : in  std_logic; --sdi_clk
    refclk_rst                  : out std_logic;

    refclk_change               : in  std_logic; --1 148.5MHz, 0 148.35MHz
    
    refclk_pll_locked           : in  std_logic;
    refclk_cl_busy              : out std_logic

);
end entity;

architecture behav of sdi_clock_select is


signal pos_edge_flag              : std_logic;
signal neg_edge_flag              : std_logic;

signal refclk_pll_locked_d        : std_logic;
signal refclk_pll_locked_rising   : std_logic; 

signal refclk_change_d            : std_logic; 
signal refclk_change_rising       : std_logic;
signal refclk_change_falling      : std_logic;

begin

process(sysclk, nRST)
begin
    if nRST = '0' then
        refclk_change_d      <= '0';
        refclk_change_rising <= '0';
        refclk_change_falling<= '0';

    elsif rising_edge(sysclk) then
        refclk_change_rising  <= '0';
        refclk_change_falling <= '0';

        if refclk_change = '1' and refclk_change_d = '0' then
            refclk_change_rising <= '1';
        else 
            refclk_change_rising <= '0';        
        end if;

        if refclk_change = '0' and refclk_change_d = '1' then
            refclk_change_falling <= '1';
        else
            refclk_change_falling <= '0';            
        end if;

        refclk_change_d <= refclk_change;
    end if;
end process;


process(sysclk, nRST)
begin
    if nRST = '0' then
        refclk_cl_busy <= '0';
    elsif rising_edge(sysclk) then
        if refclk_change_rising = '1' or refclk_change_falling = '1' then
            refclk_cl_busy <= '1';
        elsif refclk_pll_locked_rising = '1' then
            refclk_cl_busy <= '0';
        end if;
    end if;
end process ;

process(sysclk, nRST)
begin
    if nRST = '0' then
        refclk_pll_locked_d      <= '0';
        refclk_pll_locked_rising <= '0';
    elsif rising_edge(sysclk) then
        refclk_pll_locked_rising  <= '0';

        if refclk_pll_locked = '1' and refclk_change_d = '0' then
            refclk_pll_locked_rising <= '1';
        else
            refclk_pll_locked_rising <= '0';
        end if;

        refclk_pll_locked_d <= refclk_pll_locked;

    end if;
end process;

--cross domain







process(sysclk, nRST)
begin
    if nRST = '0'then 
    elsif rising_edge(sysclk) then

    end if;
end process;


end behav;