`include "defines.v"

module fetch(
    input wire clk, 
    input wire rst, 
    input wire stall, 

    input wire enJump, 
    input wire[`InstAddrBus] JumpAddr, 

    input wire enBranch, 
    input wire[`InstAddrBus] BranchAddr,

    //from mem
    input wire memInstFree, 
    input wire memInstOutEn, 
    input wire[`InstBus] memInst, 
    //to mem_ctrl
    output reg[`InstAddrBus] PC, 
    //to decoder
    output reg[`InstAddrBus] instAddr, 
    output reg[`InstBus]   inst
    //to mem
    output reg instEn, 
    output ret[`InstAddrBus]
);
    always @(*) begin
      if (rst == `Enable) begin
        ret <= 
      end
    end

endmodule