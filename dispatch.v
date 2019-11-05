`include "defines.v"
//caution! not test if Status == 0
module Table(
    input wire rst, 
    input wire[`rsSize - 1] freeStatusALU, 
    input wire[`rsSize - 1] freeStatusLS
    input wire[`rsSize - 1] readyStatusALU,
    input wire[`rsSize - 1] readyStatusLS, 
    output wire[`TagRootBus] freeTagALU, 
    output wire[`TagRootBus] freeTagLS, 
    output wire[`TagRootBus] readyTagALU, 
    output wire[`TagRootBus] readyTagLS
)
    reg [`rsSize - 1] list[`TagBus];

    assign freeTagALU = list[freeStatusALU];
    assign freeTagLS = list[freeStatusLS];
    assign readyTagALU = list[readyStatusALU];
    assign readyTagLS = list[readyStatusLS];

    always @ (posedge rst) begin
        list[6'b000000] = `NoFreeTag;
        list[6'b000001] = 3'b000;
        list[6'b000010] = 3'b001;
        list[6'b000011] = 3'b000;
        list[6'b000100] = 3'b010;
        list[6'b000101] = 3'b000;
        list[6'b000110] = 3'b001;
        list[6'b000111] = 3'b000;
        list[6'b001000] = 3'b011;
        list[6'b001001] = 3'b000;
        list[6'b001010] = 3'b001;
        list[6'b001011] = 3'b000;
        list[6'b001100] = 3'b010;
        list[6'b001101] = 3'b000;
        list[6'b001110] = 3'b001;
        list[6'b001111] = 3'b000;
        list[6'b010000] = 3'b100;
        list[6'b010001] = 3'b000;
        list[6'b010010] = 3'b001;
        list[6'b010011] = 3'b000;
        list[6'b010100] = 3'b010;
        list[6'b010101] = 3'b000;
        list[6'b010110] = 3'b001;
        list[6'b010111] = 3'b000;
        list[6'b011000] = 3'b011;
        list[6'b011001] = 3'b000;
        list[6'b011010] = 3'b001;
        list[6'b011011] = 3'b000;
        list[6'b011100] = 3'b010;
        list[6'b011101] = 3'b000;
        list[6'b011110] = 3'b001;
        list[6'b011111] = 3'b000;
        list[6'b100000] = 3'b101;
        list[6'b100001] = 3'b000;
        list[6'b100010] = 3'b001;
        list[6'b100011] = 3'b000;
        list[6'b100100] = 3'b010;
        list[6'b100101] = 3'b000;
        list[6'b100110] = 3'b001;
        list[6'b100111] = 3'b000;
        list[6'b101000] = 3'b011;
        list[6'b101001] = 3'b000;
        list[6'b101010] = 3'b001;
        list[6'b101011] = 3'b000;
        list[6'b101100] = 3'b010;
        list[6'b101101] = 3'b000;
        list[6'b101110] = 3'b001;
        list[6'b101111] = 3'b000;
        list[6'b110000] = 3'b100;
        list[6'b110001] = 3'b000;
        list[6'b110010] = 3'b001;
        list[6'b110011] = 3'b000;
        list[6'b110100] = 3'b010;
        list[6'b110101] = 3'b000;
        list[6'b110110] = 3'b001;
        list[6'b110111] = 3'b000;
        list[6'b111000] = 3'b011;
        list[6'b111001] = 3'b000;
        list[6'b111010] = 3'b001;
        list[6'b111011] = 3'b000;
        list[6'b111100] = 3'b010;
        list[6'b111101] = 3'b000;
        list[6'b111110] = 3'b001;
        list[6'b111111] = 3'b000;
    end

endmodule

module dispatcher(
    //from decoder
    input wire[`NameBus]        regNameO, 
    input wire[`NameBus]        regNameT, 
    input wire[`NameBus]        rdName,
    input wire[`OpBus]          opCode,
    input wire[`OpClassBus]     opClass,
    input wire[`DataBus]        imm, 
    input wire[`DataBus]        Uimm, 
    input wire[`DataBus]        Jimm, 
    input wire[`DataBus]        Simm, 
    input wire[`DataBus]        Bimm, 
    //from regfile
    input wire[`TagBus]         regTagO, 
    input wire[`DataBus]        regDataO, 
    input wire[`TagBus]         regTagT, 
    input wire[`DataBus]        regDataT, 
    //from ALUrs, which tag is avaliable
    input wire[`rsSize - 1:0]   ALUfreeStatus,
    //from LSbuffer, which tag is avaliable
    input wire[`rsSize - 1:0]   LSfreeStatus,

    //to regfile(rename the rd)
    output wire                 enWrt, 
    output wire[`TagBus]        wrtTag, 
    output wire[`NameBus]       wrtName, 
    //to ALUrs
    output wire                 ALUen, 
    output wire[`DataBus]       ALUoperandO, 
    output wire[`DataBus]       ALUoperandT, 
    output wire[`TagBus]        ALUtagO, 
    output wire[`TagBus]        ALUtagT,
    output wire[`TagBus]        ALUtagW, 
    output wire[`NameBus]       ALUnameW, 
    output wire[`OpBus]         ALUop, 
    //to BranchRS
    output wire                 BranchEn, 
    output wire[`DataBus]       BranchOperandO, 
    output wire[`DataBus]       BranchOperandT, 
    output wire[`TagBus]        BranchTagO, 
    output wire[`TagBus]        BranchTagT, 
    output wire[`OpBus]         BranchOp, 
    output wire[`DataBus]       BranchImm, 
    //to LSbuffer
    output wire                 LSen, 
    output wire[`DataBus]       LSoperandO, 
    output wire[`DataBus]       LSoperandT, 
    output wire[`TagBus]        LStagO, 
    output wire[`TagBus]        LStagT,
    output wire[`OpBus]         LStagW, 
    output wire[`NameBus]       ALUnameW, 
    output wire[`DataBus]       LSimm

);
    wire [`TagRootBus] ALUfreeTag;
    wire [`TagRootBus] LSfreeTag;

    wire [`TagBus]      finalTag;
    wire                prefix;
    //get the avaliable tag
    Table freetag(
        .rst(rst),
        .freeStatus(ALUfreeStatus), 
        .
        .freeTag(ALUfreeTag)
    );
    //choose the correct avaliable tag
    assign prefix   = opClass == `LD ? `LStagPrefix : `ALUtagPrefix;
    assign finalTag = {prefix, prefix == `ALUtagPrefix ? ALUfreeTag : LSfreeTag};
    //
    always @ (posedge clk) begin
        case(opClass):
            `ClassLUI: begin
              ALUen <= `Enable;
              ALUop <= `opCode;
              ALUoperandO <= regDataO;
              ALUoperandT <= Uimm;
              ALUtagO <= regTagO;
              ALUtagT <= `tagFree;
              ALUtagW <= finalTag;
              ALUnameW <= rdName;

              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;
              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            `ClassAUIPC: begin
              ALUen <= `Enable;
              ALUop <= `opCode;
              ALUoperandO <= regDataO;
              ALUoperandT <= Uimm;
              ALUtagO <= regTagO;
              ALUtagT <= `tagFree;
              ALUtagW <= finalTag;
              ALUnameW <= rdName;

              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;
              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            `ClassJAL: begin
              ALUen <= `Enable;
              ALUop <= `opCode;
              ALUoperandO <= regDataO;
              ALUoperandT <= Jimm;
              ALUtagO <= regTagO;
              ALUtagT <= `tagFree;
              ALUtagW <= finalTag;
              ALUnameW <= rdName;

              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;
              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            `ClassJALR: begin
              ALUen <= `Enable;
              ALUop <= `opCode;
              ALUoperandO <= regDataO;
              ALUoperandT <= imm;
              ALUtagO <= regTagO;
              ALUtagT <= `tagFree;
              ALUtagW <= finalTag;
              ALUnameW <= rdName;

              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;
              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            `ClassB:    begin
              ALUen <= `Disable;
              ALUop <= `NOP;
              ALUoperandO <= `dataFree;
              ALUoperandT <= `dataFree;
              ALUtagO <= `tagFree;
              ALUtagT <= `tagFree;
              ALUtagW <= `tagFree;
              ALUnameW <= `nameFree;

              BranchEn <= `Enable;
              BranchOperandO <= regDataO;
              BranchOperandT <= regDataT;
              BranchTagO <= regTagO;
              BranchTagT <= regTagT;
              BranchOp <= opCode;
              BranchImm <= Bimm;

              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            `ClassLD:   begin
              ALUen <= `Disable;
              ALUop <= `NOP;
              ALUoperandO <= `dataFree;
              ALUoperandT <= `dataFree;
              ALUtagO <= `tagFree;
              ALUtagT <= `tagFree;
              ALUtagW <= `tagFree;
              ALUnameW <= `nameFree;
              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;

              LSen <= `Enable;
              LSoperandO <= regDataO;
              LSoperandT <= `dataFree;
              LStagO <= regTagO;
              LStagT <= `tagFree;
              LStagW <= finalTag;
              LSnameW <= rdName;
              LSimm <= imm;
            end
            `ClassST:   begin
              ALUen <= `Disable;
              ALUop <= `NOP;
              ALUoperandO <= `dataFree;
              ALUoperandT <= `dataFree;
              ALUtagO <= `tagFree;
              ALUtagT <= `tagFree;
              ALUtagW <= `tagFree;
              ALUnameW <= `nameFree;
              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;

              LSen <= `Enable;
              LSoperandO <= regDataO;
              LSoperandT <= regDataT;
              LStagO <= regTagO;
              LStagT <= regTagT;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= Simm;
            end
            `ClassRI:   begin
              ALUen <= `Enable;
              ALUop <= `opCode;
              ALUoperandO <= regDataO;
              ALUoperandT <= imm;
              ALUtagO <= regTagO;
              ALUtagT <= `tagFree;
              ALUtagW <= finalTag;
              ALUnameW <= rdName;

              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;
              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            `ClassRR:   begin
              ALUen <= `Enable;
              ALUop <= `opCode;
              ALUoperandO <= regDataO;
              ALUoperandT <= regDataT;
              ALUtagO <= regtagO;
              ALUtagT <= regtagT;
              ALUtagW <= finalTag;
              ALUnameW <= rdName;

              BranchEn <= `Disable;
              BranchOperandO <= `dataFree;
              BranchOperandT <= `dataFree;
              BranchTagO <= `tagFree;
              BranchTagT <= `tagFree;
              BranchOp <= `NOP;
              BranchImm <= `dataFree;
              LSen <= `Disable;
              LSoperandO <= `dataFree;
              LSoperandT <= `dataFree;
              LStagO <= `tagFree;
              LStagT <= `tagFree;
              LStagW <= `tagFree;
              LSnameW <= `nameFree;
              LSimm <= `dataFree;
            end
            default:;
        endcase
    end

endmodule