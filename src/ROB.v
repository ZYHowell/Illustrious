`include "defines.v"
//this version implements an ROB that only commit one each clk
module ROB(
    input wire clk, 
    input wire rst, 
    //input from alu
    input wire enWrtO, 
    input wire[`TagBus]     WrtTagO, 
    input wire[`DataBus]    WrtDataO, 
    input wire[`NameBus]    WrtNameO, 
    //input from LS
    input wire enWrtT, 
    input wire[`TagBus] WrtTagT,
    input wire[`DataBus] WrtDataT,
    input wire[`NameBus] WrtNameT, 
    //communicate with dispatcher: about write out
    input wire[`TagBus] ReadTagO, 
    input wire[`TagBus] ReadTagT, 
    output wire enReadO, 
    output wire enReadT, 
    output wire ReadDataO, 
    output wire ReadDataT, 
    //output: commit to regfile
    output wire ROBfree, 
    output reg enComO, 
    output reg[`TagBus]     ComTagO, 
    output reg[`DataBus]    ComDataO, 
    output reg[`NameBus]    ComNameO, 
    // output reg enComT, 
    // output reg[`TagBus]     ComTagT, 
    // output reg[`DataBus]    ComDataT, 
    // output reg[`NameBus]    ComNameT, 
    //communicate with Dispatcher: about tagW
    input wire dispatchEn, 
    output wire[`TagBus] freeTag
);
    reg [`ROBsize - 1 : 0] empty;
    wire[`ROBsize - 1 : 0] ready;

    reg[`DataBus] rsData[`ROBsize - 1 : 0];
    reg[`NameBus] rsNameW[`ROBsize - 1 : 0];
    reg[`TagBus]  rsTagW[`ROBsize - 1 : 0];

    reg[`rsSize - 1 : 0] allocEnO, allocEnT;
    reg[`DataBus]     AllocPostDataO,AllocPostDataT; 
    reg[`TagBus]      AllocPostTagO,AllocPostTagT; 
    reg[`NameBus]     AllocPostNameO,AllocPostNameT; 

    wire[`DataBus] issueData[`rsSize - 1 : 0];
    wire[`NameBus] issueNameW[`rsSize - 1 : 0];
    wire[`TagBus]  issueTagW[`rsSize - 1 : 0];

    reg [`TagRootBus]   head, tail, num;
    wire canIssue;
    //the head is the head while the tail is the next;

    assign ROBfree = num + dispatchEn < `ROBsize ? 1 : 0;
    assign freeTag = {`ALUtagPrefix,tail};//0 is the prefix

    assign enReadO = (ReadTagO == WrtTagO) ? `Enable : 
                     (ReadTagO == WrtTagT) ? `Enable : 
                     (~empty[ReadTagO[`TagRootBus]]) ? `Enable : `Disable;
    assign ReadDataO = (ReadTagO == WrtTagO) ? WrtDataO : 
                       (ReadTagO == WrtTagT) ? WrtDataT : 
                       (~empty[ReadTagO[`TagRootBus]]) ? rsData[ReadTagO[`TagRootBus]] : `dataFree;
    
    assign enReadT = (ReadTagT == WrtTagO) ? `Enable : 
                     (ReadTagT == WrtTagT) ? `Enable : 
                     (~empty[ReadTagT[`TagRootBus]]) ? `Enable : `Disable;
    assign ReadDataT = (ReadTagT == WrtTagO) ? WrtDataO : 
                       (ReadTagT == WrtTagT) ? WrtDataT : 
                       (~empty[ReadTagT[`TagRootBus]]) ? rsData[ReadTagT[`TagRootBus]] : `dataFree;

    generate
      genvar j;
      for (j = 0; j < `rsSize;j = j + 1) begin: ROBline
        assign ready[j] = ~empty[j];//& branchTag=tagfree;
        always @(posedge clk or posedge rst) begin
          if (rst) begin
            rsData[j] <= `dataFree;
            rsNameW[j] <= `nameFree;
            rsTagW[j] <= `tagFree;
          end else if (allocEnO[j] == `Enable) begin
            rsData[j] <= AllocPostDataO;
            rsNameW[j] <= AllocPostNameO;
            rsTagW[j] <= AllocPostTagO;
          end else if (allocEnT[j] == `Enable) begin
            rsData[j] <= AllocPostDataT;
            rsNameW[j] <= AllocPostNameT;
            rsTagW[j] <= AllocPostTagT;
          end
        end
      end
    endgenerate

    always @(*) begin
      allocEnO = 0;
      allocEnT = 0;
      allocEnO[WrtTagO[`TagRootBus]] = 1;
      allocEnT[WrtTagT[`TagRootBus]] = 1;
      AllocPostDataO = WrtDataO;
      AllocPostDataT = WrtDataT;
      AllocPostTagO = WrtTagO;
      AllocPostTagT = WrtTagT;
      AllocPostNameO = WrtNameO;
      AllocPostNameT = WrtNameT;
    end

    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        head <= 0;
        tail <= 0;
        num <= 0;
        empty <= {`ROBsize{1'b1}};
      end else begin
        //change the empty status, commited
        if (enWrtO) empty[WrtTagO[`TagRootBus]] <= 0;
        if (enWrtT) empty[WrtTagT[`TagRootBus]] <= 0;
        //give dispatcher a tag(at post edge)
        if (dispatchEn)
          tail <= (tail + 1 < `ROBsize) ? tail + 1 : 0;
        //commit below
        if (ready[head] && num) begin
          enComO <= `Enable;
          ComDataO <= rsData[head];
          ComTagO <= rsTagW[head];
          ComNameO <= rsNameW[head];
          num <= dispatchEn ? num : num - 1; 
          head <= (head + 1 < `ROBsize) ? head + 1 : 0;
        end else begin
          enComO <= `Disable;
          ComDataO <= `dataFree;
          ComTagO <= `tagFree;
          ComNameO <= `nameFree;
          num <= dispatchEn ? num + 1 : num;
        end
      end
    end
endmodule