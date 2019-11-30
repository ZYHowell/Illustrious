`include "defines.v"

module fetch(
    input wire clk, 
    input wire rst, 
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
    wire isBJ, cacheIsBJ;

    assign isBJ = memInst[6];
    assign cacheIsBJ = cacheInst[6];

    always @(posedge clk or posedge rst) begin
      if (rst == `Enable) begin
        status <= StatusFree;
        instEn <= `Disable;
        instAddr <= `addrFree;
        DecEn <= `Disable;
        DecPC <= `addrFree;
        DecInst <= `dataFree;
      end else begin
        case(status)
          StatusFree: begin
            DecEn <= `Disable;
            instEn <= `Enable;
            //instAddr <= instAddr;
            status <= StatusWork;
          end
          StatusWork: begin
            if (hit) begin
              DecInst <= cacheInst;
              if (!stall) begin
                DecEn <= `Enable;
                DecPC <= instAddr;
                DecInst <= cacheInst;
                if (cacheIsBJ) begin
                  instEn <= `Disable;
                  instAddr <= instAddr;
                  status <= StatusWaitBJ;
                end else begin
                  instEn <= `Enable;
                  instAddr <= instAddr + 4;
                  status <= StatusWork;
                end
              end else begin
                DecEn <= `Disable;
                instEn <= `Disable;
                status <= StatusStall;
              end
            end else if (memInstOutEn == `Enable) begin
              DecInst <= memInst;
              if (!stall) begin
                DecEn <= `Enable;
                DecPC <= instAddr;
                if (isBJ) begin
                  instEn <= `Disable;
                  instAddr <= instAddr;
                  status <= StatusWaitBJ;
                end else begin
                  instEn <= `Enable;
                  instAddr <= instAddr + 4;
                  status <= StatusWork;
                end
              end else begin
                DecEn <= `Disable;
                instEn <= `Disable;
                status <= StatusStall;
              end
            end else begin
              //waiting for an value
              //decoder cannot work
              DecEn <= `Disable;
              DecPC <= instAddr;
              //DecInst <= DecInst;
              instEn <= `Disable;
              //instAddr <= instAddr;
              status <= StatusWork;
            end
          end
          StatusWaitBJ: begin
            if (!stall) begin
              DecEn <= `Disable;
            end
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
              instAddr <= instAddr;
              status <= StatusWaitBJ;
            end
          end
          StatusStall: begin
            if (stall) begin
              status <= StatusStall;
              instEn <= `Disable;
            end else begin
              status <= StatusWork;
              DecEn <= `Enable;
              DecPC <= instAddr;
              instEn <= `Enable;
              instAddr <= instAddr + 4;
              //when stalls, the meminst won't change(because instEn is disable), 
              //so when the stall ends, it returns the correct answer. 
            end
          end
        endcase
      end
    end

endmodule