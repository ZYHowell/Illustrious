`include "defines.v"
//CAUTION! not test if Status == 0, WHICH SHOULD BE IN CPU

module dispatcher(
    //from decoder
    // input wire[`NameBus]        regNameO, 
    // input wire[`NameBus]        regNameT, 
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
    //from Table
    input wire [`TagRootBus]    ALUfreeTag,
    input wire [`TagRootBus]    LSfreeTag,
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
    output reg[`TagBus]         LStagW, 
    output reg[`DataBus]        LSimm, 
    output reg[`OpBus]          LSop, 
    //from ROB
    input wire ROBtagOen, 
    input wire[`DataBus] ROBdataO, 
    input wire ROBtagTen, 
    input wire[`DataBus] ROBdataT, 
    output wire dispatchEn,
    //branchtag
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum, 
    input wire[`BranchTagBus] DecBranchTag, 
    output wire[`BranchTagBus]  FinalBranchTag, 
    input wire misTaken
);

    wire [`TagBus]      finalTag;
    wire                prefix;
    wire[`TagBus] rdFinalTagO, rdFinalTagT;
    wire[`DataBus]rdFinalDataO, rdFinalDataT;
    //get the avaliable tag. 
    //choose the correct and avaliable tag
    assign prefix   = ((opClass == `ClassLD) || (opClass == `ClassST)) ? `LStagPrefix : `ALUtagPrefix;
    assign finalTag = {prefix, prefix == `ALUtagPrefix ? ALUfreeTag : LSfreeTag};

    //notice that the branch tag here should always contains that tag
    assign FinalBranchTag = bFreeEn ? (DecBranchTag ^ (1 << bFreeNum)) : DecBranchTag;

    always @(*) begin
      wrtTag = finalTag;
      wrtName = rdName;
    end

    assign rdFinalTagO = (regTagO == `tagFree) ? `tagFree : 
                         (ROBtagOen) ? `tagFree : regTagO;
    assign rdFinalDataO = (regTagO == `tagFree) ? regDataO : 
                      (ROBtagOen) ? ROBdataO : regDataO;
    assign rdFinalTagT = (regTagT == `tagFree) ? `tagFree : 
                         (ROBtagTen) ? `tagFree : regTagT;
    assign rdFinalDataT = (regTagT == `tagFree) ? regDataT : 
                      (ROBtagTen) ? ROBdataT : regDataT;

    assign dispatchEn = ALUen;
    
    //assign the tag and acquire required datas.
    always @ (*) begin
      ALUaddr = instAddr;
      BranchAddr = instAddr;
      ALUen = `Disable;
      ALUop = `NOP;
      ALUoperandO = `dataFree;
      ALUoperandT = `dataFree;
      ALUtagO = `tagFree;
      ALUtagT = `tagFree;
      ALUtagW = `tagFree;
      BranchEn = `Disable;
      BranchOperandO = `dataFree;
      BranchOperandT = `dataFree;
      BranchTagO = `tagFree;
      BranchTagT = `tagFree;
      BranchOp = `NOP;
      BranchImm = `dataFree;
      LSen = `Disable;
      LSoperandO = `dataFree;
      LSoperandT = `dataFree;
      LStagO = `tagFree;
      LStagT = `tagFree;
      LStagW = `tagFree;
      LSimm = `dataFree;
      LSop = `NOP;
      enWrt = `Disable;
      if (~misTaken) begin
        case(opClass)
          `ClassLUI: begin
            ALUen = `Enable;
            ALUop = opCode;
            ALUoperandO = rdFinalDataO;
            ALUoperandT = Uimm;
            ALUtagO = rdFinalTagO;
            ALUtagT = `tagFree;
            ALUtagW = finalTag;
            enWrt = `Enable;
          end
          `ClassAUIPC: begin
            ALUen = `Enable;
            ALUop = opCode;
            ALUoperandO = rdFinalDataO;
            ALUoperandT = Uimm;
            ALUtagO = rdFinalTagO;
            ALUtagT = `tagFree;
            ALUtagW = finalTag;
            enWrt = `Enable;
          end
          `ClassJAL: begin
            ALUen = `Enable;
            ALUop = opCode;
            ALUoperandO = instAddr;
            ALUoperandT = Jimm;
            ALUtagO = `tagFree;
            ALUtagT = `tagFree;
            ALUtagW = finalTag;
            enWrt = `Enable;
          end
          `ClassJALR: begin
            ALUen = `Enable;
            ALUop = opCode;
            ALUoperandO = rdFinalDataO;
            ALUoperandT = imm;
            ALUtagO = rdFinalTagO;
            ALUtagT = `tagFree;
            ALUtagW = finalTag;
            enWrt = `Enable;
          end
          `ClassB:    begin
            BranchEn = `Enable;
            BranchOperandO = rdFinalDataO;
            BranchOperandT = rdFinalDataT;
            BranchTagO = rdFinalTagO;
            BranchTagT = rdFinalTagT;
            BranchOp = opCode;
            BranchImm = Bimm;
          end
          `ClassLD:   begin
            LSen = `Enable;
            LSoperandO = rdFinalDataO;
            LSoperandT = `dataFree;
            LStagO = rdFinalTagO;
            LStagT = `tagFree;
            LStagW = finalTag;
            LSimm = imm;
            LSop = opCode;
            enWrt = `Enable;
          end
          `ClassST:   begin
            LSen = `Enable;
            LSoperandO = rdFinalDataO;
            LSoperandT = rdFinalDataT;
            LStagO = rdFinalTagO;
            LStagT = rdFinalTagT;
            LStagW = finalTag;
            LSimm = Simm;
            LSop = opCode;
          end
          `ClassRI:   begin
            ALUen = `Enable;
            ALUop = opCode;
            ALUoperandO = rdFinalDataO;
            ALUoperandT = imm;
            ALUtagO = rdFinalTagO;
            ALUtagT = `tagFree;
            ALUtagW = finalTag;
            enWrt = `Enable;
          end
          `ClassRR:   begin
            ALUen = `Enable;
            ALUop = opCode;
            ALUoperandO = rdFinalDataO;
            ALUoperandT = rdFinalDataT;
            ALUtagO = rdFinalTagO;
            ALUtagT = rdFinalTagT;
            ALUtagW = finalTag;
            enWrt = `Enable;
          end
        endcase
      end
    end
endmodule