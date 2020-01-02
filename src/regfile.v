`include "defines.v"
module regfileLine(
  input wire clk, 
  input wire rst, 
  input wire rdy, 
  input wire branchDeeper, 
  input wire branchFree, 
  input wire misTaken, 

  input wire renamEn, 
  input wire[`TagBus] renamTag, 

  input wire enWrtO, 
  input wire[`DataBus] WrtDataO, 
  input wire[`TagBus] WrtTagO, 
  input wire enWrtT, 
  input wire[`DataBus] WrtDataT, 
  input wire[`TagBus] WrtTagT, 
  output reg[`DataBus] Data, 
  output wire[`TagBus] tagS
);
  reg[`TagBus] allTag[3:0];
  wire[`TagBus] nxtPosTag[3:0];
  reg[1:0] head, tail;
  wire[1:0] nxtHead, nxtTail;

  assign nxtHead = head < 3 ? head + 1 : 0;
  assign nxtTail = tail < 3 ? tail + 1 : 0;

  assign tagS = allTag[tail];
  generate
    genvar j;
    for(j = 0;j < 4;j = j + 1) begin: nxtPosCounter
      assign nxtPosTag[j] = (enWrtO & (allTag[j] == WrtTagO)) ? `tagFree : 
                            (enWrtT & (allTag[j] == WrtTagT)) ? `tagFree : allTag[j];
    end
  endgenerate

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for(i = 0;i < 4;i = i + 1) begin
        allTag[i] <= `tagFree;
      end
      head <= 0;
      tail <= 0;
      Data <= `dataFree;
    end else if (rdy) begin
      for (i = 0; i < 4;i = i + 1) begin
        allTag[i] <= (renamEn && (i == tail)) ? renamTag : nxtPosTag[i];
      end
      Data <= (enWrtO & (allTag[head] == WrtTagO)) ? WrtDataO : 
              (enWrtT & (allTag[head] == WrtTagT)) ? WrtDataT : Data;
      
      if (branchFree & ~misTaken) begin
        head <= nxtHead;
      end
      if (misTaken) begin
        tail <= head;
      end else if (branchDeeper) begin
        tail <= nxtTail;
        allTag[nxtTail] <= nxtPosTag[tail];
      end
      //if the inst is a branchInst, it will send branchDeeper without renamEn, so the nxtTail can just copy the current Tag and data. 
    end
  end
  //notice that the branch tag can only be a continuous set of 1:000//001,010,100//011,110,101//111//

endmodule
module Regfile(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    //ALU is actually from the ROB. 
    input wire ALUwrtEn, 
    input wire [`TagBus]  ALUwrtTag,
    input wire [`DataBus] ALUwrtData, 

    input wire LSwrtEn, 
    input wire [`TagBus]  LSwrtTag,
    input wire [`DataBus] LSwrtData,
    //from decoder
    input wire [`NameBus] regNameO, 
    input wire [`NameBus] regNameT, 
    //from dispatcher
    input wire enWrtDec, 
    input wire [`TagBus]  wrtTagDec, 
    input wire [`NameBus] wrtNameDec, 

    output reg [`DataBus] regDataO, 
    output reg [`TagBus]  regTagO, 
    output reg [`DataBus] regDataT, 
    output reg [`TagBus]  regTagT, 
    //
    input wire branchDeeper, 
    input wire bFreeEn, 
    input wire misTaken
);

    integer i;
    
    reg[`regSize - 1 : 0] renamEn;
    wire [`DataBus] data[`regSize - 1 : 0];
    wire [`TagBus] tag[`regSize - 1 : 0];

    always @(*) begin
      renamEn = 0;
      renamEn[wrtNameDec] = enWrtDec;
    end

    generate
      genvar j;
      for (j = 0; j < `regSize;j = j + 1) begin: regfileLine
        regfileLine regfileLine(
          .clk(clk), 
          .rst(rst), 
          .rdy(rdy), 
          .branchDeeper(branchDeeper), 
          .branchFree(bFreeEn), 
          .misTaken(misTaken), 
          .renamEn(renamEn[j]), 
          .renamTag(wrtTagDec), 

          .enWrtO(ALUwrtEn), 
          .WrtDataO(ALUwrtData), 
          .WrtTagO(ALUwrtTag), 

          .enWrtT(LSwrtEn), 
          .WrtDataT(LSwrtData),
          .WrtTagT(LSwrtTag), 
          
          .Data(data[j]), 
          .tagS(tag[j])
        );
      end
    endgenerate

    always @(*) begin
      if (regNameO) begin
        regTagO   = tag[regNameO];
        regDataO  = data[regNameO];
        if (ALUwrtEn && regTagO == ALUwrtTag) begin
          regTagO   = `tagFree;
          regDataO  = ALUwrtData;
        end else if (LSwrtEn && regTagO == LSwrtTag) begin
          regTagO   = `tagFree;
          regDataO  = LSwrtData;
        end
      end else begin
        regTagO   = `tagFree;
        regDataO  = `dataFree;
      end
    end

    always @(*) begin
      if (regNameT) begin
        regTagT   = tag[regNameT];
        regDataT  = data[regNameT];
        if (ALUwrtEn && regTagT == ALUwrtTag) begin
          regTagT   = `tagFree;
          regDataT  = ALUwrtData;
        end else if (LSwrtEn && regTagT == LSwrtTag) begin
          regTagT   = `tagFree;
          regDataT  = LSwrtData;
        end
      end else begin
        regTagT   = `tagFree;
        regDataT  = `dataFree;
      end
    end
endmodule 