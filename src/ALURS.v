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
    input wire[`NameBus]    allocNameW,  
    input wire[`OpBus]      allocOp, 
    input wire[`InstAddrBus]allocAddr, 
    //
    input wire empty, 
    output wire ready, 
    output wire[`DataBus] issueOperandO, 
    output wire[`DataBus] issueOperandT, 
    output wire[`OpBus]   issueOp,  
    output wire[`NameBus] issueNameW, 
    output wire[`InstAddrBus] issuePC

);
    reg[`TagBus]  rsTagO, rsTagT;
    reg[`DataBus] rsDataO, rsDataT;
    reg[`NameBus] rsNameW;
    reg[`InstAddrBus] rsPC;
    reg[`OpBus]   rsOp;
    wire[`TagBus] nxtPosTagO, nxtPosTagT;
    wire[`DataBus] nxtPosDataO, nxtPosDataT;

    assign ready = ~empty & (nxtPosTagO == `tagFree) & (nxtPosTagT == `tagFree);
    assign issueOperandO = (nxtPosTagO == `tagFree) ? nxtPosDataO : rsDataO;
    assign issueOperandT = (nxtPosTagT == `tagFree) ? nxtPosDataT : rsDataT;
    assign issueOp = rsOp;
    assign issueNameW = rsNameW;
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
        rsTagO <= `tagFree;
        rsTagT <= `tagFree;
        rsDataO <= `dataFree;
        rsDataT <= `dataFree;
        rsNameW <= `nameFree;
        rsPC <= `addrFree;
        rsOp <= `NOP;
      end else if (allocEn == `Enable) begin
        rsTagO <= allocTagO;
        rsTagT <= allocTagT;
        rsDataO <= allocOperandO;
        rsDataT <= allocOperandT;
        rsNameW <= allocNameW;
        rsPC <= allocAddr;
        rsOp <= allocOp;
      end else begin
        rsTagO <= nxtPosTagO;
        rsTagT <= nxtPosTagT;
        rsDataO <= nxtPosDataO;
        rsDataT <= nxtPosDataT;
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
    input wire[`NameBus]    ALUnameW,  
    input wire[`OpBus]      ALUop, 
    input wire[`InstAddrBus]ALUaddr, 

    //to ALU
    output reg ALUworkEn, 
    output reg[`DataBus]    operandO, 
    output reg[`DataBus]    operandT,
    output reg[`TagBus]     wrtTag, 
    output reg[`NameBus]    wrtName, 
    output reg[`OpBus]      opCode, 
    output reg[`InstAddrBus]instAddr,
    //to dispatcher
    output wire[`rsSize - 1 : 0] ALUfreeStatus
);

    wire [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;

    wire [`rsSize - 1 : 0] issueRS;

    reg allocEn[`rsSize - 1 : 0];
    reg[`DataBus]    AllocPostOperandO; 
    reg[`DataBus]    AllocPostOperandT; 
    reg[`TagBus]     AllocPostTagO; 
    reg[`TagBus]     AllocPostTagT;
    reg[`TagBus]     AllocPostTagW;
    reg[`NameBus]    AllocPostNameW;  
    reg[`OpBus]      AllocPostOp; 
    reg[`InstAddrBus]AllocPostAddr; 

    wire[`DataBus] issueOperandO[`rsSize - 1 : 0];
    wire[`DataBus] issueOperandT[`rsSize - 1 : 0];
    wire[`OpBus]   issueOp[`rsSize - 1 : 0]; 
    wire[`NameBus] issueNameW[`rsSize - 1 : 0];
    wire[`InstAddrBus] issuePC[`rsSize - 1 : 0];

    integer i;

    assign issueRS = ready & -ready;
    assign ALUfreeStatus = empty;

    generate
      genvar j;
      for (j = 0;j < `rsSize;j = j + 1) begin: rsLine
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
          .allocOperandO(AllocPostOperandO), 
          .allocOperandT(AllocPostOperandT), 
          .allocTagO(AllocPostTagO), 
          .allocTagT(AllocPostTagT),
          .allocTagW(AllocPostTagW),
          .allocNameW(AllocPostNameW),
          .allocOp(AllocPostOp), 
          .allocAddr(AllocPostAddr), 
          //
          .empty(empty[j]), 
          .ready(ready[j]), 
          .issueOperandO(issueOperandO[j]), 
          .issueOperandT(issueOperandT[j]), 
          .issueOp(issueOp[j]), 
          .issueNameW(issueNameW[j]), 
          .issuePC(issuePC[j])
        );
      end
    endgenerate

    always @(*) begin
      for (i = 0; i < `rsSize;i = i + 1) begin
        allocEn[i] = (ALUen && (ALUtagW[`TagRootBus] == i)) ? `Enable : `Disable;
      end
      AllocPostAddr = ALUaddr;
      AllocPostOp = ALUop;
      AllocPostOperandO = ALUoperandO;
      AllocPostOperandT = ALUoperandT;
      AllocPostTagO = ALUtagO;
      AllocPostTagT = ALUtagT;
      AllocPostTagW = ALUtagW;
      AllocPostNameW = ALUnameW;
    end

    always @ (posedge clk) begin
      if (rst) begin
        empty <= {`rsSize{1'b1}};
      end else begin
        if (ALUen) empty[ALUtagW[`TagRootBus]] <= 0;
        if (issueRS) begin
          for (i = 0;i < `rsSize;i = i + 1) begin
            if (issueRS == (1'b1 << (`rsSize - 1)) >> (`rsSize - i - 1)) begin
              ALUworkEn <= `Enable;
              operandO <= issueOperandO[i];
              operandT <= issueOperandT[i];
              opCode <= issueOp[i];
              wrtName <= issueNameW[i];
              wrtTag <= {`ALUtagPrefix,i};
              instAddr <= issuePC[i];
              empty[i] <= 1;
            end
          end
        end else begin
          ALUworkEn <= `Disable;
          operandO <= `dataFree;
          operandT <= `dataFree;
          opCode <= `NOP;
          wrtName <= `nameFree;
          wrtTag <= `tagFree;
        end
      end
    end
endmodule