`include "defines.v"

module fetch(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire stall, 

    input wire enJump, 
    input wire[`InstAddrBus] JumpAddr, 

    input wire enBranch, 
    input wire[`InstAddrBus] BranchAddr,

    //to decoder
    output reg DecEn, 
    output reg[`InstAddrBus] DecPC, 
    output reg[`InstBus]   DecInst, 
    //with mem
    input wire memInstOutEn, 
    input wire[`InstBus] memInst, 

    output reg instEn, 
    output reg[`InstAddrBus] instAddr,

    input wire hit,
    input wire[`InstBus] cacheInst
);
    localparam StatusFree = 2'b00;
    localparam StatusWork = 2'b01;
    localparam StatusWaitBJ = 2'b10;
    localparam StatusStall = 2'b11;

    reg[1:0] status;
    reg StallToWaitBJ;
    reg[`InstBus] _decInst;
    wire isBJ, cacheIsBJ;

    assign isBJ = memInst[6];
    assign cacheIsBJ = cacheInst[6];

    always @(*) begin
      DecEn = `Disable;
      DecPC = instAddr;
      DecInst = (~(hit | memInstOutEn)) ? DecInst : 
                (hit ? cacheInst : memInst);
      if (rst == `Disable) begin
        case(status)
          StatusFree: begin
            DecInst = `dataFree;
          end
          StatusWork: begin
            DecEn = (~stall & (hit | memInstOutEn)) ? `Enable : `Disable;
          end
          StatusWaitBJ: begin
            DecEn = `Disable;
          end
          StatusStall: begin
            DecEn = stall ? `Disable : `Enable;
          end
        endcase
      end
    end

    always @(posedge clk) begin
      if (rst | ~rdy) begin
        StallToWaitBJ <= 0;
        status <= StatusFree;
        instEn <= `Disable;
        instAddr <= `addrFree;
      end else begin
        case(status)
          StatusFree: begin
            instEn <= `Enable;
            status <= StatusWork;
          end
          StatusWork: begin
            if (hit) begin
              if (~stall) begin
                if (cacheIsBJ) begin
                  instEn <= `Disable;
                  status <= StatusWaitBJ;
                end else begin
                  instEn <= `Enable;
                  instAddr <= instAddr + `PCnext;
                end
              end else begin
                instEn <= `Disable;
                StallToWaitBJ <= cacheIsBJ;
                status <= StatusStall;
              end
            end else if (memInstOutEn) begin
              if (~stall) begin
                if (isBJ) begin
                  instEn <= `Disable;
                  status <= StatusWaitBJ;
                end else begin
                  instEn <= `Enable;
                  instAddr <= instAddr + `PCnext;
                end
              end else begin
                instEn <= `Disable;
                StallToWaitBJ <= isBJ;
                status <= StatusStall;
              end
            end else begin
              instEn <= `Disable;
            end
          end
          StatusWaitBJ: begin
            if (enJump) begin
              instEn <= `Enable;
              instAddr <= JumpAddr;
              status <= StatusWork;
            end else if (enBranch) begin
              instEn <= `Enable;
              instAddr <= BranchAddr;
              status <= StatusWork;
            end else begin
              instEn <= `Disable;
            end
          end
          StatusStall: begin
            if (stall) begin
              instEn <= `Disable;
            end else begin
              status <= StallToWaitBJ ? StatusWaitBJ : StatusWork;
              instEn <= StallToWaitBJ ? `Disable : `Enable;
              instAddr <= StallToWaitBJ ? instAddr : instAddr + 4;
            end
          end
        endcase
      end
    end

endmodule