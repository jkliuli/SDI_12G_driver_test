
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity measure_clk_check is 
port 
(
    nRST : in std_logic ;
    dur_en: in std_logic ;
    measured_clk_in: in std_logic ;
    
    capture_clk_in  : in std_logic;
    cnt_val: out std_logic_vector(31 downto 0);
    
    ---SYNC_3D : out std_logic;
    done_val : out std_logic
    
);
end measure_clk_check;

architecture beha_testclk of measure_clk_check is 
signal dly1_dur_en : std_logic_vector(3 downto 0):=(others=>'0');
signal dly2_dur_en : std_logic_vector(1 downto 0):=(others=>'0');
signal cnt         : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_cap    : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_val0   : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_val1   : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_val2   : std_logic_vector(31 downto 0):=(others=>'0');
signal done_tt    : std_logic := '0' ;
signal done_dly   : std_logic_vector(2 downto 0):=(others=>'0');
-- signal done_val1  : std_logic:='0';
signal done_val2  : std_logic:='0';
signal done_val3  : std_logic:='0';
signal done_cnt   : std_logic_vector(5 downto 0):=(others=>'0');

CONSTANT D_SEL : INTEGER := 1;

  attribute ASYNC_REG         : string;
  attribute shreg_extract     : string;
  attribute ASYNC_REG     of done_dly         : signal is "TRUE";
  attribute shreg_extract of done_dly         : signal is "no"; 
  attribute ASYNC_REG     of dly1_dur_en      : signal is "TRUE";
  attribute shreg_extract of dly1_dur_en      : signal is "no"; 
  attribute altera_attribute : string;
  attribute altera_attribute of done_dly    : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
  attribute altera_attribute of dly1_dur_en : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
 
begin 

    process(measured_clk_in)
    begin 
        if rising_edge(measured_clk_in) then 
            dly1_dur_en <=dly1_dur_en(2 downto 0)&dur_en ;
            dly2_dur_en <=dly2_dur_en(0 downto 0)&dly1_dur_en(2) ;
        end if;
    end process;
    
    process(measured_clk_in)
    begin 
        if rising_edge(measured_clk_in) then 
            if dly2_dur_en(D_SEL) = '1' then 
                 cnt <= cnt + 1 ;
            else 
                 cnt <= (others=>'0');
            end if;
            if dly2_dur_en(D_SEL) = '1' and dly2_dur_en(D_SEL-1)= '0' then --falling edge 
                cnt_cap <= cnt ; 
            end if;
            
            if dly2_dur_en(D_SEL) = '1' and dly2_dur_en(D_SEL-1)= '0' then --falling edge
               -- done_tt <= '1';
                done_cnt <= (others=>'1');
            elsif done_cnt /= 0 then 
                done_cnt <= done_cnt - 1 ;
            end if;
            
            if done_cnt >0 and done_cnt <16 then 
                done_tt <= '1';
            else 
                done_tt <= '0';
            end if;
        end if;
    end process;
    
   -- CNT_CRS: cross_domain   
    -- generic MAP(
        -- DATA_WIDTH			 => 32
    -- ) 
    -- port MAP
    -- (   
        -- clk0      						 => measured_clk_in ,
        -- nRst0     						 => '1',		
        -- datain    						 => cnt_val0 ,
        -- datain_req						 => '1' ,
                                                
        -- clk1							 => capture_clk_in ,
        -- nRst1							 => '1',
        -- data_out						 => cnt_val ,
        -- dataout_valid					 => OPEN ---just pulse only
    -- );
 
    
    cnt_val  <= cnt_val2;
    done_val <= done_val3;
    process(capture_clk_in)
    begin 
        if rising_edge(capture_clk_in) then 
            if done_val3 = '1' and done_val2 = '0' then --falling edge 
                cnt_val0  <= cnt_cap;
            end if;
            cnt_val1   <= cnt_val0; 
            cnt_val2   <= cnt_val1; 
            done_dly   <= done_dly(1 downto 0)&done_tt;             
            done_val2  <= done_dly(2);
            done_val3  <= done_val2;
        end if;
    end process;

end beha_testclk;