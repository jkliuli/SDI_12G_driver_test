// (C) 2001-2022 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module tx_top #(
    parameter NUM_STREAMS = 1
) (
    // TX Reference Clock
    input  wire                         tx_pll_refclk,
    input  wire                         tx_rcfg_mgmt_clk,
    // TX Reference Reset
    input  wire                         tx_resetn,
    input  wire                         tx_rcfg_mgmt_resetn,
    // TX Video Signal Interface (Could be Interface with VIP)
    input  wire [NUM_STREAMS*20-1:0]    tx_vid_data,
    input  wire                         tx_vid_datavalid,
    input  wire [2:0]                   tx_vid_std,
    input  wire                         tx_vid_trs,
    output wire                         tx_vid_clkout,
    // Other SDI TX Video Protocol Interfaces
    input  wire                         sdi_tx_enable_crc,
    input  wire                         sdi_tx_enable_ln,
    input  wire [NUM_STREAMS*11-1:0]    sdi_tx_ln,
    input  wire [NUM_STREAMS*11-1:0]    sdi_tx_ln_b,
    output wire                         sdi_tx_datavalid,
    // TX Transceiver Reconfiguration Interface (To Arbiter)
    input  wire                         tx_rcfg_cal_busy,
    // TX Transceiver Interface
    output wire                         tx_pll_locked,
    output wire                         gxb_tx_cal_busy,
    output wire                         gxb_tx_serial_data,
    output wire                         gxb_tx_ready
);

// ----------------------
// Signal Declaration
// ----------------------
wire            txpll_powerdown;
wire            txpll_serialclk;
wire            pll_cal_busy;
wire  [79:0]    sdi_txdata;

// ----------------------
// SDI TX Core with PHY
// ----------------------
sdi_tx_sys sdi_tx_sys_inst(
// Clock and reset
    .tx_core_rst_in_reset_reset                                 (~(tx_resetn & gxb_tx_ready) ),
    .tx_phy_reset_in_reset_reset                                (~tx_rcfg_mgmt_resetn),
    .tx_phy_rst_ctrl_clk_in_clk_clk                             (tx_rcfg_mgmt_clk),
    .tx_phy_tx_serial_clk0_clk                                  (txpll_serialclk),

// Inputs
    .tx_sdi_tx_enable_crc_export                                (sdi_tx_enable_crc),
    .tx_sdi_tx_enable_ln_export                                 (sdi_tx_enable_ln),
    .tx_sdi_tx_ln_export                                        (sdi_tx_ln),
    .tx_sdi_tx_ln_b_export                                      (sdi_tx_ln_b),
    .tx_sdi_tx_std_export                                       (tx_vid_std),
    .tx_sdi_tx_datain_export                                    (tx_vid_data),
    .tx_sdi_tx_datain_valid_export                              (tx_vid_datavalid),
    .tx_sdi_tx_trs_export                                       (tx_vid_trs),
    .tx_phy_rst_ctrl_pll_select_pll_select                      (1'b0),
    .tx_phy_rst_ctrl_tx_cal_busy_tx_cal_busy                    (tx_rcfg_cal_busy | pll_cal_busy),
    .tx_phy_rst_ctrl_pll_locked_pll_locked                      (tx_pll_locked),
    .tx_phy_tx_control_tx_control                               (18'd0),
    .tx_phy_tx_enh_data_valid_tx_enh_data_valid                 (1'b1),
    .tx_phy_tx_parallel_data_tx_parallel_data                   ({24'd0, sdi_txdata[79:40], 24'd0, sdi_txdata[39:0]}),
// Outputs
    .tx_sdi_clkout_out_clk_clk                                  (tx_vid_clkout),
    .tx_phy_tx_clkout_clk                                       (),
    .tx_sdi_tx_dataout_tx_parallel_data                         (sdi_txdata),
    .tx_sdi_tx_dataout_valid_export                             (sdi_tx_datavalid),
    .tx_phy_tx_serial_data_tx_serial_data                       (gxb_tx_serial_data),
    .tx_phy_rst_ctrl_tx_ready_tx_ready                          (gxb_tx_ready),
    .tx_phy_tx_cal_busy_tx_cal_busy                             (gxb_tx_cal_busy),
    .tx_phy_rst_ctrl_pll_powerdown_pll_powerdown                (txpll_powerdown)
);

// -------------------------------
// TX PLL
// -------------------------------
tx_pll tx_pll_inst (
// Clock and reset
    .pll_refclk0                (tx_pll_refclk),
    .pll_powerdown              (txpll_powerdown),

// Outputs
    .pll_locked                 (tx_pll_locked),
    .pll_cal_busy               (pll_cal_busy),
    .tx_serial_clk              (txpll_serialclk)
);



endmodule

