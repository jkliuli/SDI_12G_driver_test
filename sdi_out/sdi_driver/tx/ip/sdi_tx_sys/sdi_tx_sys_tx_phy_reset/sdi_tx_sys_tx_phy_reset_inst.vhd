	component sdi_tx_sys_tx_phy_reset is
		port (
			in_reset  : in  std_logic := 'X'; -- reset
			out_reset : out std_logic         -- reset
		);
	end component sdi_tx_sys_tx_phy_reset;

	u0 : component sdi_tx_sys_tx_phy_reset
		port map (
			in_reset  => CONNECTED_TO_in_reset,  --  in_reset.reset
			out_reset => CONNECTED_TO_out_reset  -- out_reset.reset
		);

