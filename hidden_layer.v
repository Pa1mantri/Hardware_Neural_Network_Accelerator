`include "defines.vh"

module hidden_layer(
	input wire clk,
	input wire reset_n,
	input wire start_layer,
	input wire data_valid,
	input wire signed [`DATA_WIDTH-1:0] input_pixel,  //single pixel 8-bit


	//memory interface
	output reg [7:0] weight_address_base,
	input wire signed [`DATA_WIDTH-1:0] weight_n0,
	input wire signed [`DATA_WIDTH-1:0] weight_n1,
	input wire signed [`DATA_WIDTH-1:0] weight_n2,
	input wire signed [`DATA_WIDTH-1:0] weight_n3,
	
	//Configurable datapath interface
	input wire [1:0]activation_type,
	
	//output (the final score after all pixel's are processed)
	output wire signed [`DATA_WIDTH-1:0] out_n0,
	output wire signed [`DATA_WIDTH-1:0] out_n1,
	output wire signed [`DATA_WIDTH-1:0] out_n2,
	output wire signed [`DATA_WIDTH-1:0] out_n3
	
);

//Internal wires for MAC outputs {20-bit}
wire signed [`ACC_WIDTH-1:0] acc_n0,acc_n1,acc_n2,acc_n3;


// --- 1. Address Counter Logic ---
    // This tells the memory which weight to fetch for the current pixel
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            weight_address_base <= 0;
        end else if (start_layer) begin
            weight_address_base <= 0; // Reset counter for new image
        end else if (data_valid) begin
            weight_address_base <= weight_address_base + 1; // Move to next weight
        end
    end

//Instantiating neurons with same input and different weights

mac_unit mac0 (
	.clk(clk), .reset_n(reset_n), .clear_acc(start_layer), .enable(data_valid),
	.weight_val(weight_n0), .input_val(input_pixel),.accumulated_result(acc_n0)
);


mac_unit mac1 (
	.clk(clk), .reset_n(reset_n), .clear_acc(start_layer), .enable(data_valid),
	.weight_val(weight_n1), .input_val(input_pixel),.accumulated_result(acc_n1)
);

mac_unit mac2 (
	.clk(clk), .reset_n(reset_n), .clear_acc(start_layer), .enable(data_valid),
	.weight_val(weight_n2), .input_val(input_pixel),.accumulated_result(acc_n2)
);

mac_unit mac3 (
	.clk(clk), .reset_n(reset_n), .clear_acc(start_layer), .enable(data_valid),
	.weight_val(weight_n3), .input_val(input_pixel),.accumulated_result(acc_n3)
);


//Activation logic & convert the 20-bit accumulator output to 8-bit

activation_unit act0(.activation_type(activation_type),.data_in(acc_n0), .data_out(out_n0));
activation_unit act1(.activation_type(activation_type),.data_in(acc_n1), .data_out(out_n1));
activation_unit act2(.activation_type(activation_type),.data_in(acc_n2), .data_out(out_n2));
activation_unit act3(.activation_type(activation_type),.data_in(acc_n3), .data_out(out_n3));

endmodule


