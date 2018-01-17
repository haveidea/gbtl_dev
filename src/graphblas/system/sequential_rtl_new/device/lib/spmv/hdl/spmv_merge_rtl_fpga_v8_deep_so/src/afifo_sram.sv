//
//---------------------------------------------------------------------------
// Asynchronous FIFO with SRAM based memory   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module afifo_sram 
  #(parameter 
    DSIZE = `DATA_WIDTH_BUFF_SO_SEG,
    ASIZE = `BITS_SLOW_BLK_BUFF_ADDR)
   (//input
    input [DSIZE-1:0] wdata,
    input winc, wclk, wrst_n,
    input rinc, rclk, rrst_n,
    output [DSIZE-1:0] rdata,
    output wfull, rempty);
   
wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

sync_r2w #(.ADDRSIZE(ASIZE)) sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr), .wclk(wclk), .wrst_n(wrst_n));

sync_w2r #(.ADDRSIZE(ASIZE)) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr), .rclk(rclk), .rrst_n(rrst_n));

wire wen_sram;
assign wen_sram = winc && !wfull;
   
fifomem_asyn_sram #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) fifomem_sram
(.rdata(rdata), .wdata(wdata),
.waddr(waddr), .raddr(raddr),
//.wclken(winc), .wfull(wfull), .rclken(rinc), .rempty(rempty),
.wen(wen_sram), .wclk(wclk), .rclk(rclk));

rptr_empty #(.ADDRSIZE(ASIZE)) rptr_empty
(.rempty(rempty),
.raddr(raddr),
.rptr(rptr), .rq2_wptr(rq2_wptr),
.rinc(rinc), .rclk(rclk),
.rrst_n(rrst_n));
   
wptr_full #(.ADDRSIZE(ASIZE)) wptr_full
(.wfull(wfull), .waddr(waddr),
.wptr(wptr), .wq2_rptr(wq2_rptr),
.winc(winc), .wclk(wclk),
.wrst_n(wrst_n));
endmodule

//=========================== Buffer ==================================
module fifomem_asyn_sram 
  #(parameter 
    DATASIZE = `DATA_WIDTH_BUFF_SO_SEG, // Memory data word width
    ADDRSIZE = `BITS_SLOW_BLK_BUFF_ADDR) // Number of mem address bits
   (//input
    input [DATASIZE - 1 : 0] wdata,
    input [ADDRSIZE - 1 : 0] waddr, raddr,
    //input wclken, wfull, wclk, rclken, rempty, rclk,
    input wen, wclk, rclk,
    
    output logic [DATASIZE - 1 : 0] rdata);
   
   // RTL Verilog memory model
   parameter DEPTH = 1 << ADDRSIZE;
   reg [DATASIZE - 1 : 0] mem [0 : DEPTH - 1];
   //assign rdata = mem[raddr];

   //Tool wil have hardtime to infer this code block
   /*
   always_ff @(posedge rclk) begin    
      if(rclken && !rempty) rdata <= mem[raddr];
      else rdata <= '0;
   end
    */ 
   always_ff @(posedge rclk) begin    
      rdata <= mem[raddr];
   end
   
   always_ff @(posedge wclk) begin
      //if (wclken && !wfull) mem[waddr] <= wdata;
      if (wen) mem[waddr] <= wdata;
   end
   
endmodule
//=====================================================================

//=====================================================================
module afifo_ptr_only 
  #(parameter 
    ASIZE = `BITS_SLOW_BLK_BUFF_ADDR)
   (//input
    input winc, wclk, wrst_n,
    input rinc, rclk, rrst_n,
    output wfull, rempty,
    output [ASIZE-1:0] waddr, raddr);
   
wire [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
sync_r2w #(.ADDRSIZE(ASIZE)) sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr), .wclk(wclk), .wrst_n(wrst_n));
sync_w2r #(.ADDRSIZE(ASIZE)) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr), .rclk(rclk), .rrst_n(rrst_n));

/*   
fifomem_asyn_sram #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) fifomem_sram
(.rdata(rdata), .wdata(wdata),
.waddr(waddr), .raddr(raddr),
.wclken(winc), .wfull(wfull), .rclken(rinc), .rempty(rempty),
.wclk(wclk), .rclk(rclk));
*/
   
rptr_empty #(.ADDRSIZE(ASIZE)) rptr_empty
(.rempty(rempty),
.raddr(raddr),
.rptr(rptr), .rq2_wptr(rq2_wptr),
.rinc(rinc), .rclk(rclk),
.rrst_n(rrst_n));
   
wptr_full #(.ADDRSIZE(ASIZE)) wptr_full
(.wfull(wfull), .waddr(waddr),
.wptr(wptr), .wq2_rptr(wq2_rptr),
.winc(winc), .wclk(wclk),
.wrst_n(wrst_n));
endmodule // afifo_ptr_only
//=====================================================================
