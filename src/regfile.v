`include "defines.v"
module regfileLine(
  input wire clk, 
  input wire rst, 
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
  reg[`DataBus] allData[3:0];
  wire[`TagBus] nxtPosTag[3:0];
  wire[`DataBus] nxtPosData[3:0];
  reg[1:0] head, tail;
  wire[1:0] nxtHead, nxtTail;

  assign nxtHead = head < 3 ? head + 1 : 0;
  assign nxtTail = tail < 3 ? tail + 1 : 0;

  assign dataS = nxtPosData[tail];
  assign tagS = nxtPosTag[tail];
  generate
    genvar j;
    for(j = 0;j < 4;j = j + 1) begin: nxtPosCounter
      nxtPosCal nxtPosCal(
        .enWrtO(enWrtO), 
        .WrtTagO(WrtTagO), 
        .WrtDataO(WrtDataO), 
        .enWrtT(enWrtT), 
        .WrtTagT(WrtTagT), 
        .WrtDataT(WrtDataT), 
        .dataNow(allData[j]), 
        .tagNow(allTag[j]), 
        .dataNxtPos(nxtPosData[j]),
        .tagNxtPos(nxtPosTag[j])
      );
    end
  endgenerate

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for(i = 0;i < 4;i = i + 1) begin
        allTag[i] <= `tagFree;
        allData[i] <= `dataFree;
      end
      head <= 0;
      tail <= 0;
    end else begin
      for (i = 0; i < 4;i = i + 1) begin
        allTag[i] <= (renamEn && (i == tail)) ? renamTag : nxtPosTag[i];
        allData[i] <= nxtPosData[i];
      end
      
      if (branchFree & ~misTaken) begin
        head <= nxtHead;
      end
      if (misTaken) begin
        tail <= head;
      end else if (branchDeeper) begin
        tail <= nxtTail;
        allTag[nxtTail] <= nxtPosTag[tail];
        allData[nxtTail] <= nxtPosData[tail];
      end
      //if the inst is a branchInst, it will send branchDeeper without renamEn, so the nxtTail can just copy the current Tag and data. 
    end
  end
  //notice that the branch tag can only be a continuous set of 1:000//001,010,100//011,110,101//111//
  /*
   * head records the latest and reliable data and tag, (so head+1 is the next to be free)
   * tail records the latest but maybe not reliable data and tag. 
   * When read: returns the tag[tail] and data[tail], judge the enwrt at the same time;(done)
   * When write: check the tag with each one, if any one fits, replace the tag and data with the input one(done)
   * When free: head+1(done)
   * When mistaken: tail=head(done)
   * When a new branch tag is used: tail+1(done)
   * When rename: change tag[tail](done)
  */
endmodule
module Regfile(
    input wire clk, 
    input wire rst, 
    //ALU is actually from the ROB. 
    input wire ALUwrtEn, 
    input wire [`NameBus] ALUwrtName, 
    input wire [`TagBus] ALUwrtTag,
    input wire [`DataBus] ALUwrtData, 

    input wire LSwrtEn, 
    input wire [`NameBus] LSwrtName,
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