`include "defines.v"
module BP(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire predEn, 
    input wire[`InstBus] inst, 
    input wire[`InstAddrBus] PC, 

    output reg taken, 
    output reg[`InstAddrBus] predAddr
);
    always @(posedge clk) begin
        taken <= 1;
        predAddr <= 0;
        if (predEn) begin
            taken <= 0;
            predAddr <= PC + `PCnext;
        end 
    end
endmodule