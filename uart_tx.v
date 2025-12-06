module uart_tx 
  #(parameter CLKS_PER_BIT = 10) // Matching this number to receiver unit!
  (
   input wire       clk,
   input wire       reset_n,
   input wire       tx_start, // Pulse HIGH to start sending
   input wire [7:0] tx_data,  // Byte to send
   output reg       tx_active, // High while sending
   output reg       tx_serial, // The wire to Python
   output reg       tx_done    // High when finished
   );
 
  localparam s_IDLE         = 3'b000;
  localparam s_TX_START_BIT = 3'b001;
  localparam s_TX_DATA_BITS = 3'b010;
  localparam s_TX_STOP_BIT  = 3'b011;
  localparam s_CLEANUP      = 3'b100;
   
  reg [2:0]    r_SM_Main;
  reg [13:0]   r_Clock_Count;
  reg [2:0]    r_Bit_Index;
  reg [7:0]    r_Tx_Data;
   
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      r_SM_Main <= s_IDLE;
      tx_active <= 0;
      tx_serial <= 1; // Idle state for UART is High
      tx_done   <= 0;
      r_Clock_Count <= 0;
      r_Bit_Index <= 0;
      r_Tx_Data <= 0;
    end else begin
       
      case (r_SM_Main)
        s_IDLE : begin
          tx_active <= 0;
          tx_serial <= 1;
          tx_done   <= 0;
          r_Clock_Count <= 0;
          r_Bit_Index <= 0;
           
          if (tx_start == 1'b1) begin
            tx_active <= 1;
            r_Tx_Data <= tx_data;
            r_SM_Main <= s_TX_START_BIT;
          end
        end
         
        s_TX_START_BIT : begin
          tx_serial <= 0; // Start bit = Low
          if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
          end else begin
            r_Clock_Count <= 0;
            r_SM_Main     <= s_TX_DATA_BITS;
          end
        end
         
        s_TX_DATA_BITS : begin
          tx_serial <= r_Tx_Data[r_Bit_Index];
           
          if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
          end else begin
            r_Clock_Count <= 0;
            if (r_Bit_Index < 7) begin
              r_Bit_Index <= r_Bit_Index + 1;
            end else begin
              r_Bit_Index <= 0;
              r_SM_Main   <= s_TX_STOP_BIT;
            end
          end
        end
         
        s_TX_STOP_BIT : begin
          tx_serial <= 1; // Stop bit = High
          if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
          end else begin
            tx_done       <= 1;
            r_Clock_Count <= 0;
            r_SM_Main     <= s_CLEANUP;
            tx_active     <= 0;
          end
        end
         
        s_CLEANUP : begin
          tx_done   <= 1;
          r_SM_Main <= s_IDLE;
        end
         
        default : r_SM_Main <= s_IDLE;
      endcase
    end
  end
endmodule
