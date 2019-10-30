//module:   id
//file:     id.v
//decode instructions in this module

`include "defines.v"

module id(
    input wire                  rst,
    input wire[`InstAddrBus]    instPc,
    input wire[`InstBus]        inst,

    //simply output everything to the dispatcher
    output wire[`NameBus]       regNameO, 
    output wire[`NameBus]       regNameT, 
    output wire[`NameBus]       rdName,
    output wire[`OpBus]         opCode
    //Imm
);

    wire[6:0] opcode 
    wire[2:0] func3;
    wire[6:0] func7;

    assign opcode = inst[6:0];
    assign func3 = inst[14:12];
    assign func7 = inst[31:25];

    assign regNameO = inst[19:15];
    assign regNameT = inst[24:20];

    always @ (posedge rst) begin
        
    end

    always @ (posedge clk) begin
        begin
            case(opcode)
                `EXE_LUI_OP:    begin

                end
                `EXE_AUIPC_OP:  begin

                end
                `EXE_JAL_OP:    begin

                end
                `EXE_JALR_OP:   begin

                end
                `EXE_BRANCH_OP: begin
                    case(func3)
                        `FUN_BEQ_OP:    begin

                        end
                        `FUN_BNE_OP:    begin

                        end
                        `FUN_BLT_OP:    begin

                        end
                        `FUN_BGE_OP:    begin

                        end
                        `FUN_BLTU_OP:   begin

                        end
                        `FUN_BGEU_OP:   begin

                        end
                end
                `EXE_LD_OP:     begin
                    case(func3)
                        `FUN_LB_OP:     begin
                          
                        end
                        `FUN_LH_OP:     begin

                        end
                        `FUN_LW_OP:     begin

                        end
                        `FUN_LBU_OP:    begin

                        end
                        `FUN_LHU_OP:    begin

                        end
                end
                `EXE_ST_OP:     begin
                    case(func3)
                        `FUN_SB_OP:     begin

                        end
                        `FUN_SH_OP:     begin

                        end
                        `FUN_SW_OP:     begin

                        end
                end
                `EXE_IMM_OP:    begin
                    case(func3)
                        `FUN_ADD_SUB_OP:    begin

                        end
                        `FUN_SLL_OP:        begin

                        end
                        `FUN_SLT_OP:        begin
                        
                        end
                        `FUN_SLTU_OP:       begin

                        end
                        `FUN_XOR_OP:        begin

                        end
                        `FUN_SRL_SRA_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP:    begin//SRL

                                end
                                `FUN_SPECIAL2_OP:   begin//SRA

                                end
                        end
                        `FUN_OR_OP:         begin

                        end
                        `FUN_AND_OP:        begin

                        end
                end
                `EXE_INT_OP:    begin
                    case(func3)
                        `FUN_ADD_SUB_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP:    begin//ADD

                                end
                                `FUN_SPECIAL2_OP:   begin//SUB

                                end
                        end
                        `FUN_SLL_OP:        begin

                        end
                        `FUN_SLT_OP:        begin
                        
                        end
                        `FUN_SLTU_OP:       begin

                        end
                        `FUN_XOR_OP:        begin

                        end
                        `FUN_SRL_SRA_OP:    begin
                            case(func7)
                                `FUN_SPECIAL_OP:    begin//SRL

                                end
                                `FUN_SPECIAL2_OP:   begin//SRA

                                end
                        end
                        `FUN_OR_OP:         begin

                        end
                        `FUN_AND_OP:        begin

                        end
                end
        end
    end

endmodule