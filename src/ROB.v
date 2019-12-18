`include "defines.v"
//this version implements an ROB that only commit one each clk
module ROB(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    //input from alu
    input wire enWrtO, 
    input wire[`TagBus]     WrtTagO, 
    input wire[`DataBus]    WrtDataO, 
    input wire[`NameBus]    WrtNameO, 
    //input from LS for precise exception
    input wire enWrtT, 
    input wire[`TagBus] WrtTagT,
    input wire[`DataBus] WrtDataT,
    input wire[`NameBus] WrtNameT, 
    //input from Branch
    input wire enWrtB, 
    input wire mistaken, 
    input wire[`DataBus] WrtDataB, 
    input wire[`TagBus] WrtTagB, 
    //communicate with dispatcher: about write out
    input wire[`TagBus] ReadTagO, 
    input wire[`TagBus] ReadTagT, 
    output wire enReadO, 
    output wire enReadT, 
    output wire[`DataBus] ReadDataO, 
    output wire[`DataBus] ReadDataT, 
    //output: commit to regfile
    output wire ROBfree, 
    output reg enComO, 
    output reg[`TagBus]     ComTagO, 
    output reg[`DataBus]    ComDataO, 
    output reg[`NameBus]    ComNameO, 
    //communicate with Dispatcher: about tagW
    input wire dispatchEn, 
    output wire[`TagBus] freeTag, 
    output reg mis
);
    reg [`ROBsize - 1 : 0] empty;

    reg[`DataBus] rsData[`ROBsize - 1 : 0];
    reg[`NameBus] rsNameW[`ROBsize - 1 : 0];
    reg[`ROBsize - 1 : 0] rsBranchMis;

    reg[`rsSize - 1 : 0] allocEnO, allocEnT, allocEnB;

    reg[`TagBus] head, tail, num;
    //the head is the head while the tail is the next;

    assign ROBfree = (num + dispatchEn) < `ROBsize ? 1 : 0;
    assign freeTag = tail;

    assign enReadO = (ReadTagO == `tagFree) ? `Disable : 
                     (ReadTagO == WrtTagO) ? `Enable : 
                     (ReadTagO == WrtTagT) ? `Enable : 
                     (~empty[ReadTagO]) ? `Enable : `Disable;
    assign ReadDataO = (ReadTagO == `tagFree) ? `dataFree : 
                       (ReadTagO == WrtTagO) ? WrtDataO : 
                       (ReadTagO == WrtTagT) ? WrtDataT : 
                       (~empty[ReadTagO]) ? rsData[ReadTagO] : `dataFree;
    
    assign enReadT = (ReadTagT == `tagFree) ? `Disable : 
                     (ReadTagT == WrtTagO) ? `Enable : 
                     (ReadTagT == WrtTagT) ? `Enable : 
                     (~empty[ReadTagT]) ? `Enable : `Disable;
    assign ReadDataT = (ReadTagT == `tagFree) ? `dataFree : 
                       (ReadTagT == WrtTagO) ? WrtDataO : 
                       (ReadTagT == WrtTagT) ? WrtDataT : 
                       (~empty[ReadTagT]) ? rsData[ReadTagT] : `dataFree;

    generate
      genvar j;
      for (j = 0; j < `rsSize;j = j + 1) begin: ROBline
        always @(posedge clk or posedge rst) begin
          if (rst) begin
            rsData[j] <= `dataFree;
            rsNameW[j] <= `nameFree;
            rsBranchMis[j] <= 0;
          end else if (allocEnO[j]) begin
            rsData[j] <= WrtDataO;
            rsNameW[j] <= WrtNameO;
            rsBranchMis[j] <= 0;
          end else if (allocEnT[j]) begin
            rsData[j] <= WrtDataT;
            rsNameW[j] <= WrtNameT;
            rsBranchMis[j] <= 0;
          end else if (allocEnB[j]) begin
            rsData[j] <= WrtDataB;
            rsNameW[j] <= 0;
            rsBranchMis[j] <= mistaken;
          end
        end
      end
    endgenerate

    always @(*) begin
      allocEnO = 0;
      allocEnO[WrtTagO] = enWrtO;
    end
    always @(*) begin
      allocEnT = 0;
      allocEnT[WrtTagT] = enWrtT;
    end
    always @(*) begin
      allocEnB = 0;
      allocEnB[WrtTagB] = enWrtB;
    end

    always @ (posedge clk) begin
      if (rst) begin
        head <= 0;
        tail <= 0;
        num <= 0;
        empty <= {`ROBsize{1'b1}};
      end else if (rdy) begin
        if (rsBranchMis[head]) begin
          head <= 0;
          tail <= 0;
          num <= 0;
          empty <= {`ROBsize{1'b1}};
          mis <= 1;
        end else begin
          mis <= 0;
          //change the empty status, commited
          if (enWrtO) empty[WrtTagO] <= 0;
          if (enWrtT) empty[WrtTagT] <= 0;
          if (enWrtB) empty[WrtTagB] <= 0;
          //give dispatcher a tag(at post edge)
          if (dispatchEn)
            tail <= (tail + 1 < `ROBsize) ? tail + 1 : 0;
          //commit below
          if (~empty[head] && num) begin
            enComO <= `Enable;
            ComDataO <= rsData[head];
            ComTagO <=  head;
            ComNameO <= rsNameW[head];
            num <= dispatchEn ? num : num - 1; 
            head <= (head + 1 < `ROBsize) ? head + 1 : 0;
            empty[head] <= 1;
          end else begin
            enComO <= `Disable;
            ComDataO <= `dataFree;
            ComTagO <= `tagFree;
            ComNameO <= `nameFree;
            num <= dispatchEn ? num + 1 : num;
          end
        end
      end
    end
endmodule