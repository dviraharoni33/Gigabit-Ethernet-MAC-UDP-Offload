module eth_mac_rx 
  (
    input wire clk,
    input wire rst_n,
    
    input wire [7:0] gmii_rxd,
    input wire gmii_dv,
    input wire gmii_er,
    
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_sof,
    output reg rx_eof,
    output reg rx_error
  );
  
  localparam STATE_IDLE = 3'd0;
  localparam STATE_PREAMBLE = 3'd1;
  localparam STATE_SFD = 3'd2;
  localparam STATE_DATA = 3'd3;
  localparam STATE_CHECK_CRC = 3'd4;
  
  reg [2:0] state;
  reg [2:0] next_state;
  
  wire [31:0] crc_result;
  reg crc_clear;
  reg crc_enable;
  
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end
  
  always @(*) begin
    next_state = state;
    
    case (state)
      STATE_IDLE: begin
        if (gmii_dv && !gmii_er) begin
          next_state = STATE_PREAMBLE;
        end
      end
      
      STATE_PREAMBLE: begin
        if (!gmii_dv) begin
          next_state = STATE_IDLE;
        end else if (gmii_rxd == 8'hD5) begin
          next_state = STATE_SFD;
        end
      end
      
      STATE_SFD: begin
        next_state = STATE_DATA;
      end
      
      STATE_DATA: begin
        if (!gmii_dv) begin
          next_state = STATE_CHECK_CRC;
        end
      end
      
      STATE_CHECK_CRC: begin
        next_state = STATE_IDLE;
      end
    endcase
  end
  
  
  crc32_eth crc_instance (
    .clk (clk),
    .rst_n (rst_n),
    .clear (crc_clear),
    .enable (crc_enable),
    .data_in (gmii_rxd),
    .crc_out (crc_result)
  );
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_valid <= 0;
      rx_data <= 0;
      rx_sof <= 0;
      rx_eof <= 0;
      rx_error <= 0;
      crc_clear <= 1;
      crc_enable <= 0;
    end else begin
      rx_sof <= 0;
      rx_eof <= 0;
      rx_error <= 0;
      
      case (state)
        STATE_IDLE: begin
          crc_clear <= 1;
          rx_valid <= 0;
        end
        
        STATE_PREAMBLE: begin
          crc_clear <= 0;
        end
        
        STATE_SFD: begin
          crc_enable <= 1;
        end
        
        STATE_DATA: begin
          rx_valid <= 1;
          rx_data <= gmii_rxd;
          crc_enable <= 1;
          
          if (rx_valid == 0) begin 
            rx_sof <= 1;
          end 
        end
        
        STATE_CHECK_CRC: begin
          crc_enable <= 0; 
          rx_valid <= 0;
          rx_eof <= 1;
          
          if(crc_result != 32'hC704DD7B) begin
            rx_error <= 1;
          end
        end
      endcase
    end
  end
  
  
endmodule
