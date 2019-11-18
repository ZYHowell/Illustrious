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
    input wire[`InstAddrBus]    instAddr,
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
    output reg enWrt, 
    output reg[`TagBus]         wrtTag, 
    output reg[`NameBus]        wrtName, 
    //to ALUrs
    output reg                  ALUen, 
    output reg[`DataBus]        ALUoperandO, 
    output reg[`DataBus]        ALUoperandT, 
    output reg[`TagBus]         ALUtagO, 
    output reg[`TagBus]         ALUtagT,
    output reg[`TagBus]         ALUtagW, 
    output reg[`NameBus]        ALUnameW, 
    output reg[`OpBus]          ALUop, 
    output reg[`InstAddrBus]    ALUaddr, 
    //to BranchRS
    output reg BranchEn, 
    output reg[`DataBus]        BranchOperandO, 
    output reg[`DataBus]        BranchOperandT, 
    output reg[`TagBus]         BranchTagO, 
    output reg[`TagBus]         BranchTagT, 
    output reg[`OpBus]          BranchOp, 
    output reg[`DataBus]        BranchImm, 
    output reg[`InstAddrBus]    BranchAddr, 
    //to LSbuffer
    output reg LSen, 
    output reg[`DataBus]        LSoperandO, 
    output reg[`DataBus]        LSoperandT, 
    output reg[`TagBus]         LStagO, 
    output reg[`TagBus]         LStagT,
    output reg[`OpBus]          LStagW, 
    output reg[`NameBus]        LSnameW, 
    output reg[`DataBus]        LSimm, 
    output reg[`OpBus]          LSop

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
    assign ALUaddr = instAddr;
    assign BranchAddr = instAddr;
    //assign the tag and acquire required datas.
    always @ (posedge clk or posedge rst) begin
      if (rst == `Enable) begin
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
        LSen <= `Disable;
        LSoperandO <= `dataFree;
        LSoperandT <= `dataFree;
        LStagO <= `tagFree;
        LStagT <= `tagFree;
        LStagW <= `tagFree;
        LSnameW <= `nameFree;
        LSimm <= `dataFree;
        LSop <= `NOP;
      end else begin
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
            LSop <= `NOP;
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
            LSop <= `NOP;
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
            LSop <= `NOP;
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
            LSop <= `NOP;
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
            LSop <= `NOP;
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
            LSop <= opCode;
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
            LSop <= opCode;
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
            LSop <= `NOP;
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
            LSop <= `NOP;
          end
          default:;
        endcase
      end
    end
endmodule