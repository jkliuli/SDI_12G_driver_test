//jiangyong
module top_sdi (
    input               clk_100m            ,
	input               sysclk              ,
    input               sdi_refclk          , 	
    input               sdi_rstn            ,

	output  [3:0]       sdi_tx_serial_data  , 
    output  [3:0]       sdi_sd_hd_n         ,						//sd-1 hd-0
    output  [3:0]       sdi_eq_en_n         ,                  //0-open-HD 1-close-SD
    output  [3:0]       sdi_disable_n       ,                  //1
	input   [3:0]       sdi_osp_n           ,                    //0-valid 1-invalid
	
	input  [3:0]         is_ntsc             ,
    input  [3*4-1:0]     sdi_colorbits       ,
    input  [4*4-1:0]     sdi_format          ,
    input  [3*4-1:0]     sdi_std             ,  
    input  [3:0]         sdi_vsync           ,
    input  [3:0]         sdi_hsync           ,
    input  [3:0]         sdi_de              ,
    input  [24*4-1:0]    sdi_data          	,
	
	output [3:0]         sdi_tx_clk              

);

localparam NUM_STREAMS = 1;

wire                        sdi_tx_clkout;
wire [NUM_STREAMS*11-1:0]   sdi_tx_ln;
wire [NUM_STREAMS*11-1:0]   sdi_tx_ln_b;
wire                        sdi_tx_trs;
wire [NUM_STREAMS*20-1:0]   sdi_tx_datain;
wire                        sdi_tx_datain_valid;

wire                        sdi_tx_clkout_A;
wire                        sdi_tx_clkout_B;
wire                        sdi_tx_clkout_C;
wire                        sdi_tx_clkout_D;

wire                        sdi_tx_p_A;
wire                        sdi_tx_p_B;
wire                        sdi_tx_p_C;
wire                        sdi_tx_p_D;

wire						sdi_tx_datavalid_a;

wire [2:0]   tx_std;
wire [3:0]   tx_format;



assign sdi_tx_clk = {sdi_tx_clkout_D,sdi_tx_clkout_C,sdi_tx_clkout_B,sdi_tx_clkout_A};
assign sdi_tx_serial_data = {sdi_tx_p_D,sdi_tx_p_C,sdi_tx_p_B,sdi_tx_p_A};
assign sdi_sd_hd_n = 4'b0000;
assign sdi_eq_en_n = 4'b0000;
assign sdi_disable_n = 4'b1111;

assign tx_std = 3'b001;
assign tx_format = 4'b0110;

sdi_ii_ed_vid_pattgen #(
    .OUTW_MULTP          (NUM_STREAMS),
    .SD_BIT_WIDTH        (20),
    .TEST_GEN_ANC        (1),
    .TEST_GEN_VPID       (1),
    .TEST_VPID_PKT_COUNT (1),
    .TEST_ERR_VPID       (0),
    .TEST_VPID_OVERWRITE (1)
) pattgen (
    // Clocks and resets
    .clk          (sdi_tx_clkout_A),
//    .rst          (~pattgen_rst),
//
//    // Inputs
//    .enable       (sdi_tx_dataout_valid),
//    .tx_std       (sdi_tx_std),
//    .tx_format    (pattgen_tx_format),
//    .dl_mapping   (pattgen_dl_mapping),
//    .bar_100_75n  (1'b0),
//    .patho        (pattgen_patho),
//    .blank        (1'b0),
//    .no_color     (1'b0),
//    .sgmt_frame   (pattgen_sgmt_frame),
//    .ntsc_paln    (pattgen_ntsc_paln),

	.rst          (~sdi_rstn),
    
    // Inputs
    .enable       (sdi_tx_datavalid_a),
    .tx_std       (tx_std),
    .tx_format    (tx_format),
    .dl_mapping   (1'b0),
    .bar_100_75n  (1'b0),
    .patho        (1'b0),
    .blank        (1'b0),
    .no_color     (1'b0),
    .sgmt_frame   (1'b0),
    .ntsc_paln    (1'b0),

    // Outputs
    .ln           (sdi_tx_ln),
    .ln_b         (sdi_tx_ln_b),
    .line_f0      (),
    .line_f1      (),
    .vpid_byte1   (),
    .vpid_byte2   (),
    .vpid_byte3   (),
    .vpid_byte4   (),
    .vpid_byte1_b (),
    .vpid_byte2_b (),
    .vpid_byte3_b (),
    .vpid_byte4_b (),
    .trs          (sdi_tx_trs),
    .dout         (sdi_tx_datain),
    .dout_valid   (sdi_tx_datain_valid)
);


wire            			 pll_cal_busy_A;
wire                         tx_pll_locked_A;
wire                         txpll_serialclk_A;
wire            			 pll_cal_busy_B;
wire                         tx_pll_locked_B;
wire                         txpll_serialclk_B;

wire                        txpll_powerdown_A;
wire                        txpll_powerdown_B;
wire                        txpll_powerdown_C;
wire                        txpll_powerdown_D;

wire                        gxb_tx_cal_busy_A;
wire                        gxb_tx_cal_busy_B;
wire                        gxb_tx_cal_busy_C;
wire                        gxb_tx_cal_busy_D;

wire						pllA_powerdown;
wire						pllB_powerdown;
wire						tx_rcfg_cal_busy;



assign pllA_powerdown = txpll_powerdown_A||txpll_powerdown_B;
assign pllB_powerdown = txpll_powerdown_C||txpll_powerdown_D;
assign tx_rcfg_cal_busy = gxb_tx_cal_busy_A||gxb_tx_cal_busy_B||gxb_tx_cal_busy_C||gxb_tx_cal_busy_D;


tx_pll tx_pll_inst_A (
// Clock and reset
    .pll_refclk0                (sdi_refclk),
    .pll_powerdown              (pllA_powerdown),

// Outputs
    .pll_locked                 (tx_pll_locked_A),
    .pll_cal_busy               (pll_cal_busy_A),
    .tx_serial_clk              (txpll_serialclk_A)
);

tx_pll tx_pll_inst_B (
// Clock and reset
    .pll_refclk0                (sdi_refclk),
    .pll_powerdown              (pllA_powerdown),

// Outputs
    .pll_locked                 (tx_pll_locked_B),
    .pll_cal_busy               (pll_cal_busy_B),
    .tx_serial_clk              (txpll_serialclk_B)
);
// -------------------------------------------------------------------------
// Transmitter IP Top Level
// -------------------------------------------------------------------------
tx_top #(
    .NUM_STREAMS                    (NUM_STREAMS)
) tx_inst_A (
// Clocks and reset
//    .tx_resetn                      (cpu_resetn & ~pattgen_pio_rst),
	.tx_resetn                      (sdi_rstn),
    .tx_pll_refclk                  (txpll_serialclk_A),
	.pll_cal_busy                  (pll_cal_busy_A),
//	.tx_pll_locked                  (tx_pll_locked),
    .tx_rcfg_mgmt_clk               (clk_100m),
    .tx_rcfg_mgmt_resetn            (sdi_rstn),

// Inputs
//    .tx_rcfg_cal_busy               (tx_rcfg_cal_busy),
	.tx_rcfg_cal_busy               (tx_rcfg_cal_busy),                     //1'b0
    .tx_vid_data                    (sdi_tx_datain),
    .tx_vid_datavalid               (sdi_tx_datain_valid),
//    .tx_vid_std                     (sdi_tx_std),
	.tx_vid_std                     (tx_std),
    .tx_vid_trs                     (sdi_tx_trs),
    .sdi_tx_enable_crc              (1'b1),
    .sdi_tx_enable_ln               (1'b1),
    .sdi_tx_ln                      (sdi_tx_ln),
    .sdi_tx_ln_b                    (sdi_tx_ln_b),

// Outputs
    .tx_vid_clkout                  (sdi_tx_clkout_A),
    .tx_pll_locked                  (tx_pll_locked_A),
    .gxb_tx_serial_data             (sdi_tx_p_A),
    .gxb_tx_cal_busy                (gxb_tx_cal_busy_A),                        //gxb_tx_cal_busy	
	.txpll_powerdown                (txpll_powerdown_A),							//txpll_powerdown
    .gxb_tx_ready                   (),            //gxb_tx_ready
    .sdi_tx_datavalid               (sdi_tx_datavalid_a)          //sdi_tx_dataout_valid
);


endmodule


