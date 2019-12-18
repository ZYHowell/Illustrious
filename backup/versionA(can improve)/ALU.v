`include "defines.v"

module ALU(
    //from RS
    input wire ALUworkEn, 
    input wire[`DataBus]    operandO, 
    input wire[`DataBus]    operandT, 
    input wire[`TagBus]     wrtTag, 
    input wire[`OpBus]      opCode, 
    input wire[`InstAddrBus]instAddr, 
    input wire[`BranchTagBus] instBranchTag, 
    //to ROB
    output reg ROBen, 
    output reg[`TagBus]     ROBtagW, 
    output reg[`DataBus]    ROBdataW,
    output reg[`BranchTagBus] ROBbranchW, 
    //to PC
    output reg jumpEn, 
    output reg[`InstAddrBus]  jumpAddr,
    //
    input wire                  misTaken, 
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum
);

    always @ (*) begin
      if (ALUworkEn & ~misTaken) begin
        ROBen = `Enable;
        ROBtagW = wrtTag;
        jumpEn = `Disable;
        jumpAddr = `addrFree;
        ROBdataW = `dataFree;
        ROBbranchW = (bFreeEn & instBranchTag[bFreeNum]) ? (instBranchTag ^ (1 << bFreeNum)) : instBranchTag;
        case(opCode)
          `ADD: ROBdataW = $signed(operandO) + $signed(operandT);
          `SUB: ROBdataW = $signed(operandO) - $signed(operandT);
          `SLL: ROBdataW = operandO << operandT[4:0];
          `SLT: ROBdataW = $signed(operandO) < $signed(operandT) ? 1 : 0;
          `SLTU:ROBdataW = operandO < operandT ? 1 : 0;
          `XOR: ROBdataW = $signed(operandO) ^ $signed(operandT);
          `SRL: ROBdataW = operandO >> operandT[4:0];
          `SRA: ROBdataW = $signed(operandO) >>> operandT[4:0];
          `OR : ROBdataW = operandO | operandT;
          `AND: ROBdataW = operandO & operandT;
          `LUI: ROBdataW = operandT;
          `JAL: begin
            jumpEn = `Enable;
            jumpAddr = $signed(operandO) + $signed(operandT);
            ROBdataW = $signed(operandO) + 4;
          end
          `JALR: begin
            jumpEn = `Enable;
            jumpAddr = ($signed(operandO) + $signed(operandT)) & `JALRnum;
            ROBdataW = instAddr + 4;
          end
          `AUIPC:ROBdataW = $signed(operandO) + $signed(operandT);
          default:ROBdataW = ROBdataW;
        endcase
      end else begin
        ROBen = `Disable;
        ROBtagW = `tagFree;
        ROBdataW = `dataFree;
        ROBbranchW = 0;
        jumpEn = `Disable;
        jumpAddr = `addrFree;
      end
    end
endmodule