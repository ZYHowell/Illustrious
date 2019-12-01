`include "defines.v"
//rewriting
//Here hides a big problem in this one, for load after a store can execute before it. 
//When this load loads the address where store stores, it creates a problem. 
//rewriting... make it fifo
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

    wire canIssue;

    reg [`DataBus]      rsDataO[`rsSize - 1:0];
    reg [`DataBus]      rsDataT[`rsSize - 1:0];
    reg [`TagBus]       rsTagO[`rsSize - 1:0];
    reg [`TagBus]       rsTagT[`rsSize - 1:0];
    reg [`OpBus]        rsOp[`rsSize - 1:0];
    reg [`DataBus]      rsImm[`rsSize - 1:0];
    reg [`NameBus]      rsNameW[`rsSize - 1:0];
    reg [`TagBus]       rsTagW[`rsSize - 1:0];
    reg [`TagRootBus]   head, tail, num;
    //the head is the head while the tail is the next;

    assign canIssue = (~empty[head]) && (rsTagO[head] == `tagFree) && (rsTagT[head] == `tagFree);
    
    assign LSfreeTag = (tail != head) ? tail : 
                        num ? `NoFreeTag : tail;

    assign LSbufFree = (num + LSen + 1) < `rsSize ? 1 : 0;

    integer i;
    //deal with rst
    always @ (*) begin
      if (rst == `Enable) begin
        head = 0;
        tail = 0;
        num = 0;
        empty = {`rsSize{1'b1}};
      end else begin
        for (i = 0;i < `rsSize;i = i + 1) begin
          empty[i] = rsOp[i] == `NOP;
        end
      end
    end 

    //receive boardcast from CDB
    always @ (negedge clk) begin
      if (rst == `Disable) begin
        for (i = 0;i < `rsSize;i = i + 1) begin
          rsTagO[i] <= (empty[i]) ? `tagFree : 
                        (rsTagO[i] == ALUtag && enALUwrt) ? `tagFree : 
                        (rsTagO[i] == LStag && enLSwrt) ? `tagFree : rsTagO[i];
          rsDataO[i] <= (empty[i]) ? `dataFree : 
                        (rsTagO[i] == ALUtag && enALUwrt) ? ALUdata :
                        (rsTagO[i] == LStag && enLSwrt) ? LSdata : rsDataO[i];
          rsTagT[i] <= (empty[i]) ? `tagFree : 
                        (rsTagT[i] == ALUtag && enALUwrt) ? `tagFree : 
                        (rsTagT[i] == LStag && enLSwrt) ? `tagFree : rsTagT[i];
          rsDataT[i] <= (empty[i]) ? `dataFree : 
                        (rsTagT[i] == ALUtag && enALUwrt) ? ALUdata :
                        (rsTagT[i] == LStag && enLSwrt) ? LSdata : rsDataT[i];
        end
      end
    end


    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        for (i = 0;i < `rsSize;i = i + 1) begin
          rsTagO[i] <= `tagFree;
          rsDataO[i] <= `dataFree;
          rsTagT[i] <= `tagFree;
          rsDataT[i] <= `dataFree;
          rsTagW[i] <= `tagFree;
          rsOp[i] <= `NOP;
          rsNameW[i] <= `nameFree;
          rsImm[i] <= `dataFree;
        end
      end else begin
        if (LSen) begin
          empty[tail]   <= 0;
          rsOp[tail]     <= LSop;
          rsDataO[tail]  <= LSoperandO;
          rsDataT[tail]  <= LSoperandT;
          rsTagO[tail]   <= LStagO;
          rsTagT[tail]   <= LStagT;
          rsTagW[tail]   <= LStagW;
          rsNameW[tail]  <= LSnameW;
          rsImm[tail]    <= LSimm;
          tail <= (tail == `rsSize - 1) ? 0 : tail + 1;
        end
        if ((LSreadEn == `Enable) && canIssue) begin
          LSworkEn <= `Enable;
          operandO <= rsDataO[head];
          operandT <= rsDataT[head];
          opCode <= rsOp[head];
          wrtName <= rsNameW[head];
          wrtTag <= rsTagW[head];
          imm <= rsImm[head];
          rsOp[head] <= `NOP;
          head <= (head == `rsSize - 1) ? 0 : head + 1;
          num <= LSen ? num : (num - 1);
        end else begin
          num <= LSen ? num + 1 : num;
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