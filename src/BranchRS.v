`include "defines.v"
//maybe for all rs, i need to add a "next data" and "next tag" to prevent some problems waiting to improve.
module BRsLine(
    input clk, 
    input rst, 
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
      end else if (allocEn == `Enable) begin
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
endmodule

module BranchRS(
    input rst, 
    input clk, 
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
    output reg[`InstAddrBus]    PC, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] BranchFreeStatus
);
    wire [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;

    reg allocEn[`rsSize - 1 : 0];
    reg[`DataBus]    AllocPostOperandO; 
    reg[`DataBus]    AllocPostOperandT; 
    reg[`TagBus]     AllocPostTagO; 
    reg[`TagBus]     AllocPostTagT; 
    reg[`OpBus]      AllocPostOp; 
    reg[`DataBus]    AllocPostImm; 
    reg[`InstAddrBus]AllocPostAddr; 

    wire[`DataBus] issueOperandO[`rsSize - 1 : 0];
    wire[`DataBus] issueOperandT[`rsSize - 1 : 0];
    wire[`OpBus]   issueOp[`rsSize - 1 : 0]; 
    wire[`NameBus] issueNameW[`rsSize - 1 : 0];
    wire[`DataBus] issueImm[`rsSize - 1 : 0];
    wire[`InstAddrBus] issuePC[`rsSize - 1 : 0];

    reg [`TagRootBus]   head, tail, num;
    wire canIssue;
    //the head is the head while the tail is the next;
    integer i;

    assign canIssue = ready[head];
    assign BranchFreeStatus = empty;

    generate
      genvar j;
      for (j = 0;j < `rsSize;j = j + 1) begin: ALUrsLine
        BRsLine ALUrsLine(
          .clk(clk), 
          .rst(rst), 
          //
          .enWrtO(enALUwrt), 
          .WrtTagO(ALUtag), 
          .WrtDataO(ALUdata), 
          .enWrtT(enLSwrt), 
          .WrtTagT(LStag),
          .WrtDataT(LSdata), 
          //
          .allocEn(allocEn[j]), 
          .allocOperandO(AllocPostOperandO), 
          .allocOperandT(AllocPostOperandT), 
          .allocTagO(AllocPostTagO), 
          .allocTagT(AllocPostTagT),
          .allocOp(AllocPostOp), 
          .allocImm(AllocPostImm),
          .allocPC(AllocPostAddr), 
          //
          .empty(empty[j]), 
          .ready(ready[j]), 
          .issueOperandO(issueOperandO[j]), 
          .issueOperandT(issueOperandT[j]), 
          .issueOp(issueOp[j]), 
          .issueImm(issueImm[j]), 
          .issuePC(issuePC[j])
        );
      end
    endgenerate

    //push inst to RS, each tag can be assigned to an RS
    always @(*) begin
      for (i = 0; i < `rsSize;i = i + 1) begin
        allocEn[i] = `Disable;
      end
      allocEn[tail] = BranchEn ? `Enable : `Disable;
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
        head <= 0;
        tail <= 0;
        num <= 0;
        empty <= {`rsSize{1'b1}};
      end else begin
        if (BranchEn) begin
          empty[tail]   <= 0;
          tail <= (tail == `rsSize - 1) ? 0 : tail + 1;
        end
        if (canIssue) begin
          BranchWorkEn <= `Enable;
          operandO <= issueOperandO[head];
          operandT <= issueOperandT[head];
          opCode <= issueOp[head];
          imm <= issueImm[head];
          PC <= issuePC[head];
          empty[head] <= 1;
          head <= (head == `rsSize - 1) ? 0 : head + 1;
          num <= BranchEn ? num : (num - 1);
        end else begin
          num <= BranchEn ? num + 1 : num;
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