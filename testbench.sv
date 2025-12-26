`timescale 1ns/1ps

module tb_ethernet;
  
  reg rst_n;
  reg rgmii_rxc;
  reg [3:0] rgmii_rxd;
  reg rgmii_rx_ctl;
  
  wire [7:0] rx_data;
  wire rx_valid;
  wire rx_sof;
  wire rx_eof;
  wire rx_error;
  
  reg clk_125m;
  reg tx_start;
  reg [7:0] tx_data;
  reg [15:0] tx_len;
  
  wire tx_busy;
  wire tx_done;
  wire rgmii_txc;
  wire [3:0] rgmii_txd;
  wire rgmii_tx_ctl;
  
  ethernet_top dut (
    .rst_n (rst_n),
    
    .rgmii_rxc (rgmii_rxc),
    .rgmii_rxd (rgmii_rxd),
    .rgmii_rx_ctl (rgmii_rx_ctl),
    .rx_data (rx_data),
    .rx_valid (rx_valid),
    .rx_sof (rx_sof),
    .rx_eof (rx_eof),
    .rx_error (rx_error),
    
    .clk_125m (clk_125m),
    .tx_start (tx_start),
    .tx_data (tx_data),
    .tx_len (tx_len),
    .tx_busy (tx_busy),
    .tx_done (tx_done),
    .rgmii_txc (rgmii_txc),
    .rgmii_txd (rgmii_txd),
    .rgmii_tx_ctl (rgmii_tx_ctl)
  );
  
  
  initial rgmii_rxc = 0;
  always #4 rgmii_rxc = ~rgmii_rxc;
  
  initial clk_125m = 0;
  always #4 clk_125m = ~clk_125m;
  
  
  task send_byte (input [7:0] data, input ctl);
    begin 
      rgmii_rx_ctl = ctl;
      
      rgmii_rxd = data [3:0];
      @(posedge rgmii_rxc);
      #1;
      
      rgmii_rxd = data [7:4];
      @(negedge rgmii_rxc);
      #1;
   
    end
  endtask
  
  
  initial begin 
    rst_n = 0;
    rgmii_rxd = 0;
    rgmii_rx_ctl = 0;
    
    tx_start = 0;
    tx_data = 0;
    tx_len = 0;
    
    #100;
    rst_n = 1;
    #20;
    
    $display ("Time %0t: Starting Packet Transmission...", $time);
    
    repeat(7) send_byte (8'h55, 1);
    
    send_byte (8'hD5, 1);
    
    send_byte (8'hAA, 1);
    send_byte (8'hBB, 1);
    send_byte (8'hCC, 1);
    send_byte (8'hDD, 1);
    
    send_byte (8'hDE, 1);
    send_byte (8'hAD, 1);
    send_byte (8'hBE, 1);
    send_byte (8'hEF, 1);
    
    rgmii_rx_ctl = 0;
    rgmii_rxd = 0;
    
    $display ("Time %0t: Packet Finished. waiting for results...", $time);
    
    #200;
    
    $display ("Time %0t: [TX TEST] Starting Packet Transmission...", $time);
    
    @(posedge clk_125m);
    tx_len = 4;
    tx_data = 8'hA5;
    tx_start = 1;
    
    @(posedge clk_125m);
    tx_start = 0;
    
    wait (tx_done);
    
    $display ("Time %0t: TX Done!", $time);
    
    #100;
    
    $finish; 
  end
  
  initial begin 
    $dumpfile ("dump.vcd");
    $dumpvars (0, tb_ethernet);
  end
  
  initial begin
    #500000;
    $display ("ERROR: Simulation Timed out! Stuck in loop?");
    $finish;
  end
  
endmodule
