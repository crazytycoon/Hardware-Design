//**************************************************************************************
//  Author		: Inc
//  Module Name		: Double Flop Synchronizer 
//  Description		: SYnchronizes the level based signals
//  DoR			: June 2021
//  Rev. History	: v1
//  Remarks		:
//
//
//***************************************************************************************

`timescale 1 ns / 1 ps

module double_flop_sync ( 
	input wire       clk_i        ,
	input wire       rst_n        ,     
	input wire       signal_in    ,
	output wire      sync_sig_out 
);



  reg ff_1;
  reg ff_2;


  always @ (posedge clk_i, negedge rst_n) begin
    if (!rst_n) begin
      ff_1 <= 'd0;
      ff_2 <= 'd0;
    end 
    else begin
      ff_1 <= signal_in;
      ff_2 <= ff_1;
    end
  end

  assign sync_sig_out = ff_2;

endmodule
