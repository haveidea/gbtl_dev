//
//---------------------------------------------------------------------------
// Asynchronous FIFO   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module afifo 
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

sync_r2w #(.ADDRSIZE(ASIZE)) sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr),
.wclk(wclk), .wrst_n(wrst_n));

sync_w2r #(.ADDRSIZE(ASIZE)) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr),
.rclk(rclk), .rrst_n(rrst_n));
   
fifomem_asyn #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) fifomem
(.rdata(rdata), .wdata(wdata),
.waddr(waddr), .raddr(raddr),
.wclken(winc), .wfull(wfull),
.wclk(wclk));

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
module fifomem_asyn 
  #(parameter 
    DATASIZE = `DATA_WIDTH_BUFF_SO_SEG, // Memory data word width
    ADDRSIZE = `BITS_SLOW_BLK_BUFF_ADDR) // Number of mem address bits
   (//input
    input [DATASIZE - 1 : 0] wdata,
    input [ADDRSIZE - 1 : 0] waddr, raddr,
    input wclken, wfull, wclk,
    output [DATASIZE - 1 : 0] rdata);
   
   // RTL Verilog memory model
   parameter DEPTH = 1 << ADDRSIZE;
   reg [DATASIZE - 1 : 0] mem [0 : DEPTH - 1];
   assign rdata = mem[raddr];
   always_ff @(posedge wclk) begin
     if (wclken && !wfull) mem[waddr] <= wdata;
   end
   
endmodule
//=====================================================================

//============ Read / Write Pointer Synchronizers =====================
module sync_r2w 
  #(parameter ADDRSIZE = 4)
   (//input
    input [ADDRSIZE:0] rptr,
    input wclk, wrst_n,
    output reg [ADDRSIZE:0] wq2_rptr);
   
reg [ADDRSIZE:0] wq1_rptr;

always @(posedge wclk)
  if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
  else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
endmodule

module sync_w2r 
  #(parameter ADDRSIZE = 4)
   (//input
    input [ADDRSIZE:0] 	    wptr,
    input 		    rclk, rrst_n,
    output reg [ADDRSIZE:0] rq2_wptr);
   
reg [ADDRSIZE:0] rq1_wptr;

always @(posedge rclk)
if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;
else {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
endmodule
//=====================================================================

//====================== Buffer Empty =================================
module rptr_empty 
  #(parameter ADDRSIZE = 4)
   (
    input [ADDRSIZE :0] rq2_wptr,
    input rinc, rclk, rrst_n, 
    output reg rempty,
    output [ADDRSIZE-1:0] raddr,
    output reg [ADDRSIZE :0] rptr);
   
reg [ADDRSIZE:0] rbin;
wire [ADDRSIZE:0] rgraynext, rbinnext;
   
//-------------------
// GRAYSTYLE2 pointer
//-------------------
always @(posedge rclk)
if (!rrst_n) {rbin, rptr} <= 0;
else {rbin, rptr} <= {rbinnext, rgraynext};
// Memory read-address pointer (okay to use binary to address memory)
assign raddr = rbin[ADDRSIZE-1:0];
assign rbinnext = rbin + (rinc & ~rempty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;

//---------------------------------------------------------------
// FIFO empty when the next rptr == synchronized wptr or on reset
//---------------------------------------------------------------
assign rempty_val = (rgraynext == rq2_wptr);
always @(posedge rclk)
if (!rrst_n) rempty <= 1'b1;
else rempty <= rempty_val;
endmodule // rptr_empty
//=====================================================================


//========================= Buffer Full ===============================
module wptr_full 
  #(parameter ADDRSIZE = 4)
   (//input
    input [ADDRSIZE :0] wq2_rptr,
    input winc, wclk, wrst_n,
    output reg wfull,
    output [ADDRSIZE-1:0] waddr,
    output reg [ADDRSIZE :0] wptr);
   
reg [ADDRSIZE:0] wbin;
wire [ADDRSIZE:0] wgraynext, wbinnext;

// GRAYSTYLE2 pointer
always @(posedge wclk)
if (!wrst_n) {wbin, wptr} <= 0;
else {wbin, wptr} <= {wbinnext, wgraynext};

// Memory write-address pointer (okay to use binary to address memory)
assign waddr = wbin[ADDRSIZE-1:0];
assign wbinnext = wbin + (winc & ~wfull);
assign wgraynext = (wbinnext>>1) ^ wbinnext;

//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------
assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]});
always @(posedge wclk)
if (!wrst_n) wfull <= 1'b0;
else wfull <= wfull_val;
endmodule
//=====================================================================




