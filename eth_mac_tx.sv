module eth_mac_tx
  (
    input wire clk,
    input wire rst_n,
    
    input wire tx_start,
    input wire [7:0] tx_data,
    input wire [15:0] tx_len,
    output reg tx_busy,
    output reg tx_done,
    
    output reg [7:0] gmii_txd,
    output reg gmii_tx_en
  );
 
  
  typedef enum logic [2:0] 
  {
    IDLE, 
    PREAMBLE,
    SFD,
    DATA,
    CRC
  } state_t;
  
  state_t state;
  reg [15:0] byte_cnt;
  
  reg crc_init;
  reg crc_calc;
  wire [31:0] crc_result;
  
  
  crc32_gen crc_inst (
    .clk (clk),
    .rst_n (rst_n),
    
    .init (crc_init),
    .calc (crc_calc),
    
    .data_in (tx_data),
    
    .crc_out (crc_result)
  );
  
  
  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
      state <= IDLE;
      gmii_tx_en <= 0;
      gmii_txd <= 0;
      tx_busy <= 0;
      tx_done <= 0;
      crc_init <= 0;
      crc_calc <= 0;
      byte_cnt <= 0;
      
    end else begin 
      crc_init <= 0;
      crc_calc <= 0;
      tx_done <= 0;
      
      case (state)
        IDLE: begin
          gmii_tx_en <= 0;
          tx_busy <= 0;
          
          if (tx_start) begin
            state <= PREAMBLE;
            byte_cnt <= 0;
            tx_busy <= 1;
            crc_init <= 1;
          end
        end
        
        PREAMBLE: begin
          gmii_tx_en <= 1;
          gmii_txd <= 8'h55;
          
          byte_cnt <= byte_cnt + 1;
          if (byte_cnt == 6) begin
            state <= SFD;
          end
        end
        
        SFD: begin
          gmii_txd <= 8'hD5;
          state <= DATA;
          byte_cnt <= 0;
        end
        
        DATA: begin
          gmii_txd <= tx_data;
          crc_calc <= 1;
          
          byte_cnt <= byte_cnt + 1;
          
          if (byte_cnt == tx_len - 1) begin
            state <= CRC;
            byte_cnt <= 0;
          end
        end
        
        CRC: begin
          case (byte_cnt)
            0: gmii_txd <= crc_result [7:0];
            1: gmii_txd <= crc_result [15:8];
            2: gmii_txd <= crc_result [23:16];
            3: gmii_txd <= crc_result [31:24];
          endcase
          
          
         byte_cnt <= byte_cnt + 1;
          
          if (byte_cnt == 3) begin
            state <= IDLE;
            tx_done <= 1;
            gmii_tx_en <= 0;
          end
        end
      endcase
    end
  end
    
endmodule
