module rgmii_rx
  (
    input wire rst_n,
    
    input wire rgmii_rxc,
    input wire [3:0] rgmii_rxd,
    input wire rgmii_rx_ctl,
    
    output wire [7:0] gmii_rxd_out,
    output wire gmii_dv_out,
    output wire gmii_er_out
  );
  
  
  reg [3:0] data_lo;
  reg [3:0] data_hi;
  reg ctl_rise;
  reg ctl_fall;
  
  always @(posedge rgmii_rxc or negedge rst_n) begin
    if (!rst_n) begin
      data_lo <= 4'd0;
      ctl_rise <= 1'b0;
    end else begin
      data_lo <= rgmii_rxd;
      ctl_rise <= rgmii_rx_ctl;
    end
  end
  
  always @(negedge rgmii_rxc or negedge rst_n) begin
    if (!rst_n) begin
      data_hi <= 4'd0;
      ctl_fall <= 1'b0;
    end else begin
      data_hi <= rgmii_rxd;
      ctl_fall <= rgmii_rx_ctl;
    end
  end
  
  
  reg [7:0] rxd_reg;
  reg dv_reg;
  reg er_reg;
  
  always @(posedge rgmii_rxc or negedge rst_n) begin
    if (!rst_n) begin
      rxd_reg <= 8'd0;
      dv_reg <= 1'b0;
      er_reg <= 1'b0;
    end else begin
      rxd_reg <= {data_hi, data_lo};
      
      dv_reg <= ctl_rise;
      er_reg <= ctl_rise ^ ctl_fall;
    end
  end
  
  assign gmii_rxd_out = rxd_reg;
  assign gmii_dv_out = dv_reg;
  assign gmii_er_out = er_reg;
  
endmodule
