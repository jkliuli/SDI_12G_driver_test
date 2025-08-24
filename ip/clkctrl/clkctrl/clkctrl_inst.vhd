	component clkctrl is
		port (
			inclk  : in  std_logic := 'X'; -- clk
			outclk : out std_logic         -- clk
		);
	end component clkctrl;

	u0 : component clkctrl
		port map (
			inclk  => CONNECTED_TO_inclk,  --  inclk.clk
			outclk => CONNECTED_TO_outclk  -- outclk.clk
		);

