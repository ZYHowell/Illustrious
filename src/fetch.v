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
    output reg[`InstAddrBus] PC, 
    output reg[`InstBus]   inst, 
    //with mem
    input wire memInstFree, 
    input wire memInstOutEn, 
    input wire[`InstBus] memInst, 

    output reg instEn, 
    output reg[`InstAddrBus] instAddr
);
    localparam StatusFree = 2'b00;
    localparam StatusWork = 2'b01;
    localparam StatusWaitBJ = 2'b10;
    localparam StatusStall = 2'b11;

    reg[1:0] status;
    wire isBJ;

    assign isBJ = memInst[6];

    always @(posedge clk or posedge clk) begin
      if (rst == `Enable) begin
        status <= `IsFree;
        instEn <= `Disable;
        instAddr <= `addrFree;
        DecEn <= `Disable;
        PC <= `addrFree;
        inst <= `dataFree;
      end else begin
        case(status)
          StatusFree: begin
            DecEn <= `Disable;
            instEn <= `Disable;
            //instAddr <= instAddr;
            status <= StatusWork;
          end
          StatusWork: begin
            if (memInstOutEn) begin
              if (!stall) begin
                DecEn <= `Enable;
                PC <= instAddr;
                inst <= memInst;
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
                instEn <= `Disable;
                status <= StatusStall;
              end
            end else begin
              DecEn <= `Disable;
              PC <= instAddr;
              //inst <= inst;
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
              instAddr <= JumpAddr;
              instEn <= `Enable;
              status <= StatusWork;
            end else if (enBranch) begin
              instAddr <= BranchAddr;
              instEn <= `Enable;
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
              DecEn <= `Enable;
              PC <= instAddr;
              inst <= memInst;
              //when stalls, the meminst won't change(because instEn is disable), 
              //so when the stall ends, it returns the correct answer. 
            end
          end
        endcase
      end
    end

endmodule