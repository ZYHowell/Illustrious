`include "defines.v"
//maybe for all rs, i need to add a "next data" and "next tag" to prevent some problems waiting to improve.
module BRsLine(
    input clk, 
    input rst, 
    input rdy, 
    //
    input wire enWrtO, 
    input wire[`TagBus] WrtTagO, 
    input wire[`DataBus]  WrtDataO, 
    input wire enWrtT, 
    input wire[`TagBus] WrtTagT,
    input wire[`DataBus] WrtDataT, 
    //
    input wire allocEn, 
    input wire[`DataBus]    allocOperandO, 
    input wire[`DataBus]    allocOperandT, 
    input wire[`TagBus]     allocTagO, 
    input wire[`TagBus]     allocTagT,
    input wire[`OpBus]      allocOp, 
    input wire[`DataBus]    allocImm, 
    input wire[`InstAddrBus]allocPC, 
    //
    input wire empty, 
    output wire ready, 
    output wire[`DataBus] issueOperandO, 
    output wire[`DataBus] issueOperandT, 
    output wire[`OpBus]   issueOp, 
    output wire[`DataBus] issueImm, 
    output wire[`InstAddrBus] issuePC
    //the imm is pc in alu, is imm in ls; so bucket branchRS for it contains both
);
    reg[`TagBus]  rsTagO, rsTagT;
    reg[`DataBus] rsDataO, rsDataT;
    reg[`InstAddrBus] rsPC;
    reg[`OpBus]   rsOp;
    reg[`DataBus] rsImm;
    wire[`TagBus] nxtPosTagO, nxtPosTagT;
    wire[`DataBus] nxtPosDataO, nxtPosDataT;

    assign ready = ~empty & (nxtPosTagO == `tagFree) & (nxtPosTagT == `tagFree);
    assign issueOperandO = (nxtPosTagO == `tagFree) ? nxtPosDataO : rsDataO;
    assign issueOperandT = (nxtPosTagT == `tagFree) ? nxtPosDataT : rsDataT;
    assign issueOp = rsOp;
    assign issueImm = rsImm;
    assign issuePC = rsPC;
    nxtPosCal nxtPosCalO(
      .enWrtO(enWrtO), 
      .WrtTagO(WrtTagO), 
      .WrtDataO(WrtDataO), 
      .enWrtT(enWrtT), 
      .WrtTagT(WrtTagT), 
      .WrtDataT(WrtDataT), 
      .dataNow(rsDataO), 
      .tagNow(rsTagO), 
      .dataNxtPos(nxtPosDataO),
      .tagNxtPos(nxtPosTagO)
    );
    nxtPosCal nxtPosCalT(
      .enWrtO(enWrtO), 
      .WrtTagO(WrtTagO), 
      .WrtDataO(WrtDataO), 
      .enWrtT(enWrtT), 
      .WrtTagT(WrtTagT), 
      .WrtDataT(WrtDataT), 
      .dataNow(rsDataT), 
      .tagNow(rsTagT), 
      .dataNxtPos(nxtPosDataT),
      .tagNxtPos(nxtPosTagT)
    );
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        rsTagO  <= `tagFree;
        rsTagT  <= `tagFree;
        rsDataO <= `dataFree;
        rsDataT <= `dataFree;
        rsPC    <= `addrFree;
        rsImm   <= `dataFree;
        rsOp    <= `NOP;
      end else if (rdy) begin
        if (allocEn == `Enable) begin
          rsTagO  <= allocTagO;
          rsTagT  <= allocTagT;
          rsDataO <= allocOperandO;
          rsDataT <= allocOperandT;
          rsPC    <= allocPC;
          rsImm   <= allocImm;
          rsOp    <= allocOp;
        end else begin
          rsTagO  <= nxtPosTagO;
          rsTagT  <= nxtPosTagT;
          rsDataO <= nxtPosDataO;
          rsDataT <= nxtPosDataT;
        end
      end
    end
endmodule

module BranchRS(
    input rst, 
    input clk, 
    input wire rdy, 
    //from ALU and LS
    input wire enALUwrt, 
    input wire[`TagBus] ALUtag, 
    input wire[`DataBus]  ALUdata, 
    input wire enLSwrt, 
    input wire[`TagBus] LStag,
    input wire[`DataBus] LSdata, 
    //input from dispatcher
    input wire BranchEn, 
    input wire[`DataBus]        BranchOperandO, 
    input wire[`DataBus]        BranchOperandT, 
    input wire[`TagBus]         BranchTagO, 
    input wire[`TagBus]         BranchTagT, 
    input wire[`OpBus]          BranchOp, 
    input wire[`DataBus]        BranchImm, 
    input wire[`InstAddrBus]    BranchPC, 
    //to branchEx
    output reg BranchWorkEn, 
    output reg[`DataBus]        operandO, 
    output reg[`DataBus]        operandT, 
    output reg[`DataBus]        imm, 
    output reg[`OpBus]          opCode, 
    output reg[`InstAddrBus]    PC
);
    wire ready;
    reg empty;

    reg allocEn;
    reg[`DataBus]    AllocPostOperandO; 
    reg[`DataBus]    AllocPostOperandT; 
    reg[`TagBus]     AllocPostTagO; 
    reg[`TagBus]     AllocPostTagT; 
    reg[`OpBus]      AllocPostOp; 
    reg[`DataBus]    AllocPostImm; 
    reg[`InstAddrBus]AllocPostAddr; 

    wire[`DataBus] issueOperandO;
    wire[`DataBus] issueOperandT;
    wire[`OpBus]   issueOp; 
    wire[`NameBus] issueNameW;
    wire[`DataBus] issueImm;
    wire[`InstAddrBus] issuePC;

    assign canIssue = ready;

    BRsLine ALUrsLine(
      .clk(clk), 
      .rst(rst), 
      .rdy(rdy), 
      //
      .enWrtO(enALUwrt), 
      .WrtTagO(ALUtag), 
      .WrtDataO(ALUdata), 
      .enWrtT(enLSwrt), 
      .WrtTagT(LStag),
      .WrtDataT(LSdata), 
      //
      .allocEn(allocEn), 
      .allocOperandO(AllocPostOperandO), 
      .allocOperandT(AllocPostOperandT), 
      .allocTagO(AllocPostTagO), 
      .allocTagT(AllocPostTagT),
      .allocOp(AllocPostOp), 
      .allocImm(AllocPostImm),
      .allocPC(AllocPostAddr), 
      //
      .empty(empty), 
      .ready(ready), 
      .issueOperandO(issueOperandO), 
      .issueOperandT(issueOperandT), 
      .issueOp(issueOp), 
      .issueImm(issueImm), 
      .issuePC(issuePC)
    );

    //push inst to RS, each tag can be assigned to an RS
    always @(*) begin
      allocEn = BranchEn;
      AllocPostImm = BranchImm;
      AllocPostAddr = BranchPC;
      AllocPostOp = BranchOp;
      AllocPostOperandO = BranchOperandO;
      AllocPostOperandT = BranchOperandT;
      AllocPostTagO = BranchTagO;
      AllocPostTagT = BranchTagT;
    end

    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        empty <= 1;
        BranchWorkEn <= `Disable; 
        operandO <= `dataFree; 
        operandT <= `dataFree;
        imm <= `dataFree;
        opCode <= `NOP; 
        PC <= `addrFree;
      end else if (rdy) begin
        empty <= ~BranchEn;
        if (canIssue) begin
          BranchWorkEn <= `Enable;
          operandO <= issueOperandO;
          operandT <= issueOperandT;
          opCode <= issueOp;
          imm <= issueImm;
          PC <= issuePC;
          empty <= 1;
        end else begin
          BranchWorkEn <= `Disable;
          operandO <= `dataFree;
          operandT <= `dataFree;
          opCode <= `NOP;
          PC <= `addrFree;
          imm <= `dataFree;
        end
      end
    end
endmodule