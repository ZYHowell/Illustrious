`define Enable  1'b1
`define Disable 1'b0
`define InstValid   1'b0
`define InstInvalid 1'b1
`define NotFree 1'b0
`define IsFree  1'b1
`define NotUsing    1'b0
`define IsUsing     1'b1
`define MemRead     1'b1
`define MemWrite    1'b0
`define Valid   1'b1
`define Invalid 1'b0
//should mem discard PC/LS in waiting
`define Discard 1'b1
`define Keep    1'b0

`define MemReceive 1'b1
`define MemNotReceive 1'b0
`define NoFreeTag 3'b111
`define ALUtagPrefix 1'b0
`define LStagPrefix 1'b1
`define JALRnum 32'hfffffffe;
//******************12345678901234567890123456789012
`define PCnext  32'h00000004;
`define Read 1'b0
`define Write 1'b1
`define instPort 1'b0
`define LSport 1'b1
`define SignEx 1'b1
`define UnsignEx 1'b0

//mem length and bus related
`define LenBus 2:0
`define ZeroLen 3'b000
`define ByteLen 3'b001
`define HexLen 3'b010
`define WordLen 3'b100

//
`define AddrBus     31:0
`define InstAddrBus 31:0
`define InstBus     31:0
`define DataAddrBus 31:0
`define DataBus     31:0
`define TagBus      3:0
`define TagRootBus  2:0
`define OpBus       4:0
`define NameBus     4:0
`define RAMBus      7:0
`define StageBus    1:0
`define OpClassBus  6:0
`define memTagBus   7:0
`define memAddrTagBus   16:9
`define memAddrIndexBus 8:2
`define BranchTagBus 2:0

`define immFillLen 20
`define UimmFillLen 12
`define regSize 32

`define rsWidth 128
`define rsSize 7
`define branchRsSize 3
`define ROBsize 7
`define memCacheSize 128

`define tagFree     4'b0111
`define nameFree    5'b00000
`define dataFree    32'h00000000
`define addrFree    32'h00000000
//**********************12345678
`define RAMdataFree 8'h00
`define memTagFree  8'h00

//opcodes
`define ClassNOP    7'b0000000
`define ClassLUI    7'b0110111
`define ClassAUIPC  7'b0010111
`define ClassJAL    7'b1101111
`define ClassJALR   7'b1100111
`define ClassB      7'b1100011
`define ClassLD     7'b0000011
`define ClassST     7'b0100011
`define ClassRI     7'b0010011
`define ClassRR     7'b0110011

//funct3 codes
`define FUN_JALR_OP     3'b000

`define FUN_BEQ_OP      3'b000 
`define FUN_BNE_OP      3'b001 
`define FUN_BLT_OP      3'b100
`define FUN_BGE_OP      3'b101 
`define FUN_BLTU_OP     3'b110 
`define FUN_BGEU_OP     3'b111

`define FUN_LB_OP       3'b000 
`define FUN_LH_OP       3'b001 
`define FUN_LW_OP       3'b010 
`define FUN_LBU_OP      3'b100 
`define FUN_LHU_OP      3'b101 

`define FUN_SB_OP       3'b000 
`define FUN_SH_OP       3'b001 
`define FUN_SW_OP       3'b010 

`define FUN_ADD_SUB_OP  3'b000
`define FUN_SLL_OP      3'b001
`define FUN_SLT_OP      3'b010 
`define FUN_SLTU_OP     3'b011 
`define FUN_XOR_OP      3'b100 
`define FUN_SRL_SRA_OP  3'b101 
`define FUN_OR_OP       3'b110 
`define FUN_AND_OP      3'b111 

//func7 codes
`define FUN_SPECIAL_OP  7'b0000000 
`define FUN_SPECIAL2_OP 7'b0100000 

`define NOP     5'b00000
`define LUI     5'b00001
`define AUIPC   5'b00010
`define JAL     5'b00011
`define JALR    5'b00100
`define BEQ     5'b00101
`define BNE     5'b00110
`define BLT     5'b00111 
`define BGE     5'b01000
`define BLTU    5'b01001 
`define BGEU    5'b01010 
`define LB      5'b01011 
`define LH      5'b01100 
`define LW      5'b01101 
`define LBU     5'b01110 
`define LHU     5'b01111 
`define SB      5'b10000 
`define SH      5'b10001 
`define SW      5'b10010 
`define ADD     5'b10011 
`define SUB     5'b10100 
`define SLL     5'b10101 
`define SLT     5'b10110 
`define SLTU    5'b10111 
`define XOR     5'b11000 
`define SRL     5'b11001 
`define SRA     5'b11010 
`define OR      5'b11011 
`define AND     5'b11100 