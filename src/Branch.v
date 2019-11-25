//`include "defines.v"

module Branch(
    //from the RS
    input wire BranchWorkEn, 
    input wire[`DataBus]    operandO, 
    input wire[`DataBus]    operandT, 
    input wire[`OpBus]      opCode, 
    input wire[`DataBus]    imm, 
    input wire[`InstAddrBus]PC, 
    //to the PC
    output reg BranchResultEn, 
    output reg[`InstAddrBus]    BranchAddr
);
    wire [`InstAddrBus] jmpAddr;
    wire [`InstAddrBus] nxtAddr;

    assign jmpAddr = PC + imm;
    assign nxtAddr = PC + 4;

    always @ (*) begin
      if (BranchWorkEn == `Enable) begin
        BranchResultEn = `Enable;
        case (opCode)
          `BEQ: BranchAddr = operandO == operandT ? jmpAddr : nxtAddr;
          `BNE: BranchAddr = operandO != operandT ? jmpAddr : nxtAddr;
          `BLT: BranchAddr = $signed(operandO) <  $signed(operandT) ? jmpAddr : nxtAddr;
          `BGE: BranchAddr = $signed(operandO) >= $signed(operandT) ? jmpAddr : nxtAddr;
          `BLTU:BranchAddr = operandO <  operandT ? jmpAddr : nxtAddr;
          `BGEU:BranchAddr = operandO >= operandT ? jmpAddr : nxtAddr;
          default:;
        endcase
      end
      else begin
        BranchResultEn = `Disable;
        BranchAddr = `addrFree;
      end
    end
endmodule