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

module ftdi_engine_tb;
  parameter FIFO_WIDTH = 8, FIFO_DEPTH=16 ;

  reg                async_rst_n  ;
  
  reg                clk_ftdi =0  ;


  // ftdi CHIP bus
  reg                rxf_n = 1'b1 ;
  wire               rd_n         ;
  reg                txe_n =1'b1  ;
  wire               wr_n         ;
  wire [7:0]         data         ;

  reg                data_oe=0     ;

  //ext device side
  reg              clk_ext = 0      ;

  reg              ext_dev_rd_en   ;
  wire  [7:0]      ext_dev_rd_data ;
  wire             ext_dev_rd_empty;

  reg              ext_dev_wr_en   ;
  reg  [7:0]       ext_dev_wr_data ;
  wire             ext_dev_wr_full ;

  wire [7:0]        data_in         ;
  reg [7:0]        data_out        ;


  assign data    = (data_oe == 1'b1) ? data_out : 'bz;

  assign data_in = data;


  // ftdi clock generator 60MHz
  always #10 clk_ftdi = ~clk_ftdi;

  // external device clock 25MHz
  always #20 clk_ext = ~ clk_ext;



  task async_reset_generator;
    begin
      async_rst_n = 1'b1;
      #100;
      async_rst_n = 1'b0;
      #100;
      async_rst_n = 1'b1;
    end
  endtask    

  task ftdi_write;
     input [7:0] tx_data;
     begin
       rxf_n = 1'b0;
       wait (rd_n == 1'b0);
       #15;
       data_oe = 1'b1;
       data_out= tx_data;
       wait (rd_n == 1'b1);
       data_oe = 1'b0;
       rxf_n  = 1'b1;
       #65;
     end	     
  endtask

  task ftdi_read;
    output [7:0] rx_data;
    begin
      txe_n = 1'b0;
      wait (wr_n == 1'b0);
      rx_data = data;
      #15;
      txe_n = 1'b1;
    end
  endtask	  

  reg [7:0] cap_data;
  integer k;

  initial begin
    $dumpfile ("ftdi_engine_tb.vcd");
    $dumpvars (0, ftdi_engine_tb);    
    #100;
    async_reset_generator;
    #100;
    
    for (k=0;k<16;k=k+1) begin
      ftdi_write (k+1);
      #10;
    end  
    
    for (k=0;k<16;k=k+1) begin
       ftdi_read (cap_data);
       if (cap_data == (k+8'h02)) begin
	 $display ("========== TEST PASS ==============");
       end
       #50;
    end       

     #100;
     $finish;    
  end


  ftdi_engine_top #(.FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) FTDI_ENG_TOP_U1(
	.async_rst_n         (async_rst_n       ),
	 .clk_ftdi           (clk_ftdi          ),

	// ftdi CHIP bus
	.rxf_n               (rxf_n             ),
	.rd_n                (rd_n              ),

	.txe_n                (txe_n            ),
	.wr_n                 (wr_n             ),
	.data                 (data             ),


        //ext device side
	.clk_ext              (clk_ext          ),

	.ext_dev_rd_en         (ext_dev_rd_en   ),
        .ext_dev_rd_data       (ext_dev_rd_data ),
        .ext_dev_rd_empty      (ext_dev_rd_empty),

	.ext_dev_wr_en         (ext_dev_wr_en    ),
        .ext_dev_wr_data       (ext_dev_wr_data  ),
        .ext_dev_wr_full       (ext_dev_wr_full  )  
  );


  // EXT DEVICE LOGIC

  reg [7:0] dev_rd_data;
  reg       data_valid ;
  reg       ext_rd_en_delayed ;

  // read data
  always @(posedge clk_ext, negedge async_rst_n) begin
    if (!async_rst_n) begin	  
      dev_rd_data       <= 8'd0;
      data_valid        <= 1'b0;
      ext_dev_rd_en     <= 1'b0;
      ext_rd_en_delayed <= 1'd0;
    end
    else begin
      ext_rd_en_delayed <= ext_dev_rd_en;
      data_valid        <= 1'b0;
      if (!ext_dev_rd_empty) begin
         ext_dev_rd_en <= 1'b1;
       end
       if (ext_rd_en_delayed == 1'b1) begin
          ext_dev_rd_en     <= 1'b0;
          dev_rd_data       <= ext_dev_rd_data; 
          data_valid        <= 1'b1;
	  ext_rd_en_delayed <= 'd0;
       end       
    end	    
  end	  

  reg [7:0] dev_wr_data;

  // write data
  always @(posedge clk_ext, negedge async_rst_n) begin
    if (!async_rst_n) begin	  
      ext_dev_wr_data <= 8'd0;
      ext_dev_wr_en   <= 1'b0;
    end
    else begin
      ext_dev_wr_en   <= 1'b0;
      if ((!ext_dev_wr_full) && (data_valid == 1'b1)) begin
         ext_dev_wr_en   <= 1'b1;
	 ext_dev_wr_data <= dev_rd_data + 1'b1; 
       end
    end	    
  end	  


endmodule 
