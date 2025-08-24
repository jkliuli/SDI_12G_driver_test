	sdi_tx_sys u0 (
		.tx_core_rst_in_reset_reset                  (_connected_to_tx_core_rst_in_reset_reset_),                  //   input,    width = 1,          tx_core_rst_in_reset.reset
		.tx_phy_tx_cal_busy_tx_cal_busy              (_connected_to_tx_phy_tx_cal_busy_tx_cal_busy_),              //  output,    width = 1,            tx_phy_tx_cal_busy.tx_cal_busy
		.tx_phy_tx_serial_clk0_clk                   (_connected_to_tx_phy_tx_serial_clk0_clk_),                   //   input,    width = 1,         tx_phy_tx_serial_clk0.clk
		.tx_phy_tx_serial_data_tx_serial_data        (_connected_to_tx_phy_tx_serial_data_tx_serial_data_),        //  output,    width = 1,         tx_phy_tx_serial_data.tx_serial_data
		.tx_phy_tx_clkout_clk                        (_connected_to_tx_phy_tx_clkout_clk_),                        //  output,    width = 1,              tx_phy_tx_clkout.clk
		.tx_phy_tx_parallel_data_tx_parallel_data    (_connected_to_tx_phy_tx_parallel_data_tx_parallel_data_),    //   input,  width = 128,       tx_phy_tx_parallel_data.tx_parallel_data
		.tx_phy_tx_control_tx_control                (_connected_to_tx_phy_tx_control_tx_control_),                //   input,   width = 18,             tx_phy_tx_control.tx_control
		.tx_phy_tx_enh_data_valid_tx_enh_data_valid  (_connected_to_tx_phy_tx_enh_data_valid_tx_enh_data_valid_),  //   input,    width = 1,      tx_phy_tx_enh_data_valid.tx_enh_data_valid
		.tx_phy_reset_in_reset_reset                 (_connected_to_tx_phy_reset_in_reset_reset_),                 //   input,    width = 1,         tx_phy_reset_in_reset.reset
		.tx_phy_rst_ctrl_pll_powerdown_pll_powerdown (_connected_to_tx_phy_rst_ctrl_pll_powerdown_pll_powerdown_), //  output,    width = 1, tx_phy_rst_ctrl_pll_powerdown.pll_powerdown
		.tx_phy_rst_ctrl_tx_ready_tx_ready           (_connected_to_tx_phy_rst_ctrl_tx_ready_tx_ready_),           //  output,    width = 1,      tx_phy_rst_ctrl_tx_ready.tx_ready
		.tx_phy_rst_ctrl_pll_locked_pll_locked       (_connected_to_tx_phy_rst_ctrl_pll_locked_pll_locked_),       //   input,    width = 1,    tx_phy_rst_ctrl_pll_locked.pll_locked
		.tx_phy_rst_ctrl_pll_select_pll_select       (_connected_to_tx_phy_rst_ctrl_pll_select_pll_select_),       //   input,    width = 1,    tx_phy_rst_ctrl_pll_select.pll_select
		.tx_phy_rst_ctrl_tx_cal_busy_tx_cal_busy     (_connected_to_tx_phy_rst_ctrl_tx_cal_busy_tx_cal_busy_),     //   input,    width = 1,   tx_phy_rst_ctrl_tx_cal_busy.tx_cal_busy
		.tx_phy_rst_ctrl_clk_in_clk_clk              (_connected_to_tx_phy_rst_ctrl_clk_in_clk_clk_),              //   input,    width = 1,    tx_phy_rst_ctrl_clk_in_clk.clk
		.tx_sdi_tx_datain_valid_export               (_connected_to_tx_sdi_tx_datain_valid_export_),               //   input,    width = 1,        tx_sdi_tx_datain_valid.export
		.tx_sdi_tx_trs_export                        (_connected_to_tx_sdi_tx_trs_export_),                        //   input,    width = 1,                 tx_sdi_tx_trs.export
		.tx_sdi_tx_std_export                        (_connected_to_tx_sdi_tx_std_export_),                        //   input,    width = 3,                 tx_sdi_tx_std.export
		.tx_sdi_tx_enable_ln_export                  (_connected_to_tx_sdi_tx_enable_ln_export_),                  //   input,    width = 1,           tx_sdi_tx_enable_ln.export
		.tx_sdi_tx_enable_crc_export                 (_connected_to_tx_sdi_tx_enable_crc_export_),                 //   input,    width = 1,          tx_sdi_tx_enable_crc.export
		.tx_sdi_tx_datain_export                     (_connected_to_tx_sdi_tx_datain_export_),                     //   input,   width = 80,              tx_sdi_tx_datain.export
		.tx_sdi_tx_ln_export                         (_connected_to_tx_sdi_tx_ln_export_),                         //   input,   width = 44,                  tx_sdi_tx_ln.export
		.tx_sdi_tx_ln_b_export                       (_connected_to_tx_sdi_tx_ln_b_export_),                       //   input,   width = 44,                tx_sdi_tx_ln_b.export
		.tx_sdi_tx_dataout_valid_export              (_connected_to_tx_sdi_tx_dataout_valid_export_),              //  output,    width = 1,       tx_sdi_tx_dataout_valid.export
		.tx_sdi_tx_dataout_tx_parallel_data          (_connected_to_tx_sdi_tx_dataout_tx_parallel_data_),          //  output,   width = 80,             tx_sdi_tx_dataout.tx_parallel_data
		.tx_sdi_clkout_out_clk_clk                   (_connected_to_tx_sdi_clkout_out_clk_clk_)                    //  output,    width = 1,         tx_sdi_clkout_out_clk.clk
	);

