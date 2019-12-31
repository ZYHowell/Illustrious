`include "defines.v"

module fetch(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    //input wire rdy, 
    input wire stall, 

    input wire enJump, 
    input wire[`InstAddrBus] JumpAddr, 

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
    input wire[`InstBus] cacheInst, 
    //branch
    input wire misTaken, 
    input wire enBranch, 
    input wire[`InstAddrBus] BranchAddr
);
    localparam StatusFree = 2'b00;
    localparam StatusWork = 2'b01;
    localparam StatusWaitJ = 2'b10;
    localparam StatusStall = 2'b11;

    reg[1:0] status;
    reg StallToWaitJ;
    reg[`InstBus] _DecInst;
    reg[`InstAddrBus] _DecPC;
    wire isJ, cacheIsJ;
    wire[`DataBus] Jimm;

    assign isJ = memInst[6] & memInst[2];
    assign cacheIsJ = cacheInst[6] & cacheInst[2];
    assign Jimm = {{`UimmFillLen{DecInst[31]}}, DecInst[19:12], DecInst[20], DecInst[30:21], 1'b0};

    always @(*) begin
      DecEn = `Disable;
      DecInst = (~(hit | memInstOutEn)) ? _DecInst : 
                (hit ? cacheInst : memInst);
      if (rst == `Disable) begin
        case(status)
          StatusFree: begin
            DecInst = `dataFree;
          end
          StatusWork: begin
            DecEn = ~stall & (hit | memInstOutEn) & ~misTaken;
          end
          StatusWaitJ: begin
            DecEn = `Disable;
          end
          StatusStall: begin
            DecEn = ~stall & ~misTaken;
          end
        endcase
      end
      DecPC = DecEn ? instAddr : _DecPC;
    end

    always @(posedge clk) begin
      _DecPC <= DecPC;
      _DecInst <= DecInst;
      if (rst) begin //| ~rdy) begin
        StallToWaitJ <= 0;
        status <= StatusFree;
        instEn <= `Disable;
        instAddr <= `addrFree;
      end else if (rdy) begin
        if (misTaken) begin
          //only when not hit, the mem receives and needs to discard
          instEn <= `Enable;
          instAddr <= BranchAddr;
          status <= StatusWork;
        end else begin
          case(status)
            StatusFree: begin
              instEn <= `Enable;
              status <= StatusWork;
            end
            StatusWork: begin
              if (hit) begin
                if (~stall) begin
                  if (cacheIsJ) begin
                    instEn <= `Disable;
                    status <= StatusWaitJ;
                  end else begin
                    instEn <= `Enable;
                    instAddr <= instAddr + `PCnext;
                  end
                end else begin
                  instEn <= `Disable;
                  StallToWaitJ <= cacheIsJ;
                  status <= StatusStall;
                end
              end else if (memInstOutEn) begin
                if (~stall) begin
                  if (isJ) begin
                    instEn <= `Disable;
                    status <= StatusWaitJ;
                  end else begin
                    instEn <= `Enable;
                    instAddr <= instAddr + `PCnext;
                  end
                end else begin
                  instEn <= `Disable;
                  StallToWaitJ <= isJ;
                  status <= StatusStall;
                end
              end else begin
                instEn <= `Disable;
              end
            end
            StatusWaitJ: begin
              if (DecInst[3]) begin
                instEn <= `Enable;
                instAddr <= $signed(Jimm) + $signed(DecPC);
                status <= StatusWork;
                //deal with JAL: jump straightly
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
                status <= StallToWaitJ ? StatusWaitJ : StatusWork;
                instEn <= StallToWaitJ ? `Disable : `Enable;
                instAddr <= StallToWaitJ ? instAddr : instAddr + 4;
              end
            end
          endcase
        end
      end
    end

endmodule