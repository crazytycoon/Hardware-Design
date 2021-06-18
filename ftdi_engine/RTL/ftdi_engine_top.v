//***********************************************************************
// Author		: Inc
// Module Name		:
// Desc			:
// DoR			:
// Rev History		:
// Remarks		:
//
//
// ***********************************************************************
`timescale 1 ns/ 1 ps

module ftdi_engine_top  # (parameter FIFO_WIDTH = 8, FIFO_DEPTH=16) (
	input wire   async_rst_n  ,
	input wire   clk_ftdi     ,

	// ftdi CHIP bus
	input  wire         rxf_n   ,
	output wire         rd_n    ,

	input  wire         txe_n   ,
	output wire         wr_n    ,
	inout  wire   [7:0] data    ,


        //ext device side
	input wire        clk_ext         ,

	input wire        ext_dev_rd_en   ,
        output wire [7:0] ext_dev_rd_data ,
        output wire       ext_dev_rd_empty,

	input wire        ext_dev_wr_en   ,
        input wire [7:0]  ext_dev_wr_data ,
        output wire       ext_dev_wr_full 
);



  wire [7:0]        data_in  ;
  wire [7:0]        data_out ;
  wire              data_oe  ;

  wire              ftdi_rd_fifo_full    ;
  wire [7:0]        ftdi_rd_fifo_data    ;
  wire              ftdi_rd_fifo_en      ;
                                
  wire              ftdi_wr_fifo_empty   ;
  wire [7:0]        ftdi_wr_data         ;
  wire              ftdi_wr_fifo_en      ;






  assign data     = (data_oe) ? data_out : 'bz;
  assign data_in  = data;



  //ftdi engine
  ftdi_engine  FTDI_ENGINE_U1 (
	.clk_i              (clk_ftdi               ),
        .async_rst_n        (async_rst_n            ),

        .rxf_n              (rxf_n                  ),
	.rd_n               (rd_n                   ),
        .txe_n              (txe_n                  ),
	.wr_n               (wr_n                   ),

        .data_in            (data_in                ),
	.data_out           (data_out               ),
	.data_oe            (data_oe                ),

	.ftdi_rd_fifo_full  (ftdi_rd_fifo_full      ),
	.ftdi_rd_fifo_data  (ftdi_rd_fifo_data      ),
	.ftdi_rd_fifo_en    (ftdi_rd_fifo_en        ),

        .ftdi_wr_fifo_empty (ftdi_wr_fifo_empty     ),	
        .ftdi_wr_data       (ftdi_wr_data           ),
        .ftdi_wr_fifo_en    (ftdi_wr_fifo_en        )  );	


  // FTDI RD FIFO
  async_fifo FTDI_RD_FIFO_U2
    (
      .async_rst_n            (async_rst_n             ),
      .wr_clk                  (clk_ftdi                ),
      .fifo_wr_en              (ftdi_rd_fifo_en         ),
      .fifo_wr_data            (ftdi_rd_fifo_data       ),
      .fifo_full               (ftdi_rd_fifo_full       ),
      .rd_clk                  (clk_ext                 ),
      .fifo_rd_en              (ext_dev_rd_en           ),
      .fifo_rd_data            (ext_dev_rd_data         ),
      .fifo_empty              (ext_dev_rd_empty        )   ); 
    
  // FTDI WR FIFO  
  async_fifo FTDI_WR_FIFO_U3
    (
      .async_rst_n             (async_rst_n             ),
      .wr_clk                  (clk_ext                 ),
      .fifo_wr_en              (ext_dev_wr_en           ),
      .fifo_wr_data            (ext_dev_wr_data         ),
      .fifo_full               (ext_dev_wr_full         ),
      .rd_clk                  (clk_ftdi                ),
      .fifo_rd_en              (ftdi_wr_fifo_en         ),
      .fifo_rd_data            (ftdi_wr_data            ),
      .fifo_empty              (ftdi_wr_fifo_empty      )   ); 

endmodule 
