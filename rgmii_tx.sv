module rgmii_tx 
   (
    input wire clk,
    input wire rst_n,
    input wire [7:0] gmii_txd,
    input wire gmii_tx_en,
     
    output wire [3:0] rgmii_txd,
    output wire rgmii_tx_ctl,
    output wire rgmii_txc
   );
  
  
  assign rgmii_txc = clk;
  assign rgmii_txd = (clk) ? gmii_txd[3:0] : gmii_txd[7:4];
  assign rgmii_tx_ctl = gmii_tx_en;

  
endmodule
