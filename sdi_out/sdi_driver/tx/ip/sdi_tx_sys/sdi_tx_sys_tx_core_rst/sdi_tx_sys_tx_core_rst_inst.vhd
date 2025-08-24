	component sdi_tx_sys_tx_core_rst is
		port (
			in_reset  : in  std_logic := 'X'; -- reset
			out_reset : out std_logic         -- reset
		);
	end component sdi_tx_sys_tx_core_rst;

	u0 : component sdi_tx_sys_tx_core_rst
		port map (
			in_reset  => CONNECTED_TO_in_reset,  --  in_reset.reset
			out_reset => CONNECTED_TO_out_reset  -- out_reset.reset
		);

