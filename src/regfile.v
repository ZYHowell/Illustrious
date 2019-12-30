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
  output wire[`DataBus] dataS, 
  output wire[`TagBus] tagS
);
  reg[`TagBus] allTag[3:0];
  reg[`DataBus] Data;
  wire[`TagBus] nxtPosTag[3:0];
  wire[`DataBus] nxtPosData;
  reg[1:0] head, tail;
  wire[1:0] nxtHead, nxtTail;

  assign nxtHead = head < 3 ? head + 1 : 0;
  assign nxtTail = tail < 3 ? tail + 1 : 0;

  assign dataS = nxtPosData;
  assign tagS = nxtPosTag[tail];
  generate
    genvar j;
    for(j = 0;j < 4;j = j + 1) begin: nxtPosCounter
      assign nxtPosTag[j] = (enWrtO & (allTag[j] == WrtTagO)) ? `tagFree : 
                            (enWrtT & (allTag[j] == WrtTagT)) ? `tagFree : allTag[j];
    end
  endgenerate
  assign nxtPosData = (enWrtO & (allTag[head] == WrtTagO)) ? WrtDataO : 
                      (enWrtT & (allTag[head] == WrtTagT)) ? WrtDataT : Data;

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
      Data <= nxtPosData;
      
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
    input wire [`TagBus] ALUwrtTag,
    input wire [`DataBus] ALUwrtData, 

    input wire LSwrtEn, 
    input wire [`TagBus] LSwrtTag,
    input wire [`DataBus] LSwrtData,
    //from decoder
    input wire [`NameBus]   regNameO, 
    input wire [`NameBus]   regNameT, 
    //from dispatcher
    input wire enWrtDec, 
    input wire [`TagBus]    wrtTagDec, 
    input wire [`NameBus]   wrtNameDec, 

    output reg [`DataBus]   regDataO, 
    output reg [`TagBus]    regTagO, 
    output reg [`DataBus]   regDataT, 
    output reg [`TagBus]    regTagT, 
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
          
          .dataS(data[j]), 
          .tagS(tag[j])
        );
      end
    endgenerate

    always @(*) begin
      regDataO = regNameO ? data[regNameO] : 0;
      regTagO = regNameO ? tag[regNameO] : `tagFree;
      regDataT = regNameT ? data[regNameT] : 0;
      regTagT = regNameT ? tag[regNameT] : `tagFree;
    end
endmodule 