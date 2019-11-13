`include "defines.v"

module ALU(
    //from RS
    input wire ALUworkEn, 
    input wire[`DataBus]    operandO, 
    input wire[`DataBus]    operandT, 
    input wire[`TagBus]     wrtTag, 
    input wire[`NameBus]    wrtName, 
    input wire[`OpBus]      opCode, 
    //to ROB
    output reg ROBen, 
    output reg[`TagBus]     ROBtagW, 
    output reg[`DataBus]    ROBdataW,
    output reg[`NameBus]    ROBnameW
    //todo: to PC
    output reg jumpEn, 
    output reg[`InstAddrBus]  jumpAddr
);

    always @ (*) begin
      if (ALUworkEn == `Enable) begin
        ROBen = `Enable;
        ROBtagW = wrtTag;
        ROBnameW = wrtName;
        jumpEn = `Disable;
        jumpAddr = `addrFree;
        case(rstOp[i])
          `ADD: ROBdataW = $signed(operandO) + $signed(operandT);
          `SUB: ROBdataW = $signed(operandO) - $signed(operandT);
          `SLL: ROBdataW = 
          `SLT: ROBdataW = $signed(operandO) < $signed(operandT) ? 1 : 0;
          `SLTU:ROBdataW = operandO < operandT ? 1 : 0;
          `XOR: ROBdataW = $signed(operandO) ^ $signed(operandT);
          `SRL: ROBdataW = 
          `SRA: ROBdataW = 
          `OR : ROBdataW = operandO || operandT;
          `AND: ROBdataW = operandO && operandT;
          `LUI: ROBdataW = operandT;
          `JAL: begin
            jumpEn = `Enable;
            jumpAddr = $signed(operandO) + $signed(operandT);
            ROBdataW = $signed(operandT) + 4;
          end
          `JALR: begin
            jumpEn = `Enable;
            jumpAddr = ($signed(operandO) + $signed(operandT)) & `JALRnum;
            //...
          end
          `AUIPC:ROBdataW = $signed(operandO) + $signed(operandT);
          default:;
          //...
        endcase
      end else begin
        ROBen = `Disable;
        ROBtagW = `tagFree;
        ROBnameW = `nameFree;
        ROBdataW = `dataFree;
        jumpEn = `Disable;
        jumpAddr = `addrFree;
      end
    end
endmodule