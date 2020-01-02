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
    input wire pred, 
    //to the PC
    //the bResultEn is also bFreeEn
    output wire               BranchResultEn, 
    output reg[`InstAddrBus]  BranchAddr, 
    output wire[1:0]          bFreeNum, 
    output reg misTaken
);
    wire [`InstAddrBus] jmpAddr;
    wire [`InstAddrBus] nxtAddr;

    assign jmpAddr = PC + imm;
    assign nxtAddr = PC + 4;
    assign bFreeNum = bNum;

    assign BranchResultEn = BranchWorkEn;
    always @ (*) begin
      BranchAddr = `addrFree;
      misTaken = 0;
      if (BranchWorkEn) begin
        case (opCode)
          `BEQ: begin
            BranchAddr = operandO == operandT ? jmpAddr : nxtAddr;
            misTaken = (operandO == operandT) ^ pred;
          end
          `BNE: begin
            BranchAddr = operandO != operandT ? jmpAddr : nxtAddr;
            misTaken = (operandO != operandT) ^ pred;
          end
          `BLT: begin
            BranchAddr = $signed(operandO) <  $signed(operandT) ? jmpAddr : nxtAddr;
            misTaken = ($signed(operandO) <  $signed(operandT)) ^ pred;
          end
          `BGE: begin
            BranchAddr = $signed(operandO) >= $signed(operandT) ? jmpAddr : nxtAddr;
            misTaken = (operandO >= operandT) ^ pred;
          end
          `BLTU: begin
            BranchAddr = operandO <  operandT ? jmpAddr : nxtAddr;
            misTaken = (operandO < operandT) ^ pred;
          end
          `BGEU: begin
            BranchAddr = operandO >= operandT ? jmpAddr : nxtAddr;
            misTaken = (operandO >= operandT) ^ pred;
          end
        endcase
      end
    end
endmodule