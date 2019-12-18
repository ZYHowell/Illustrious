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
    //to regfile(rename the rd)
    output reg enWrt, 
    output reg[`TagBus]         wrtTag, 
    output reg[`NameBus]        wrtName,
    //from ROB
    input wire ROBtagOen, 
    input wire ROBtagTen, 
    input wire[`DataBus] ROBdataO, 
    input wire[`DataBus] ROBdataT, 
    input wire [`TagBus] ROBfreeTag,
    //to ALUrs
    output reg ALUen, 
    output reg BranchEn, 
    output reg LSen, 
    //sources
    output reg[`DataBus]        operandO, 
    output reg[`DataBus]        operandT, 
    output reg[`TagBus]         tagO, 
    output reg[`TagBus]         tagT,
    output reg[`NameBus]        nameW, 
    output reg[`DataBus]        immO, 
    output reg[`OpBus]          op, 
    output reg[`InstAddrBus]    Addr, 
    output reg[`TagBus]         ROBloc,  
    //to ROB
    output reg dispatchEn
);
    wire[`TagBus] rdFinalTagO, rdFinalTagT;
    wire[`DataBus]rdFinalDataO, rdFinalDataT;
    
    always @(*) begin
      wrtTag = ROBfreeTag;
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
    
    //assign the tag and acquire required datas.
    always @ (*) begin
      Addr = instAddr;
      ROBloc = ROBfreeTag;
      //
      ALUen = `Disable;
      BranchEn = `Disable;
      LSen = `Disable;
      enWrt = `Disable;
      dispatchEn = 0;
      operandO = `dataFree; 
      operandT = `dataFree; 
      tagO = `tagFree; 
      tagT = `tagFree;
      nameW = `nameFree; 
      immO = `dataFree; 
      op = `NOP; 
      case(opClass)
        `ClassLUI: begin
          dispatchEn = 1;
          ALUen = `Enable;
          op = opCode;
          operandO = rdFinalDataO;
          operandT = Uimm;
          tagO = rdFinalTagO;
          tagT = `tagFree;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassAUIPC: begin
          dispatchEn = 1;
          ALUen = `Enable;
          op = opCode;
          operandO = rdFinalDataO;
          operandT = Uimm;
          tagO = rdFinalTagO;
          tagT = `tagFree;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassJAL: begin
          dispatchEn = 1;
          ALUen = `Enable;
          op = opCode;
          operandO = instAddr;
          operandT = Jimm;
          tagO = `tagFree;
          tagT = `tagFree;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassJALR: begin
          dispatchEn = 1;
          ALUen = `Enable;
          op = opCode;
          operandO = rdFinalDataO;
          operandT = imm;
          tagO = rdFinalTagO;
          tagT = `tagFree;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassB:    begin
          dispatchEn = 1;
          BranchEn = `Enable;
          operandO = rdFinalDataO;
          operandT = rdFinalDataT;
          tagO = rdFinalTagO;
          tagT = rdFinalTagT;
          op = opCode;
          immO = Bimm;
        end
        `ClassLD:   begin
          dispatchEn = 1;
          LSen = `Enable;
          operandO = rdFinalDataO;
          operandT = `dataFree;
          tagO = rdFinalTagO;
          tagT = `tagFree;
          nameW = rdName;
          immO = imm;
          op = opCode;
          enWrt = `Enable;
        end
        `ClassST:   begin
          dispatchEn = 1;
          LSen = `Enable;
          operandO = rdFinalDataO;
          operandT = rdFinalDataT;
          tagO = rdFinalTagO;
          tagT = rdFinalTagT;
          nameW = `nameFree;
          immO = Simm;
          op = opCode;
        end
        `ClassRI:   begin
          dispatchEn = 1;
          ALUen = `Enable;
          op = opCode;
          operandO = rdFinalDataO;
          operandT = imm;
          tagO = rdFinalTagO;
          tagT = `tagFree;
          nameW = rdName;
          enWrt = `Enable;
        end
        `ClassRR:   begin
          dispatchEn = 1;
          ALUen = `Enable;
          op = opCode;
          operandO = rdFinalDataO;
          operandT = rdFinalDataT;
          tagO = rdFinalTagO;
          tagT = rdFinalTagT;
          nameW = rdName;
          enWrt = `Enable;
        end
        default:dispatchEn = 0;
      endcase
    end
endmodule