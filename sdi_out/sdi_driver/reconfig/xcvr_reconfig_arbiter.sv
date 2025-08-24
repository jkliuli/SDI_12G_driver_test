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


// *********************************************************************
//
// xcvr_reconfig_arbiter.v
// 
// Description
// This module is responsible for arbitrate the AVMM interface between
// XCVR and Reconfiguration module. 
// 
// *********************************************************************

//`define SEPARATE_RCFG_INTF_EN
`ifdef SEPARATE_RCFG_INTF_EN
    `define SEPARATE_RCFG_INTF 1
`else
    `define SEPARATE_RCFG_INTF 0
`endif

// synthesis translate_off
`timescale 1 ps / 1 ps
// synthesis translate_on

module xcvr_reconfig_arbiter #(
    parameter   LANES = 4,
    parameter   DPRIO_ADDRESS_WIDTH = 10, 
    parameter   DPRIO_DATA_WIDTH = 32,
    parameter [31:0] EXPIRED_COUNTER = 32'h042C1D80       // 700ms
)(
    input  wire                                     clk,            // This should be the same 100MHz clock driving the reconfig controller
    input  wire                                     reset,          // This should be the same reset driving the reconfig controller

    // rcfg_ch is transceiver channel/lane number.
    input  wire                                     rx_rcfg_en,
    input  wire                                     tx_rcfg_en, 
    input  wire [1:0]                               rx_rcfg_ch,
    input  wire [1:0]                               tx_rcfg_ch,
    input  wire [`SEPARATE_RCFG_INTF*(LANES-1):0]                            rx_reconfig_mgmt_write,
    input  wire [`SEPARATE_RCFG_INTF*(LANES-1):0]                            rx_reconfig_mgmt_read,
    input  wire [(`SEPARATE_RCFG_INTF*(LANES-1)+1)*DPRIO_ADDRESS_WIDTH-1:0]  rx_reconfig_mgmt_address,
    input  wire [(`SEPARATE_RCFG_INTF*(LANES-1)+1)*DPRIO_DATA_WIDTH-1:0]     rx_reconfig_mgmt_writedata,
    output wire [(`SEPARATE_RCFG_INTF*(LANES-1)+1)*DPRIO_DATA_WIDTH-1:0]     rx_reconfig_mgmt_readdata,
    output wire [`SEPARATE_RCFG_INTF*(LANES-1):0]                            rx_reconfig_mgmt_waitrequest,

    input  wire [`SEPARATE_RCFG_INTF*(LANES-1):0]                            tx_reconfig_mgmt_write,
    input  wire [`SEPARATE_RCFG_INTF*(LANES-1):0]                            tx_reconfig_mgmt_read,
    input  wire [(`SEPARATE_RCFG_INTF*(LANES-1)+1)*DPRIO_ADDRESS_WIDTH-1:0]  tx_reconfig_mgmt_address,
    input  wire [(`SEPARATE_RCFG_INTF*(LANES-1)+1)*DPRIO_DATA_WIDTH-1:0]     tx_reconfig_mgmt_writedata,
    output wire [(`SEPARATE_RCFG_INTF*(LANES-1)+1)*DPRIO_DATA_WIDTH-1:0]     tx_reconfig_mgmt_readdata,
    output wire [`SEPARATE_RCFG_INTF*(LANES-1):0]                            tx_reconfig_mgmt_waitrequest,
  
    output reg [LANES-1:0]                         reconfig_write,
    output reg [LANES-1:0]                         reconfig_read,
    output reg [(LANES*DPRIO_ADDRESS_WIDTH)-1:0]   reconfig_address,
    output reg [(LANES*DPRIO_DATA_WIDTH)-1:0]      reconfig_writedata,

    input  wire [(LANES*DPRIO_DATA_WIDTH)-1:0]      rx_reconfig_readdata,
    input  wire [LANES-1:0]                         rx_reconfig_waitrequest,
    input  wire [(LANES*DPRIO_DATA_WIDTH)-1:0]      tx_reconfig_readdata,
    input  wire [LANES-1:0]                         tx_reconfig_waitrequest,

    input  wire [LANES-1:0]                         rx_cal_busy,
    input  wire [LANES-1:0]                         tx_cal_busy,
    output wire [LANES-1:0]                         rx_reconfig_cal_busy,
    output wire [LANES-1:0]                         tx_reconfig_cal_busy
);
  
    reg [31:0] expire_count;

    // --------------------------------------------------------------------------//
    // Main FSM                                                                  //
    // --------------------------------------------------------------------------//
    // Main FSM to sequence the Rx and Tx Reconfiguration Cycle to ensure        //
    // to ensure there is not data corrupted.                                    //
    //                                                                           //
    // --------------------------------------------------------------------------//
    localparam  FSM_IDLE    = 0,
                FSM_RX      = 2,
                FSM_TX      = 3;

    reg  [1:0]  fsm_main_ns;     
    reg  [1:0]  fsm_main_ps;

    wire        arc_to_RX, arc_to_TX;

    always @ (posedge clk or posedge reset)
    begin
        if (reset) begin
            fsm_main_ps <= FSM_IDLE;
        end else begin
            fsm_main_ps <= fsm_main_ns;
        end        
    end   
    
    // next state logic
    always @ (*) 
    begin
        fsm_main_ns = fsm_main_ps;
        
        case (fsm_main_ps)
            // IDLE
            FSM_IDLE: begin
                if (arc_to_RX) begin
                    fsm_main_ns = FSM_RX;
                end else begin
                    fsm_main_ns = FSM_IDLE;                
                end
            end //IDLE

            // RX
            FSM_RX: begin
                if (arc_to_TX) begin
                    fsm_main_ns = FSM_TX;
                end else begin
                    fsm_main_ns = FSM_RX;
                end	       
            end //RX
            
            // TX
            FSM_TX: begin
                if (arc_to_RX) begin
                    fsm_main_ns = FSM_RX;
                end else begin
                    fsm_main_ns = FSM_TX;
                end	       
            end //TX
        endcase
    end

    assign arc_to_RX = (fsm_main_ps == FSM_IDLE) || 
                       (fsm_main_ps == FSM_TX) && (((!tx_rcfg_en) && rx_rcfg_en) || 
                       (expire_count[31:16] == EXPIRED_COUNTER[31:16])); 
    assign arc_to_TX = (fsm_main_ps == FSM_RX) && (((!rx_rcfg_en) && tx_rcfg_en) || (expire_count[31:16] == EXPIRED_COUNTER[31:16]));

    wire    is_rx_nxt, is_tx_nxt;
    reg     is_rx, is_tx;
    assign is_rx_nxt = (fsm_main_ns==FSM_RX) ? 1'b1 : 1'b0;
    assign is_tx_nxt = (fsm_main_ns==FSM_TX) ? 1'b1 : 1'b0;
    
    always @ (posedge clk or posedge reset)
    begin
        if (reset) begin
            is_rx <= 1'b0;
            is_tx <= 1'b0;
        end else begin
            is_rx <= is_rx_nxt;
            is_tx <= is_tx_nxt;
        end        
    end   

    // --------------------------------------------------------------------------//
    // Expired Timer Counter                                                     //
    // --------------------------------------------------------------------------//
    // If Rx or Tx reconfiguration hang, it will switch to other reconfiguration //
    // sequence after it expired.                                                //
    // --------------------------------------------------------------------------//
    wire [31:0] expire_count_nxt;

    always @ (posedge clk or posedge reset)
    begin
        if (reset) begin
            expire_count <= 32'd0;
        end else begin
            if (fsm_main_ps != fsm_main_ns)
              expire_count <= 32'd0;
            else
              expire_count <= expire_count_nxt;
        end        
    end   
    
    assign expire_count_nxt = ((is_rx && rx_rcfg_en) || (is_tx && tx_rcfg_en)) ? expire_count + 32'b1 : 32'd0;
    
    
    // --------------------------------------------------------------------------//
    // From Reconfiguration Management (AVMM Master) to XCVR                     //
    // --------------------------------------------------------------------------//
    // Concatenate AVMM output interface each channel into XCVR AVMM interface   //
    // before sending to XCVR.                                                   //
    // Reconfiguration management FSM will process the AVMM transaction per      //
    // channel in sequence.                                                      //
    // is_rx and is_tx are indicator from reconfiguration management module to   //
    // indicate whether Rx and Tx is currently being reconfigured.               //
    // --------------------------------------------------------------------------//

        generate 
        genvar ch; 
            for (ch=0; ch<(LANES); ch=ch+1) 
            begin :  Reconfig_arb
                `ifdef SEPARATE_RCFG_INTF_EN
                    assign reconfig_write[ch] = (is_rx) ? rx_reconfig_mgmt_write[ch] : 
                                ((is_tx) ? tx_reconfig_mgmt_write[ch] : 1'b0);
                    assign reconfig_read[ch] = (is_rx) ? rx_reconfig_mgmt_read[ch] : 
                                ((is_tx) ? tx_reconfig_mgmt_read[ch] : 1'b0);
                `else               
                    assign reconfig_write[ch] = (is_rx) ? ((ch==rx_rcfg_ch)? rx_reconfig_mgmt_write[0] : 1'b0) : 
                                            ((is_tx) ? ((ch==tx_rcfg_ch)? tx_reconfig_mgmt_write[0] :1'b0) : 1'b0);
                    assign reconfig_read[ch] = (is_rx) ? ((ch==rx_rcfg_ch)? rx_reconfig_mgmt_read[0] : 1'b0) : 
                                           ((is_tx) ? ((ch==tx_rcfg_ch)? tx_reconfig_mgmt_read[0] : 1'b0) : 1'b0);
                `endif
            end 
        endgenerate

`ifdef SEPARATE_RCFG_INTF_EN
        assign reconfig_address = (is_rx) ? rx_reconfig_mgmt_address  : 
                                  ((is_tx) ? tx_reconfig_mgmt_address : {(LANES*DPRIO_ADDRESS_WIDTH){1'b0}});
        assign reconfig_writedata = (is_rx) ? rx_reconfig_mgmt_writedata : 
                                    ((is_tx) ? tx_reconfig_mgmt_writedata : {(LANES*DPRIO_DATA_WIDTH){1'b0}});
        assign rx_reconfig_cal_busy = (is_tx && tx_rcfg_en) ? {LANES{1'b0}} : rx_cal_busy;
        assign tx_reconfig_cal_busy = (is_rx && rx_rcfg_en) ? {LANES{1'b0}} : tx_cal_busy;
`else 
        assign reconfig_address = (is_rx) ? {LANES{rx_reconfig_mgmt_address}}  : 
                                    ((is_tx) ? {LANES{tx_reconfig_mgmt_address}} : {(LANES*DPRIO_ADDRESS_WIDTH){1'b0}});
        assign reconfig_writedata = (is_rx) ? {LANES{rx_reconfig_mgmt_writedata}} : 
                                    ((is_tx) ? {LANES{tx_reconfig_mgmt_writedata}} : {(LANES*DPRIO_DATA_WIDTH){1'b0}});
        assign rx_reconfig_cal_busy = (is_tx && tx_rcfg_en) ? {LANES{1'b0}} : rx_cal_busy;
        assign tx_reconfig_cal_busy = (is_rx && rx_rcfg_en) ? {LANES{1'b0}} : tx_cal_busy;
`endif


    // --------------------------------------------------------------------------//
    // From XCVR to Reconfiguration Management (AVMM Master)                     //
    // --------------------------------------------------------------------------//
    // Arbitrate readdata and waitrequest from XCVR (Tx and RX) to               //
    // reconfiguration management module.                                        //
    // Reconfiguration management FSM will process the AVMM transaction per      //
    // channel in sequence.                                                      //
    // --------------------------------------------------------------------------//
    
`ifdef SEPARATE_RCFG_INTF_EN
        assign rx_reconfig_mgmt_readdata = rx_reconfig_readdata;
        assign rx_reconfig_mgmt_waitrequest = (is_rx) ? rx_reconfig_waitrequest : {LANES{1'b1}};
        assign tx_reconfig_mgmt_readdata = tx_reconfig_readdata;
        assign tx_reconfig_mgmt_waitrequest = (is_tx) ? tx_reconfig_waitrequest : {LANES{1'b1}};
`else 
        assign rx_reconfig_mgmt_readdata = rx_reconfig_readdata[(rx_rcfg_ch*DPRIO_DATA_WIDTH) +: DPRIO_DATA_WIDTH];
        assign rx_reconfig_mgmt_waitrequest = (is_rx) ? rx_reconfig_waitrequest[rx_rcfg_ch] : 1'b1;
        assign tx_reconfig_mgmt_readdata = tx_reconfig_readdata[(tx_rcfg_ch*DPRIO_DATA_WIDTH) +: DPRIO_DATA_WIDTH];
        assign tx_reconfig_mgmt_waitrequest = (is_tx) ? tx_reconfig_waitrequest[tx_rcfg_ch] : 1'b1;
`endif

endmodule
