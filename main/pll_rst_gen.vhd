--#######################################################################
--
--  LOGIC CORE:         pll_rst_gen                            
--  MODULE NAME:        pll_rst_gen()
--  COMPANY:             
--                              
--
--  REVISION HISTORY:  
--
--  Revision 0.1  07/20/2007    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is to generate the rst signal for pll
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pll_rst_gen is
port(
	clkin								: in  std_logic;
	pll_rst								: out std_logic
);
end entity;

architecture behav of pll_rst_gen is

signal rst_cnt							: std_logic_vector(15 downto 0):= (others => '0');

begin

process(clkin)
begin	
	if rising_edge(clkin) then
		if rst_cnt(15) = '0' then
			rst_cnt <= rst_cnt + '1';
		end if;

		pll_rst <= not rst_cnt(15);
	end if;
end process;


end behav;

