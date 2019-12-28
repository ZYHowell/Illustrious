`include "defines.v"
module countNext(
  input wire now, 
  output wire nxt
);
  localparam size = 6;
  assign nxt = (now + 1 < size) ? now + 1 : 0;
endmodule
module instQ(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire stall, 
    input wire clear, 

    input wire instEnO, 
    input wire instEnT, 
    input wire[`InstBus] instO, 
    input wire[`InstBus] instT, 
    input wire[`InstAddrBus] PCO, 
    input wire[`InstAddrBus] PCT, 

    output wire ifStall, 
    output reg DecEnO, 
    output reg DecEnT, 
    output reg[`InstBus] DecInstO, 
    output reg[`InstBus] DecInstT, 
    output reg[`InstAddrBus] DecPCO, 
    output reg[`InstAddrBus] DecPCT
);
    localparam Qsize = 6;
    reg[`InstBus] insts[Qsize - 1 : 0];
    reg[`InstAddrBus] PCs[Qsize - 1 : 0];
    reg[Qsize - 1 : 0] valid;
    reg[3:0] head, tail;
    wire[3:0] nxtHead, nxtTail, nxtnxtHead;
    
    countNext nHead(.now(head), .nxt(nxtHead));
    countNext nTail(.now(tail), .nxt(nxtTail));
    countNext nnHed(.now(nxtHead), .nxt(nxtnxtHead));

    always @(posedge clk) begin
      if (rst | clear) begin
        valid <= 0;
        head <= 0;
        tail <= 0;
      end else if (rdy & ~stall) begin
        if (valid[head]) begin
          DecEnO <= `Enable;
          valid[head] <= `Invalid;
          DecInstO <= insts[head];
          DecPCO <= PCs[head];
          if (valid[nxtHead]) begin
            //dec two
            DecEnT <= `Enable;
            valid[nxtHead] <= `Invalid;
            head <= nxtnxtHead;
            DecInstT <= insts[nxtHead];
            DecPCT <= PCs[nxtHead];
          end else begin
            //dec one
            DecEnT <= `Disable;
            head <= nxtHead;
          end
        end else begin
          DecEnO <= `Disable;
          DecEnT <= `Disable;
        end

        if (instEnO) begin
          if (instEnT) begin
          end else begin
          end
        end
      end
    end
endmodule 