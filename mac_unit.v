`include "defines.vh"

module mac_unit(
	input clk,
	input reset_n,
	input clear_acc,
	input enable,
	input signed [`DATA_WIDTH-1:0] weight_val,  //uses signed values to correctly handle negative weights.
	input signed [`DATA_WIDTH-1:0] input_val,
	output signed [`ACC_WIDTH-1:0] accumulated_result
);

	wire signed [(`DATA_WIDTH*2)-1:0] product;
	reg  signed [`ACC_WIDTH-1:0] accumulator;
	
	//Multiplication Stage
	assign product = weight_val * input_val;
	
	//Accumulation Stage
	always@(posedge clk or negedge reset_n) 
	begin
	if(!reset_n) begin
	accumulator <= 0;
	end
	else if (clear_acc) begin
	accumulator <= 0;
	end
	else if (enable) begin
	accumulator <= accumulator  + product;
	end
	end
	
	assign accumulated_result = accumulator;
	
endmodule


