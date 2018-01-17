module top
#(parameter ADDRESS_SIZE = 27) //Memory Address Size (Avalon) - must be no greater than 29
(
 input                ddr3_clk                      ,
 input                ddr3_reset                    ,
 output [ADDRESS_SIZE-1:0]     ddr3_m0_address      , // as 0, 1, 2,.... (64 bytes aligned)
 output               ddr3_m0_read                  ,
 input                ddr3_m0_waitrequest           ,
 input  [575:0]       ddr3_m0_readdata              ,
 output               ddr3_m0_write                 ,
 output [575:0]       ddr3_m0_writedata             ,
 input                ddr3_m0_readdatavalid         ,
 output [71:0]        ddr3_m0_be                    ,
 output [6:0]         ddr3_m0_burstcount            ,
                      
 input                spmv_start,
 input                spmv_clear,
 output               spmv_done
);


parameter DDR_DATA_WIDTH  =512;
parameter LDQ_DATA_WIDTH  =512;
parameter STQ_DATA_WIDTH  =512;
//parameter STQ_DATA_WIDTH  =256;
parameter ADDR_WIDTH      =32;
parameter NUM_LDQ         =4;
parameter NUM_STQ         =1;
parameter TOTAL_LDQ_IDS   =512;
parameter TOTAL_STQ_IDS   =1; 
parameter BASE_ADDR_WIDTH =20;

wire [ADDRESS_SIZE-1:0]       sr0_address      ;
wire                          sr0_read         ;
wire                          sr0_waitrequest  ;
wire [DDR_DATA_WIDTH-1:0]     sr0_readdata     ;
wire                          sr0_write        ;
wire [DDR_DATA_WIDTH-1:0]     sr0_writedata    ;
wire                          sr0_readdatavalid;
wire [DDR_DATA_WIDTH/8 -1:0]  sr0_be           ;
wire [6:0]                    sr0_burstcount   ;

wire [ADDRESS_SIZE-1:0]       sr1_address      ;
wire                          sr1_read         ;
wire                          sr1_waitrequest  ;
wire [DDR_DATA_WIDTH-1:0]     sr1_readdata     ;
wire                          sr1_write        ;
wire [DDR_DATA_WIDTH-1:0]     sr1_writedata    ;
wire                          sr1_readdatavalid;
wire [DDR_DATA_WIDTH/8 -1:0]  sr1_be           ;
wire [6:0]                    sr1_burstcount   ;

wire [ADDRESS_SIZE-1:0]       sr2_address      ;
wire                          sr2_read         ;
wire                          sr2_waitrequest  ;
wire [DDR_DATA_WIDTH-1:0]     sr2_readdata     ;
wire                          sr2_write        ;
wire [DDR_DATA_WIDTH-1:0]     sr2_writedata    ;
wire                          sr2_readdatavalid;
wire [DDR_DATA_WIDTH/8 -1:0]  sr2_be           ;
wire [6:0]                    sr2_burstcount   ;

wire [ADDRESS_SIZE-1:0]       sr3_address      ;
wire                          sr3_read         ;
wire                          sr3_waitrequest  ;
wire [DDR_DATA_WIDTH-1:0]     sr3_readdata     ;
wire                          sr3_write        ;
wire [DDR_DATA_WIDTH-1:0]     sr3_writedata    ;
wire                          sr3_readdatavalid;
wire [DDR_DATA_WIDTH/8 -1:0]  sr3_be           ;
wire [6:0]                    sr3_burstcount   ;

wire [ADDRESS_SIZE-1:0]       sw0_address      ;
wire                          sw0_read         ;
wire                          sw0_waitrequest  ;
wire [DDR_DATA_WIDTH-1:0]     sw0_readdata     ;
wire                          sw0_write        ;
wire [DDR_DATA_WIDTH-1:0]     sw0_writedata    ;
wire                          sw0_readdatavalid;
wire [DDR_DATA_WIDTH/8 -1:0]  sw0_be           ;
wire [6:0]                    sw0_burstcount   ;

avl_comb #(.SLAVE_NUM(5), .ADDR_WIDTH(ADDRESS_SIZE),.DATA_WIDTH(576))
u_avl_comb(
 .clk            (ddr3_clk),
 .reset          (ddr3_reset ),

 .s_address      ({sw0_address      ,sr3_address      ,sr2_address      ,sr1_address      ,sr0_address      }),
 .s_read         ({sw0_read         ,sr3_read         ,sr2_read         ,sr1_read         ,sr0_read         }),
 .s_waitrequest  ({sw0_waitrequest  ,sr3_waitrequest  ,sr2_waitrequest  ,sr1_waitrequest  ,sr0_waitrequest  }),
 .s_readdata     ({sw0_readdata     ,sr3_readdata     ,sr2_readdata     ,sr1_readdata     ,sr0_readdata     }), 
 .s_write        ({sw0_write        ,sr3_write        ,sr2_write        ,sr1_write        ,sr0_write        }),
 .s_writedata    ({sw0_writedata    ,sr3_writedata    ,sr2_writedata    ,sr1_writedata    ,sr0_writedata    }),
 .s_readdatavalid({sw0_readdatavalid,sr3_readdatavalid,sr2_readdatavalid,sr1_readdatavalid,sr0_readdatavalid}),
 .s_be           ({sw0_be           ,sr3_be           ,sr2_be           ,sr1_be           ,sr0_be           }),
 .s_burstcount   ({sw0_burstcount   ,sr3_burstcount   ,sr2_burstcount   ,sr1_burstcount   ,sr0_burstcount   }),

 .m_address      (ddr3_m0_address      ),
 .m_read         (ddr3_m0_read         ),
 .m_waitrequest  (ddr3_m0_waitrequest  ),
 .m_readdata     (ddr3_m0_readdata     ), 
 .m_write        (ddr3_m0_write        ),
 .m_writedata    (ddr3_m0_writedata    ),
 .m_readdatavalid(ddr3_m0_readdatavalid), 
 .m_be           (ddr3_m0_be           ),
 .m_burstcount   (ddr3_m0_burstcount   )

);

  wire [BASE_ADDR_WIDTH * TOTAL_LDQ_IDS -1 :0]  rchannel_addr_base = 0;
  wire [BASE_ADDR_WIDTH * TOTAL_STQ_IDS -1 :0]  wchannel_addr_base = 0;

spmv_func
#(.DDR_DATA_WIDTH (DDR_DATA_WIDTH), .LDQ_DATA_WIDTH(LDQ_DATA_WIDTH), .STQ_DATA_WIDTH(STQ_DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NUM_LDQ(NUM_LDQ), .NUM_STQ(NUM_STQ), .TOTAL_LDQ_IDS(TOTAL_LDQ_IDS), .TOTAL_STQ_IDS(TOTAL_STQ_IDS), .BASE_ADDR_WIDTH(BASE_ADDR_WIDTH))
u_spmv_func(
  .clock                    (ddr3_clk),
  .resetn                   (~ddr3_reset),
  .spmv_start               (spmv_start),
  .spmv_clear               (spmv_clear),
  .spmv_done                (spmv_done),
  .rchannel_addr_base       (rchannel_addr_base),
  .wchannel_addr_base       (wchannel_addr_base),

  .m_rchannel0_address      (sr0_address      ),
  .m_rchannel0_read         (sr0_read         ),
  .m_rchannel0_waitrequest  (sr0_waitrequest  ),
  .m_rchannel0_readdata     (sr0_readdata     ),
  .m_rchannel0_write        (sr0_write        ),
  .m_rchannel0_writedata    (sr0_writedata    ),
  .m_rchannel0_readdatavalid(sr0_readdatavalid),
  .m_rchannel0_be           (sr0_be           ),
  .m_rchannel0_burstcount   (sr0_burstcount   ),

  .m_rchannel1_address      (sr1_address      ),
  .m_rchannel1_read         (sr1_read         ),
  .m_rchannel1_waitrequest  (sr1_waitrequest  ),
  .m_rchannel1_readdata     (sr1_readdata     ),
  .m_rchannel1_write        (sr1_write        ),
  .m_rchannel1_writedata    (sr1_writedata    ),
  .m_rchannel1_readdatavalid(sr1_readdatavalid),
  .m_rchannel1_be           (sr1_be           ),
  .m_rchannel1_burstcount   (sr1_burstcount   ),

  .m_rchannel2_address      (sr2_address      ),
  .m_rchannel2_read         (sr2_read         ),
  .m_rchannel2_waitrequest  (sr2_waitrequest  ),
  .m_rchannel2_readdata     (sr2_readdata     ),
  .m_rchannel2_write        (sr2_write        ),
  .m_rchannel2_writedata    (sr2_writedata    ),
  .m_rchannel2_readdatavalid(sr2_readdatavalid),
  .m_rchannel2_be           (sr2_be           ),
  .m_rchannel2_burstcount   (sr2_burstcount   ),

  .m_rchannel3_address      (sr3_address      ),
  .m_rchannel3_read         (sr3_read         ),
  .m_rchannel3_waitrequest  (sr3_waitrequest  ),
  .m_rchannel3_readdata     (sr3_readdata     ),
  .m_rchannel3_write        (sr3_write        ),
  .m_rchannel3_writedata    (sr3_writedata    ),
  .m_rchannel3_readdatavalid(sr3_readdatavalid),
  .m_rchannel3_be           (sr3_be           ),
  .m_rchannel3_burstcount   (sr3_burstcount   ),

  .m_wchannel0_address      (sw0_address      ),
  .m_wchannel0_read         (sw0_read         ),
  .m_wchannel0_waitrequest  (sw0_waitrequest  ),
  .m_wchannel0_readdata     (sw0_readdata     ),
  .m_wchannel0_write        (sw0_write        ),
  .m_wchannel0_writedata    (sw0_writedata    ),
  .m_wchannel0_readdatavalid(sw0_readdatavalid),
  .m_wchannel0_be           (sw0_be           ),
  .m_wchannel0_burstcount   (sw0_burstcount   )
);
endmodule
