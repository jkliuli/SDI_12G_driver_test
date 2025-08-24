	component sys_sdi is
		port (
			reset_reset : in std_logic := 'X'  -- reset
		);
	end component sys_sdi;

	u0 : component sys_sdi
		port map (
			reset_reset => CONNECTED_TO_reset_reset  -- reset.reset
		);

