//*****************************************************************************
// Module name: DUal Clock Dual Port RAM module
//
//
//
//
//
//
//
//
//
//
//
//********************************************************************************
`timescale 1 ns/ 1 ps

module dc_dpram #(parameter WIDTH = 8, DEPTH = 16)(
	// write port
	input wire                     wr_clk,
	input wire                     wr_en ,
	input wire [$clog2(DEPTH)-1:0] wr_addr,
	input wire [WIDTH-1:0]         wr_data,


	//read port
	input wire                      rd_clk,
	input wire                      rd_en ,
	input wire [$clog2(DEPTH)-1:0]  rd_addr,
        output reg [WIDTH-1:0]          rd_data);



  reg [WIDTH-1:0] mem [DEPTH-1:0];


  // write port logic
  always @ (posedge wr_clk) begin
    if (wr_en) begin
       mem[wr_addr] <= wr_data;
     end   
  end


  // read port logic
  always @(posedge rd_clk) begin
    if (rd_en) begin
      rd_data <= mem[rd_addr];
    end	    
  end

endmodule












