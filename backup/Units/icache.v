`include "defines.v"
//this is a two-way associative icache
module way(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire[`AddrBus] Addr, 
    input wire addEn, 
    input wire[`DataBus]  addInst,
    input wire[`AddrBus]  addAddr, 

    output wire hit, 
    output wire [`DataBus]  foundInst
);
    reg[`DataBus]   memInst[63 : 0];
    reg[8 : 0] memTag[63 : 0];
    reg[63 : 0] memValid;

    wire[5 : 0] index;
    wire[8 : 0]  tag;

    assign tag = Addr[16 : 8];
    assign index = Addr[7 : 2];

    assign hit = (memTag[index] == tag) & (memValid[index]);
    assign foundInst = memInst[index];

    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        memValid <= 0;
      end else if (addEn) begin
        memInst[addAddr[7 : 2]] <= addInst;
        memTag[addAddr[7 : 2]] <= addAddr[16 : 8];
        memValid[addAddr[7 : 2]] <= `Valid;
      end
    end
endmodule

module icache(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire fetchEn, 
    input wire[`AddrBus] Addr, 
    input wire addEn, 
    input wire[`DataBus]  addInst,
    input wire[`AddrBus]  addAddr, 

    output wire hit, 
    output wire [`DataBus]  foundInst, 

    output wire memfetchEn, 
    output wire[`InstAddrBus] memfetchAddr
);
    reg[1:0] addEnable;
    wire hitL, hitR;
    wire [`InstBus] instL, instR; 
    wire mux;
    wire[5:0] index;
    reg[63:0] lru;
      
    assign index = addAddr[7 : 2];
    assign mux   = lru[index];

    assign memfetchEn = ~hit & fetchEn;
    assign memfetchAddr = Addr;
    
    way wayL(
        .clk(clk), 
        .rst(rst), 
        .rdy(rdy), 
        .Addr(Addr), 
        .addEn(addEnable[0]), 
        .addInst(addInst),
        .addAddr(addAddr), 

        .hit(hitL), 
        .foundInst(instL)
    );
    
    way wayR(
        .clk(clk), 
        .rst(rst), 
        .rdy(rdy), 
        .Addr(Addr), 
        .addEn(addEnable[1]), 
        .addInst(addInst),
        .addAddr(addAddr), 

        .hit(hitR), 
        .foundInst(instR)
    );
    
    assign hit = (hitL | hitR) & fetchEn;
    assign foundInst = hitL ? instL : instR;

    always @ (*) begin
        addEnable[mux] = addEn;
        addEnable[~mux] = 0;
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            lru <= 0;
        end else if (rdy) begin
            if (addEn) begin
                lru[index] <= ~lru[index];
            end
        end
    end
endmodule