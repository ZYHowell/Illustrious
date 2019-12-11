//module:   id
//file:     id.v
//decode instructions in this module

`include "defines.v"

module decoder(
    input wire                  clk, 
    input wire                  rst,
    input wire                  stall, 
    input wire                  DecEn, 
    input wire[`InstAddrBus]    instPC,
    input wire[`InstBus]        inst,

    //simply output everything to the dispatcher
    output reg[`NameBus]        regNameO, 
    output reg[`NameBus]        regNameT, 
    output reg[`NameBus]        rdName,
    output reg[`OpBus]          opCode, 
    output reg[`OpClassBus]     opClass, 
    output reg[`InstAddrBus]    instAddr, 
    //Imm
    output reg[`DataBus]        imm, 
    output reg[`DataBus]        Uimm, 
    output reg[`DataBus]        Jimm, 
    output reg[`DataBus]        Simm, 
    output reg[`DataBus]        Bimm, 
    //about branch, I control it in decoder rather than BranchRS, maybe this is useful to deal with LS too. 
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum, 

    //notice that the BranchTag of output here does not consider the result of the Branch FU
    //which works at this cycle, and it cannot judge this: is supposed to be solved by dispathcer
    output reg[`BranchTagBus]   BranchTag, 
    output wire                 BranchFree, 
    input wire misTaken
);

    wire[6:0] opType; 
    wire[2:0] func3;
    wire[6:0] func7;
    wire isBranch;

    reg[`BranchTagBus] bTag;
    reg[1:0] BranchNum, BranchTail;

    assign BranchFree = (BranchNum + (opClass == `ClassB)) < `branchRsSize;

    assign opType = inst[6:0];
    assign func3 = inst[14:12];
    assign func7 = inst[31:25];
    assign isBranch = (opType == `ClassB) & DecEn;

    always @ (posedge clk) begin
      instAddr <= instPC;
      imm <= {{`immFillLen{inst[31]}}, inst[31:20]};
      Uimm <= {inst[31:12], {`UimmFillLen{1'b0}}};
      Jimm <= {{`UimmFillLen{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
      Simm <= {{`immFillLen{inst[31]}}, inst[31:25], inst[11:7]};
      Bimm <= {{`immFillLen{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      BranchTag <= bTag;
      if (rst) begin
        regNameO <= `nameFree;
        regNameT <= `nameFree;
        rdName <= `nameFree;
        opCode <= `NOP;
        opClass <= `ClassNOP;
        bTag <= 0;
        BranchNum <= 0;
        BranchTail <= 0;
      end else begin
        //if mistaken, clear all. (branch is executed in order, ovo)
        if (misTaken) begin
            bTag <= 0;
            BranchNum <= 0;
        end else if (bFreeEn) begin
            bTag[bFreeNum] <= 0;
            BranchNum <= isBranch ? BranchNum : BranchNum - 1;
        end else begin
            BranchNum <= isBranch ? BranchNum + 1 : BranchNum;
        end

        if (DecEn & ~stall) begin
            opClass <= opType;
            regNameO = inst[19:15];
            regNameT <= inst[24:20];
            rdName <= inst[11:7];
            //the following case deals with opCode only
            case(opType)
                `ClassLUI: opCode <= `LUI;
                `ClassAUIPC: opCode <= `AUIPC;
                `ClassJAL: opCode <= `JAL;
                `ClassJALR: opCode <= `JALR;
                `ClassB:    begin
                    bTag[BranchTail] <= 1;
                    BranchTail <= (BranchTail + 1 < `branchRsSize) ? BranchTail + 1 : 0;
                    case(func3)
                        `FUN_BEQ_OP: opCode <= `BEQ;
                        `FUN_BNE_OP: opCode <= `BNE;
                        `FUN_BLT_OP: opCode <= `BLT;
                        `FUN_BGE_OP: opCode <= `BGE;
                        `FUN_BLTU_OP: opCode <= `BLTU;
                        `FUN_BGEU_OP: opCode <= `BGEU;
                    endcase
                end
                `ClassLD:   begin
                    case(func3)
                        `FUN_LB_OP: opCode <= `LB;
                        `FUN_LH_OP: opCode <= `LH;
                        `FUN_LW_OP: opCode <= `LW;
                        `FUN_LBU_OP: opCode <= `LBU;
                        `FUN_LHU_OP: opCode <= `LHU;
                    endcase
                end
                `ClassST:   begin
                    case(func3)
                        `FUN_SB_OP: opCode <= `SB;
                        `FUN_SH_OP: opCode <= `SH;
                        `FUN_SW_OP: opCode <= `SW;
                    endcase
                end
                `ClassRI:   begin
                    case(func3)
                        `FUN_ADD_SUB_OP: opCode <= `ADD;
                        `FUN_SLL_OP: opCode <= `SLL;
                        `FUN_SLT_OP: opCode <= `SLT;
                        `FUN_SLTU_OP: opCode <= `SLTU;
                        `FUN_XOR_OP: opCode <= `XOR;
                        `FUN_SRL_SRA_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP: opCode <= `SRL;
                                `FUN_SPECIAL2_OP: opCode <= `SRA;
                            endcase
                        end
                        `FUN_OR_OP: opCode <= `OR;
                        `FUN_AND_OP: opCode <= `AND;
                    endcase
                end
                `ClassRR:   begin
                    case(func3)
                        `FUN_ADD_SUB_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP: opCode <= `ADD;
                                `FUN_SPECIAL2_OP: opCode <= `SUB;
                            endcase
                        end
                        `FUN_SLL_OP: opCode <= `SLL;
                        `FUN_SLT_OP: opCode <= `SLT;
                        `FUN_SLTU_OP: opCode <= `SLTU;
                        `FUN_XOR_OP: opCode <= `XOR;
                        `FUN_SRL_SRA_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP: opCode <= `SRL;
                                `FUN_SPECIAL2_OP: opCode <= `SRA;
                            endcase
                        end
                        `FUN_OR_OP: opCode <= `OR;
                        `FUN_AND_OP: opCode <= `AND;
                    endcase
                end
            endcase
        end else begin
            // regNameO <= `nameFree;
            // regNameT <= `nameFree;
            // rdName <= `nameFree;
            opCode <= `NOP;
            opClass <= `ClassNOP;
        end
      end
    end

endmodule