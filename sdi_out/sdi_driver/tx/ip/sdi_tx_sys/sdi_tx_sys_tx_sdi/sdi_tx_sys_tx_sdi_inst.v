	sdi_tx_sys_tx_sdi u0 (
		.tx_rst           (_connected_to_tx_rst_),           //   input,   width = 1,           tx_rst.reset
		.tx_datain_valid  (_connected_to_tx_datain_valid_),  //   input,   width = 1,  tx_datain_valid.export
		.tx_trs           (_connected_to_tx_trs_),           //   input,   width = 1,           tx_trs.export
		.tx_std           (_connected_to_tx_std_),           //   input,   width = 3,           tx_std.export
		.tx_enable_ln     (_connected_to_tx_enable_ln_),     //   input,   width = 1,     tx_enable_ln.export
		.tx_enable_crc    (_connected_to_tx_enable_crc_),    //   input,   width = 1,    tx_enable_crc.export
		.tx_datain        (_connected_to_tx_datain_),        //   input,  width = 80,        tx_datain.export
		.tx_ln            (_connected_to_tx_ln_),            //   input,  width = 44,            tx_ln.export
		.tx_ln_b          (_connected_to_tx_ln_b_),          //   input,  width = 44,          tx_ln_b.export
		.tx_dataout_valid (_connected_to_tx_dataout_valid_), //  output,   width = 1, tx_dataout_valid.export
		.tx_dataout       (_connected_to_tx_dataout_),       //  output,  width = 80,       tx_dataout.tx_parallel_data
		.tx_pclk          (_connected_to_tx_pclk_)           //   input,   width = 1,          tx_pclk.clk
	);

