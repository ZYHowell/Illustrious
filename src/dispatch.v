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
    output reg ALUen, 
    output reg BranchEn, 
    output reg LSen, 
    output reg[`DataBus] operandO, 
    output reg[`DataBus] operandT, 
    output reg[`TagBus]  tagO, 
    output reg[`TagBus]  tagT,
    output reg[`TagBus]  tagW, 
    output reg[`NameBus] nameW, 
    output reg[`OpBus]   op, 
    output reg[`InstAddrBus] addr, 
    output reg[`DataBus] Imm, 
    output wire alreadyRdy
);

    wire [`TagBus]      finalTag;
    wire                prefix;
    //get the avaliable tag. 
    //choose the correct and avaliable tag
    assign prefix   = ((opClass == `ClassLD) || (opClass == `ClassST)) ? `LStagPrefix : `ALUtagPrefix;
    assign finalTag = {prefix, prefix == `ALUtagPrefix ? ALUfreeTag : LSfreeTag};
    assign alreadyRdy = (tagO == `tagFree) & (tagT == `tagFree);

    always @(*) begin
      wrtTag = finalTag;
      wrtName = rdName;
    end

    //assign the tag and acquire required datas.
    always @ (*) begin
      addr = instAddr;
      ALUen = `Disable;
      BranchEn = `Disable;
      op = `NOP;
      operandO = `dataFree;
      operandT = `dataFree;
      tagO = `tagFree;
      tagT = `tagFree;
      tagW = `tagFree;
      nameW = `nameFree;
      Imm = `dataFree;
      LSen = `Disable;
      
      enWrt = `Disable;
      case(opClass)
        `ClassLUI: begin
          ALUen = `Enable;
          op = opCode;
          operandO = regDataO;
          operandT = Uimm;
          tagO = regTagO;
          tagT = `tagFree;
          tagW = finalTag;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassAUIPC: begin
          ALUen = `Enable;
          op = opCode;
          operandO = regDataO;
          operandT = Uimm;
          tagO = regTagO;
          tagT = `tagFree;
          tagW = finalTag;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassJAL: begin
          ALUen = `Enable;
          op = opCode;
          operandO = instAddr;
          operandT = Jimm;
          tagO = `tagFree;
          tagT = `tagFree;
          tagW = finalTag;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassJALR: begin
          ALUen = `Enable;
          op = opCode;
          operandO = regDataO;
          operandT = imm;
          tagO = regTagO;
          tagT = `tagFree;
          tagW = finalTag;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassB:    begin
          BranchEn = `Enable;
          operandO = regDataO;
          operandT = regDataT;
          tagO = regTagO;
          tagT = regTagT;
          op = opCode;
          Imm = Bimm;
        end
        `ClassLD:   begin
          LSen = `Enable;
          operandO = regDataO;
          operandT = `dataFree;
          tagO = regTagO;
          tagT = `tagFree;
          tagW = finalTag;
          nameW = rdName;
          Imm = imm;
          op = opCode;
          enWrt = `Enable;
        end
        `ClassST:   begin
          LSen = `Enable;
          operandO = regDataO;
          operandT = regDataT;
          tagO = regTagO;
          tagT = regTagT;
          tagW = finalTag;
          nameW = `nameFree;
          Imm = Simm;
          op = opCode;
        end
        `ClassRI:   begin
          ALUen = `Enable;
          op = opCode;
          operandO = regDataO;
          operandT = imm;
          tagO = regTagO;
          tagT = `tagFree;
          tagW = finalTag;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassRR:   begin
          ALUen = `Enable;
          op = opCode;
          operandO = regDataO;
          operandT = regDataT;
          tagO = regTagO;
          tagT = regTagT;
          tagW = finalTag;
          nameW = rdName;
          enWrt = `Enable;
        end
        default:;
      endcase
    end
endmodule