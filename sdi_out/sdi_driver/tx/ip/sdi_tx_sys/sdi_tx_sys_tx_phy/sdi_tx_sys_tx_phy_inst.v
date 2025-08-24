	sdi_tx_sys_tx_phy u0 (
		.tx_analogreset    (_connected_to_tx_analogreset_),    //   input,    width = 1,    tx_analogreset.tx_analogreset
		.tx_digitalreset   (_connected_to_tx_digitalreset_),   //   input,    width = 1,   tx_digitalreset.tx_digitalreset
		.tx_cal_busy       (_connected_to_tx_cal_busy_),       //  output,    width = 1,       tx_cal_busy.tx_cal_busy
		.tx_serial_clk0    (_connected_to_tx_serial_clk0_),    //   input,    width = 1,    tx_serial_clk0.clk
		.tx_serial_data    (_connected_to_tx_serial_data_),    //  output,    width = 1,    tx_serial_data.tx_serial_data
		.tx_coreclkin      (_connected_to_tx_coreclkin_),      //   input,    width = 1,      tx_coreclkin.clk
		.tx_clkout         (_connected_to_tx_clkout_),         //  output,    width = 1,         tx_clkout.clk
		.tx_pma_div_clkout (_connected_to_tx_pma_div_clkout_), //  output,    width = 1, tx_pma_div_clkout.clk
		.tx_parallel_data  (_connected_to_tx_parallel_data_),  //   input,  width = 128,  tx_parallel_data.tx_parallel_data
		.tx_control        (_connected_to_tx_control_),        //   input,   width = 18,        tx_control.tx_control
		.tx_enh_data_valid (_connected_to_tx_enh_data_valid_)  //   input,    width = 1, tx_enh_data_valid.tx_enh_data_valid
	);

