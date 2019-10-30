`include "defines.v"

module ALU(
    input wire clk, 
    input wire rst, 
    //from CDB
    input wire[`TagBus]     CDBTag, 
    input wire[`DataBus]    CDBData, 
    //from decoder
    input wire[`DataBus]    operandO, 
    input wire[`DataBus]    operandT, 
    input wire[`TagBus]     wrtTag, 
    input wire[`OpBus]      opCode, 
    //to ROB
    output wire[`TagBus]    CDBTagW, 
    output wire[`DataBus]   CDBDataW

)
    always @ (posedge clk) begin
        ROBTag <= rsTagW[i];
        case(rsOp[i]) begin
            `ADD: ROBData <= rsDataO + rsDataT;
            `SUB: ROBData <= rsDataO - rsDataT;
            //...
            default :;
        endcase
        //
        rsOp[i] <= `NOP;
    end
endmodule