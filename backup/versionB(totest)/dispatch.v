`include "defines.v"

module dispatcher(
    //from decoder
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
    output reg[`TagBus]         LStagW, 
    output reg[`NameBus]        LSnameW, 
    output reg[`DataBus]        LSimm, 
    output reg[`OpBus]          LSop

);

    wire [`TagBus]      finalTag;
    wire                prefix;
    //get the avaliable tag. 
    //choose the correct and avaliable tag
    assign prefix   = ((opClass == `ClassLD) || (opClass == `ClassST)) ? `LStagPrefix : `ALUtagPrefix;
    assign finalTag = {prefix, prefix == `ALUtagPrefix ? ALUfreeTag : LSfreeTag};

    always @(*) begin
      wrtTag = finalTag;
      wrtName = rdName;
    end

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
      ALUnameW = `nameFree;
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
      LSnameW = `nameFree;
      LSimm = `dataFree;
      LSop = `NOP;
      enWrt = `Disable;
      case(opClass)
        `ClassLUI: begin
          ALUen = `Enable;
          ALUop = opCode;
          ALUoperandO = regDataO;
          ALUoperandT = Uimm;
          ALUtagO = regTagO;
          ALUtagT = `tagFree;
          ALUtagW = finalTag;
          ALUnameW = rdName;
          enWrt = `Enable;
        end
        `ClassAUIPC: begin
          ALUen = `Enable;
          ALUop = opCode;
          ALUoperandO = regDataO;
          ALUoperandT = Uimm;
          ALUtagO = regTagO;
          ALUtagT = `tagFree;
          ALUtagW = finalTag;
          ALUnameW = rdName;
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
          ALUnameW = rdName;
          enWrt = `Enable;
        end
        `ClassJALR: begin
          ALUen = `Enable;
          ALUop = opCode;
          ALUoperandO = regDataO;
          ALUoperandT = imm;
          ALUtagO = regTagO;
          ALUtagT = `tagFree;
          ALUtagW = finalTag;
          ALUnameW = rdName;
          enWrt = `Enable;
        end
        `ClassB:    begin
          BranchEn = `Enable;
          BranchOperandO = regDataO;
          BranchOperandT = regDataT;
          BranchTagO = regTagO;
          BranchTagT = regTagT;
          BranchOp = opCode;
          BranchImm = Bimm;
        end
        `ClassLD:   begin
          LSen = `Enable;
          LSoperandO = regDataO;
          LSoperandT = `dataFree;
          LStagO = regTagO;
          LStagT = `tagFree;
          LStagW = finalTag;
          LSnameW = rdName;
          LSimm = imm;
          LSop = opCode;
          enWrt = `Enable;
        end
        `ClassST:   begin
          LSen = `Enable;
          LSoperandO = regDataO;
          LSoperandT = regDataT;
          LStagO = regTagO;
          LStagT = regTagT;
          LStagW = finalTag;
          LSnameW = `nameFree;
          LSimm = Simm;
          LSop = opCode;
        end
        `ClassRI:   begin
          ALUen = `Enable;
          ALUop = opCode;
          ALUoperandO = regDataO;
          ALUoperandT = imm;
          ALUtagO = regTagO;
          ALUtagT = `tagFree;
          ALUtagW = finalTag;
          ALUnameW = rdName;
          enWrt = `Enable;
        end
        `ClassRR:   begin
          ALUen = `Enable;
          ALUop = opCode;
          ALUoperandO = regDataO;
          ALUoperandT = regDataT;
          ALUtagO = regTagO;
          ALUtagT = regTagT;
          ALUtagW = finalTag;
          ALUnameW = rdName;
          enWrt = `Enable;
        end
        default:;
      endcase
    end
endmodule