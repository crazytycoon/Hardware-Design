//*************************************************************************************
//  Author		: Inc
//  DoR			: June 2021
//  module name	: Dual clock Asynchronous FIFO
//  RH			: v1
//  Remarks		:
//
//**************************************************************************************
`timescale 1 ns/ 1 ps

module async_fifo #(parameter FIFO_WIDTH = 8, FIFO_DEPTH=16)(
	input wire                      async_rst_n ,

	// write port
	input wire                      wr_clk      ,
	input wire                      fifo_wr_en  ,
        input wire [FIFO_WIDTH-1:0]	fifo_wr_data,
	output reg                      fifo_full   ,

	//read port
	input wire                      rd_clk      ,
	input wire                      fifo_rd_en  ,
	output wire [FIFO_WIDTH-1:0]    fifo_rd_data,
	output reg                      fifo_empty );



  reg async_rst_n1_wr;
  reg async_rst_n2_wr;
  wire async_rst_n_wr;

  reg async_rst_n1_rd;
  reg async_rst_n2_rd;
  wire async_rst_n_rd;

  reg  [$clog2(FIFO_DEPTH):0]   wr_ptr             ; // add extra bit for full & empty
  wire [$clog2(FIFO_DEPTH)-1:0] wr_addr            ; // add extra bit for full & empty
  wire [$clog2(FIFO_DEPTH):0]   wr_ptr_nxt         ;
  reg  [$clog2(FIFO_DEPTH):0]   wr_ptr_gray        ;
  wire [$clog2(FIFO_DEPTH):0]   wr_ptr_nxt_gray    ;

  reg [$clog2(FIFO_DEPTH):0] rd_ptr_ms;
  reg [$clog2(FIFO_DEPTH):0] rd_ptr_wr;
  reg [$clog2(FIFO_DEPTH):0] rd_ptr_wr_bin;

  wire wr_en;
  reg  fifo_full_nxt;


  reg  [$clog2(FIFO_DEPTH):0]   rd_ptr          ;
  wire [$clog2(FIFO_DEPTH)-1:0] rd_addr         ;
  wire [$clog2(FIFO_DEPTH):0]   rd_ptr_nxt      ;
  wire [$clog2(FIFO_DEPTH):0]   rd_ptr_nxt_gray ;
  reg  [$clog2(FIFO_DEPTH):0]   rd_ptr_gray     ;

  reg [$clog2(FIFO_DEPTH):0] wr_ptr_ms;
  reg [$clog2(FIFO_DEPTH):0] wr_ptr_rd;
  reg [$clog2(FIFO_DEPTH):0] wr_ptr_rd_bin;

  wire rd_en;
  reg fifo_empty_nxt;

  // wr port logic
  //async reset sync logic in wr clk domain
  always @ (posedge wr_clk) begin
    async_rst_n1_wr <= async_rst_n;
    async_rst_n2_wr <= async_rst_n1_wr;
  end

  assign async_rst_n_wr = async_rst_n2_wr;

  always @(posedge wr_clk, negedge async_rst_n_wr) begin
    if (! async_rst_n_wr) begin	  
      wr_ptr       <= 'd0;
      fifo_full    <= 'd0;
      wr_ptr_gray  <= 'd0;
    end
    else begin
      fifo_full   <= fifo_full_nxt;
      if (wr_en) begin	    
         wr_ptr      <= wr_ptr_nxt;
         wr_ptr_gray <= wr_ptr_nxt_gray;
      end	 
    end
  end

  

  assign wr_en = (!fifo_full) && (fifo_wr_en) ;  

  assign wr_ptr_nxt      = wr_ptr+ 1'b1;
  assign wr_ptr_nxt_gray = (wr_ptr_nxt >> 1) ^ (wr_ptr_nxt);

  assign wr_addr = wr_ptr [$clog2(FIFO_DEPTH)-1:0] ;


  // sync rd ptr gray
  always @ (posedge wr_clk) begin
    rd_ptr_ms <= rd_ptr_gray; 
    rd_ptr_wr <= rd_ptr_ms; 
  end

  integer i;

  // gray to binary
  always @(*) begin
    for (i=0;i <= $clog2(FIFO_DEPTH);i=i+1) begin
      rd_ptr_wr_bin[i] = ^(rd_ptr_wr >> i);
    end		  
  end

  always @ (*) begin
    fifo_full_nxt = 1'b0;
    if (({~wr_ptr_nxt[$clog2(FIFO_DEPTH)],wr_ptr_nxt[$clog2(FIFO_DEPTH)-1:0]} == rd_ptr_wr_bin) && (wr_en==1'b1)) begin
      fifo_full_nxt = 1'b1;
    end
    else if ({~wr_ptr[$clog2(FIFO_DEPTH)],wr_ptr[$clog2(FIFO_DEPTH)-1:0]} == rd_ptr_wr_bin) begin
      fifo_full_nxt = 1'b1;
    end	    
  end



  //rd port logic
  //async reset sync logic in rd clk domain
  always @ (posedge rd_clk) begin
    async_rst_n1_rd <= async_rst_n;
    async_rst_n2_rd <= async_rst_n1_rd;
  end

  assign async_rst_n_rd = async_rst_n2_rd;

  always @(posedge rd_clk, negedge async_rst_n_rd) begin
    if (! async_rst_n_rd) begin	  
      rd_ptr      <=  'd0;
      fifo_empty  <= 1'd1;
      rd_ptr_gray <=  'd0;
    end
    else begin
      fifo_empty   <= fifo_empty_nxt  ;
      if (rd_en) begin	    
        rd_ptr      <= rd_ptr_nxt      ;
        rd_ptr_gray <=  rd_ptr_nxt_gray;
      end
    end
  end


  assign rd_en           = (!fifo_empty) && (fifo_rd_en) ;  
  assign rd_ptr_nxt_gray = (rd_ptr_nxt >> 1) ^ (rd_ptr_nxt);

  assign rd_ptr_nxt      = rd_ptr + 1'b1;
  assign rd_addr         = rd_ptr [$clog2(FIFO_DEPTH)-1:0] ;

  // sync wr ptr gray
  always @ (posedge rd_clk) begin
    wr_ptr_ms <= wr_ptr_gray; 
    wr_ptr_rd <= wr_ptr_ms; 
  end

  integer j;

  // gray to binary
  always @(*) begin
    for (j=0; j <= $clog2(FIFO_DEPTH);j=j+1) begin
      wr_ptr_rd_bin[j] = ^(wr_ptr_rd >> j);
    end		  
  end


  //assign fifo_empty_nxt = (rd_ptr == wr_ptr_rd_bin) ? 1'b1 : 1'b0;

  always @ (*) begin
    fifo_empty_nxt = 1'b0;
    if  ((rd_ptr_nxt == wr_ptr_rd_bin) && (rd_en==1'b1)) begin
      fifo_empty_nxt = 1'b1;
    end	    
    else if (rd_ptr == wr_ptr_rd_bin) begin
      fifo_empty_nxt = 1'b1;
    end	    
  end	  



  // dcdpram instantiation
  dc_dpram  # (.WIDTH (FIFO_WIDTH), .DEPTH(FIFO_DEPTH)) DC_DPRAM_U1 (
	  .wr_clk   (wr_clk         ),
	  .wr_en    (wr_en          ),
	  .wr_addr  (wr_addr        ),
	  .wr_data  (fifo_wr_data   ),

	  .rd_clk   (rd_clk         ),
	  .rd_en    (rd_en          ),
	  .rd_addr  (rd_addr        ),
	  .rd_data  (fifo_rd_data   ) 
  );



endmodule
