`include "defines.vh"

module activation_unit (
	input wire [1:0] activation_type,
	input signed [`ACC_WIDTH-1:0] data_in, //input from MAC unit
	output reg signed [`DATA_WIDTH-1:0] data_out //8-bit signed output to next layer 
);

	parameter SIGNED_THRESHOLD = 0;

    // Define Max Positive Value for 8-bit signed (01111111 = 127)
    parameter MAX_VAL = 8'sd127; 

    always @(*) begin
        case (activation_type)
            // --- Mode 0: ReLU (Rectified Linear Unit) for hidden layer---
            2'b00: begin
                if (data_in < 0) 
                    data_out = 8'sd0; // Block negative values
                else begin
                    // Saturation Logic: If value is too big for 8 bits, cap it at MAX
                    if (data_in > MAX_VAL) 
                        data_out = MAX_VAL;
                    else 
                        data_out = data_in[`DATA_WIDTH-1:0]; // Truncate/Pass through
                end
            end

            // --- Mode 1: Step Function (Threshold) for output layers---
            2'b01: begin
                if (data_in > SIGNED_THRESHOLD) 
                    data_out = MAX_VAL; // "Yes" / Class Detected (High)
                else 
                    data_out = 8'sd0;   // "No" / Nothing (Low)
            end

            // --- Mode 2: Passthrough (Linear) ---
            // Useful for debugging or regression tasks
            default: begin
                 // Simple saturation logic
                 if (data_in > MAX_VAL) data_out = MAX_VAL;
                 else if (data_in < -128) data_out = -8'sd128; // Min signed 8-bit
                 else data_out = data_in[`DATA_WIDTH-1:0];
            end
        endcase
    end

endmodule
