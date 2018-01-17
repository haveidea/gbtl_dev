//
//---------------------------------------------------------------------------
// this module calculates the rd, wr and trach counter values for each block of input data
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module input_fifo_ctr_calc
  #(//parameter
    NUM_UNITs = `NUM_UNITs,
    BITS_UNIT_SELECTION = `BITS_UNIT_SELECTION,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    DATA_WIDTH = `BITS_ROW_IDX + `DATA_PRECISION,
    STREAM_WIDTH = `STREAM_WIDTH,
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    NUM_BIOTONIC_STGS_TOT = `NUM_BIOTONIC_STGS_TOT,
    NUM_ADDTREE_STGS = LOG_STREAM_WIDTH,
    EXTRA_DELAY_PIPE = NUM_BIOTONIC_STGS_TOT - NUM_ADDTREE_STGS - 1) //extra 1 cycle as we flop the incoming data first. So we need to delay the pipeline (6 - 3 - 1 = 2) cycles for 8 streaming width of the bitonic sort
   (input clk, rst_b, enable,   
    input [STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : 0] din,

    output logic [NUM_UNITs - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_rd_ctr_pb, set_wr_ctr_pb,
    output logic [NUM_UNITs - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_pb);

   logic [STREAM_WIDTH - 1 : 0] [`BITS_ROW_IDX - 1 : 0] index_adv;
   //assign index_adv[STREAM_WIDTH - 1 : 0] = din[STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];  
   always_comb begin      
      for (integer i11 = 0; i11 < STREAM_WIDTH; i11 = i11 + 1) begin
         index_adv[i11] = din[i11][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      end
   end 
  
   logic [STREAM_WIDTH - 1 : 0][BITS_UNIT_SELECTION - 1 : 0] radix, radix_adv;
   //assign radix_adv[STREAM_WIDTH - 1 : 0] = index[STREAM_WIDTH - 1 : 0][BITS_UNIT_SELECTION - 1 : 0];
   always_comb begin      
      for (integer i12 = 0; i12 < STREAM_WIDTH; i12 = i12 + 1) begin
         radix_adv[i12] = index_adv[i12][BITS_UNIT_SELECTION - 1 : 0];
      end
   end 
     
  register2D #(.WIDTH1(STREAM_WIDTH), .WIDTH2(BITS_UNIT_SELECTION)) reg_radix(.q(radix), .d(radix_adv), .clk(clk), .enable(enable), .rst_b(rst_b));

   //for track ctr
   //================================================================================
   //-----------------------------------------------------------
   //Comapring unit selection bits to see how many element each unit should get 
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0] unit_match_flag;

   integer unsigned i0, i1;
   always_comb begin      
      for (i0 = 0; i0 < NUM_UNITs; i0 = i0 + 1) begin
	 for (i1 = 0; i1 < STREAM_WIDTH; i1 = i1 + 1) begin
            unit_match_flag[i0][i1] = (radix[i1] == i0) ? 1'b1 : 1'b0;
	 end
      end
   end
   //-----------------------------------------------------------
   //-----------------------------------------------------------
   //Adder tree
   //logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_din; 
   //logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_dout;
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_din; 
   logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_dout; 
   
   integer unsigned i2, i3;
   always_comb begin      
      for (i2 = 0; i2 < NUM_UNITs; i2 = i2 + 1) begin
	 for (i3 = 0; i3 < STREAM_WIDTH; i3 = i3 + 1) begin
            //addtree_din[i2][i3] = {{LOG_STREAM_WIDTH - 1{1'b0}}, unit_match_flag[i2][i3]};
	    addtree_din[i2][i3] = {{LOG_STREAM_WIDTH{1'b0}}, unit_match_flag[i2][i3]};
	 end
      end
   end 

   genvar j0;
    generate
       for (j0 = 0; j0 < NUM_UNITs; j0 = j0 + 1) begin
	  input_ctr_addtree #(.DATA_WIDTH(LOG_STREAM_WIDTH + 1)) addtree
	    (//input
	     .rst_b, .clk, .enable, 
	     .din(addtree_din[j0]), .dout(addtree_dout[j0]));
      end
    endgenerate  
   //-----------------------------------------------------------
   //================================================================================
   
    //for rd ctr
   //================================================================================
   //-----------------------------------------------------------
   //Comapring unit selection bits to see how many element each unit should get 
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0] unit_match_flag_incr;

   integer unsigned i4, i5;
   always_comb begin
      unit_match_flag_incr[0] = '0;
      for (i4 = 1; i4 < NUM_UNITs; i4 = i4 + 1) begin
            unit_match_flag_incr[i4] = unit_match_flag[i4 - 1] | unit_match_flag_incr[i4 - 1] ;
      end
   end
   //-----------------------------------------------------------
   //-----------------------------------------------------------
   //Adder tree
   //logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_din_incr; 
   //logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_dout_incr; 
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_din_incr; 
   logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_dout_incr; 
   
   integer unsigned i6, i7;
   always_comb begin      
      for (i6 = 0; i6 < NUM_UNITs; i6 = i6 + 1) begin
	 for (i7 = 0; i7 < STREAM_WIDTH; i7 = i7 + 1) begin
            addtree_din_incr[i6][i7] = {{LOG_STREAM_WIDTH{1'b0}}, unit_match_flag_incr[i6][i7]};
	 end
      end
   end 

   genvar j1;
    generate
       for (j1 = 0; j1 < NUM_UNITs; j1 = j1 + 1) begin
	  input_ctr_addtree #(.DATA_WIDTH(LOG_STREAM_WIDTH + 1)) addtree_incr
	    (//input
	     .rst_b, .clk, .enable, 
	     .din(addtree_din_incr[j1]), .dout(addtree_dout_incr[j1]));
      end
    endgenerate  
   //-----------------------------------------------------------
   //================================================================================

   // Delay and final assignments
   //================================================================================
   ///logic [EXTRA_DELAY_PIPE : 0] [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_dout_temp, addtree_dout_incr_temp;
   logic [EXTRA_DELAY_PIPE : 0][NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_dout_temp, addtree_dout_incr_temp;

   
   assign addtree_dout_temp[0] = addtree_dout;
   assign addtree_dout_incr_temp[0] = addtree_dout_incr;

   always_ff @(posedge clk) begin
     if (~rst_b)
       for (integer i8 = 1; i8 < EXTRA_DELAY_PIPE + 1; i8 = i8 + 1) begin
	  for (integer i9 = 0; i9 < NUM_UNITs; i9 = i9 + 1) begin
	     addtree_dout_temp[i8][i9] <= '0;
	     addtree_dout_incr_temp[i8][i9] <= '0;
	  end
       end
     else if (enable) begin
	for (integer i10 = 1; i10 < EXTRA_DELAY_PIPE + 1; i10 = i10 + 1) begin
	   addtree_dout_temp[i10] <= addtree_dout_temp[i10 - 1];
	   addtree_dout_incr_temp[i10] <= addtree_dout_incr_temp[i10 - 1];
	end
     end
   end

   ///assign set_rd_ctr_pb = addtree_dout_incr_temp[EXTRA_DELAY_PIPE][NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0];
   ///assign set_wr_ctr_pb = '0; //we probably don't care about wr counters
   ///assign set_track_ctr_pb = addtree_dout_temp[EXTRA_DELAY_PIPE];

   always_comb begin      
      for (integer i13 = 0; i13 < NUM_UNITs; i13 = i13 + 1) begin//shouldn't addtree_dout_x should have 1 bit more width? Change accordingly
         set_rd_ctr_pb[i13] = addtree_dout_incr_temp[EXTRA_DELAY_PIPE][i13][`BITS_INPUT_BIN_ADDR - 1 : 0];
	 set_wr_ctr_pb[i13] = '0;
	 set_track_ctr_pb[i13] = addtree_dout_temp[EXTRA_DELAY_PIPE][i13];
      end
   end 
   //================================================================================  
   
endmodule // input_fifo_ctr_calc


module input_ctr_addtree 
  #(//parameter
    STREAM_WIDTH = `STREAM_WIDTH,
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    NUM_ADDTREE_STGS = `LOG_STREAM_WIDTH,
    DATA_WIDTH = `LOG_STREAM_WIDTH + 1)
   (input rst_b, clk, enable, 
    input [STREAM_WIDTH - 1 : 0] [DATA_WIDTH - 1 : 0] din,			      
    output [DATA_WIDTH - 1 : 0] dout);

   wire [(1 << NUM_ADDTREE_STGS)*2 - 2 : 0] [DATA_WIDTH - 1 : 0] addtree_data; //addtree_data[0] is final output

   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_ADDTREE_STGS; j0 = j0 + 1) begin
      	 input_ctr_addtree_stg #(.NUM_ATOMS(1 << j0), .DATA_WIDTH(LOG_STREAM_WIDTH + 1)) addtree_stg
           (//input										 
            .rst_b, .clk, .enable,
	    .din(addtree_data[(1 << (j0+2)) - 2 : (1 << (j0+1)) - 1]),
	    //output
	    .dout(addtree_data[(1 << (j0+1)) - 2 : (1 << j0) - 1]));
      end
   endgenerate

   assign dout = addtree_data[0];
   assign addtree_data[(1 << (NUM_ADDTREE_STGS + 1)) - 2 : (1 << NUM_ADDTREE_STGS) - 1] = din[STREAM_WIDTH - 1 : 0];
   
endmodule 


module input_ctr_addtree_stg 
  #(//parameter
    NUM_ATOMS = 1,
    DATA_WIDTH = `LOG_STREAM_WIDTH + 1)
   (input rst_b, clk, enable, 
    input [(NUM_ATOMS << 1) - 1 : 0] [DATA_WIDTH - 1 : 0] din,			      
    output [NUM_ATOMS - 1 : 0] [DATA_WIDTH - 1 : 0] dout);

   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_ATOMS; j0 = j0 + 1) begin 
	 input_ctr_addtree_atom #(.DATA_WIDTH(DATA_WIDTH)) addtree_atom
         (//input
	  .rst_b, .clk, .enable,
	  .din0(din[(j0<<1)]), .din1(din[(j0<<1) + 1]),
	  //output
	  .dout(dout[j0]));
      end     
   endgenerate
endmodule // input_ctr_addtree_stg


module input_ctr_addtree_atom
  #(//parameter
    NUM_UNITs = `NUM_UNITs,
    DATA_WIDTH = `LOG_STREAM_WIDTH + 1) //because log of stream width is the bits needed for max add value
   (input clk, rst_b, enable,   
    input [DATA_WIDTH - 1 : 0] din0, din1,
    output [DATA_WIDTH - 1 : 0] dout);

   //==============================================================================
   //------------------------------------------------------------
   // Make the addtree entirely pipelined
   wire [DATA_WIDTH - 1 : 0] din0_reg, din1_reg;
   
   register #(.WIDTH(DATA_WIDTH)) reg_din0(.q(din0_reg), .d(din0), .clk(clk), .enable(enable), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_din1(.q(din1_reg), .d(din1), .clk(clk), .enable(enable), .rst_b(rst_b)); 
   //------------------------------------------------------------
   //------------------------------------------------------------
   // Make the addtree entirely combinational
   //assign din0_reg = din0;
   //assign din1_reg = din1;
   //------------------------------------------------------------
   //==============================================================================

   assign dout = din0_reg + din1_reg;  
endmodule // input_ctr_addtree_atom



