

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity clk_mea_top is  
generic (
 CLK_NUM: integer:= 1
);
port 
(  
   nRST_sys  :   in  std_logic ;
   sysclk    :   in  std_logic ; ---200M 
   
   clk_set   :   in  std_logic_vector(CLK_NUM-1 downto 0);
   
   clk_cnt_o   :  out std_logic_vector(CLK_NUM*32-1 downto 0);
   done_val_o  :  out std_logic_vector(CLK_NUM -1 downto 0);
   mask_out_o  : out std_logic

);
end clk_mea_top;

architecture beha of clk_mea_top is 

component measure_clk_check is 
port 
(
    nRST : in std_logic ;
    dur_en: in std_logic ;
    measured_clk_in: in std_logic ;
    
    capture_clk_in  : in std_logic;
    cnt_val: out std_logic_vector(31 downto 0);
    
    done_val : out std_logic
    
);
end component ;

signal done_val : std_logic_vector(CLK_NUM-1 downto 0);
signal clk_cnt  : std_logic_vector(CLK_NUM*32-1 downto 0);
signal mask_out    : std_logic := '0';
signal test_dur_en : std_logic := '0';
signal mmcnt       : std_logic_vector(31 downto 0) :=(others=>'0');

signal cnt_a : std_logic_vector(5*8-1 downto 0);
 

constant START_CYCLES : integer := 10000;
-- constant DUR_CYCLES   : integer := 100000*125; ----8,ms000,000ns *125=1000ms=1s
constant DUR_CYCLES   : integer := 100000*200; ----5ns, ms000,000ns *125=1000ms=1s

begin 


process(nRST_sys,sysclk)
begin 
    if rising_edge(sysclk) then 
         if clk_cnt = 0 then 
             mask_out <= '0';
         else 
             mask_out <= '1';
         end if;
         if mmcnt >= (START_CYCLES+DUR_CYCLES)*2+10 then 
             mmcnt <= (others=>'0');
         else 
             mmcnt <= mmcnt + 1 ;
         end if;
         if mmcnt >=START_CYCLES  AND mmcnt <START_CYCLES+DUR_CYCLES then 
             test_dur_en <= '1' ;
         else 
             test_dur_en <= '0';
         end if;
    end if;
end process;


mm: for i in 0 to CLK_NUM-1 generate 
 mc: measure_clk_check  
    port  map
    (
        nRST    => nRST_sys  ,
        dur_en  => test_dur_en ,
        measured_clk_in => clk_set(i) , 
        
        capture_clk_in  => sysclk ,
        cnt_val         => clk_cnt(31+32*i downto 32*i),
        
        done_val        => done_val(i)
        
    );
end generate mm;


    clk_cnt_o   <= clk_cnt ;
   done_val_o   <= done_val;
   mask_out_o   <= mask_out;


end beha ;
