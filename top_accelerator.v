`include "defines.vh"

module top_accelerator (
    input wire clk,
    input wire reset_n,
    input wire rx_in,             // UART Input (From Python)
    output wire tx_out            // UART Output (To Python)
);

    // --- SIGNALS ---
    wire [7:0] rx_data;
    wire rx_done;

    // FSM Signals
    wire write_enable_mem;
    wire start_compute; // This is the 'reset accumulator' signal
    wire [7:0] write_addr;
    wire [7:0] layer_read_addr; 
    
    // Weights & Outputs
    wire signed [`DATA_WIDTH-1:0] w0, w1, w2, w3;
    wire signed [`DATA_WIDTH-1:0] n0_out, n1_out, n2_out, n3_out;

    // --- TX LOGIC SIGNALS ---
    reg tx_start_reg;
    reg [1:0] tx_delay_cnt; // To wait for MAC calculation
    wire tx_active, tx_done_sig;

    // --- 1. UART RX ---
    uart_rx u_rx (
        .clk(clk), .reset_n(reset_n),
        .rx_in(rx_in),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // --- 2. THE FSM ---
    control_fsm u_fsm (
        .clk(clk), .reset_n(reset_n),
        .rx_done(rx_done),       
        .write_en(write_enable_mem), 
        .write_addr(write_addr),     
        .start_compute(start_compute) 
    );

    // --- 3. MEMORY BANKS ---
    weight_memory bank0 (.clk(clk), .write_en(write_enable_mem), .write_addr(write_addr), .write_data(rx_data), .read_addr(layer_read_addr), .read_data(w0));
    weight_memory bank1 (.clk(clk), .write_en(write_enable_mem), .write_addr(write_addr), .write_data(rx_data), .read_addr(layer_read_addr), .read_data(w1));
    weight_memory bank2 (.clk(clk), .write_en(write_enable_mem), .write_addr(write_addr), .write_data(rx_data), .read_addr(layer_read_addr), .read_data(w2));
    weight_memory bank3 (.clk(clk), .write_en(write_enable_mem), .write_addr(write_addr), .write_data(rx_data), .read_addr(layer_read_addr), .read_data(w3));

    // --- 4. THE Hidden Layer ---
    hidden_layer u_layer2 (
        .clk(clk), .reset_n(reset_n),
        .start_layer(start_compute),
        .data_valid(rx_done), // Compute trigger
        .input_pixel(rx_data), 
        .weight_address_base(layer_read_addr),
        .weight_n0(w0), .weight_n1(w1), .weight_n2(w2), .weight_n3(w3),
        .activation_type(2'b00), 
        .out_n0(n0_out), .out_n1(n1_out), .out_n2(n2_out), .out_n3(n3_out)
    );

    // --- 5. TX TRIGGER LOGIC (New!) ---
    // We only want to send data back when we are in COMPUTING mode, not LOADING mode.
    // from FSM If write_enable_mem is LOW and start_compute is LOW (Running state), we are computing.
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_start_reg <= 0;
            tx_delay_cnt <= 0;
        end else begin
            // Default
            tx_start_reg <= 0;

            // Logic: If we received a byte (rx_done) AND we are NOT loading weights
            if (rx_done && !write_enable_mem && !start_compute) begin
                tx_delay_cnt <= 1; // Start delay timer
            end
            
            // Wait 1 cycle for MAC to finish, then fire TX
            if (tx_delay_cnt == 1) begin
                tx_delay_cnt <= 2;
            end else if (tx_delay_cnt == 2) begin
                tx_start_reg <= 1; // FIRE!
                tx_delay_cnt <= 0; // Reset
            end
        end
    end

    // --- 6. UART TX (Sends Result) ---
    uart_tx u_tx (
        .clk(clk), .reset_n(rst_n),
        .tx_start(tx_start_reg),
        .tx_data(n0_out), // Send Neuron 0's result (or use Mux to cycle through them)
        .tx_active(tx_active),
        .tx_serial(tx_out),
        .tx_done(tx_done_sig)
    );

endmodule
