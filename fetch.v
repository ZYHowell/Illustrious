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
    input wire[`InstBus] memInst, 
    //to mem_ctrl
    output wire[`InstAddrBus] PC, 
    //to decoder
    output wire[`InstAddrBus] instAddr, 
    output wire[`InstBus]   inst

);

endmodule