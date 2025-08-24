	component sdi_tx_sys_tx_phy_rst_ctrl is
		port (
			clock           : in  std_logic                    := 'X';             -- clk
			reset           : in  std_logic                    := 'X';             -- reset
			pll_powerdown   : out std_logic_vector(0 downto 0);                    -- pll_powerdown
			tx_analogreset  : out std_logic_vector(0 downto 0);                    -- tx_analogreset
			tx_digitalreset : out std_logic_vector(0 downto 0);                    -- tx_digitalreset
			tx_ready        : out std_logic_vector(0 downto 0);                    -- tx_ready
			pll_locked      : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_locked
			pll_select      : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_select
			tx_cal_busy     : in  std_logic_vector(0 downto 0) := (others => 'X')  -- tx_cal_busy
		);
	end component sdi_tx_sys_tx_phy_rst_ctrl;

	u0 : component sdi_tx_sys_tx_phy_rst_ctrl
		port map (
			clock           => CONNECTED_TO_clock,           --           clock.clk
			reset           => CONNECTED_TO_reset,           --           reset.reset
			pll_powerdown   => CONNECTED_TO_pll_powerdown,   --   pll_powerdown.pll_powerdown
			tx_analogreset  => CONNECTED_TO_tx_analogreset,  --  tx_analogreset.tx_analogreset
			tx_digitalreset => CONNECTED_TO_tx_digitalreset, -- tx_digitalreset.tx_digitalreset
			tx_ready        => CONNECTED_TO_tx_ready,        --        tx_ready.tx_ready
			pll_locked      => CONNECTED_TO_pll_locked,      --      pll_locked.pll_locked
			pll_select      => CONNECTED_TO_pll_select,      --      pll_select.pll_select
			tx_cal_busy     => CONNECTED_TO_tx_cal_busy      --     tx_cal_busy.tx_cal_busy
		);

