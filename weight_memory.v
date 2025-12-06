`include "defines.vh"

module weight_memory (
	input wire clk,
	
	//PORT A: Connected to UART
	input wire write_en,
	input wire [7:0] write_addr,
	input wire signed [`DATA_WIDTH-1:0] write_data,
	
	//PORT B: Connected to MAC_units
	input wire [7:0] read_addr,
	output reg signed [`DATA_WIDTH-1:0] read_data
);

	//Defining MEMORY ARRAY
	reg signed [`DATA_WIDTH-1:0] mem_array[0:63];
	
	always@(posedge clk)
	begin
	if(write_en) begin
	mem_array[write_addr] <= write_data;
	end
	end
	
	//combinational read is faster 
	always@(*)
	begin
	read_data = mem_array[read_addr];
	end
endmodule


