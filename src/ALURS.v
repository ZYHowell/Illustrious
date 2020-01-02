`include "defines.v"
//caution! not test if Status == 0
module nxtPosCal(
  input wire enWrtO, 
  input wire[`TagBus]   WrtTagO, 
  input wire[`DataBus]  WrtDataO, 
  input wire enWrtT, 
  input wire[`TagBus]   WrtTagT,
  input wire[`DataBus]  WrtDataT, 

  input wire[`DataBus]  dataNow,
  input wire[`TagBus]   tagNow,

  output wire[`DataBus] dataNxtPos, 
  output wire[`TagBus]  tagNxtPos
);
  assign dataNxtPos = (enWrtO & (tagNow == WrtTagO)) ? WrtDataO : 
                      (enWrtT & (tagNow == WrtTagT)) ? WrtDataT :
                      dataNow;
  assign tagNxtPos  = (enWrtO & (tagNow == WrtTagO)) ? `tagFree : 
                      (enWrtT & (tagNow == WrtTagT)) ? `tagFree :
                      tagNow;
endmodule
module RsLine(
    input clk, 
    input rst, 
    input rdy, 
    //
    input wire enWrtO, 
    input wire[`TagBus]   WrtTagO, 
    input wire[`DataBus]  WrtDataO, 
    input wire enWrtT, 
    input wire[`TagBus]   WrtTagT,
    input wire[`DataBus]  WrtDataT, 
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
    output reg[`OpBus]    issueOp,  
    output reg[`TagBus]   issueTagW,
    output reg[`DataBus]  issueImm, 
    output wire[`BranchTagBus]  issueBranchTag, 
    //the imm is pc in alu, is imm in ls; so bucket branchRS for it contains both
    input wire bFreeEn, 
    input wire[1:0]             bFreeNum, 
    input wire misTaken, 
    output wire nxtPosEmpty
);
    reg[`TagBus]        rsTagO, rsTagT;
    reg[`DataBus]       rsDataO, rsDataT;
    reg[`BranchTagBus]  BranchTag;
    wire[`TagBus]       nxtPosTagO, nxtPosTagT;
    wire[`DataBus]      nxtPosDataO, nxtPosDataT;
    wire[`BranchTagBus] nxtPosBranchTag;
    wire discard;

    assign discard = ~empty & misTaken & BranchTag[bFreeNum];
    assign nxtPosEmpty = (~allocEn & empty) | discard;
    assign ready = ~empty & (nxtPosTagO == `tagFree) & (nxtPosTagT == `tagFree) & ~discard;
    assign issueOperandO = (nxtPosTagO == `tagFree) ? nxtPosDataO : rsDataO;
    assign issueOperandT = (nxtPosTagT == `tagFree) ? nxtPosDataT : rsDataT;
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
        issueTagW <= `tagFree;
        issueImm <= `dataFree;
        issueOp <= `NOP;
        BranchTag <= 0;
      end else if (rdy) begin
        if (allocEn) begin
          rsTagO <= allocTagO;
          rsTagT <= allocTagT;
          rsDataO <= allocOperandO;
          rsDataT <= allocOperandT;
          issueTagW <= allocTagW;
          issueImm <= allocImm;
          issueOp <= allocOp;
          BranchTag <= allocBranchTag;
        end else begin
          rsTagO <= nxtPosTagO;
          rsTagT <= nxtPosTagT;
          rsDataO <= nxtPosDataO;
          rsDataT <= nxtPosDataT;
          BranchTag <= nxtPosBranchTag;
        end
      end
    end
endmodule
module ALUrs(
    input rst,
    input clk,
    input rdy, 
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

    wire [`rsSize - 1 : 0]  ready;
    reg [`rsSize - 1 : 0]   empty;

    wire [`rsSize - 1 : 0] issueRS;

    reg[`rsSize - 1 : 0]  allocEn;
    reg[`DataBus]         AllocPostOperandO; 
    reg[`DataBus]         AllocPostOperandT; 
    reg[`TagBus]          AllocPostTagO; 
    reg[`TagBus]          AllocPostTagT;
    reg[`TagBus]          AllocPostTagW;
    //remark: this is designed for normal Tomasulo that I gave up. 
    reg[`OpBus]           AllocPostOp; 
    reg[`InstAddrBus]     AllocPostAddr; 
    reg[`BranchTagBus]    AllocBranchTag;

    wire[`DataBus]        issueOperandO [`rsSize - 1 : 0];
    wire[`DataBus]        issueOperandT [`rsSize - 1 : 0];
    wire[`OpBus]          issueOp       [`rsSize - 1 : 0]; 
    wire[`TagBus]         issueTagW     [`rsSize - 1 : 0];
    wire[`InstAddrBus]    issuePC       [`rsSize - 1 : 0];
    wire[`BranchTagBus]   issueBranchTag[`rsSize - 1 : 0];
    wire[`rsSize - 1 : 0] nxtPosEmpty;
    reg straightlyIssue;

    integer i;

    assign issueRS = ready & -ready;
    assign ALUfree = (nxtPosEmpty != 0);

    generate
      genvar j;
      for (j = 0;j < `rsSize;j = j + 1) begin: ALUrsLine
        RsLine ALUrsLine(
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
          .allocEn(allocEn[j]), 
          .allocOperandO(AllocPostOperandO), 
          .allocOperandT(AllocPostOperandT), 
          .allocTagO(AllocPostTagO), 
          .allocTagT(AllocPostTagT),
          .allocTagW(AllocPostTagW),
          .allocOp(AllocPostOp), 
          .allocImm(AllocPostAddr), 
          .allocBranchTag(AllocBranchTag), 
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
      if (ALUen) straightlyIssue = ALUtagO == `tagFree && ALUtagT == `tagFree;
      else straightlyIssue = 0;
    end
    always @(*) begin
      allocEn = 0;
      allocEn[ALUtagW[`TagRootBus]] = ALUen;

      AllocPostAddr     = ALUaddr;
      AllocPostOp       = ALUop;
      AllocPostOperandO = ALUoperandO;
      AllocPostOperandT = ALUoperandT;
      AllocPostTagO     = ALUtagO;
      AllocPostTagT     = ALUtagT;
      AllocPostTagW     = ALUtagW;
      AllocBranchTag    = BranchTag;
    end

    always @ (posedge clk) begin
      if (rst) begin
        empty <= {`rsSize{1'b1}};
        instBranchTag <= 0;
      end else begin
        if (ALUen) empty[ALUtagW[`TagRootBus]] <= straightlyIssue && (!issueRS);
        if (issueRS) begin
          for (i = 0;i < `rsSize;i = i + 1) begin
            if (issueRS == (1'b1 << (`rsSize - 1)) >> (`rsSize - i - 1)) begin
              ALUworkEn     <= `Enable;
              operandO      <= issueOperandO[i];
              operandT      <= issueOperandT[i];
              opCode        <= issueOp[i];
              wrtTag        <= {`ALUtagPrefix,i};
              instAddr      <= issuePC[i];
              instBranchTag <= issueBranchTag[i];
              empty[i] <= 1;
            end else begin
              empty[i] <= nxtPosEmpty[i];
            end
          end
        end else if (straightlyIssue) begin
            ALUworkEn     <= `Enable;
            operandO      <= ALUoperandO;
            operandT      <= ALUoperandT;
            opCode        <= ALUop;
            wrtTag        <= ALUtagW;
            instAddr      <= ALUaddr;
            instBranchTag <= BranchTag;
        end else begin
          ALUworkEn     <= `Disable;
          operandO      <= `dataFree;
          operandT      <= `dataFree;
          opCode        <= `NOP;
          wrtTag        <= `tagFree;
          instBranchTag <= 0;
          empty <= nxtPosEmpty;
        end
      end
    end
endmodule