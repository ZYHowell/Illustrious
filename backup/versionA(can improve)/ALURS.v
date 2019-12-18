`include "defines.v"
//caution! not test if Status == 0
module nxtPosCal(
  input wire enWrtO, 
  input wire[`TagBus] WrtTagO, 
  input wire[`DataBus]  WrtDataO, 
  input wire enWrtT, 
  input wire[`TagBus] WrtTagT,
  input wire[`DataBus] WrtDataT, 

  input wire[`DataBus] dataNow,
  input wire[`TagBus]   tagNow,

  output wire[`DataBus] dataNxtPos, 
  output wire[`TagBus]  tagNxtPos
);
  assign dataNxtPos = (enWrtO & (tagNow == WrtTagO)) ? WrtDataO : 
                      (enWrtT & (tagNow == WrtTagT)) ? WrtDataT :
                      dataNow;
  assign tagNxtPos = (enWrtO & (tagNow == WrtTagO)) ? `tagFree : 
                      (enWrtT & (tagNow == WrtTagT)) ? `tagFree :
                      tagNow;
endmodule
module RsLine(
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
    input wire[`TagBus]     allocTagW, 
    input wire[`OpBus]      allocOp, 
    input wire[`InstAddrBus]allocImm, 
    input wire[`BranchTagBus] allocBranchTag, 
    //
    input wire empty, 
    output wire ready, 
    output wire[`DataBus] issueOperandO, 
    output wire[`DataBus] issueOperandT, 
    output wire[`OpBus]   issueOp,  
    output wire[`TagBus]  issueTagW,
    output wire[`DataBus] issueImm, 
    output wire[`BranchTagBus]  issueBranchTag, 
    //the imm is pc in alu, is imm in ls; so bucket branchRS for it contains both
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum, 
    input wire misTaken, 
    output wire nxtPosEmpty
);
    reg[`TagBus]  rsTagO, rsTagT;
    reg[`DataBus] rsDataO, rsDataT;
    reg[`TagBus]  rsTagW;
    reg[`DataBus] rsImm;
    reg[`OpBus]   rsOp;
    reg[`BranchTagBus] BranchTag;
    wire[`TagBus] nxtPosTagO, nxtPosTagT;
    wire[`DataBus] nxtPosDataO, nxtPosDataT;
    wire[`BranchTagBus] nxtPosBranchTag;
    wire discard;

    assign discard = ~empty & misTaken & BranchTag[bFreeNum];
    assign nxtPosEmpty = (~allocEn & empty) | discard;
    assign ready = ~empty & (nxtPosTagO == `tagFree) & (nxtPosTagT == `tagFree) & ~discard;
    assign issueOperandO = (nxtPosTagO == `tagFree) ? nxtPosDataO : rsDataO;
    assign issueOperandT = (nxtPosTagT == `tagFree) ? nxtPosDataT : rsDataT;
    assign issueOp = rsOp;
    assign issueImm = rsImm;
    assign issueTagW = rsTagW;
    assign nxtPosBranchTag = (bFreeEn & BranchTag[bFreeNum]) ? (BranchTag ^ (1 << bFreeNum)) : BranchTag;
    assign issueBranchTag = nxtPosBranchTag;

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
    always @(posedge clk) begin
      if (rst | discard) begin
        rsTagO <= `tagFree;
        rsTagT <= `tagFree;
        rsDataO <= `dataFree;
        rsDataT <= `dataFree;
        rsTagW <= `tagFree;
        rsImm <= `dataFree;
        rsOp <= `NOP;
        BranchTag <= 0;
      end else if (allocEn) begin
        rsTagO <= allocTagO;
        rsTagT <= allocTagT;
        rsDataO <= allocOperandO;
        rsDataT <= allocOperandT;
        rsTagW <= allocTagW;
        rsImm <= allocImm;
        rsOp <= allocOp;
        BranchTag <= allocBranchTag;
      end else begin
        rsTagO <= nxtPosTagO;
        rsTagT <= nxtPosTagT;
        rsDataO <= nxtPosDataO;
        rsDataT <= nxtPosDataT;
        BranchTag <= nxtPosBranchTag;
      end
    end
endmodule
module ALUrs(
    input rst,
    input clk,
    //from ALU and LS
    input wire enALUwrt, 
    input wire[`TagBus] ALUtag, 
    input wire[`DataBus]  ALUdata, 
    input wire enLSwrt, 
    input wire[`TagBus] LStag,
    input wire[`DataBus] LSdata, 
    
    //from dispatcher
    input wire ALUen, 
    input wire[`DataBus]    ALUoperandO, 
    input wire[`DataBus]    ALUoperandT, 
    input wire[`TagBus]     ALUtagO, 
    input wire[`TagBus]     ALUtagT,
    input wire[`TagBus]     ALUtagW, 
    input wire[`OpBus]      ALUop, 
    input wire[`InstAddrBus]ALUaddr, 
    input wire[`BranchTagBus]   BranchTag, 

    //to ALU
    output reg ALUworkEn, 
    output reg[`DataBus]    operandO, 
    output reg[`DataBus]    operandT,
    output reg[`TagBus]     wrtTag, 
    output reg[`OpBus]      opCode, 
    output reg[`InstAddrBus]instAddr,
    output reg[`BranchTagBus] instBranchTag, 
    //to dispatcher
    output wire ALUfree, 
    //from branch
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum, 
    input wire misTaken
);

    wire [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;

    wire [`rsSize - 1 : 0] issueRS;

    reg[`rsSize - 1 : 0] allocEn;

    wire[`DataBus] issueOperandO[`rsSize - 1 : 0];
    wire[`DataBus] issueOperandT[`rsSize - 1 : 0];
    wire[`OpBus]   issueOp[`rsSize - 1 : 0]; 
    wire[`TagBus]   issueTagW[`rsSize - 1 : 0];
    wire[`InstAddrBus] issuePC[`rsSize - 1 : 0];
    wire[`BranchTagBus]issueBranchTag[`rsSize - 1 : 0];
    wire[`rsSize - 1 : 0] nxtPosEmpty;

    integer i;

    assign issueRS = ready & -ready;
    //assign ALUfreeStatus = empty;
    assign ALUfree = (nxtPosEmpty != 0);

    generate
      genvar j;
      for (j = 0;j < `rsSize;j = j + 1) begin: ALUrsLine
        RsLine ALUrsLine(
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
          .allocOperandO(ALUoperandO), 
          .allocOperandT(ALUoperandT), 
          .allocTagO(ALUtagO), 
          .allocTagT(ALUtagT),
          .allocTagW(ALUtagW),
          .allocOp(ALUop), 
          .allocImm(ALUaddr), 
          .allocBranchTag(BranchTag), 
          //
          .empty(empty[j]), 
          .ready(ready[j]), 
          .issueOperandO(issueOperandO[j]), 
          .issueOperandT(issueOperandT[j]), 
          .issueOp(issueOp[j]), 
          .issueTagW(issueTagW[j]), 
          .issueImm(issuePC[j]),
          .issueBranchTag(issueBranchTag[j]),
          //
          .bFreeEn(bFreeEn), 
          .bFreeNum(bFreeNum), 
          .misTaken(misTaken), 
          .nxtPosEmpty(nxtPosEmpty[j])
        );
      end
    endgenerate

    always @(*) begin
      allocEn = 0;
      allocEn[ALUtagW[`TagRootBus]] = ALUen;
    end

    always @ (posedge clk) begin
      if (rst) begin
        empty <= {`rsSize{1'b1}};
        instBranchTag <= 0;
      end else begin
        if (ALUen) empty[ALUtagW[`TagRootBus]] <= 0;
        if (issueRS) begin
          for (i = 0;i < `rsSize;i = i + 1) begin
            if (issueRS == (1'b1 << (`rsSize - 1)) >> (`rsSize - i - 1)) begin
              ALUworkEn <= `Enable;
              operandO <= issueOperandO[i];
              operandT <= issueOperandT[i];
              opCode <= issueOp[i];
              wrtTag <= {`ALUtagPrefix,i};
              instAddr <= issuePC[i];
              instBranchTag <= issueBranchTag[i];
              empty[i] <= 1;
            end else begin
              empty[i] <= nxtPosEmpty[i];
            end
          end
        end else begin
          ALUworkEn <= `Disable;
          operandO <= `dataFree;
          operandT <= `dataFree;
          opCode <= `NOP;
          wrtTag <= `tagFree;
          instBranchTag <= 0;
          empty <= nxtPosEmpty;
        end
      end
    end
endmodule