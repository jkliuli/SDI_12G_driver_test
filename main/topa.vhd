library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_subfrm_type.all;

entity topa is 
generic (
	FRAME_W                             : integer   := 11;
	NUM_STREAMS                         : integer	:= 4;
	VID_NUM                 			: integer   := 4
);

port(
	clkusr                              : in  std_logic; --100mhz

	F_ODCK                              : in  std_logic; --148.5Mhz
	
	A10_REFCLK_1C                		: in  std_logic;
	A10_REFCLK_1D                		: in  std_logic;
	A10_REFCLK_1E                       : in  std_logic;

    SDI_TX      						: out std_logic; 

	sdi_tx_sd_hdn       				: out  std_logic_vector(3 downto 0);--0: complies with HD / 1: complies with SD
	sdi_EQ_EN       					: out  std_logic_vector(3 downto 0);--Rx Equalization Bypass - 0: Normal Operation / 1: No Equalization occurs
	sdi_DISABLE       					: out  std_logic_vector(3 downto 0);
	sdi_osp      						: in   std_logic_vector(3 downto 0)

);

end entity;

architecture behav of topa is

attribute keep : boolean;

signal clk_mea_set                      : std_logic_vector(2 downto 0);
signal clk_cnt                          : std_logic_vector(3*32-1 downto 0);

signal pll_locked                       : std_logic;
signal sysclk							: std_logic; 

signal tx_pll_locked                    : std_logic;
signal pll_24_locked                    : std_logic;
signal tx_clk                           : std_logic;

signal clk_100M                         : std_logic;
signal clk_200M                         : std_logic;
signal clk_24M                          : std_logic;

signal pll_sys_rst						: std_logic;

signal time_ms_en 	                    : std_logic;
signal sys_nRST                         : std_logic; 
signal nRST_8201	                    : std_logic;
signal nRST_150M	                    : std_logic; 
signal nRST_ODCK	                    : std_logic_vector(VID_NUM-1 downto 0);
signal nRST_tx_clk	                    : std_logic;

signal pll_100M_lock                	: std_logic;
signal phy_8201_50M     	            : std_logic;
signal clk_150M                         : std_logic;
signal pll_lock_150M                    : std_logic;

signal sdiclk                 		    : std_logic_vector(VID_NUM-1 downto 0);
signal XGMII_tx_clk        			    : std_logic;

signal is_ntsc                          :  std_logic_vector(3 downto 0);
signal sdi_colorbits                    :  std_logic_vector(3*4-1 downto 0);
signal sdi_format                       :  std_logic_vector(4*4-1 downto 0);
signal sdi_std                          :  std_logic_vector(3*4-1 downto 0);
signal sdi_vsync                        :  std_logic_vector(3 downto 0);
signal sdi_hsync                        :  std_logic_vector(3 downto 0);
signal sdi_de                           :  std_logic_vector(3 downto 0);
signal sdi_data                         :  std_logic_vector(24*4-1 downto 0);

--test
signal ptype                            : std_logic_vector(7 downto 0);
signal paddr                            :  std_logic_vector(FRAME_W-1 downto 0);
signal pdata                            :  std_logic_vector(7 downto 0);

signal sdi_vidin_start                  : std_logic;
signal sdi_vidin_end                    : std_logic;
signal sdi_vidin_wren                   : std_logic;
signal sdi_vidin_data                   : std_logic_vector(191 downto 0);
signal sdi_vidin_fifo_wcnt              : std_logic_vector(10 downto 0);

attribute keep of tx_pll_locked      : signal is true;
attribute keep of pll_24_locked      : signal is true;
attribute keep of pll_locked         : signal is true;
attribute keep of pll_sys_rst        : signal is true;
attribute keep of clk_200M           : signal is true;


component clk_mea_top is 
generic(  
    CLK_NUM         : integer := 4
);
port(
	nRST_sys    :   in  std_logic ;
    sysclk      :   in  std_logic ; ---125M
    
    clk_set     :   in  std_logic_vector(CLK_NUM-1 downto 0);
    
    clk_cnt_o   :   out std_logic_vector(CLK_NUM*32-1 downto 0);
    done_val_o  :   out std_logic_vector(CLK_NUM -1 downto 0);
    mask_out_o  :   out std_logic
);
end component;


component pll_sys is
port(
	rst      : in  std_logic := '0'; 
	refclk   : in  std_logic := '0'; 
	locked   : out std_logic;        
	outclk_0 : out std_logic         
);
end component;

component tx_clk_148 is
port(
	rst      : in  std_logic := '0'; 
	refclk   : in  std_logic := '0'; 
	locked   : out std_logic;        
	outclk_0 : out std_logic    
);
end component;

component tx_clk_24 is
port(
	rst      : in  std_logic := '0'; 
	refclk   : in  std_logic := '0'; 
	locked   : out std_logic;        
	outclk_0 : out std_logic     
);
end component;

component clkctrl is
port (
    inclk  : in  std_logic := 'X';
    outclk : out std_logic        
);
end component clkctrl;


component pll_rst_gen is
port(
	clkin								: in  std_logic;
	pll_rst								: out std_logic
);
end component;


component reset_module is 
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
	nRST_ODCK		: out  STD_LOGIC_VECTOR(VID_NUM-1 downto 0);

	XGMII_tx_clk	: in  STD_LOGIC;
	nRST_tx_clk		: out  STD_LOGIC		
);
end component;


component sdi_top is
  generic (
    FRAME_W                   : integer:=11;
    NUM_STREAMS               : integer:=4;
    SDI_NUM_USE               : integer:=2;
    SDI_NUM_PORT_TURE         : integer:=4
  );
  port (
    sysclk              : in std_logic;
    nRST                : in std_logic;

    odck_ref            : in std_logic;
    clk_user            : in std_logic;

    time_ms_en          : in std_logic;

    sdi_vidin_start     : in std_logic;
    sdi_vidin_end       : in std_logic;
    sdi_vidin_wren      : in std_logic;
    sdi_vidin_data      : in std_logic_vector(191 downto 0);
    sdi_vidin_fifo_wcnt : out std_logic_vector(10 downto 0);

    pframe_ss           : in std_logic;
    ptype               : in std_logic_vector(7 downto 0);
    pwren               : in std_logic;
    paddr               : in std_logic_vector(FRAME_W-1 downto 0);
    pdata               : in std_logic_vector(7 downto 0);


    tx_rcfg_cal_busy    : in  std_logic;
    gxb_tx_serial_data  : out std_logic;
    tx_pll_locked       : out std_logic;
    gxb_tx_cal_busy     : out std_logic;
    gxb_tx_ready        : out std_logic;

    work_LED            : out std_logic_vector(SDI_NUM_PORT_TURE-1 downto 0)
  );
end component;


begin

clk_mea_set <= A10_REFCLK_1C&tx_clk&clkusr;

clk_mea_top_inst : clk_mea_top 
generic map(       
    CLK_NUM         => 3
)
port map(
	nRST_sys       => sys_nRST         ,
    sysclk         => sysclk           ,
									  
    clk_set        => clk_mea_set      ,
									   
    clk_cnt_o      => clk_cnt          ,
    done_val_o     => open             ,
    mask_out_o     => open      

);

--rst
pll_rst_gen_inst: pll_rst_gen
port map(
	clkin				=> clk_100M	    ,
	pll_rst				=> pll_sys_rst
);

--125Mhz
pll_sys_inst: pll_sys
port map(
	rst      			=> pll_sys_rst	,
	refclk   			=> A10_REFCLK_1C    ,
	locked   			=> pll_locked   ,
	outclk_0 			=> sysclk
);


--24Mhz
pll_tx_24_inst: tx_clk_24
port map(
	rst      			=> pll_sys_rst	   ,
	refclk   			=> clk_100M        ,
	locked   			=> pll_24_locked   ,
	outclk_0 			=> clk_24M         
);

--148.5Mhz
pll_tx_inst: tx_clk_148
port map(
	rst      			=> not pll_24_locked	   ,
	refclk   			=> clk_24M         ,
	locked   			=> tx_pll_locked   ,
    outclk_0            => tx_clk 
);

--clk ctrl
clkctrl_inst0 : clkctrl 
port map(
    inclk    		=> clkusr,
    outclk   		=> clk_100M
);


reset_module_inst : reset_module 
generic map(       
    VID_NUM         => VID_NUM
)
port map(
    pll_locked   	=> pll_locked		,
    clk_125m     	=> sysclk			,
    nRST         	=> sys_nRST			,
	
	time_ms_en		=> time_ms_en		,
										
	phy_8201_50M  	=> phy_8201_50M     ,
	pll_lock_8201  	=> pll_100M_lock	,
	nRST_8201 		=> nRST_8201	    ,
										
	clk_150M 		=> clk_150M	        ,
	pll_lock_150M	=> pll_lock_150M	,
	nRST_150M 		=> nRST_150M	    ,
										
	DVI_ODCK		=> sdiclk	        ,
	nRST_ODCK		=> nRST_ODCK		,
	
	XGMII_tx_clk	=> XGMII_tx_clk		,
	nRST_tx_clk		=> nRST_tx_clk	
);


sdi_tx_sd_hdn  <= "0000";
sdi_EQ_EN      <= "0000";
sdi_DISABLE    <= "1111";

sdi_top_inst :  sdi_top
  port map (
    sysclk                => sysclk,
    nRST                  => sys_nRST,

    odck_ref              => tx_clk,
    clk_user              => clk_100M,
    time_ms_en            => time_ms_en,

    sdi_vidin_start       => sdi_vidin_start,
    sdi_vidin_end         => sdi_vidin_end,
    sdi_vidin_wren        => sdi_vidin_wren,
    sdi_vidin_data        => sdi_vidin_data,
    sdi_vidin_fifo_wcnt   => sdi_vidin_fifo_wcnt,

    pframe_ss             => '0',
    ptype                 => ptype,
    pwren                 => '0',
    paddr                 => paddr,
    pdata                 => pdata,
    tx_rcfg_cal_busy      => not tx_pll_locked,

    gxb_tx_serial_data    => SDI_TX,
    tx_pll_locked         => open,
    gxb_tx_cal_busy       => open,
    gxb_tx_ready          => open,

    work_LED              => open
  );

end behav;