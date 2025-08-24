	component sdi_tx_sys_tx_phy is
		port (
			tx_analogreset    : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- tx_analogreset
			tx_digitalreset   : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- tx_digitalreset
			tx_cal_busy       : out std_logic_vector(0 downto 0);                      -- tx_cal_busy
			tx_serial_clk0    : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
			tx_serial_data    : out std_logic_vector(0 downto 0);                      -- tx_serial_data
			tx_coreclkin      : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
			tx_clkout         : out std_logic_vector(0 downto 0);                      -- clk
			tx_pma_div_clkout : out std_logic_vector(0 downto 0);                      -- clk
			tx_parallel_data  : in  std_logic_vector(127 downto 0) := (others => 'X'); -- tx_parallel_data
			tx_control        : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- tx_control
			tx_enh_data_valid : in  std_logic_vector(0 downto 0)   := (others => 'X')  -- tx_enh_data_valid
		);
	end component sdi_tx_sys_tx_phy;

	u0 : component sdi_tx_sys_tx_phy
		port map (
			tx_analogreset    => CONNECTED_TO_tx_analogreset,    --    tx_analogreset.tx_analogreset
			tx_digitalreset   => CONNECTED_TO_tx_digitalreset,   --   tx_digitalreset.tx_digitalreset
			tx_cal_busy       => CONNECTED_TO_tx_cal_busy,       --       tx_cal_busy.tx_cal_busy
			tx_serial_clk0    => CONNECTED_TO_tx_serial_clk0,    --    tx_serial_clk0.clk
			tx_serial_data    => CONNECTED_TO_tx_serial_data,    --    tx_serial_data.tx_serial_data
			tx_coreclkin      => CONNECTED_TO_tx_coreclkin,      --      tx_coreclkin.clk
			tx_clkout         => CONNECTED_TO_tx_clkout,         --         tx_clkout.clk
			tx_pma_div_clkout => CONNECTED_TO_tx_pma_div_clkout, -- tx_pma_div_clkout.clk
			tx_parallel_data  => CONNECTED_TO_tx_parallel_data,  --  tx_parallel_data.tx_parallel_data
			tx_control        => CONNECTED_TO_tx_control,        --        tx_control.tx_control
			tx_enh_data_valid => CONNECTED_TO_tx_enh_data_valid  -- tx_enh_data_valid.tx_enh_data_valid
		);

