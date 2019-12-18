`include "defines.v"

module fetch(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire stall, 

    input wire enJump, 
    input wire[`InstAddrBus] JumpAddr, 

    input wire mistaken, 
    input wire[`InstAddrBus] BranchAddr,

    //to decoder
    output reg DecEn, 
    output reg[`InstAddrBus] DecPC, 
    output reg[`InstBus]   DecInst, 
    //with mem
    output reg instEn, 
    output reg[`InstAddrBus] instAddr,
    input wire memInstOutEn, 
    input wire[`InstBus] memInst, 
    input wire hit,
    input wire[`InstBus] cacheInst, 
    //with BP
    output wire predEn, 
    input wire[`InstAddrBus] predAddr
);
    localparam StatusFree = 2'b00;
    localparam StatusWork = 2'b01;
    localparam StatusWaitBJ = 2'b10;
    localparam StatusStall = 2'b11;

    reg[1:0] status;
    reg StallToWaitBJ;
    reg[`InstBus] _decInst;
    reg isJ;
    wire isBJ, cacheIsBJ;

    assign isBJ = memInst[6];
    assign cacheIsBJ = cacheInst[6];

    assign predEn = (hit & ~cacheInst[2]) | (memInstOutEn & ~memInst[2]);

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
      if (rst) begin
        StallToWaitBJ <= 0;
        status <= StatusFree;
        instEn <= `Disable;
        instAddr <= `addrFree;
      end else if (rdy) begin
        if (mistaken) begin
          StallToWaitBJ <= 0;
          status <= StatusFree;
          instEn <= `Enable;
          instAddr <= BranchAddr;
        end else begin
          case(status)
            StatusFree: begin
              instEn <= `Enable;
              status <= StatusWork;
            end
            StatusWork: begin
              if (hit) begin
                isJ <= cacheInst[2];
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
                isJ <= memInst[2];
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
                isJ <= 0;
                instEn <= `Disable;
              end
            end
            StatusWaitBJ: begin
              if (~isJ) begin
                instEn <= `Enable;
                instAddr <= predAddr;
                status <= StatusWork;
              end else if (enJump) begin
                instEn <= `Enable;
                instAddr <= JumpAddr;
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
    end

endmodule