library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity reset_module is 
generic(  
    VID_NUM         : integer := 4
);
port(
    pll_locked      : in std_logic ;
    clk_125m        : in std_logic ;
    nRST            : out std_logic;

	time_ms_en		: out std_logic;

	phy_8201_50M  	: in  std_logic;	
	pll_lock_8201  	: in  std_logic;
	nRST_8201 		: out std_logic;

	clk_150M 		: in  std_logic;
	pll_lock_150M	: in  std_logic;
	nRST_150M 		: out std_logic;	
	
	DVI_ODCK		: in  STD_LOGIC_VECTOR(VID_NUM-1 downto 0);
	nRST_ODCK		: out STD_LOGIC_VECTOR(VID_NUM-1 downto 0);

	XGMII_tx_clk	: in  STD_LOGIC;
	nRST_tx_clk		: out STD_LOGIC	
);
end entity;

architecture behav of reset_module is 

component altera_std_synchronizer is 
generic (depth : integer := 3);
port 
(  
	clk     : in std_logic ;
	reset_n : in std_logic ;
	din     : in std_logic ;
	dout    : out std_logic
);
end component ;

signal rst_cnt      		: std_logic_vector(29 downto 0):=(others=>'0');
signal nRST_buf				: std_logic;
signal time_cnt				: std_logic_vector(17 downto 0);
signal time_ms_en_buf		: std_logic;

begin 

nRST <= nRST_buf;

process(pll_locked,clk_125m)
begin
    if pll_locked = '0' then
        rst_cnt <= (others => '0');
    elsif rising_edge(clk_125m) then
        if rst_cnt(29) = '0' then
            rst_cnt <= rst_cnt + '1';
        end if;
        
        nRST_buf <= rst_cnt(29) ;
    end if;
end process; 

phy_8201_50M_inst:  altera_std_synchronizer   
port map
(  
	clk     	=> phy_8201_50M	,
	reset_n     => '1'          ,
	din         => nRST_buf     ,
	dout        => nRST_8201
);

clk_150M_inst:  altera_std_synchronizer   
port map
(  
	clk     	=> clk_150M		,
	reset_n     => '1'          ,
	din         => nRST_buf     ,
	dout        => nRST_150M
);

DVI_ODCK_gen: for i in 0 to VID_NUM-1 generate
DVI_ODCK_inst:  altera_std_synchronizer   
port map
(  
	clk     	=> DVI_ODCK(i)	,
	reset_n     => '1'          ,
	din         => nRST_buf     ,
	dout        => nRST_ODCK(i)
);
end generate DVI_ODCK_gen;

nRST_tx_clk_inst:  altera_std_synchronizer   
port map
(  
	clk     	=> XGMII_tx_clk	,
	reset_n     => '1'          ,
	din         => nRST_buf     ,
	dout        => nRST_tx_clk
);

process(clk_125m)
begin
	if rising_edge(clk_125m) then
		if time_cnt = 0 then
			time_cnt <= conv_std_logic_vector(125000,18) - '1';
			time_ms_en_buf <= '1';
		else
			time_cnt <= time_cnt - '1';
			time_ms_en_buf <= '0';
		end if;	
		time_ms_en <= time_ms_en_buf;
	end if;
end process;

end behav;