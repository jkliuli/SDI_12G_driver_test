	component clk_io is
		port (
			inclk  : in  std_logic := 'X'; -- clk
			outclk : out std_logic         -- clk
		);
	end component clk_io;

	u0 : component clk_io
		port map (
			inclk  => CONNECTED_TO_inclk,  --  inclk.clk
			outclk => CONNECTED_TO_outclk  -- outclk.clk
		);

