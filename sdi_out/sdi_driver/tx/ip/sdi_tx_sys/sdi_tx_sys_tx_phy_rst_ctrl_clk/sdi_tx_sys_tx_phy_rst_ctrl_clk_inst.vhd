	component sdi_tx_sys_tx_phy_rst_ctrl_clk is
		port (
			in_clk  : in  std_logic := 'X'; -- clk
			out_clk : out std_logic         -- clk
		);
	end component sdi_tx_sys_tx_phy_rst_ctrl_clk;

	u0 : component sdi_tx_sys_tx_phy_rst_ctrl_clk
		port map (
			in_clk  => CONNECTED_TO_in_clk,  --  in_clk.clk
			out_clk => CONNECTED_TO_out_clk  -- out_clk.clk
		);

