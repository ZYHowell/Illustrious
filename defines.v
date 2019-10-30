//
`define RstEnable 1'b1
`define RstDisable 1'b0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define InstValid 1'b0
`define InstInvalid 1'b1

//opcodes
`define EXE_LUI_OP 7'b0110111
`define EXE_AUIPC_OP 7'b0010111
`define EXE_JAL_OP 7'b1101111
`define EXE_JALR_OP 7'b1100111
`define EXE_BRANCH_OP 7'b1100011
`define EXE_LD_OP 7'b0000011
`define EXE_ST_OP 7'b0100011
`define EXE_IMM_OP 7'b0010011
`define EXE_INT_OP 7'b0110011

//funct3 codes
`define FUN_JALR_OP 3'b000

`define FUN_BEQ_OP 3'b000 
`define FUN_BNE_OP 3'b001 
`define FUN_BLT_OP 3'b100
`define FUN_BGE_OP 3'b101 
`define FUN_BLTU_OP 3'b110 
`define FUN_BGEU_OP 3'b111

`define FUN_LB_OP 3'b000 
`define FUN_LH_OP 3'b001 
`define FUN_LW_OP 3'b010 
`define FUN_LBU_OP 3'b100 
`define FUN_LHU_OP 3'b101 

`define FUN_SB_OP 3'b000 
`define FUN_SH_OP 3'b001 
`define FUN_SW_OP 3'b010 

`define FUN_ADD_SUB_OP 3'b000
`define FUN_SLL_OP 3'b001
`define FUN_SLT_OP 3'b010 
`define FUN_SLTU_OP 3'b011 
`define FUN_XOR_OP 3'b100 
`define FUN_SRL_SRA_OP 3'b101 
`define FUN_OR_OP 3'b110 
`define FUN_AND_OP 3'b111 

//func7 codes
`define FUN_SPECIAL_OP 7'b0000000 
`define FUN_SPECIAL2_OP 7'b0100000 

//
`define InstAddrBus 31:0
`define InstBus 31:0
`define DataAddrBus 31:0
`define DataBus 31:0
`define TagBus 3:0
`define OpBus 4:0
`define NameBus 4:0


`define regSize 32

`define rsWidth 128
`define rsSize 6

`define tagFree 4'b0000

`define NOP 5'b00000