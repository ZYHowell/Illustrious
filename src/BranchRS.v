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
    input wire[`BranchTagBus] allocBranchTag, 
    //
    input wire empty, 
    output wire ready, 
    output wire[`DataBus] issueOperandO, 
    output wire[`DataBus] issueOperandT, 
    output wire[`OpBus]   issueOp, 
    output wire[`DataBus] issueImm, 
    output wire[`InstAddrBus] issuePC,
    //the imm is pc in alu, is imm in ls; so bucket branchRS for it contains both
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum
);
    reg[`TagBus]  rsTagO, rsTagT;
    reg[`DataBus] rsDataO, rsDataT;
    reg[`InstAddrBus] rsPC;
    reg[`OpBus]   rsOp;
    reg[`DataBus] rsImm;
    reg[`BranchTagBus] BranchTag;
    wire[`TagBus] nxtPosTagO, nxtPosTagT;
    wire[`DataBus] nxtPosDataO, nxtPosDataT;
    wire[`BranchTagBus] nxtPosBranchTag;

    assign ready = (~empty & (nxtPosTagO == `tagFree) & (nxtPosTagT == `tagFree)) && !(nxtPosBranchTag);
    assign issueOperandO = (nxtPosTagO == `tagFree) ? nxtPosDataO : rsDataO;
    assign issueOperandT = (nxtPosTagT == `tagFree) ? nxtPosDataT : rsDataT;
    assign issueOp = rsOp;
    assign issueImm = rsImm;
    assign issuePC = rsPC;
    assign nxtPosBranchTag = (bFreeEn & BranchTag[bFreeNum]) ? (BranchTag ^ (1 << bFreeNum)) : BranchTag;

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
        BranchTag <= 0;
      end else if (allocEn == `Enable) begin
        rsTagO  <= allocTagO;
        rsTagT  <= allocTagT;
        rsDataO <= allocOperandO;
        rsDataT <= allocOperandT;
        rsPC    <= allocPC;
        rsImm   <= allocImm;
        rsOp    <= allocOp;
        BranchTag <= allocBranchTag;
      end else begin
        rsTagO  <= nxtPosTagO;
        rsTagT  <= nxtPosTagT;
        rsDataO <= nxtPosDataO;
        rsDataT <= nxtPosDataT;
        BranchTag <= nxtPosBranchTag;
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
    input wire[`BranchTagBus]   BranchTag, 
    //to branchEx
    output reg BranchWorkEn, 
    output reg[`DataBus]        operandO, 
    output reg[`DataBus]        operandT, 
    output reg[`DataBus]        imm, 
    output reg[`OpBus]          opCode, 
    output reg[`InstAddrBus]    PC,
    output reg[1:0]             bNum, 
    //from branch
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum, 
    input wire misTaken
);
    wire [`branchRsSize - 1 : 0] ready;
    reg [`branchRsSize - 1 : 0] empty;

    reg[`branchRsSize - 1 : 0] allocEn;
    reg[`DataBus]    AllocPostOperandO; 
    reg[`DataBus]    AllocPostOperandT; 
    reg[`TagBus]     AllocPostTagO; 
    reg[`TagBus]     AllocPostTagT; 
    reg[`OpBus]      AllocPostOp; 
    reg[`DataBus]    AllocPostImm; 
    reg[`InstAddrBus]AllocPostAddr; 
    reg[`BranchTagBus] AllocBranchTag;

    wire[`DataBus] issueOperandO[`branchRsSize - 1 : 0];
    wire[`DataBus] issueOperandT[`branchRsSize - 1 : 0];
    wire[`OpBus]   issueOp[`branchRsSize - 1 : 0]; 
    wire[`NameBus] issueNameW[`branchRsSize - 1 : 0];
    wire[`DataBus] issueImm[`branchRsSize - 1 : 0];
    wire[`InstAddrBus] issuePC[`branchRsSize - 1 : 0];

    reg [1:0]   head, tail;
    wire canIssue;
    //the head is the head while the tail is the next;
    integer i;

    assign canIssue = ready[head];

    generate
      genvar j;
      for (j = 0;j < `branchRsSize;j = j + 1) begin: BrsLine
        BRsLine BrsLine(
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
          .allocBranchTag(AllocBranchTag), 
          //
          .empty(empty[j]), 
          .ready(ready[j]), 
          .issueOperandO(issueOperandO[j]), 
          .issueOperandT(issueOperandT[j]), 
          .issueOp(issueOp[j]), 
          .issueImm(issueImm[j]), 
          .issuePC(issuePC[j]),
          //
          .bFreeEn(bFreeEn), 
          .bFreeNum(bFreeNum) 
        );
      end
    endgenerate

    //push inst to RS, each tag can be assigned to an RS
    always @(*) begin
      allocEn = 0;
      allocEn[tail] = BranchEn;
      AllocPostImm = BranchImm;
      AllocPostAddr = BranchPC;
      AllocPostOp = BranchOp;
      AllocPostOperandO = BranchOperandO;
      AllocPostOperandT = BranchOperandT;
      AllocPostTagO = BranchTagO;
      AllocPostTagT = BranchTagT;
      AllocBranchTag = BranchTag;
    end

    always @ (posedge clk) begin
      if (rst | misTaken) begin
        head <= 0;
        tail <= 0;
        empty <= {`branchRsSize{1'b1}};
        BranchWorkEn <= `Disable; 
        operandO <= `dataFree; 
        operandT <= `dataFree;
        imm <= `dataFree;
        opCode <= `NOP; 
        PC <= `addrFree;
        bNum <= 0;
      end else begin
        bNum <= head;
        if (BranchEn) begin
          empty[tail] <= 0;
          tail <= (tail == `branchRsSize - 1) ? 0 : tail + 1;
        end
        if (canIssue) begin
          BranchWorkEn <= `Enable;
          operandO <= issueOperandO[head];
          operandT <= issueOperandT[head];
          opCode <= issueOp[head];
          imm <= issueImm[head];
          PC <= issuePC[head];
          empty[head] <= 1;
          head <= (head == `branchRsSize - 1) ? 0 : head + 1;
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