//`include "defines.v"

module mem(
    input wire clk, 
    input wire rst, 
    //with PC
    input wire instEn, 
    input wire[`InstAddrBus]    instAddr, 
    output reg instOutEn, 
    output reg[`InstBus]        inst, 
    output reg instFree, 
    //with LS
    input wire dataEn, 
    input wire LSRW, //always 0 for read and 1 for write
    input wire[`DataAddrBus]    dataAddr,
    input wire[1:0]             LSlen, 
    input wire[`DataBus]        Sdata, 
      //is DataFree when it is read
    output reg LOutEn, 
    output reg[`DataBus]        Ldata, 
    output reg LSfree, 
    //with ram
    output wire RWstate, 
    output wire[`AddrBus]        RWaddr, 
    input wire[`RAMBus]         ReadData, 
    output wire[`RAMBus]         WrtData
);
    reg status;
    //0:free,1:working
    
    reg             Waiting[1:0];
    reg             WaitingRW[1:0];
    //Waiting[0]:inst, Waiting[1]:LS
    reg [`AddrBus]  WaitingAddr[1:0];
    reg [1:0]       WaitingLen[1:0];
    reg [`DataBus]  WaitingData;
    //only Save can put something here
    
    reg             RW;
    reg             Port;//0 for inst and 1 for LS
    reg [`StageBus] stage;
    reg [`AddrBus]  AddrPlatform;
    reg [`RAMBus]   DataPlatformW[3:0];
    reg [1:0]       Lens;

    assign RWstate = RW;
    assign RWaddr = AddrPlatform;
    assign WrtData = DataPlatformW[stage];

    integer i;
    always @ (negedge clk or posedge rst) begin
      instFree <= status == `IsFree || Waiting[`instPort] == `NotUsing;
      LSfree <= status == `IsFree || Waiting[`LSport] == `NotUsing;
      if (rst == `Enable) begin
        status <= `IsFree;
        for (i = 0;i < 2;i = i + 1) begin
          Waiting[i] <= `NotUsing;
          WaitingRW[i] <= `Read;
          WaitingAddr[i] <= `addrFree;
          WaitingLen[i] <= 2'b00;
        end
        WaitingData <= `dataFree;
        RW <= `Read;
        stage <= 2'b00;
        AddrPlatform <= `addrFree;
        for (i = 0;i < 4;i = i + 1)
          DataPlatformW[i] <= 8'h00;

        //output
        instOutEn <= `Disable;
        inst <= `dataFree;
        LOutEn <= `Disable;
        Ldata <= `dataFree;
      end else begin
        instOutEn <= `Disable;
        LOutEn <= `Disable;
        //input and fill in
        if (instEn == `Enable && Waiting[`instPort] == `NotUsing) begin
          Waiting[`instPort] <= `IsUsing;
          WaitingAddr[`instPort] <= instAddr;
          WaitingRW[`instPort] <= `Read;
          WaitingLen[`instPort] <= 2'b11;
        end
        //input and fill in
        if (dataEn == `Enable && Waiting[`LSport] == `NotUsing) begin
          Waiting[`LSport] <= `IsUsing;
          WaitingAddr[`LSport] <= dataAddr;
          WaitingRW[`LSport] <= LSRW;
          WaitingData <= Sdata;
          WaitingLen[`LSport] <= LSlen;
        end

        case (status)
          `IsFree: begin
          //A free state cannot come up with a waiting inst which is thrown in the past
          //if it is thrown when the state is free, it is handle there, 
          //if it is thrown when the state is busy, it waited but then the state cannot turn to free
            if (dataEn == `Enable) begin
              RW <= LSRW;
              DataPlatformW[0] <= Sdata[7:0];
              DataPlatformW[1] <= Sdata[15:8];
              DataPlatformW[2] <= Sdata[23:16];
              DataPlatformW[3] <= Sdata[31:24];
              AddrPlatform <= dataAddr;
              Lens <= LSlen;
              stage <= 2'b00;
              status <= `NotFree;
              Port <= `LSport;

              Waiting[`LSport] <= `NotUsing;
              WaitingRW[`LSport] <= `Read;
              WaitingAddr[`LSport] <= `addrFree;
              WaitingData <= `dataFree;
              WaitingLen[`LSport] <= 2'b00;
            end else if (instEn == `Enable)begin
              RW <= `Read;
              for (i = 0; i < 4;i = i + 1)
                DataPlatformW[i] <= 8'h00;
              AddrPlatform <= instAddr;
              Lens <= 2'b11;
              stage <= 2'b00;
              status <= `NotFree;
              Port <= `instPort;

              Waiting[`instPort] <= `NotUsing;
              WaitingRW[`instPort] <= `Read;
              WaitingAddr[`instPort] <= `addrFree;
              WaitingLen[`instPort] <= 2'b00;
            end else begin
              status <= `IsFree;
            end
          end
          `NotFree: begin
            if (Port == `instPort) begin
              case (stage)
                2'b00: inst[7:0] <= ReadData;
                2'b01: inst[15:8] <= ReadData;
                2'b10: inst[23:16] <= ReadData;
                2'b11: inst[31:24] <= ReadData;
              endcase
            end else begin
              case (stage)
                2'b00: Ldata[7:0] <= ReadData;
                2'b01: Ldata[15:8] <= ReadData;
                2'b10: Ldata[23:16] <= ReadData;
                2'b11: Ldata[31:24] <= ReadData;
              endcase
            end
            if (stage == Lens) begin
              //the port not read should remains, instead of make it dataFree;
              instOutEn <= Port == `instPort;
              LOutEn <= Port == `LSport;
              if (Waiting[`LSport] == `Enable) begin
                RW <= WaitingRW[`LSport];
                DataPlatformW[0] <= WaitingData[7:0];
                DataPlatformW[1] <= WaitingData[15:8];
                DataPlatformW[2] <= WaitingData[23:16];
                DataPlatformW[3] <= WaitingData[31:24];
                AddrPlatform <= WaitingAddr[`LSport];
                Lens <= WaitingLen[`LSport];
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `LSport;

                Waiting[`LSport] <= `NotUsing;
                WaitingRW[`LSport] <= `Read;
                WaitingAddr[`LSport] <= `addrFree;
                WaitingData <= `dataFree;
                WaitingLen[`LSport] <= 2'b00;
              end else if (Waiting[`instPort] == `Enable) begin
                RW <= WaitingRW[`instPort];
                for (i = 0; i < 4;i = i + 1)
                  DataPlatformW[i] <= 8'h00;
                AddrPlatform <= WaitingAddr[`instPort];
                Lens <= WaitingLen[`instPort];
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `instPort;

                Waiting[`instPort] <= `NotUsing;
                WaitingRW[`instPort] <= `Read;
                WaitingAddr[`instPort] <= `addrFree;
                WaitingLen[`instPort] <= 2'b00;
              end else if (dataEn == `Enable) begin
                RW <= LSRW;
                DataPlatformW[0] <= Sdata[7:0];
                DataPlatformW[1] <= Sdata[15:8];
                DataPlatformW[2] <= Sdata[23:16];
                DataPlatformW[3] <= Sdata[31:24];
                AddrPlatform <= dataAddr;
                Lens <= LSlen;
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `LSport;

                Waiting[`LSport] <= `NotUsing;
                WaitingRW[`LSport] <= `Read;
                WaitingAddr[`LSport] <= `addrFree;
                WaitingData <= `dataFree;
                WaitingLen[`LSport] <= 2'b00;
              end else if (instEn == `Enable) begin
                RW <= `Read;
                for (i = 0; i < 4;i = i + 1)
                  DataPlatformW[i] <= 8'h00;
                AddrPlatform <= instAddr;
                Lens <= 2'b11;
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `instPort;

                Waiting[`instPort] <= `NotUsing;
                WaitingRW[`instPort] <= `Read;
                WaitingAddr[`instPort] <= `addrFree;
                WaitingLen[`instPort] <= 2'b00;
              end else begin
                stage <= 2'b00;
                status <= `IsFree;
              end
            end else begin
              stage <= stage + 1;
              AddrPlatform <= AddrPlatform + 1;
              status <= `NotFree;
            end
          end
        endcase
      end
    end
endmodule