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
    reg[`DataBus]   memInst[`memCacheSize - 1 : 0];
    reg[`memTagBus] memTag[`memCacheSize - 1:0];
    reg[`memCacheSize - 1 : 0] memValid;

    wire[`memCacheSize - 1 : 0] index;
    wire[`memTagBus]  tag;

    assign tag = Addr[`memTagBus];
    assign index = Addr[`memAddrIndexBus];

    assign hit = (memTag[index] == tag) & (memValid[index]);
    assign foundInstO = (hit & memValid[index]) ? (memInst[index]) : `dataFree;

    integer i;
    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        for (i = 0; i < `memCacheSize;i = i + 1) begin
          memInst[i] <= `dataFree;
          memTag[i] <= `memTagFree;
          memValid[i] <= `Invalid;
        end
      end else if (addEn) begin
        memInst[addAddr[`memAddrIndexBus]] <= addInst;
        memTag[addAddr[`memAddrIndexBus]] <= addAddr[`memAddrTagBus];
        memValid[addAddr[`memAddrIndexBus]] <= `Valid;
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
    reg[127:0] lru;
      
    assign index = addInst[`memAddrIndexBus];
    assign mux   = lru[index];
    
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
        .AddrO(Addr), 
        .addEn(addEnable[1]), 
        .addInst(addInst),
        .addAddr(addAddr), 

        .hit(hitR), 
        .foundInst(instR)
    );
    
    assign hit = hitL | hitR;
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