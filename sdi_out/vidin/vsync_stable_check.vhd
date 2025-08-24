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

entity vsync_stable_check is
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
end entity;

architecture behav of vsync_stable_check is


signal vsync_neg_buf            : std_logic_vector(2 downto 0);
signal vsync_neg                : std_logic;

constant MS_CNT_W               : integer:= 8;
signal ms_cnt                   : std_logic_vector(MS_CNT_W-1 downto 0);
signal vsync_en                 : std_logic;

constant VSYNC_CNT_W            : integer:= 5;
signal vsync_cnt                : std_logic_vector(VSYNC_CNT_W-1 downto 0);


begin



process(nRST,sysclk)
begin
    if nRST = '0' then
        vsync_neg_buf <= (others => '0');
        vsync_neg     <= '0';
    elsif rising_edge(sysclk) then
        vsync_neg_buf <= vsync_neg_buf(1 downto 0)&vsync_in;

        if vsync_neg_buf(2 downto 1) = "10" then
            vsync_neg <= '1';
        else
            vsync_neg <= '0';
        end if;

    end if;
end process;


process(nRST,sysclk)
begin
    if nRST = '0' then
        ms_cnt   <= (others => '1');
        vsync_en <= '0';
    elsif rising_edge(sysclk) then

        if vsync_neg = '1' then
            ms_cnt <= (others => '0');
        elsif time_ms_en = '1' then
            if ms_cnt(MS_CNT_W-1) = '0' then
                ms_cnt <= ms_cnt + '1';
            end if;
        end if;

        vsync_en <= not ms_cnt(MS_CNT_W-1);

    end if;
end process;


process(nRST,sysclk)
begin
    if nRST = '0' then
        vsync_cnt    <= (others => '0');
        vsync_stable <= '0';
    elsif rising_edge(sysclk) then

        if vsync_en = '0' then
            vsync_cnt <= (others => '0');
        else
            if vsync_neg = '1' then
                if vsync_cnt(VSYNC_CNT_W-1) = '0' then
                    vsync_cnt <= vsync_cnt + '1';
                end if;
            end if;
        end if;

        vsync_stable <= vsync_cnt(VSYNC_CNT_W-1) or SIM;

    end if;
end process;




end behav;