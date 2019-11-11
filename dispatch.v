`include "defines.v"
//CAUTION! not test if Status == 0, WHICH SHOULD BE IN CPU
//CAUTION! THE TABLE IS BETTER TO BE PUT IN CPU RANTHER THAN DISPATCHER

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
    //get the avaliable tag. 
    //IN FACT, THIS SHOULD BE PUT IN CPU RATHER THAN DISPATCHER
    Table freetag(
        .rst(rst),
        .freeStatusALU(ALUfreeStatus), 
        .freeStatusLS(LSfreeStatus),
        .freeTagALU(ALUfreeTag), 
        .freeTagLS(LSfreeTag)
    );
    //choose the correct and avaliable tag
    assign prefix   = opClass == `ClassLD ? `LStagPrefix : `ALUtagPrefix;
    assign finalTag = {prefix, prefix == `ALUtagPrefix ? ALUfreeTag : LSfreeTag};
    //assign the tag and acquire required datas.
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