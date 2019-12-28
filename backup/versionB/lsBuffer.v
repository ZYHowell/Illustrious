`include "defines.v"
//should superscalar supported?
module lsBuffer(
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
    //input from dispatcher
    input wire LSen, 
    input wire[`DataBus]        LSoperandO, 
    input wire[`DataBus]        LSoperandT, 
    input wire[`TagBus]         LStagO, 
    input wire[`TagBus]         LStagT, 
    input wire[`TagBus]         LStagW, 
    input wire[`NameBus]        LSnameW, 
    input wire[`OpBus]          LSop, 
    input wire[`DataBus]        LSimm, 
    //from the LS
    input wire LSreadEn, 
    input wire LSdone,
    //to LS
    output reg LSworkEn, 
    output reg[`DataBus]        operandO, 
    output reg[`DataBus]        operandT,
    output reg[`DataBus]        imm, 
    output reg[`TagBus]         wrtTag, 
    output reg[`NameBus]        wrtName, 
    output reg[`OpBus]          opCode, 
    //to dispatcher
    output wire[`TagRootBus] LSfreeTag, 
    output wire LSbufFree
);
    reg [`LSrsSize - 1 : 0] empty;
    wire[`LSrsSize - 1 : 0] ready;

    reg[`LSrsSize - 1 : 0] allocEn;
    reg[`DataBus]     AllocPostOperandO; 
    reg[`DataBus]     AllocPostOperandT; 
    reg[`TagBus]      AllocPostTagO; 
    reg[`TagBus]      AllocPostTagT;
    reg[`TagBus]      AllocPostTagW;
    reg[`NameBus]     AllocPostNameW;  
    reg[`OpBus]       AllocPostOp; 
    reg[`DataBus]     AllocPostImm; 

    wire[`DataBus] issueOperandO[`LSrsSize - 1 : 0];
    wire[`DataBus] issueOperandT[`LSrsSize - 1 : 0];
    wire[`OpBus]   issueOp[`LSrsSize - 1 : 0]; 
    wire[`NameBus] issueNameW[`LSrsSize - 1 : 0];
    wire[`TagBus] issueTagW[`LSrsSize - 1 : 0];
    wire[`DataBus] issueImm[`LSrsSize - 1 : 0];
    wire[`LSrsSize - 1 : 0] nxtPosEmpty;

    reg [`TagRootBus]   head, tail, judgeIssue;
    wire canIssue;
    //the head is the head while the tail is the next;
    integer i;

    assign canIssue = ready[judgeIssue];
    assign LSfreeTag = empty ? tail : `NoFreeTag;
    assign LSbufFree = (nxtPosEmpty != 0);

    generate
      genvar j;
      for (j = 0; j < `LSrsSize;j = j + 1) begin: LSbufLine
        RsLine LSbufLine(
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
          .allocNameW(AllocPostNameW),
          .allocOp(AllocPostOp), 
          .allocImm(AllocPostImm), 
          //
          .empty(empty[j]), 
          .ready(ready[j]), 
          .issueOperandO(issueOperandO[j]), 
          .issueOperandT(issueOperandT[j]), 
          .issueOp(issueOp[j]), 
          .issueNameW(issueNameW[j]), 
          .issueTagW(issueTagW[j]), 
          .issueImm(issueImm[j]),
          .nxtPosEmpty(nxtPosEmpty[j])
        );
      end
    endgenerate

    always @(*) begin
      allocEn = 0;
      allocEn[tail] = LSen ? `Enable : `Disable;
      AllocPostImm = LSimm;
      AllocPostOp = LSop;
      AllocPostOperandO = LSoperandO;
      AllocPostOperandT = LSoperandT;
      AllocPostTagO = LStagO;
      AllocPostTagT = LStagT;
      AllocPostTagW = LStagW;
      AllocPostNameW = LSnameW;
    end

    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        judgeIssue <= 0;
        head <= 0;
        tail <= 0;
        empty <= {`LSrsSize{1'b1}};
        LSworkEn <= `Disable; 
        operandO <= `dataFree; 
        operandT <= `dataFree;
        imm <= `dataFree;
        wrtTag <= `tagFree; 
        wrtName <= `nameFree; 
        opCode <= `NOP; 
      end else if (rdy) begin
        if (LSen) begin
          empty[tail]   <= 0;
          tail <= (tail == `LSrsSize - 1) ? 0 : tail + 1;
        end
        if (LSdone) begin
          head <= judgeIssue;
          empty[head] <= 1;
        end 
        if ((LSreadEn == `Enable) && canIssue) begin
          LSworkEn <= `Enable;
          operandO <= issueOperandO[judgeIssue];
          operandT <= issueOperandT[judgeIssue];
          opCode <= issueOp[judgeIssue];
          wrtName <= issueNameW[judgeIssue];
          wrtTag <= issueTagW[judgeIssue];
          imm <= issueImm[judgeIssue];
          judgeIssue <= (judgeIssue == `LSrsSize - 1) ? 0 : judgeIssue + 1;
        end else begin
          LSworkEn <= `Disable;
          operandO <= `dataFree;
          operandT <= `dataFree;
          opCode <= `NOP;
          wrtName <= `nameFree;
          wrtTag <= `tagFree;
          imm <= `dataFree;
        end
      end
    end
endmodule