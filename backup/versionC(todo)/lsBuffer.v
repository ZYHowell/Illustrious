`include "defines.v"
//should superscalar supported?
module lsBuffer(
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
    reg [`rsSize - 1 : 0] empty;
    wire[`rsSize - 1 : 0] ready;

    reg[`rsSize - 1 : 0] allocEn;
    reg[`DataBus]     AllocPostOperandO; 
    reg[`DataBus]     AllocPostOperandT; 
    reg[`TagBus]      AllocPostTagO; 
    reg[`TagBus]      AllocPostTagT;
    reg[`TagBus]      AllocPostTagW;
    reg[`NameBus]     AllocPostNameW;  
    reg[`OpBus]       AllocPostOp; 
    reg[`DataBus]     AllocPostImm; 

    wire[`DataBus] issueOperandO[`rsSize - 1 : 0];
    wire[`DataBus] issueOperandT[`rsSize - 1 : 0];
    wire[`OpBus]   issueOp[`rsSize - 1 : 0]; 
    wire[`NameBus] issueNameW[`rsSize - 1 : 0];
    wire[`TagBus] issueTagW[`rsSize - 1 : 0];
    wire[`DataBus] issueImm[`rsSize - 1 : 0];

    reg [`TagRootBus]   head, tail, num, judgeIssue;
    wire canIssue;
    //the head is the head while the tail is the next;
    integer i;

    assign canIssue = ready[judgeIssue];
    assign LSfreeTag = (tail != head) ? tail : 
                        num ? `NoFreeTag : tail;
    assign LSbufFree = (num + LSen + 1) < `rsSize ? 1 : 0;

    generate
      genvar j;
      for (j = 0; j < `rsSize;j = j + 1) begin: LSbufLine
        RsLine LSbufLine(
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
          .issueImm(issueImm[j])
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
        num <= 0;
        empty <= {`rsSize{1'b1}};
        LSworkEn <= `Disable; 
        operandO <= `dataFree; 
        operandT <= `dataFree;
        imm <= `dataFree;
        wrtTag <= `tagFree; 
        wrtName <= `nameFree; 
        opCode <= `NOP; 
      end else begin
        if (LSen) begin
          empty[tail]   <= 0;
          tail <= (tail == `rsSize - 1) ? 0 : tail + 1;
        end
        if (LSdone) begin
          head <= judgeIssue;
          empty[head] <= 1;
          num <= LSen ? num : (num - 1);
        end else begin
          num <= LSen ? num + 1 : num;
        end
        if ((LSreadEn == `Enable) && canIssue) begin
          LSworkEn <= `Enable;
          operandO <= issueOperandO[judgeIssue];
          operandT <= issueOperandT[judgeIssue];
          opCode <= issueOp[judgeIssue];
          wrtName <= issueNameW[judgeIssue];
          wrtTag <= issueTagW[judgeIssue];
          imm <= issueImm[judgeIssue];
          judgeIssue <= (judgeIssue == `rsSize - 1) ? 0 : judgeIssue + 1;
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