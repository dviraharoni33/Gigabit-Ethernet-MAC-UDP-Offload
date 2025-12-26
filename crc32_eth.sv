module crc32_eth
  (
    input wire clk,
    input wire rst_n,
    input wire clear,
    input wire enable, 
    input wire [7:0] data_in,
    input wire [31:0] crc_out
  );
  
  reg [31:0] crc_reg;
  reg [31:0] crc_next;
  integer i;
  
  assign crc_out = 
    ~{crc_reg[0], crc_reg[1], crc_reg[2], crc_reg[3],
      crc_reg[4], crc_reg[5], crc_reg[6], crc_reg[7],
      crc_reg[8], crc_reg[9], crc_reg[10], crc_reg[11],
      crc_reg[12], crc_reg[13], crc_reg[14], crc_reg[15],
      crc_reg[16], crc_reg[17], crc_reg[18], crc_reg[19],
      crc_reg[20], crc_reg[21], crc_reg[22], crc_reg[23],
      crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27],
      crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31]};
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      crc_reg <= 32'hFFFFFFFF;
    else if (clear)  crc_reg <= 32'hFFFFFFFF;
    else if (enable) crc_reg <= crc_next;
      end 
  
  always @(*) begin
    crc_next = crc_reg;
    for (i = 0; i<8; i = i+1) begin
      if (data_in[i] ^ crc_next[31])
        crc_next = {crc_next[30:0], 1'b0} ^ 32'h04C11DB7;
      else
        crc_next = {crc_next[30:0], 1'b0};
    end
  end
  
endmodule
