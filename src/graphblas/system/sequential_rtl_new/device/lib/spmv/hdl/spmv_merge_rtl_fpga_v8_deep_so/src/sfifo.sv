//
//---------------------------------------------------------------------------
// Synchronous FIFO   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module sfifo
  #(parameter 
   DSIZE = `DATA_WIDTH_ADD_STG,
   ASIZE = `BITS_ADDER_OUT_Q,
   FIFO_DEPTH = 1 << ASIZE)
  (//input
   input clk, rst_b, rd_en, wr_en,
   input [DSIZE-1:0] data_in, 
   output [DSIZE-1:0] data_out,
   output empty, full);    

//-----------Internal variables-------------------
reg [ASIZE - 1 : 0] wr_pointer;
reg [ASIZE - 1 : 0] rd_pointer;
reg [ASIZE : 0] status_cnt;
////wire [DSIZE - 1 : 0] data_ram ;

//-----------Variable assignments---------------
////assign full = (status_cnt == (RAM_DEPTH-1));
assign full = (status_cnt == (FIFO_DEPTH));   
assign empty = (status_cnt == 0);

//-----------Code Start---------------------------
always_ff @(posedge clk) begin : WRITE_POINTER
  if (!rst_b) begin
    wr_pointer <= 0;
  end else if (wr_en && !full) begin
    wr_pointer <= wr_pointer + 1;
  end
end

always_ff @(posedge clk) begin : READ_POINTER
  if (!rst_b) begin
    rd_pointer <= 0;
  end else if (rd_en && !empty) begin
    rd_pointer <= rd_pointer + 1;
  end
end

/*
always_ff  @(posedge clk) begin : READ_DATA
  if (!rst_b) begin
    data_out <= 0;
  end else if (rd_cs && rd_en ) begin
    data_out <= data_ram;
  end
end
*/
 
always_ff @(posedge clk) begin : STATUS_COUNTER
  if (!rst_b) begin
    status_cnt <= 0;
  // Read but no write.
  end else if (rd_en && !wr_en && (status_cnt != 0)) begin
    status_cnt <= status_cnt - 1;
  // Write but no read.
  end else if (wr_en && !rd_en && (status_cnt != FIFO_DEPTH)) begin
    status_cnt <= status_cnt + 1;
  end
end 
   
fifomem_syn #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifomem
(.data_out, .data_in,
.waddr(wr_pointer), .raddr(rd_pointer), .wr_en, .full, .empty, .clk);      
endmodule

//=========================== Buffer ==================================
module fifomem_syn 
  #(parameter 
    DSIZE = `DATA_WIDTH_ADD_STG, // Memory data word width
    ASIZE = `BITS_ADDER_OUT_Q,
    FIFO_DEPTH = 1 << ASIZE) // Number of mem address bits
   (//input
    input [DSIZE - 1 : 0] data_in,
    input [ASIZE - 1 : 0] waddr, raddr,
    input wr_en, clk, full, empty,
    output [DSIZE - 1 : 0] data_out);
   
   // RTL Verilog memory model
   reg [DSIZE - 1 : 0] mem [0 : FIFO_DEPTH - 1];
   //assign data_out = mem[raddr];//ori
   assign data_out = !empty ? mem[raddr] : '0; //so that we don't need to initialize memory
   always_ff @(posedge clk) begin
     if (wr_en && !full) mem[waddr] <= data_in;
   end
endmodule
//=====================================================================
