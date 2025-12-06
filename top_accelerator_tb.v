`timescale 1ns / 1ps
`include "defines.vh"

module top_accelerator_tb;

    // --- DUT Signals ---
    reg clk;
    reg reset_n;
    reg rx_in;          // Input TO the FPGA
    wire tx_out;        // Output FROM the FPGA

    // --- Simulation Parameters ---
    localparam CLKS_PER_BIT = 10; 
    localparam BIT_PERIOD = 100; // 10 clocks * 10ns period

    // --- Instantiate the Full System ---
    top_accelerator u_dut (
        .clk(clk),
        .reset_n(reset_n),
        .rx_in(rx_in),
        .tx_out(tx_out)
    );

    // --- Clock Generation ---
    always #5 clk = ~clk; // 100 MHz

    // --- TASK: SEND BYTE (Simulates Python Writing) ---
    task send_byte_to_fpga;
        input [7:0] data_to_send;
        integer i;
        begin
            rx_in = 0; #(BIT_PERIOD); // Start Bit
            for (i=0; i<8; i=i+1) begin
                rx_in = data_to_send[i]; #(BIT_PERIOD);
            end
            rx_in = 1; #(BIT_PERIOD); // Stop Bit
        end
    endtask

    // --- NEW TASK: RECEIVE BYTE (Simulates Python Reading) ---
    reg [7:0] received_data; // Buffer to store the byte
    task wait_and_receive_byte;
        integer i;
        begin
            // 1. Wait for the FPGA to pull the line LOW (Start Bit)
            @(negedge tx_out);
            
            // 2. Wait 1.5 bit periods to get to the middle of the first data bit
            #(BIT_PERIOD + (BIT_PERIOD/2));
            
            // 3. Sample 8 Bits
            for (i=0; i<8; i=i+1) begin
                received_data[i] = tx_out;
                #(BIT_PERIOD);
            end
            
            // 4. Print the result to the terminal!
            $display("\n------------------------------------------------");
            $display("PYTHON RECEIVED: %d (Binary: %b)", received_data, received_data);
            $display("------------------------------------------------\n");
        end
    endtask

    // --- TEST PROCEDURE ---
    integer w;
    initial begin
        $dumpfile("full_system.vcd");
        $dumpvars(0, top_accelerator_tb);

        // 1. Initialize
        clk = 0;
        reset_n = 0;
        rx_in = 1; // UART Idle is High
        #100;
        reset_n = 1;
        #100;

        // --- PHASE 1: LOAD WEIGHTS ---
        $display("--- PHASE 1: Loading Weights (Simulating Python) ---");
        
        // Loop 64 times to load weights
        for (w=0; w<64; w=w+1) begin
            // Send unique weights (w+1) so we don't multiply by zero!
            send_byte_to_fpga(w + 1); 
            #1000; 
        end
        $display("Weights Loaded!");

        // --- PHASE 2: SEND PIXEL & LISTEN FOR ANSWER ---
        $display("--- PHASE 2: Sending Pixel Data & Listening ---");
        
        // We use 'fork..join' so we can SEND and LISTEN at the same time
        fork
            // Thread 1: Send the Pixel (Value = 10)
            begin
                #100; // Small delay
                send_byte_to_fpga(8'd10);
            end
            
            // Thread 2: Listen for the result
            begin
                wait_and_receive_byte();
            end
        join

        // Calculation Check:
        // Input (10) * Weight_0 (1) = 10.
        // Expected Output: 10.
        
        #1000;
        $finish;
    end

endmodule
