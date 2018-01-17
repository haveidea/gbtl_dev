//
//---------------------------------------------------------------------------
//  2 input comparator
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module compare_mux #(
   parameter
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG) (
   input [DATA_WIDTH - 1 : 0] so, buff,
   output logic [DATA_WIDTH - 1 : 0] smaller_row, bigger_row);

   wire [`BITS_ROW_IDX - 1 : 0] row_idx_buff, row_idx_so;
   assign row_idx_buff = buff[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign row_idx_so = so[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      
always_comb begin: compare   
   unique if (row_idx_buff <= row_idx_so) begin
      smaller_row = buff;
      bigger_row = so;     
   end
   else begin
      smaller_row = so;
      bigger_row = buff;
   end     
end: compare   
endmodule


module compare_select #(
   parameter
     DATA_WIDTH = `DATA_WIDTH_ADD_STG,
     VI = 0) (
   input [DATA_WIDTH - 1 : 0] din0, din1,
   output logic select);

   wire [`BITS_ROW_IDX - 1 : 0] rowidx0, rowidx1;
   wire	valid0, valid1;
   
   assign rowidx0 = din0[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign rowidx1 = din1[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign valid0 = din0[VI];
   assign valid1 = din1[VI];
   
always_comb begin   
   unique if (rowidx0 <= rowidx1 && valid0) begin
      select = '0;
   end
   else if (!(rowidx0 <= rowidx1) && valid1) begin
      select = '1;
   end
   else if (!valid0 && valid1) begin
      select = '1;
   end
   else begin
      select = '0;
   end 
end   
endmodule

module compare_select_simple #(
   parameter
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG)(			       
     //DATA_WIDTH = `DATA_WIDTH_ADD_STG) (
					
   input [DATA_WIDTH - 1 : 0] din0, din1,
   output logic 	      select);

   wire [`BITS_ROW_IDX - 1 : 0] rowidx0, rowidx1;
     
   assign rowidx0 = din0[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign rowidx1 = din1[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      
always_comb begin   
   unique if (rowidx0 <= rowidx1) begin
      select = 1'b0;
   end
   else begin
      select = 1'b1;
   end
end   
endmodule
