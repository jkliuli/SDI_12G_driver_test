module sdi_tx_sys_tx_phy (
		input  wire [0:0]   tx_analogreset,    //    tx_analogreset.tx_analogreset
		input  wire [0:0]   tx_digitalreset,   //   tx_digitalreset.tx_digitalreset
		output wire [0:0]   tx_cal_busy,       //       tx_cal_busy.tx_cal_busy
		input  wire [0:0]   tx_serial_clk0,    //    tx_serial_clk0.clk
		output wire [0:0]   tx_serial_data,    //    tx_serial_data.tx_serial_data
		input  wire [0:0]   tx_coreclkin,      //      tx_coreclkin.clk
		output wire [0:0]   tx_clkout,         //         tx_clkout.clk
		output wire [0:0]   tx_pma_div_clkout, // tx_pma_div_clkout.clk
		input  wire [127:0] tx_parallel_data,  //  tx_parallel_data.tx_parallel_data
		input  wire [17:0]  tx_control,        //        tx_control.tx_control
		input  wire [0:0]   tx_enh_data_valid  // tx_enh_data_valid.tx_enh_data_valid
	);
endmodule

