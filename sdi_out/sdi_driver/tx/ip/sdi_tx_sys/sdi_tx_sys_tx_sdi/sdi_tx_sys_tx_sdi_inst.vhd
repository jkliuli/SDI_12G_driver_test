	component sdi_tx_sys_tx_sdi is
		port (
			tx_rst           : in  std_logic                     := 'X';             -- reset
			tx_datain_valid  : in  std_logic                     := 'X';             -- export
			tx_trs           : in  std_logic                     := 'X';             -- export
			tx_std           : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- export
			tx_enable_ln     : in  std_logic                     := 'X';             -- export
			tx_enable_crc    : in  std_logic                     := 'X';             -- export
			tx_datain        : in  std_logic_vector(79 downto 0) := (others => 'X'); -- export
			tx_ln            : in  std_logic_vector(43 downto 0) := (others => 'X'); -- export
			tx_ln_b          : in  std_logic_vector(43 downto 0) := (others => 'X'); -- export
			tx_dataout_valid : out std_logic;                                        -- export
			tx_dataout       : out std_logic_vector(79 downto 0);                    -- tx_parallel_data
			tx_pclk          : in  std_logic                     := 'X'              -- clk
		);
	end component sdi_tx_sys_tx_sdi;

	u0 : component sdi_tx_sys_tx_sdi
		port map (
			tx_rst           => CONNECTED_TO_tx_rst,           --           tx_rst.reset
			tx_datain_valid  => CONNECTED_TO_tx_datain_valid,  --  tx_datain_valid.export
			tx_trs           => CONNECTED_TO_tx_trs,           --           tx_trs.export
			tx_std           => CONNECTED_TO_tx_std,           --           tx_std.export
			tx_enable_ln     => CONNECTED_TO_tx_enable_ln,     --     tx_enable_ln.export
			tx_enable_crc    => CONNECTED_TO_tx_enable_crc,    --    tx_enable_crc.export
			tx_datain        => CONNECTED_TO_tx_datain,        --        tx_datain.export
			tx_ln            => CONNECTED_TO_tx_ln,            --            tx_ln.export
			tx_ln_b          => CONNECTED_TO_tx_ln_b,          --          tx_ln_b.export
			tx_dataout_valid => CONNECTED_TO_tx_dataout_valid, -- tx_dataout_valid.export
			tx_dataout       => CONNECTED_TO_tx_dataout,       --       tx_dataout.tx_parallel_data
			tx_pclk          => CONNECTED_TO_tx_pclk           --          tx_pclk.clk
		);

