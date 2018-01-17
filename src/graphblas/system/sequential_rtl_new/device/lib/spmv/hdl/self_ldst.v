module self_ldst
#(parameter DATA_WIDTH = 512,
            ADDR_WIDTH=32,
            NUM_LDQ    =4,
            NUM_STQ    =1
           )
(
  // global reset.
  input                             rst_b,

  input                             clk_slow,
  input                             clk_fast,
  input                             clk_ldq,

  input                             enable, 
  input                             mode,
  output                            init,
  output                            done,

  input  [NUM_LDQ-1:0]              self_rd_en,
  input  [NUM_STQ-1:0]              self_wr_en,

  output [7*4 -1:0]                 ldq_addr,
  output [7 -1:0]                   stq_id,

  // ldq
  output [NUM_LDQ-1:0]              ldq_addr_valid,
  input  [NUM_LDQ-1:0]              ldq_addr_ready,

  input  [NUM_LDQ-1:0]              ldq_data_valid,
  output [NUM_LDQ-1:0]              ldq_data_ready,
  input  [DATA_WIDTH*NUM_LDQ-1:0]   ldq_data,

  //stq0
  output [NUM_STQ-1:0]              stq_valid,
  output [DATA_WIDTH*NUM_STQ-1:0]   stq_data,
  input  [NUM_STQ-1:0]              stq_ready
);
//assign ldq_data_ready = {NUM_LDQ{1'b1}};


// generate NUM_STQ store queue instances
genvar ii;
generate
  for (ii =0; ii<NUM_STQ; ii = ii+1)  begin :GENERATE_ST_AGENT
    st_agent 
    #(.ADDR(ii), .LFSR_IN(31'h3eef + ii))
    u_st_agent (
      .clk            (clk_fast),
      .rstn           (rst_b),
      .self_wr_en     (self_wr_en[ii]),
      .stq_valid      (stq_valid[ii]),
      .stq_data       (stq_data[DATA_WIDTH*(ii+1) -1: DATA_WIDTH*ii]),
      .stq_ready      (stq_ready[ii]),
      .stq_id         (stq_id[7*(ii+1) -1 :7*ii])
    );
  end
endgenerate

// generate NUM_LDQ load queue instances
generate 
  for (ii =0; ii<NUM_LDQ; ii = ii+1) begin:GENERATE_LD_AGENT
    ld_agent 
    u_ld_agent
    (
        .clk            (clk_slow),
        .rstn           (rst_b),
        .self_rd_en     (self_rd_en[ii]),
        .ldq_addr_valid (ldq_addr_valid[ii]),
    //    .ldq_addr       (ldq_addr[ADDR_WIDTH*(ii+1) -1: ADDR_WIDTH*ii]),
        .ldq_id         (ldq_addr[7*(ii+1) -1 : 7*ii]),
        .ldq_ready (ldq_addr_ready[ii]),

        .mode           (mode),

        .ldq_data_valid (ldq_data_valid[ii]),
        .ldq_data       (ldq_data[DATA_WIDTH*(ii+1) -1: DATA_WIDTH*ii]),
        .ldq_data_ready (ldq_data_ready[ii])
     );
   end
endgenerate
endmodule
