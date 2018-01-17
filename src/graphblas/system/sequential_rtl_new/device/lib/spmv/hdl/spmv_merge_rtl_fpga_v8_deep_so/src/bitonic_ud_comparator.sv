//
//---------------------------------------------------------------------------
// bitonic up/dowm comparator
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module bitonic_ud_comparator
  #(//parameter
    SERIAL_DPIPE = 1, //just for debug
    UP_OR_DN = 0, //1 means up, 0 means down. Down is for ascending order. Up for descending.
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    BITS_UNIT_SELECTION = `BITS_UNIT_SELECTION,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    DATA_WIDTH = `BITS_ROW_IDX + `DATA_PRECISION + LOG_STREAM_WIDTH)
   (input clk, rst_b, enable,   
    input [DATA_WIDTH - 1 : 0] din0, din1,
    output logic [DATA_WIDTH - 1 : 0] dout0, dout1);

   wire [7 : 0] serial_dpipe; //just for debug
   assign serial_dpipe = SERIAL_DPIPE;
      
   //==============================================================================
   //------------------------------------------------------------
   // Make the bitonic sorter entirely pipelined
   wire [DATA_WIDTH - 1 : 0] din0_reg, din1_reg;
   
   register #(.WIDTH(DATA_WIDTH)) reg_din0(.q(din0_reg), .d(din0), .clk(clk), .enable(enable), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_din1(.q(din1_reg), .d(din1), .clk(clk), .enable(enable), .rst_b(rst_b)); 
   //------------------------------------------------------------
   //------------------------------------------------------------
   // Make the bitonic sorter entirely combinational
   //assign din0_reg = din0;
   //assign din1_reg = din1;
   //------------------------------------------------------------
   //==============================================================================
   
   wire [`BITS_ROW_IDX - 1 : 0] index0, index1;
   assign index0 = din0_reg[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign index1 = din1_reg[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   
   wire [BITS_UNIT_SELECTION - 1 : 0] radix0, radix1;
   assign radix0 = index0[BITS_UNIT_SELECTION - 1 : 0];
   assign radix1 = index1[BITS_UNIT_SELECTION - 1 : 0];

   wire [LOG_STREAM_WIDTH - 1 : 0] stream_id0, stream_id1;
   assign stream_id0 = din0_reg[LOG_STREAM_WIDTH - 1 : 0];
   assign stream_id1 = din1_reg[LOG_STREAM_WIDTH - 1 : 0];
   
   generate 
      if (UP_OR_DN == 0) begin : down_comp 
	 always_comb begin   
	    unique if (radix0 < radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else if(radix0 > radix1) begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end
	    else if (radix0 == radix1 && stream_id0 < stream_id1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end	    
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;     
	    end		    
	 end
      end // block: down_comp
      
      else begin : up_comp  
	 always_comb begin  
	    unique if (radix0 > radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else if (radix0 < radix1) begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end
	    //for up comparators make it descending depending on stream id
	    else if (radix0 == radix1 && stream_id0 > stream_id1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end	    
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;     
	    end	     
	 end
      end // block: up_comp
   endgenerate

/*
    generate 
      if (UP_OR_DN == 0) begin : down_comp 
	 always_comb begin   
	    unique if (radix0 <= radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end     
	 end
      end // block: down_comp
      
      else begin : up_comp  
	 always_comb begin  
	    unique if (radix0 >= radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end     
	 end
      end // block: up_comp
   endgenerate
 
*/ 


   
endmodule

 
