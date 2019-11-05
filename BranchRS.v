`include "defines.v";
module BranchRS(
    //input from CDB
    input wire             enCDBwrt, 
    input wire[`TagBus]    CDBTag, 
    input wire[`DataBus]   CDBData
    //input from dispatcher
    input wire BranchEn, 
    input wire[`DataBus]        BranchOperandO, 
    input wire[`DataBus]        BranchOperandT, 
    input wire[`TagBus]         BranchTagO, 
    input wire[`TagBus]         BranchTagT, 
    input wire[`OpBus]          BranchOp, 
    input wire[`DataBus]        BranchImm, 
    //to branchEx
    output wire[`DataBus]       operandO, 
    output wire[`DataBus]       operandT, 
    output wire[`DataBus]       imm, 
    output wire[`OpBus]         opCode, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] BranchFreeStatus
);

endmodule