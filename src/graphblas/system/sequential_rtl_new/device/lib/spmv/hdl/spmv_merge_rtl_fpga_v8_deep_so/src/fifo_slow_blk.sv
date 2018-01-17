//
//---------------------------------------------------------------------------
// LiM memory block for segment for both buffer and stage output
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module fifo_slow_blk 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    SLOW_BLK_BUFF_SIZE = `SLOW_BLK_BUFF_SIZE,
    BITS_SLOW_BLK_BUFF_ADDR = `BITS_SLOW_BLK_BUFF_ADDR) (

   input rst_b, clk_slow, wr_en,  
   input [BITS_SLOW_BLK_BUFF_ADDR - 1 : 0] rd_addr, wr_addr,  
   input [DATA_WIDTH - 1 : 0] data_in,
							  
   output logic [DATA_WIDTH - 1 : 0] data_out);

//reg memory
//valiables with unpacked are not displayed in NCSim simulation, but works fine   
logic [DATA_WIDTH - 1 : 0] fifo [SLOW_BLK_BUFF_SIZE - 1 : 0];   

assign data_out = fifo[rd_addr];

//instead of using mux we are utilizing the decoder
/*   
always_comb begin
   for(integer j = 0; j < NUM_BUFF_SO_WORDS_SEG; j = j + 1) begin
      data_out_buff = rd_decoded_wl_buff_so[j] ? buff_reg[j] : 'z;
      data_out_so = rd_decoded_wl_buff_so[j] ? so_reg[j] : 'z;
   end
end 
*/

wire [SLOW_BLK_BUFF_SIZE - 1 : 0] wr_decode;
assign wr_decode = 1 << wr_addr;      
   
//********** INPUT FLOPS **********   
always_ff @ (posedge clk_slow) begin
   if(~rst_b) begin
      for (integer i = 0; i < SLOW_BLK_BUFF_SIZE; i = i + 1) begin
	 fifo[i] <= 0; 
      end
   end
   else begin
      for (integer i = 0; i < SLOW_BLK_BUFF_SIZE; i = i + 1) begin
	 fifo[i] <= (wr_decode[i] && wr_en) ? data_in : fifo[i]; 
      end
   end
end

endmodule

