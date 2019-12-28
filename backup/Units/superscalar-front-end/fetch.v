`include "defines.v"

module fetch(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire ifStall, 

    input wire enJump, 
    input wire[`InstAddrBus] JumpAddr, 

    input wire enBranch, 
    input wire[`InstAddrBus] BranchAddr,

    //to decoder
    output reg DecEnO, 
    output reg[`InstAddrBus]  DecPCO, 
    output reg[`InstBus]      DecInstO, 
    output reg DecEnT, 
    output reg[`InstAddrBus]  DecPCT, 
    output reg[`InstBus]      DecInstT, 
    //with mem
    input wire memInstOutEn, 
    input wire[`InstBus] memInst, 

    output reg instEn, 
    output reg[`InstAddrBus] instAddrO, 
    output reg[`InstAddrBus] instAddrT, 

    input wire hitO,
    input wire[`InstBus] cacheInstO, 
    input wire hitT, 
    input wire[`InstBus] cacheInstT, 
    //branch
    input wire mistaken, 
    input wire[`InstAddrBus] trueAddr
);
    localparam StatusFree = 2'b00;
    localparam StatusWork = 2'b01;
    localparam StatusStall = 2'b10;
    localparam StatusBJ = 2'b11;

    reg[1:0] status;
    wire isBJ, cacheOisBJ, cacheTisBJ;
    reg canIssueO, canIssueT;

    assign isBJ = memInst[6];
    assign cacheOisBJ = cacheInstO[6];
    assign cacheTisBJ = cacheInstT[6];
    

    always @(*) begin
      DecEnO = `Disable;
      DecEnT = `Disable;
      if (rst) begin
        DecInstO = 0;
        DecInstT = 0;
        DecPCO = 0;
        DecPCT = 0;
      end else if (~mistaken) begin
        case (status)
          StatusFree: begin
            DecInstO = `dataFree;
            DecInstT = `dataFree;
          end
          StatusWork: begin
            if (hitO) begin
              DecEnO = ~ifStall;
              DecInstO = cacheInstO;
              DecPCO = instAddrO;
              if (hitT & ~cacheOisBJ) begin
              //else, the next status will turn to be wait prediction or wait jump result. 
                DecEnT = ~ifStall;
                DecInstT = cacheInstT;
                DecPCT = instAddrT;
              end else begin
                DecEnT = `Disable;
                DecInstT = `dataFree;
              end
            end else if (memInstOutEn) begin
              DecEnO = ~ifStall;
              DecInstO = memInst;
              DecPCO = instAddrO;
              DecEnT = `Disable;
              DecInstT = `dataFree;
            end 
          end
          StatusStall: begin
            if (~ifStall) begin
              DecEnO = `Enable;
              DecEnT = hitT;
            end 
          end
          StatusBJ: begin
          end
        endcase
      end
    end

    always @(posedge clk) begin
      if (rst) begin
        status <= StatusFree;
        instEn <= `Disable;
        instAddrO <= `addrFree;
        instAddrT <= instAddrO + `PCnext;
      end else if (rdy) begin
        if (mistaken) begin
          status <= StatusWork;
          instEn <= `Enable;
          instAddrO <= trueAddr;
          instAddrT <= trueAddr + `PCnext;
        end else begin
          case(status)
            StatusFree: begin
              instEn <= `Enable;
              status <= StatusWork;
            end
            StatusWork: begin
              if (hitO | memInstOutEn) begin
                if (~ifStall) begin
                  if (cacheOisBJ | cacheTisBJ) begin 
                    instEn <= `Disable;
                    status <= StatusBJ;
                  end else begin 
                    instEn <= `Enable;
                    if (memInstOutEn | ~hitT) begin
                      instAddrO <= instAddrO + `PCnext;
                      instAddrT <= instAddrT + `PCnext;
                    end else begin
                      instAddrO <= instAddrO + 8;
                      instAddrT <= instAddrT + 8;
                    end
                  end
                end else begin
                  instEn <= `Disable;
                  status <= StatusStall;
                end
              end else begin
                instEn <= `Disable;
              end
            end
            StatusStall: begin
              if (~ifStall) begin
                //status <= StatusWork or BJ ;
              end
            end
            StatusBJ: begin
              status <= StatusWork;
              instEn <= `Enable;
              //instAddrO <= predictedAddr;
              //instAddrT <= predictedAddr + `PCnext;
            end
          endcase
        end
      end
    end

endmodule