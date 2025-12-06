`include "defines.vh"

module control_fsm (
    input wire clk,
    input wire reset_n,
    input wire rx_done,          // "New byte arrived from Python"
    
    output reg write_en,         // 1 = Write to Memory, 0 = Don't Write
    output reg [7:0] write_addr, // Where to write the weight
    output reg start_compute     // 1 = Reset Layer Accumulators
);

    // --- State Encoding ---
    localparam STATE_LOAD_WEIGHTS = 2'b00;
    localparam STATE_START_COMPUTE = 2'b01;
    localparam STATE_RUNNING       = 2'b10;

    reg [1:0] state;
    
    // Define how many weights we expect before switching modes
    // 4 neurons * 16 weights (example) = 64 bytes
    // this should match the number of bytes your Python script sends!
    localparam TOTAL_WEIGHTS = 8'd64; 

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_LOAD_WEIGHTS;
            write_addr <= 0;
            write_en <= 0;
            start_compute <= 0;
        end else begin
            case (state)
                
                // --- STATE 0: LOAD MODE ---
                // Listen to UART, fill memory, count up to 64
                STATE_LOAD_WEIGHTS: begin
                    start_compute <= 0;
                    
                    if (rx_done) begin
                        write_en <= 1; 
                        if (write_addr == TOTAL_WEIGHTS - 1) begin
                            state <= STATE_START_COMPUTE;
                        end else begin
                            write_addr <= write_addr + 1; 
                        end
                    end else begin
                        write_en <= 0; 
                    end
                end

                // --- STATE 1: RESET TRIGGER ---
                // Clear the Neural Network accumulators once
                STATE_START_COMPUTE: begin
                    write_en <= 0;       
                    start_compute <= 1;  // Pulse High to Reset Accumulators
                    state <= STATE_RUNNING;
                end

                // --- STATE 2: RUNNING MODE ---
                // FSM just sits here. The logic in top_accelerator handles the 
                // RX -> MAC -> TX pipeline.
                STATE_RUNNING: begin
                    start_compute <= 0; // Release Reset
                    write_en <= 0;      
                end
                
            endcase
        end
    end

endmodule
