`include "defines.v"

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
    input wire[`DataBus]        Sdata, 
      //is DataFree when it is read
    output reg LOutEn, 
    output reg[`DataBus]        Ldata, 
    output reg LSfree, 
    //with ram
    output wire RWstate, 
    output reg[`AddrBus]        RWaddr, 
    input wire[`RAMBus]         ReadData, 
    output reg[`RAMBus]         WrtData
)
    reg status;
    //0:free,1:working
    
    reg             Waiting[1:0];
    reg             WaitingRW[1:0];
    //Waiting[0]:inst, Waiting[1]:LS
    reg [`AddrBus]  WaitingAddr[1:0];
    reg [`DataBus]  WaitingData;
    //only Save can put something here
    
    reg             RW;
    reg             Port;//0 for inst and 1 for LS
    reg [`StageBus] stage;
    reg [`AddrBus]  AddrPlatform;
    reg [`DataBus]  DataPlatformR;
    reg [`RAMBus]   DataPlatformW[3:0];

    assign instFree = status == `IsFree || Waiting[`instPort] == `NotUsing;
    assign LSfree = status == `IsFree || Waiting[`LSport] == `NotUsing;
    assign RWaddr = AddrPlatform;
    assign RWstate = RW;
    assign WrtData = DataPlatformW[stage];

    integer i;
    always @ (negedge clk or posedge rst) begin
      if (rst == `Enable) begin
        status <= `IsFree;
        for (i = 0;i < 2;i = i + 1) begin
          Waiting[i] <= `NotUsing;
          WaitingRW[i] <= `Read;
          WaitingAddr[i] <= `addrFree;
          DataPlatform[i] <= `dataFree;
        end
        WaitingData <= `dataFree;
        RW <= `Read;
        stage <= 2'b00;
        AddrPlatform <= `addrFree;

        //output
        instOutEn <= `Disable;
        inst <= `dataFree;
        LOutEn <= `Disable;
        Ldata <= `dataFree;
        RWstate <= `Read;
        WrtData <= `RAMdataFree;
      end else begin
        //input and fill in
        if (instEn == `Enable && Waiting[`instPort] == `NotUsing) begin
          Waiting[`instPort] <= `IsUsing;
          WaitingAddr[`instPort] <= instAddr;
          WaitingRW[`instPort] <= `Read;
        end
        //input and fill in
        if (dataEn == `Enable && Waiting[`LSport] == `NotUsing) begin
          Waiting[`LSport] <= `IsUsing;
          WaitingAddr[`LSport] <= dataAddr;
          WaitingRW[`LSport] <= LSRW;
          WaitingData <= Sdata;
        end

        case (status)
          `IsFree: begin
          //A free state cannot come up with a waiting inst which is thrown in the past
          //if it is thrown when the state is free, it is handle there, 
          //if it is thrown when the state is busy, it waited but then the state cannot turn to free
            if (dataEn == `Enable) begin
              RW <= LSRW;
              DataPlatformR <= `dataFree;
              DataPlatformW <= Sdata;
              AddrPlatform <= dataAddr;
              stage <= 2'b00;
              status <= `NotFree;
              Port <= `LSport;

              Waiting[`LSport] <= `NotUsing;
              WaitingRW[`LSport] <= `Read;
              WaitingAddr[`LSport] <= `addrFree;
              WaitingData <= `dataFree;
            end else if (instEn == `Enable)begin
              RW <= `Read;
              DataPlatformR <= `dataFree;
              DataPlatformW <= `dataFree;
              AddrPlatform <= instAddr;
              stage <= 2'b00;
              status <= `NotFree;
              Port <= `instPort;

              Waiting[`instPort] <= `NotUsing;
              WaitingRW[`instPort] <= `Read;
              WaitingAddr[`instPort] <= `addrFree;
            end else begin
              status <= `IsFree;
            end
          end
          `NotFree: begin
            case (stage)
              2'b00: DataPlatformR[7:0] <= ReadData;
              2'b01: DataPlatformR[15:8] <= ReadData;
              2'b10: DataPlatformR[23:16] <= ReadData;
              2'b11: DataPlatformR[31:24] <= ReadData;
            endcase
            if (stage == `FinalStage) begin
              instOutEn <= Port == `instPort;
              inst <= Port == `instPort ? DataPlatformR : `dataFree;
              LSoutEn <= Port == `LSport;
              Ldata <= Port == `Lport ? DataPlatformR : `dataFree;
              if (Waiting[`LSport] == `Enable) begin
                RW <= WaitingRW[`LSport];
                DataPlatformR <= `dataFree;
                DataPlatformW <= WaitingData;
                AddrPlatform <= WaitingAddr[`LSport];
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `LSport;

                Waiting[`LSport] <= `NotUsing;
                WaitingRW[`LSport] <= `Read;
                WaitingAddr[`LSport] <= `addrFree;
                WaitingData <= `dataFree;
              end else if (Waiting[`instPort] == `Enable) begin
                RW <= WaitingRW[`instPort];
                DataPlatformR <= `dataFree;
                DataPlatformW <= `dataFree;
                AddrPlatform <= WaitingAddr[`instPort];
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `instPort;

                Waiting[`instPort] <= `NotUsing;
                WaitingRW[`instPort] <= `Read;
                WaitingAddr[`instPort] <= `addrFree;
              end else if (dataEn == `Enable) begin
                RW <= LSRW;
                DataPlatformR <= `dataFree;
                DataPlatformW <= Sdata;
                AddrPlatform <= dataAddr;
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `LSport;

                Waiting[`LSport] <= `NotUsing;
                WaitingRW[`LSport] <= `Read;
                WaitingAddr[`LSport] <= `addrFree;
                WaitingData <= `dataFree;
              end else if (instEn == `Enable) begin
                RW <= `Read;
                DataPlatformR <= `dataFree;
                DataPlatformW <= `dataFree;
                AddrPlatform <= instAddr;
                stage <= 2'b00;
                status <= `NotFree;
                Port <= `instPort;

                Waiting[`instPort] <= `NotUsing;
                WaitingRW[`instPort] <= `Read;
                WaitingAddr[`instPort] <= `addrFree;
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