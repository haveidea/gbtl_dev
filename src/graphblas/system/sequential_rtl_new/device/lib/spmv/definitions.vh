//
// SpMV Definitions: Numerical parameters of the SpMV core
// 
// 

//---------------------------Not regular design parameter-------------------------------
//**************************************************************************************
`define DATA_PRECISION 32
`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0
`define ISIGN 1
`define INST_FAITHFUL_ROUND 0
`define STATUS_WIDTH 8
`define RND_WIDTH 3
`define RND_NEAREST 0
`define RND_UP 2
`define RND_DOWN 3
`define NUM_STG_ADDER_PIPE 2
`define NUM_FP_ADDER_PER_UNIT 4
`define NUM_PARALLEL_ADDER 4
`define BITS_ADDER_SELECT_CTR 2
`define BITS_ROW_IDX 32
`define BITS_VALID_DATA 1
`define BITS_INPUT_TAG 1
`define MODE_POPULATE_ZERO 0
`define MODE_WORK 1
`define LIM_BRICK_WORD_SIZE 32
`define LIM_BRICK_WORD_NUM 32
`define BITS_ADDR_LIM_BRICK 5
`define INPUT_ELE_WIDTH_MATLAB 64
`define TOT_IN_WIDTH 32768
`define BITS_TOT_IN_WIDTH 15
`define TOT_IN_WIDTH_RATIO_2DATA 64
`define BITS_IN_CTR_PER_LIST 6
//**************************************************************************************

//-------------------------------Regular design parameter------------------------------
//**************************************************************************************
`define INPUT_BIN_SIZE 8
`define BITS_INPUT_BIN_ADDR 3
`define NUM_INPUTs 512
`define BITS_TOTAl_INPUTS 9
`define NUM_SEG_PER_STG 4
`define NUM_INPUTs_PER_SEG_ARR 128
`define BITS_RADIX_SORT 3
`define NUM_UNITs 8
`define BITS_UNIT_SELECTION 3
`define UNIT_INIT_BIT 29
`define NUM_STGs 9
`define BITS_ADDR_UNIT 9
`define END_OF_FAST_STG 2
`define START_OF_BIG_STG 7
`define DATA_WIDTH_BUFF_SO_SEG 65
`define TAG_INDEX_DATA_BUFF_SO_SEG 0
`define VALID_INDEX_DATA_BUFF_SO_SEG 1
`define DATA_WIDTH_INPUT 64
`define WORD_WIDTH_INPUT 64
`define NUM_BRICK_SEG_HOR 3
`define NUM_DUMMY_BITS_SEG_MEM 31
`define NUM_BRICK_SEG_HOR_INPUT 2
`define NUM_DUMMY_BITS_SEG_MEM_INPUT 0
`define BITS_INPUT_ADDR_SLOW_BLK 7
`define SLOW_BLK_BUFF_SIZE 8
`define BITS_SLOW_BLK_BUFF_ADDR 3
`define CLK_DIV_RATIO 2
`define DIV_RATIO_HALF 1
`define BITS_DIV_RATIO_HALF 0
`define DATA_WIDTH_ADD_STG 65
`define BITS_BLK_FAST_OUT_Q 3
`define BITS_BLK_FAST_FIFO 3
`define BITS_ADDER_OUT_Q 3
`define NUM_ACCUM_STG 1
`define INITIALIZE_SEG_ADDR_WIDTH 7
//**************************************************************************************

//--------------------------Load Store queue parameters---------------------------
//**************************************************************************************
`define DRAM_ADDR_WIDTH 32
`define LOAD_ADDR_WIDTH 21
`define LOAD_ADDR_ALIGNMENT_WIDTH 11
`define STORE_ADDR_WIDTH 21
`define STORE_ADDR_ALIGNMENT_WIDTH 11
`define LDQ_DEPTH 16
`define BITS_LDQ_DEPTH 4
`define STQ_DEPTH 16
`define BITS_STQ_DEPTH 4
`define LDQ_DATA_WIDTH 512
`define STQ_DATA_WIDTH 256
`define LDQ_BUFF_SIZE 16384
`define STQ_BUFF_SIZE 32768
`define LDQ_BUFF_RATIO_2DATA 32
`define BITS_LDQ_BUFF_PER_LIST 5
`define STQ_BUFF_RATIO_2DATA 128
`define BITS_STQ_BUFF_PER_UNIT 7
`define STQ_BUFF_MIN_RATIO_2DATA 64
`define BLK_WIDTH_INPUT 512
`define BLK_SLOW_PARR_WR_NUM 8
`define INPUT_BLK_RATIO_2WORD 8
`define BITS_ADDR_LD_REQ_Q 4
`define BITS_ADDR_FILL_SVC_Q 4
`define BITS_ADDR_FILL_REQ_Q 7
//**************************************************************************************

//--------------------------Data output Scan-chain parameters---------------------------
//**************************************************************************************
`define NUM_OUTPUT_WORDS_PER_UNIT 16
`define BITS_OUTPUT_ADDR_PER_UNIT 4
//**************************************************************************************

//------------------These should be inhereted parameters in the modules-----------------
//**************************************************************************************
`define NUM_BRICK_SEG_VER 16
`define NUM_BUFF_SO_WORDS_SEG 512
`define BITS_ADDR_SEG 9
//**************************************************************************************

//-------------------------Radix Sort parameters----------------------------------------
//**************************************************************************************
`define STREAM_WIDTH 8
`define LOG_STREAM_WIDTH 3
`define NUM_BIOTONIC_STGS_TOT 6
//**************************************************************************************


