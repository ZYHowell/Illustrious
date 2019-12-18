`include "defines.v"
//I notice that the ROB does not need to receive those from LS, 
//since my LS executes in order. 
//The only problem is that precise exception is not supported in such version, 
//maybe I will fix it in few generations later. 
module ROB(
    input wire clk, 
    input wire rst, 
    //input from alu
    input wire enWrtO, 
    input wire[`TagBus]     WrtTagO, 
    input wire[`DataBus]    WrtDataO, 
    //input from LS for precise exception, but not now
    // input wire enWrtT, 
    // input wire[`TagBus] WrtTagT,
    // input wire[`DataBus] WrtDataT,
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
    // output reg enComT, 
    // output reg[`TagBus]     ComTagT, 
    // output reg[`DataBus]    ComDataT, 
    //communicate with Dispatcher: about tagW
    input wire dispatchEn, 
    input wire[`BranchTagBus] dispBranchTag, 
    output wire[`TagRootBus] freeTag, 
    //
    input wire                  bFreeEn, 
    input wire[1:0]             bFreeNum, 
    input wire misTaken
);
    reg [`ROBsize - 1 : 0] empty;
    wire[`ROBsize - 1 : 0] ready;

    reg[`DataBus] rsData[`ROBsize - 1 : 0];
    reg[`TagBus]  rsTagW[`ROBsize - 1 : 0];
    reg[`BranchTagBus] rsBranchTag[`ROBsize - 1 : 0];
    wire[`BranchTagBus] nxtBranchTag[`ROBsize - 1 : 0];
    wire[`ROBsize - 1 : 0] nxtPosEmpty;
    wire[`ROBsize - 1 : 0] discard;
    reg[`ROBsize - 1 : 0] valid;

    reg[`rsSize - 1 : 0] allocEnO;//, allocEnT;

    reg [`TagRootBus]   head, tail;
    wire canIssue;
    wire headMove;
    //the head is the head while the tail is the next;

    assign ROBfree = (nxtPosEmpty != 0);
    assign freeTag = tail;//0 is the prefix
    assign headMove = (~valid[head] & (head != tail)) | ready[head] | discard[head];

    assign enReadO = (ReadTagO == `tagFree) ? `Disable : 
                     (ReadTagO == WrtTagO) ? `Enable : 
                     //(ReadTagO == WrtTagT) ? `Enable : 
                     (~empty[ReadTagO[`TagRootBus]]) ? `Enable : `Disable;
    assign ReadDataO = (ReadTagO == `tagFree) ? `dataFree : 
                       (ReadTagO == WrtTagO) ? WrtDataO : 
                       //(ReadTagO == WrtTagT) ? WrtDataT : 
                       (~empty[ReadTagO[`TagRootBus]]) ? rsData[ReadTagO[`TagRootBus]] : `dataFree;
    
    assign enReadT = (ReadTagT == `tagFree) ? `Disable : 
                     (ReadTagT == WrtTagO) ? `Enable : 
                     //(ReadTagT == WrtTagT) ? `Enable : 
                     (~empty[ReadTagT[`TagRootBus]]) ? `Enable : `Disable;
    assign ReadDataT = (ReadTagT == `tagFree) ? `dataFree : 
                       (ReadTagT == WrtTagO) ? WrtDataO : 
                       //(ReadTagT == WrtTagT) ? WrtDataT : 
                       (~empty[ReadTagT[`TagRootBus]]) ? rsData[ReadTagT[`TagRootBus]] : `dataFree;

    generate
      genvar j;
      for (j = 0; j < `ROBsize;j = j + 1) begin: ROBline
        assign discard[j] = misTaken & rsBranchTag[j][bFreeNum];
        assign ready[j] = (~empty[j]) & (!nxtBranchTag[j]) & ~discard[j];
        assign nxtBranchTag[j] = (bFreeEn & rsBranchTag[j][bFreeNum]) ? (rsBranchTag[j] ^ (1 << bFreeNum)) : rsBranchTag[j];
        assign nxtPosEmpty[j] = (empty[j] & ~allocEnO[j]) | discard[j];

        always @(posedge clk) begin
          if (rst) begin
            empty[j] <= 1'b1;
          end else begin
            if (headMove & (j == head)) empty[j] <= 1;
            else empty[j] <= nxtPosEmpty[j];
          end
        end
        always @(posedge clk) begin
          if (rst) begin
            valid[j] <= 0;
            rsBranchTag[j] <= 0;
          end else begin
            if (dispatchEn && (j == tail)) begin
              rsBranchTag[j] <= dispBranchTag;
              valid[j] <= 1;
            end else begin
              rsBranchTag[j] <= nxtBranchTag[j];
              if (j == head && headMove) begin
                valid[j] <= 0;
              end else begin
                valid[j] <= valid[j] & ~discard[j];
              end
            end
          end
        end
        always @(posedge clk) begin
          if (rst) begin
            rsData[j] <= `dataFree;
            rsTagW[j] <= `tagFree;
          end else if (allocEnO[j]) begin
            rsData[j] <= WrtDataO;
            rsTagW[j] <= WrtTagO;
          end
          // end else if (allocEnT[j] == `Enable) begin
          //   rsData[j] <= AllocPostDataT;
          //   rsTagW[j] <= AllocPostTagT;
          // end
        end
      end
    endgenerate

    always @(*) begin
      allocEnO = 0;
      //allocEnT = 0;
      allocEnO[WrtTagO[`TagRootBus]] = enWrtO;
      //allocEnT[WrtTagT[`TagRootBus]] = 1;
    end

    always @ (posedge clk) begin
      if (rst) begin
        head <= 0;
        tail <= 0;
        enComO <= `Disable; 
        ComTagO<= `tagFree; 
        ComDataO <= `dataFree; 
      end else begin
        //if (enWrtT) empty[WrtTagT[`TagRootBus]] <= 0;
        //give the dispatcher a tag(at post edge)
        if (dispatchEn)
          tail <= (tail + 1 < `ROBsize) ? tail + 1 : 0;
        //commit below
        if (headMove) 
          head <= (head + 1 < `ROBsize) ? head + 1 : 0;
        if (ready[head]) begin
          enComO <= `Enable;
          ComDataO <= rsData[head];
          ComTagO <= rsTagW[head];
        end else begin
          enComO <= `Disable;
          ComDataO <= `dataFree;
          ComTagO <= `tagFree;
        end
      end
    end
endmodule