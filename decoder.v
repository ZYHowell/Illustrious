//module:   id
//file:     id.v
//decode instructions in this module

`include "defines.v"

module decoder(
    input wire                  clk, 
    input wire                  rst,
    input wire[`InstAddrBus]    instPc,
    input wire[`InstBus]        inst,

    //simply output everything to the dispatcher
    output wire[`NameBus]       regNameO, 
    output wire[`NameBus]       regNameT, 
    output wire[`NameBus]       rdName,
    output wire[`OpBus]         opCode, 
    output wire[`OpClassBus]    opClass
    output wire[`DataBus]       imm, 
    output wire[`DataBus]       Uimm, 
    output wire[`DataBus]       Jimm, 
    output wire[`DataBus]       Simm, 
    output wire[`DataBus]       Bimm
    //Imm
);

    wire[6:0] opType; 
    wire[2:0] func3;
    wire[6:0] func7;

    assign opType = inst[6:0];
    assign func3 = inst[14:12];
    assign func7 = inst[31:25];

    assign regNameO = inst[19:15];
    assign regNameT = inst[24:20];

    assign imm = {{`immFillLen{inst[31]}, inst[31:20]}};
    assign Uimm = {inst[31:12], `UimmFillLen{1'b0}};
    assign Jimm = {`UimmFillLen{inst[31]}, inst[19:12], inst[20], inst[30:21], 1'b0};
    assign Simm = {`immFillLen{inst[31]}, inst[31:25], inst[11:7]};
    assign Bimm = {`immFillLen{inst[31]}, inst[7], inst[30:25], inst[11:8], 1'b0};

    always @ (posedge rst) begin
        regNameO <= `nameFree;
        regNameT <= `nameFree;
        rdName <= `nameFree;
        opCode <= `NOP;
        noClass <= `ClassNOP;
    end

    always @ (posedge clk) begin
        opClass <= opType;
        begin
            case(opType)
                `ClassLUI: opCode <= `LUI;
                `ClassAUIPC: opCode <= `AUIPC;
                `ClassJAL: opCode <= `JAL;
                `ClassJALR: opCode <= `JALR;
                `ClassB:    begin
                    case(func3)
                        `FUN_BEQ_OP: opCode <= `BEQ;
                        `FUN_BNE_OP: opCode <= `BNE;
                        `FUN_BLT_OP: opCode <= `BLT;
                        `FUN_BGE_OP: opCode <= `BGE;
                        `FUN_BLTU_OP: opCode <= `BLTU;
                        `FUN_BGEU_OP: opCode <= `BGEU;
                        default:;
                    endcase
                end
                `ClassLD:   begin
                    case(func3)
                        `FUN_LB_OP: opCode <= `LB;
                        `FUN_LH_OP: opCode <= `LH;
                        `FUN_LW_OP: opCode <= `LW;
                        `FUN_LBU_OP: opCode <= `LBU;
                        `FUN_LHU_OP: opCode <= `LHU;
                        default:;
                    endcase
                end
                `ClassST:   begin
                    case(func3)
                        `FUN_SB_OP: opCode <= `SB;
                        `FUN_SH_OP: opCode <= `SH;
                        `FUN_SW_OP: opCode <= `SW;
                        default:;
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
                                `FUN_SPECIAL_OP:    begin//SRL
                                    opCode <= `SRL;
                                end
                                `FUN_SPECIAL2_OP:   begin//SRA
                                    opCode <= `SRA;
                                end
                                default:;
                            endcase
                        end
                        `FUN_OR_OP: opCode <= `OR;
                        `FUN_AND_OP: opCode <= `AND;
                        default:;
                    endcase
                end
                `ClassRR:   begin
                    case(func3)
                        `FUN_ADD_SUB_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP:    begin//ADD
                                    opCode <= `ADD;
                                end
                                `FUN_SPECIAL2_OP:   begin//SUB
                                    opCode <= `SUB;
                                end
                                default:;
                            endcase
                        end
                        `FUN_SLL_OP: opCode <= `SLL;
                        `FUN_SLT_OP: opCode <= `SLT;
                        `FUN_SLTU_OP: opCode <= `SLTU;
                        `FUN_XOR_OP: opCode <= `XOR;
                        `FUN_SRL_SRA_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP:    begin//SRL
                                    opCode <= `SRL;
                                end
                                `FUN_SPECIAL2_OP:   begin//SRA
                                    opCode <= `SRA;
                                end
                                default:;
                            endcase
                        end
                        `FUN_OR_OP: opCode <= `OR;
                        `FUN_AND_OP: opCode <= `AND;
                        default:;
                    endcase
                end
                default:;
            endcase
        end
    end

endmodule