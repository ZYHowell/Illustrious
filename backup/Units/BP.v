`include "defines.v"
module BP(
  input clk, 
  input rst, 
  input rdy, 
  input wire predEn, 
  input wire[`InstAddrBus] predPC, 
  input wire[`InstBus] predInst, 
  output reg predOutEn, 
  output reg pred, //0 for not taken and 1 for taken
  output reg[`InstAddrBus] predAddr, 
  input wire BranchEn, 
  input wire BranchMisTaken
);
    reg [1:0] gshare;
    reg[1:0] misG[1:0];
    reg[1:0] corG[1:0];
    wire[`DataBus] Bimm;
    assign Bimm = {{`immFillLen{predInst[31]}}, predInst[7], predInst[30:25], predInst[11:8], 1'b0};

    always @(posedge clk) begin
        if (rst) begin
            pred <= 0;
            predAddr <= 0;
            pred <= 0;
            misG[0] <= 2'b01;
            misG[1] <= 2'b10;
            corG[0] <= 2'b00;
            corG[1] <= 2'b11;
            gshare <= 2'b00;
            //miss: 00,10->01, 01,11->10
            //corr: 00,01=>00, 10,11->11
        end else if (rdy) begin
            predOutEn <= predEn;
            pred <= gshare[1];
            predAddr <= gshare[1] ? predPC + Bimm : predPC + 4;
            if (BranchEn) begin
                gshare <= BranchMisTaken ? misG[gshare[0]] : corG[gshare[1]];
            end
        end
    end
endmodule

module BHT(
  input clk, 
  input rst, 
  input rdy, 
  input wire predEn, 
  input wire[`InstAddrBus] predPC, 
  input wire[`InstBus] predInst, 
  output reg predOutEn, 
  output reg pred, //0 for not taken and 1 for taken
  output reg[`InstAddrBus] predAddr, 
  input wire BranchEn, 
  input wire BranchMisTaken, 
  input wire[`InstAddrBus] misTakenAddr
);
    localparam BHTsize = 32;

    reg [1:0] gshare[BHTsize - 1 : 0];
    reg[1:0] misG[1:0];
    reg[1:0] corG[1:0];
    wire[`DataBus] Bimm;
    wire[4:0] misIndex, predIndex;
    assign Bimm = {{`immFillLen{predInst[31]}}, predInst[7], predInst[30:25], predInst[11:8], 1'b0};
    assign misIndex = misTakenAddr[6:2];
    assign predIndex = predAddr[6:2];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            pred <= 0;
            predAddr <= 0;
            pred <= 0;
            misG[0] <= 2'b01;
            misG[1] <= 2'b10;
            corG[0] <= 2'b00;
            corG[1] <= 2'b11;
            for (i = 0;i < BHTsize;i = i + 1)
                gshare[i] <= 2'b00;
            //miss: 00,10->01, 01,11->10
            //corr: 00,01=>00, 10,11->11
        end else if (rdy) begin
            predOutEn <= predEn;
            pred <= gshare[predIndex][1];
            predAddr <= gshare[predIndex][1] ? predPC + Bimm : predPC + 4;
            if (BranchEn) begin
                gshare[misIndex] <= BranchMisTaken ? misG[gshare[misIndex][0]] : corG[gshare[misIndex][1]];
            end
        end
    end
endmodule