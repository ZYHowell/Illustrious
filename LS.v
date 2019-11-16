`include "defines.v"

module LS(
    input wire clk, 
    input wire rst, 
    input wire stall, 

    //from lsbuffer
    input wire LSworkEn, 
    input wire[`DataBus]        operandO, 
    input wire[`DataBus]        operandT,
    input wire[`DataBus]        imm, 
    input wire[`TagBus]         wrtTag, 
    input wire[`NameBus]        wrtName, 
    input wire[`OpBus]          opCode, 

    //to lsbuffer
    output reg LSreadEn, 

    //with mem
    input wire LOutEn, 
    input wire[`DataBus]  Ldata, 
    input reg LSfree, 

    output reg dataEn, 
    output reg LSRW, 
    output reg[`DataAddrBus] dataAddr,
    output reg[1:0] LSlen, 
    output reg[`DataBus]  Sdata
    //to ROB
    output reg LS
);
    reg status;
endmodule