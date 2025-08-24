module sdi_tx_sys_tx_sdi (
		input  wire        tx_rst,           //           tx_rst.reset
		input  wire        tx_datain_valid,  //  tx_datain_valid.export
		input  wire        tx_trs,           //           tx_trs.export
		input  wire [2:0]  tx_std,           //           tx_std.export
		input  wire        tx_enable_ln,     //     tx_enable_ln.export
		input  wire        tx_enable_crc,    //    tx_enable_crc.export
		input  wire [79:0] tx_datain,        //        tx_datain.export
		input  wire [43:0] tx_ln,            //            tx_ln.export
		input  wire [43:0] tx_ln_b,          //          tx_ln_b.export
		output wire        tx_dataout_valid, // tx_dataout_valid.export
		output wire [79:0] tx_dataout,       //       tx_dataout.tx_parallel_data
		input  wire        tx_pclk           //          tx_pclk.clk
	);
endmodule

