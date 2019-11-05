`include "defines.v"

module ALU(
    input wire clk, 
    input wire rst, 
    input wire stall, 

    //from dispatcher
    input wire[`DataBus]    operandO, 
    input wire[`DataBus]    operandT, 
    input wire[`TagBus]     wrtTag, 
    input wire[`NameBus]    wrtName, 
    input wire[`OpBus]      opCode, 
    //to ROB
    output wire[`TagBus]    ROBtagW, 
    output wire[`DataBus]   ROBdataW,
    output wire[`NameBus]   ROBnameW
);

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
          ROBtagW <= `tagFree;
          ROBdataW <= `datafree;
          ROBnameW <= `nameFree;
        end else begin
          ROBtagW <= wrtTag;
          ROBnameW <= wrtName;
          case(rstOp[i])
            `ADD: ROBdataW <= operandO + operandT;
            `SUB: ROBdataW <= operandO - operandT;
            //...
          endcase
        end
    end
endmodule