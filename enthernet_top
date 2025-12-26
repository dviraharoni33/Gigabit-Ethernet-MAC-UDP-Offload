`include "crc32_eth.sv"
`include "rgmii_rx.sv"
`include "eth_mac_rx.sv"
`include "crc32_gen.sv"
`include "rgmii_tx.sv"
`include "eth_mac_tx.sv"

`timescale 1ns / 1ps

module ethernet_top 
  (
    input wire rst_n,
    input wire rgmii_rxc,
    input wire [3:0] rgmii_rxd,
    input wire rgmii_rx_ctl,
    
    output wire [7:0] rx_data,
    output wire rx_valid,
    output wire rx_sof,
    output wire rx_eof,
    output wire rx_error,
    
    
    input wire clk_125m,
    input wire tx_start,
    input wire [7:0] tx_data,
    input wire [15:0] tx_len,
    
    output wire tx_busy,
    output wire tx_done,
    
    output wire rgmii_txc,
    output wire [3:0] rgmii_txd,
    output wire rgmii_tx_ctl
  );
  
  wire [7:0] internal_data;
  wire internal_dv;
  wire internal_er;
  
  wire [7:0] tx_mac_data;
  wire tx_mac_en;
  
  rgmii_rx rgmii_inst (
    .rst_n (rst_n),
    .rgmii_rxc (rgmii_rxc),
    .rgmii_rxd (rgmii_rxd),
    .rgmii_rx_ctl (rgmii_rx_ctl),
    
    .gmii_rxd_out (internal_data),
    .gmii_dv_out (internal_dv),
    .gmii_er_out (internal_er)
  );
  
  
  eth_mac_rx mac_inst (
    .clk (rgmii_rxc),
    .rst_n (rst_n),
    .gmii_rxd (internal_data),
    .gmii_dv (internal_dv),
    .gmii_er (internal_er),
    
    .rx_data (rx_data),
    .rx_valid (rx_valid),
    .rx_sof (rx_sof),
    .rx_eof (rx_eof),
    .rx_error (rx_error)
  );
  
  eth_mac_tx mac_tx_inst (
    .clk (clk_125m),
    .rst_n (rst_n),
    
    .tx_start (tx_start),
    .tx_data (tx_data),
    .tx_len (tx_len),
    .tx_busy (tx_busy),
    .tx_done (tx_done),
    
    .gmii_txd (tx_mac_data),
    .gmii_tx_en (tx_mac_en)
  );
  
  
  rgmii_tx rgmii_tx_inst (
    .clk (clk_125m),
    .rst_n (rst_n),
    
    .gmii_txd (tx_mac_data),
    .gmii_tx_en (tx_mac_en),
    
    .rgmii_txd (rgmii_txd),
    .rgmii_tx_ctl (rgmii_tx_ctl),
    .rgmii_txc (rgmii_txc)
  );
  
  
  
endmodule
