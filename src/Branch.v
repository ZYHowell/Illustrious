`include "defines.v"

module Branch(
    //from the RS
    input wire BranchWorkEn, 
    input wire[`DataBus]    operandO, 
    input wire[`DataBus]    operandT, 
    input wire[`OpBus]      opCode, 
    input wire[`DataBus]    imm, 
    input wire[`InstAddrBus]PC, 
    input wire[1:0]         bNum, 
    //to the PC
    //the bResultEn is also bFreeEn
    output reg BranchResultEn, 
    output reg[`InstAddrBus]    BranchAddr, 
    output wire[1:0]        bFreeNum, 
    output wire misTaken
);
    wire [`InstAddrBus] jmpAddr;
    wire [`InstAddrBus] nxtAddr;

    assign jmpAddr = PC + imm;
    assign nxtAddr = PC + 4;
    assign bFreeNum = bNum;
    assign misTaken = BranchAddr == jmpAddr;

    always @ (*) begin
      if (BranchWorkEn == `Enable) begin
        BranchResultEn = `Enable;
        BranchAddr = `addrFree;
        case (opCode)
          `BEQ: BranchAddr = operandO == operandT ? jmpAddr : nxtAddr;
          `BNE: BranchAddr = operandO != operandT ? jmpAddr : nxtAddr;
          `BLT: BranchAddr = $signed(operandO) <  $signed(operandT) ? jmpAddr : nxtAddr;
          `BGE: BranchAddr = $signed(operandO) >= $signed(operandT) ? jmpAddr : nxtAddr;
          `BLTU:BranchAddr = operandO <  operandT ? jmpAddr : nxtAddr;
          `BGEU:BranchAddr = operandO >= operandT ? jmpAddr : nxtAddr;
        endcase
      end
      else begin
        BranchResultEn = `Disable;
        BranchAddr = `addrFree;
      end
    end
endmodule