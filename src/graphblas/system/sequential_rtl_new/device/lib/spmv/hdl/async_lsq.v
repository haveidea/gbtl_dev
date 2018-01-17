module async_lsq 
#(parameter DDR_DATA_WIDTH =512,
            LDQ_DATA_WIDTH =512,
            STQ_DATA_WIDTH =256,
            ADDR_WIDTH =32,
            QPTR_WIDTH =4, // bit width
            NUM_LDQ    =4,
            NUM_STQ    =1, 
            TOTAL_LDQ_IDS = 512,
            TOTAL_STQ_IDS = 1,
            BASE_ADDR_WIDTH = 20)
(
  input                                   ldq_clk,
  input                                   stq_clk,
  input                                   rstn,
  input                                   ddr_clk,
  input                                   ddr_rstn,
  input  [NUM_LDQ-1:0]                    ldq_valid,
  output [NUM_LDQ-1:0]                    ldq_ready,
  input  [NUM_LDQ*7-1+8:0]                ldq_id,
  input  [NUM_STQ*7-1:0]                  stq_id,
  output [NUM_LDQ-1:0]                    ldq_data_valid,
  output [LDQ_DATA_WIDTH*NUM_LDQ-1:0]     ldq_data,
  input  [NUM_LDQ-1:0]                    ldq_data_ready,
  input                                   spmv_done,
  
// for stq
  input [NUM_STQ-1:0]                     stq_valid,
  output[NUM_STQ-1:0]                     stq_ready,
  input [STQ_DATA_WIDTH*NUM_STQ-1:0]      stq_data,
// for base address
  input [BASE_ADDR_WIDTH * TOTAL_LDQ_IDS -1 :0]        rchannel_addr_base,
  input [BASE_ADDR_WIDTH * TOTAL_STQ_IDS -1 :0]        wchannel_addr_base,
//ddr part
  output [NUM_LDQ-1:0]                    ldq_ddr_addr_valid,
  input  [NUM_LDQ-1:0]                    ldq_ddr_addr_ready,
  output [NUM_LDQ*ADDR_WIDTH-1:0]         ldq_ddr_addr,
  input  [NUM_LDQ-1:0]                    ldq_ddr_data_valid,
//output  NUM_LDQ                         ldq_ddr_data_ready, // data slot should be pre-allocated. hence always ready
  input  [NUM_LDQ*DDR_DATA_WIDTH-1:0]     ldq_ddr_data,


  output [NUM_STQ-1:0]                    stq_ddr_valid,
  input  [NUM_STQ-1:0]                    stq_ddr_ready,
  output [NUM_STQ*ADDR_WIDTH-1:0]         stq_ddr_addr,
  output [NUM_STQ*DDR_DATA_WIDTH-1:0]     stq_ddr_data
);

genvar ii, jj;

generate 
  for(ii =0; ii <NUM_LDQ; ii= ii+1)
  begin
      load_queue 
      #(.LDQ_DATA_WIDTH(LDQ_DATA_WIDTH), .DDR_DATA_WIDTH(DDR_DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH), .QPTR_WIDTH(QPTR_WIDTH), .IDS_NUM(TOTAL_LDQ_IDS/NUM_LDQ), .BASE_ADDR_WIDTH(BASE_ADDR_WIDTH))
      u_load_queue
      (
          .sys_clk       (ldq_clk           ),
          .sys_rstn      (rstn              ),

          .req_valid     (ldq_valid[ii]),
          .req_id        (ldq_id[`BITS_TOTAl_INPUTS*(ii+1)-1:`BITS_TOTAl_INPUTS*ii]),
          .req_ready     (ldq_ready[ii]),
          .addr_base     (rchannel_addr_base[BASE_ADDR_WIDTH*(TOTAL_LDQ_IDS/NUM_LDQ)*(ii+1)-1:BASE_ADDR_WIDTH * (TOTAL_LDQ_IDS/NUM_LDQ)*ii]),

          .data_valid    (ldq_data_valid[ii]    ),
          .data_ready    (ldq_data_ready[ii]    ),
          .data          (ldq_data[LDQ_DATA_WIDTH*(ii+1)-1:LDQ_DATA_WIDTH*ii]),
          

          .ddr_clk       (ddr_clk           ),
          .ddr_rstn      (ddr_rstn          ),

          .ddr_addr_valid(ldq_ddr_addr_valid[ii]),
          .ddr_addr_ready(ldq_ddr_addr_ready[ii]),
          .ddr_addr      (ldq_ddr_addr[ADDR_WIDTH*(ii+1)-1:ADDR_WIDTH*ii]),

          .ddr_data_valid(ldq_ddr_data_valid[ii]),
          .ddr_data      (ldq_ddr_data[DDR_DATA_WIDTH*(ii+1)-1:DDR_DATA_WIDTH*ii])
      );
    end
endgenerate

generate 
    for(jj =0; jj <NUM_STQ; jj= jj+1)
    begin
      store_queue  
      #(.DDR_DATA_WIDTH(DDR_DATA_WIDTH), .STQ_DATA_WIDTH(STQ_DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH), .QPTR_WIDTH(QPTR_WIDTH), .IDS_NUM(TOTAL_STQ_IDS/NUM_STQ), .BASE_ADDR_WIDTH(BASE_ADDR_WIDTH))
      u_store_queue
      (
        .sys_clk  (stq_clk),
        .sys_rstn (rstn  ),
        .req_valid(stq_valid[jj]     ),
        .req_ready(stq_ready[jj]     ),
        .req_id   (stq_id   [7*(jj+1) -1 : 7*jj]),
        .data     (stq_data[STQ_DATA_WIDTH*(jj+1)-1:STQ_DATA_WIDTH*jj]      ),
        .addr_base(wchannel_addr_base[BASE_ADDR_WIDTH*(TOTAL_STQ_IDS/NUM_STQ)*(jj+1)-1:BASE_ADDR_WIDTH * (TOTAL_STQ_IDS/NUM_STQ)*jj]),
        .spmv_done (spmv_done),

        .ddr_clk  (ddr_clk   ),
        .ddr_rstn (ddr_rstn  ),
        .ddr_valid(stq_ddr_valid[jj] ),
        .ddr_ready(stq_ddr_ready[jj] ),
        .ddr_addr (stq_ddr_addr[ADDR_WIDTH*(jj+1)-1:ADDR_WIDTH*jj]  ),
        .ddr_data (stq_ddr_data[DDR_DATA_WIDTH*(jj+1)-1:DDR_DATA_WIDTH*jj]  )
    );
    end
endgenerate

endmodule
