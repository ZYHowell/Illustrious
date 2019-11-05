`include "defines.v";
module LSbuffer(
    //input from CDB
    input wire             enCDBwrt, 
    input wire[`TagBus]    CDBTag, 
    input wire[`DataBus]   CDBData
    //input from dispatcher
    input wire BranchEn, 
    input wire[`DataBus]        LSoperandO, 
    input wire[`DataBus]        LSoperandT, 
    input wire[`TagBus]         LStagO, 
    input wire[`TagBus]         LStagT, 
    input wire[`TagBus]         LStagW, 
    input wire[`NameBus]        LSnameW, 
    input wire[`OpBus]          LSop, 
    input wire[`DataBus]        LSimm, 
    //to branchEx
    output wire[`DataBus]       operandO, 
    output wire[`DataBus]       operandT,
    output wire[`DataBus]       imm, 
    output wire[`TagBus]        wrtTag, 
    output wire[`NameBus]       wrtName, 
    output wire[`OpBus]         opCode, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] BranchFreeStatus
);

endmodule