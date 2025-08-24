module sdi_tx_sys (
		input  wire         tx_core_rst_in_reset_reset,                  //          tx_core_rst_in_reset.reset
		output wire [0:0]   tx_phy_tx_cal_busy_tx_cal_busy,              //            tx_phy_tx_cal_busy.tx_cal_busy
		input  wire [0:0]   tx_phy_tx_serial_clk0_clk,                   //         tx_phy_tx_serial_clk0.clk
		output wire [0:0]   tx_phy_tx_serial_data_tx_serial_data,        //         tx_phy_tx_serial_data.tx_serial_data
		output wire [0:0]   tx_phy_tx_clkout_clk,                        //              tx_phy_tx_clkout.clk
		input  wire [127:0] tx_phy_tx_parallel_data_tx_parallel_data,    //       tx_phy_tx_parallel_data.tx_parallel_data
		input  wire [17:0]  tx_phy_tx_control_tx_control,                //             tx_phy_tx_control.tx_control
		input  wire [0:0]   tx_phy_tx_enh_data_valid_tx_enh_data_valid,  //      tx_phy_tx_enh_data_valid.tx_enh_data_valid
		input  wire         tx_phy_reset_in_reset_reset,                 //         tx_phy_reset_in_reset.reset
		output wire [0:0]   tx_phy_rst_ctrl_pll_powerdown_pll_powerdown, // tx_phy_rst_ctrl_pll_powerdown.pll_powerdown
		output wire [0:0]   tx_phy_rst_ctrl_tx_ready_tx_ready,           //      tx_phy_rst_ctrl_tx_ready.tx_ready
		input  wire [0:0]   tx_phy_rst_ctrl_pll_locked_pll_locked,       //    tx_phy_rst_ctrl_pll_locked.pll_locked
		input  wire [0:0]   tx_phy_rst_ctrl_pll_select_pll_select,       //    tx_phy_rst_ctrl_pll_select.pll_select
		input  wire [0:0]   tx_phy_rst_ctrl_tx_cal_busy_tx_cal_busy,     //   tx_phy_rst_ctrl_tx_cal_busy.tx_cal_busy
		input  wire         tx_phy_rst_ctrl_clk_in_clk_clk,              //    tx_phy_rst_ctrl_clk_in_clk.clk
		input  wire         tx_sdi_tx_datain_valid_export,               //        tx_sdi_tx_datain_valid.export
		input  wire         tx_sdi_tx_trs_export,                        //                 tx_sdi_tx_trs.export
		input  wire [2:0]   tx_sdi_tx_std_export,                        //                 tx_sdi_tx_std.export
		input  wire         tx_sdi_tx_enable_ln_export,                  //           tx_sdi_tx_enable_ln.export
		input  wire         tx_sdi_tx_enable_crc_export,                 //          tx_sdi_tx_enable_crc.export
		input  wire [79:0]  tx_sdi_tx_datain_export,                     //              tx_sdi_tx_datain.export
		input  wire [43:0]  tx_sdi_tx_ln_export,                         //                  tx_sdi_tx_ln.export
		input  wire [43:0]  tx_sdi_tx_ln_b_export,                       //                tx_sdi_tx_ln_b.export
		output wire         tx_sdi_tx_dataout_valid_export,              //       tx_sdi_tx_dataout_valid.export
		output wire [79:0]  tx_sdi_tx_dataout_tx_parallel_data,          //             tx_sdi_tx_dataout.tx_parallel_data
		output wire         tx_sdi_clkout_out_clk_clk                    //         tx_sdi_clkout_out_clk.clk
	);
endmodule

