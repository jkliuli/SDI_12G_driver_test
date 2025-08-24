----------------------------------------------------------------------------------
-- Company:
-- Engineer: lijb
--
-- Create Date: 2020/04/15
-- Design Name:
-- Module Name: vsync_monitor - behav
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vsync_monitor is
generic(
    DELAY                       : integer:= 5;
    PENUM                       : integer:= 10      --PENUM means "permissible error number".
);
port(
    nRST                        : in  std_logic;
    refclk                      : in  std_logic;
    monitor_en                  : in  std_logic;
    source_vsync_neg            : in  std_logic;--1 pulse only in refclk
    sink_vsync_neg              : in  std_logic;--1 pulse only in refclk

    vsync_lost_odck             : out std_logic;
    not_pass                    : out std_logic
);
end entity;

architecture behav of vsync_monitor is

signal detec_en                 : std_logic;
signal detec_cnt                : std_logic_vector(7 downto 0);
signal detec_not_pass           : std_logic;

begin




process(refclk,nRST)
begin
    if nRST = '0' then
        detec_en <= '1';
        detec_cnt <= (others => '0');
        detec_not_pass <= '0';
        vsync_lost_odck <= '0';
    elsif rising_edge(refclk) then
        if monitor_en = '1' then
            if source_vsync_neg = '1' and sink_vsync_neg = '1' then
                detec_en <= '0';
                vsync_lost_odck <= '0';
            elsif (source_vsync_neg = '1' or sink_vsync_neg = '1') and (detec_en = '0') then
                detec_en <= '1';
                if sink_vsync_neg = '1' then
                    vsync_lost_odck <= '1';
                else
                    vsync_lost_odck <= '0';
                end if;
            elsif (source_vsync_neg = '1' or sink_vsync_neg = '1') and (detec_en = '1') then
                detec_en <= '0';
                vsync_lost_odck <= '0';
            end if;

            if (source_vsync_neg = '1' or sink_vsync_neg = '1') and (detec_en = '0') then
                detec_cnt <= (others => '0');
            elsif detec_en = '1' then
                if detec_cnt(7) = '0' then
                    detec_cnt <= detec_cnt + 1;--count max 128
                -- else
                    -- detec_cnt <= detec_cnt;
                end if;
            end if;

            if (source_vsync_neg = '1' and sink_vsync_neg = '1')then
                if detec_en = '0' then
                    detec_not_pass <= '0';
                else
                    detec_not_pass <= '1';
                end if;
            elsif (source_vsync_neg = '1' or sink_vsync_neg = '1') and (detec_en = '1') then
                if detec_cnt > DELAY+PENUM-1 then
                    detec_not_pass <= '1';
                else
                    detec_not_pass <= '0';
                end if;
            else
                detec_not_pass <= '0';
            end if;
        else
            detec_en <= '1';--"monitor_en = '1' when source_vsync_neg = '1'."    so the next vsync must be "sink_vsync_neg".
            detec_cnt <= (others => '0');
            detec_not_pass <= '0';
            vsync_lost_odck <= '0';
        end if;
    end if;
end process;
not_pass <= detec_not_pass;




end behav;